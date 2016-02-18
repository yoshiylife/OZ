/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdarg.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "channel.h"
#include "queue.h"
#include "proc.h"
#include "ot.h"
#include "cl.h"
#include "debugSupport.h"
#include "executor/method-invoke.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"

extern void bcopy(char *b1, char *b2, int len);

static	OZ_MonitorRec	prLock ;
static	OzProcessRec	prTable[N_OZ_PROCESS] ;
static	OzProcess	prTableBrk = prTable + N_OZ_PROCESS ;
static	OzProcess	prFreeProcs = NULL ;
static	int		prLastPID = 0 ;

static	void	no_op()
{
	OzError("invalid channel operation for Process");
}

static	OzRecvChannelOpsRec	recv_ops = {
	(OID	(*)())no_op,
	(int	(*)())no_op,
	(char	*(*)())no_op,
	(void	*(*)())no_op,
	(Oz_ExceptionCatchTable	(*)())no_op,
	no_op,
	no_op,
	(void (*)(OzRecvChannel, OZ_ExceptionIDRec, long long, char))no_op,
	no_op
} ;

inline OzProcess
find_process( int pid )
{
	OzProcess	proc ;

	for ( proc = prTable ; proc < prTableBrk ; proc ++ ) {
		if ( proc->status != PROC_FREE
			&& (proc->pid & 0x0ffffff) == pid ) return( proc ) ;
	}

	return( NULL ) ;
}

static long long invoke(void (*func)(), int size, void *args)
{
  void *p;
  *((int **)args) = (int *)(((int **)args) + 2); /* Magic ! */
  p = __builtin_apply(func, args, size);  /* GCC C extentions */
  __builtin_return(p);                    /* GCC C extentions */
}

static	void
fork_process_stub( OzProcess proc, void (*pc)(), OZ_ClassID cid, char fmt )
{
 volatile int		block ;
 volatile long long	rval = 0LL ;
 volatile ClassCode	code = NULL ;
	void		*args = proc->args ;
	int		size = proc->size ;
	void		*entry ;
	OZ_ExceptionRec	e_rec ;

	block = ThrBlockSuspend() ;
	OtInvokePre( proc->chan.o, 0, 0 ) ;
	OzExecInitializeExceptionHandler( &e_rec, 1 ) ;
	OzExecPutEidIntoCatchTable( &e_rec, OzExceptionAbort ) ;
	OzExecRegisterExceptionHandlerFor( &e_rec ) ;
	if ( ! SETJMP( e_rec.jmp ) ) {
		ThrUnBlockSuspend( block ) ;
		if ( cid ) code = ClGetCode( cid ) ;
		switch ( fmt ) {
		/* 8bytes type(long long) */
		case 'l': case 'd': case 'P': case 'G': case 'Z':
		rval = (long long)((long long (*)())invoke)(pc, size, args);
			break ;
		/* pointer type(void *) */
		case 'O': case 'S': case 'R': case 'A':
		rval = (long long)(int)(((void *(*)())invoke)(pc, size, args));
			break ;
		/* 4bytes type(int) */
		case 'c': case 's': case 'i': case 'f':
		rval = (long long)((int (*)())invoke)(pc, size, args);
			break ;
		/* void type */
		default:
		((void (*)())invoke)(pc, size, args);
		}
		block = ThrBlockSuspend() ;
		OzExecUnregisterExceptionHandler() ;
	} else {
		block = ThrBlockSuspend() ;
		/* processing for aborting process */
		if ( OzExecEidcmp(OzExceptionDoubleFault, e_rec.eid) == 0 )
			proc->aborted = PROC_EXCEPT_DOUBLE_FAULT;
		else /* i.e. OzExecEidcmp(OzExceptionAbort, e_rec.eid) == 0 */
			proc->aborted = PROC_EXCEPT_ABORTED;
	}
	OtInvokePost( proc->chan.o ) ;

	OzExecEnterMonitor( &prLock ) ;
	switch ( proc->status ) {
	case PROC_RUNNING:
		proc->rval = rval ;
		proc->status = PROC_EXITED ;
		entry = NULL ;
		break ;
	case PROC_DETACHED:
		proc->status = PROC_FREE ;
		proc->next = prFreeProcs ;
		prFreeProcs = proc ;
		entry = proc->chan.o ;
		break ;
	case PROC_JOINED:
		proc->rval = rval ;
		proc->status = PROC_EXITED ;
		OzExecSignalCondition( &proc->wait_join ) ;
		entry = NULL ;
		break ;
	default:
		OzError( "fork_process_stub(): status = %d", proc->status ) ;
		entry = NULL ;
	}
	proc->args = NULL ;
	proc->size = 0 ;
	OzExecExitMonitor( &prLock ) ;

	if ( code ) ClReleaseCode( code ) ;
	if ( entry ) OtReleaseEntry( entry ) ;
	if ( args ) OzFree( args ) ;
	/*
	 * Don't suspend after now becase of channel destroyed.
	 */
	/* ThrUnBlockSuspend( block ) ; */
	ThrExit() ;
}

int
OzExecForkProcess( void (*pc)(), char fmt, int stackSize, int priority,
		      unsigned int debugFlags, int argc, ... )
{
 extern	long long	OzExecGlobalInvoke() ;	/* refer address only */
	int		pid = 0 ;
	va_list		new_args ;
	OzProcess	proc ;
	OZ_Object	self ;
	va_list		args ;
	int		size ;
	int		block ;
	OZ_ClassID	cid ;
	void		*entry = NULL ;
	OZ_MethodImplementation imp = OzExecGetMethodImplementation();
	cid = imp ? ((ClassCode)imp->code)->cid : 0LL ;

	/* following some lines are here for good concurrence */
	size = argc * sizeof(void *) ;
	new_args = (va_list)OzMalloc( size + 3 * sizeof(void *) ) ;

	block = ThrBlockSuspend() ;
	OzExecEnterMonitor( &prLock ) ;

	/* Find process instance & Assigne process ID */
	if ( ! (proc = prFreeProcs) ) goto error ;
	prFreeProcs = proc->next ;
	pid = prLastPID ;
	do {
		if ( pid == 0x0ffffff ) pid = 0 ;
	} while( find_process( ++pid ) ) ;
	prLastPID = pid ;
	proc->pid = OzExecutorID + pid ;

	/* Copy to new process's arguments */
	va_start( args, argc ) ;
	OzMemcpy( ((void **)new_args)+2, args, size ) ;
	if ( pc == (void *)OzExecGlobalInvoke ) {
		self = 0 ;
		proc->chan.caller = va_arg( args, OID ) ;
		proc->chan.callee = va_arg( args, OID ) ;
	} else {
		self = va_arg( args, OZ_Object ) ;
		proc->chan.caller =
			((OzRecvChannel)ThrRunningThread->channel)->callee ;
		proc->chan.callee = proc->chan.caller ;
	}
	va_end( args ) ;
	if ( proc->chan.caller
		!= ((OzRecvChannel)ThrRunningThread->channel)->callee ) {
		OzError( "OzExecForkProcess(): OzExecGlobalInvoke() "
			"caller=%016lx is invalid." ) ;
		pid = 0 ;
		goto error ;
	}
	entry = OtGetEntry( proc->chan.caller ) ;
	if ( ! entry ) {
		pid = 0 ;
		goto error ;
	}
	if ( size & 0x07 ) size = (size & ~7) + 8 ;	/* Round up by 8. */

	/* Set process contents */
	proc->aborted = 0 ;
	proc->chan.ops = &recv_ops ;
	proc->chan.pid = proc->pid ;
	proc->chan.o = entry ;
	proc->args = new_args ;
	proc->size = size ;
	OzInitializeMonitor( &proc->chan.vars.lock ) ;
	proc->chan.vars.peer.rchan = 0 ;
	proc->chan.vars.next = 0 ;
	proc->chan.vars.readyToInvoke = 0 ;
	proc->chan.vars.cvid = 0 ;
	proc->chan.vars.slot1 = 0 ;
	proc->chan.vars.slot2 = 0 ;
	proc->chan.vars.args = NULL ;
	proc->chan.vars.fmt = NULL ;
	proc->chan.vars.elist = NULL ;
	proc->chan.t = ThrCreate( (void (*))fork_process_stub,
			&proc->chan, stackSize * 4, priority,
			DsMaskProcess(debugFlags, self), 5, proc,pc,cid,fmt ) ;
	if ( ! proc->chan.t ) {
		proc->status = PROC_FREE ;
		proc->next = prFreeProcs ;
		prFreeProcs = proc ;
		pid = 0 ;
	} else {
		proc->status = PROC_RUNNING ;
		proc->args = new_args ;
		proc->size = size ;
		ThrSchedule( proc->chan.t ) ;
	}

error:
	OzExecExitMonitor( &prLock ) ;
	ThrUnBlockSuspend( block ) ;
	if ( ! pid ) {
		if ( new_args ) OzFree( new_args ) ;
		if ( entry ) {
			OtReleaseEntry( entry ) ;
			OzExecRaise( OzExceptionForkFailed, 0, 0 ) ;
			/* NOT REACHED */
		}
		OzExecRaise( OzExceptionObjectNotFound, proc->chan.caller, 0 ) ;
		/* NOT REACHED */
	}
	return( pid ) ;
}

void
OzExecDetachProcess( int pid )
{
	OzProcess	proc;
	int		block ;
	void		*entry ;

	block = ThrBlockSuspend() ;

	OzExecEnterMonitor(&prLock);
	proc = find_process(pid);
	switch (proc->status) {
	case PROC_RUNNING:
		proc->status = PROC_DETACHED;
		entry = NULL ;
		break;
	case PROC_EXITED:
		proc->status = PROC_FREE;
		proc->next = prFreeProcs ;
		prFreeProcs = proc ;
		entry = proc->chan.o ;
		break;
	default:
		OzError("process_detach: status = %d", proc->status);
		entry = NULL ;
	}
	OzExecExitMonitor(&prLock);

	if ( entry ) OtReleaseEntry( entry ) ;
	ThrUnBlockSuspend( block ) ;
}

long long
OzExecJoinProcess( int pid )
{
	long long 	rval;
	OzProcess	proc;
	int		block ;
	int		aborted ;
	void		*entry ;

	block = ThrBlockSuspend() ;

	OzExecEnterMonitor(&prLock);
	proc = find_process(pid);
	switch (proc->status) {
	case PROC_RUNNING:
		proc->status = PROC_JOINED;
		OzExecWaitCondition(&prLock, &(proc->wait_join));
		proc->status = PROC_FREE;
		proc->next = prFreeProcs ;
		prFreeProcs = proc ;
		entry = proc->chan.o ;
		aborted = proc->aborted ;
		break;
	case PROC_EXITED:
		proc->status = PROC_FREE;
		proc->next = prFreeProcs ;
		prFreeProcs = proc ;
		entry = proc->chan.o ;
		aborted = proc->aborted ;
		break;
	default:
		OzError("process_join: status = %d", proc->status);
		entry = NULL ;
		aborted = 0 ;
	}
	rval = proc->rval;
	OzExecExitMonitor(&prLock);
	if ( entry ) OtReleaseEntry( entry ) ;
	ThrUnBlockSuspend( block ) ;

	if (proc->aborted == PROC_EXCEPT_ABORTED) {
#if	0
OzDebugf("OzJoinProcess: Child Aborted\n");
#endif
		OzExecRaise(OzExceptionChildAborted, OzExecutorID|pid, 0);
	}
	if (proc->aborted == PROC_EXCEPT_DOUBLE_FAULT) {
#if	0
OzDebugf("OzJoinProcess: Child Double Fault\n");
#endif
		OzExecRaise(OzExceptionChildDoubleFault, OzExecutorID|pid, 0);
	}

	return(rval);
}

void
OzExecAbortProcess( int pid )
{
	OzProcess	proc ;
	int		block ;
	int		self ;

	if ( ThrRunningThread->channel ) {
		self = ((OzRecvChannel)ThrRunningThread->channel)->pid ;
		if ( pid == (self & 0x0ffffff) ) {
			OzExecRaise( OzExceptionKillSelf, OzExecutorID|pid, 0 );
		}
	}

	block = ThrBlockSuspend() ;
	OzExecEnterMonitor(&prLock);
	if ( ! (proc = find_process( pid )) ) goto error ;

	OzExecEnterMonitor( &proc->chan.vars.lock ) ;
	if ( proc->chan.vars.next ) {
		proc->chan.vars.next->ops->send_abort( proc->chan.vars.next ) ;
		/* proc->chan.vars.next = 0 ; */
	} else ThrAbortThread( proc->chan.t ) ;
	OzExecExitMonitor( &proc->chan.vars.lock ) ;

error:
	OzExecExitMonitor(&prLock);
	ThrUnBlockSuspend( block ) ;
}

static	int
ps_sub( HashHeader header, void *arg )
{
	OzProcess	proc = (OzProcess)header ;
	static	char	*status[] = {
		0,
		"running",
		"exited",
		"detached",
		"joined",
	} ;
	OzPrintf( "%016lx %s\n", proc->pid, status[proc->status] ) ;
	return( 0 ) ;
}

static	int
prCmdList( char *name, int argc, char *argv[], int sline, int eline )
{
	PrMapProcessTable( ps_sub, NULL ) ;
	return( 0 ) ;
}

static	int
prCmdKill( char *name, int argc, char *argv[], int sline, int eline )
{
	int	pid ;

	if ( argc != 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	pid = OzStrtol( argv[1], NULL, 16 ) ;
	if ( pid <= 0 ) {
		*argv = NULL ;
		return( -1 ) ;
	}
	OzExecAbortProcess( pid ) ;

	return( 0 ) ;
}

int
PrInit()
{
	OzProcess	proc ;

	OzInitializeMonitor( &prLock ) ;
	proc = prTableBrk ;
	while ( prTable != proc -- ) {
		proc->pid = 0 ;
		proc->next = prFreeProcs ;
		prFreeProcs = proc ;
	}
	OzShAppend( "process", "", NULL, "", "Process commands" ) ;
	OzShAppend( "process", "list", prCmdList, "",
		"Print status of processes" ) ;
	OzShAppend( "process", "kill", prCmdKill, "<process #>",
		"Kill process" ) ;
	OzShAlias( "process", "list", "ps" ) ;

	return( 0 ) ;
}

int
PrMapProcessTable( int (func)(), void *arg )
{
	int	count = 0 ;
	int	block ;
	OzProcess	proc ;

	block = ThrBlockSuspend() ;

	OzExecEnterMonitor( &prLock ) ;
	for ( proc = prTable ; proc < prTableBrk ; proc ++ ) {
		if ( proc->status != PROC_FREE ) {
			if ( func( proc, arg ) == 0 ) count ++ ;
		}
	}
	OzExecExitMonitor( &prLock ) ;

	ThrUnBlockSuspend(block ) ;

	return( count ) ;
}
