/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Multithread system: scheduler module
 *
 *	IMPORTANT:
 *		You can only call Sig..., Thr... or thr... 
 *		You must be block signal before calling thr...
 *		
 */
/* unix system include */
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <stdarg.h>
#include <fcntl.h>
#include <malloc.h>
#include <memory.h>
#include <sys/types.h>
/* multithread system include */
#include "thread.h"
#include "thread/print.h"
#include "thread/signal.h"
#include "thread/stack.h"
#include "thread/breakpoint.h"

/*
 * Don't include any other module
 */


#if	defined(SVR4)
#define	THREAD_STACK_SIZE	(4096 * 8)
#define	SIGNAL_STACK_SIZE	(4096 * 4)
#else	SVR4
#define	THREAD_STACK_SIZE	(4096 * 8)
#define	SIGNAL_STACK_SIZE	(4096 * 16)
#endif	SVR4

#define	SIGNAL_STACK_STOCK

#define	THREAD_ID_MAX		999


/*
 *	system calls
 */
#if	defined(SVR4)
#define	SETJMP( env )		setjmp( (env) )
#define	LONGJMP( env, val )	longjmp( (env), (val) )
#define	GETPAGESIZE()		sysconf(_SC_PAGESIZE)
#else	/* SVR4 */
#define	SETJMP( env )		_setjmp( (env) )
#define	LONGJMP( env, val )	_longjmp( (env), (val) )
#define	GETPAGESIZE()		getpagesize()
extern	int	getpagesize() ;
#endif	/* SVR4 */


/*
 *	External Function Signature without include file
 */
extern	void	thrJumpThread() ;
extern	void	ThrStartupIO() ;
extern	void	ThrCleanupIO() ;
extern	void	startup() ;
extern	void	cleanup() ;


/*
 *	Global variable
 */
u_int		OzDebugFlags = NULL ;
int		ThrDevZero ;			/* /dev/zero file descriptor */
int		ThrPageSize ;			/* MMU page size */


/*
 *	Internal variable
 */
	/* Don't staic, becase of inline statement */
	Thread	ThrRunningThread = NULL ;
	Thread	thrReadyThreads = NULL ;
	Thread	thrSuspendThreads = NULL ;

static	Thread	thrThreadTable ;
static	Thread	thrThreadTableBreak ;


static	Thread	thrTimeoutThreads = NULL ;
static	Thread	thrFreeThreads = NULL ;
static	Thread	thrDefunctThreads = NULL ;
#ifdef	SIGNAL_STACK_STOCK
static	caddr_t	*thrFreeSignalStacks = NULL ;
#endif	SIGNAL_STACK_STOCK

static	Thread	thrIdleThread ;
static	u_int	thrIdleTimes ;

static	ThreadRec	thrMain ;
static	int		thrLastTID = -1 ; /* at first create thread id = 0 */

static	void
thrAllocSignalStack( stack_t *ss )
{
	caddr_t	*stack ;

#ifdef	SIGNAL_STACK_STOCK
	if ( thrFreeSignalStacks == NULL ) {
#endif	SIGNAL_STACK_STOCK
		stack = (caddr_t *)stkAlloc( SIGNAL_STACK_SIZE ) ;
#ifdef	SIGNAL_STACK_STOCK
	} else {
		stack = thrFreeSignalStacks ;
		thrFreeSignalStacks = (caddr_t *)*stack ;
	}
#endif	SIGNAL_STACK_STOCK

	ss->ss_sp = (caddr_t)stack ;
#if	defined(SVR4)
	ss->ss_size = SIGNAL_STACK_SIZE ;
#else	/* SVR4 */
	ss->ss_sp += SIGNAL_STACK_SIZE ;
#endif	/* SVR4 */
	SIGSTACK_FLAGS( *ss ) = 0 ;
}

static	void
thrFreeSignalStack( stack_t *ss )
{
	caddr_t	*stack ;

#if	!defined(SVR4)
	ss->ss_sp -= SIGNAL_STACK_SIZE ;
#endif
	stack = (caddr_t *)ss->ss_sp ;
	if ( stack ) {
#ifdef	SIGNAL_STACK_STOCK
		*stack = (caddr_t)thrFreeSignalStacks ;
		thrFreeSignalStacks = stack ;
#else	SIGNAL_STACK_STOCK
		stkFree( (caddr_t)stack, SIGNAL_STACK_SIZE ) ;
#endif	SIGNAL_STACK_STOCK
	} else {
		ThrPanic( "thrFreeSignalStack(): ss_sp is NULL." ) ;
	}

	ss->ss_sp = NULL ;
#if	defined(SVR4)
	ss->ss_size = 0 ;
#endif	/* SVR4 */
	SIGSTACK_FLAGS( *ss ) = 0 ;
}

inline	Thread
thrFind( int tid )
{
	Thread	t ;

	for ( t = thrThreadTable ; t < thrThreadTableBreak ; t ++ ) {
		if ( t->status != FREE && t->tid == tid ) return( t ) ;
	}

	return( NULL ) ;
}

static	Thread
thrCreate( void (*pc)(), int stackSize, int priority, int argc, va_list args )
{
	Thread	t ;
	int	i ;
	int	*fp ;
	char	*sp ;

	if ( (t = thrFreeThreads) == NULL ) {
		ThrError( "thrCreate(): Not found FREE thread." ) ;
		return( NULL ) ;
	}
	thrFreeThreads = t->next ;

	memset( (char *)t, 0, sizeof(ThreadRec) ) ;

	i = thrLastTID ;
	do {
		if ( i == THREAD_ID_MAX ) i = 0 ;
	} while ( thrFind( ++ i ) ) ;
	thrLastTID = i ;

	t->tid = i  ;
	t->priority = priority ;
	t->status = CREATE ;
	t->stack_size = ( stackSize > 0 ? stackSize : THREAD_STACK_SIZE ) ;
	t->stack = stkAlloc( t->stack_size ) ;
	t->stack_bottom = sp = t->stack + t->stack_size ;
	SIGSTACK_FLAGS(t->signal_stack) = 0 ;

	i = (argc + 1) & ~1 ;		/* stack align to 8 */
	sp -= ( (i < 6 ? 6 : i) + 1 ) * sizeof(int) + 16 ;
	fp = (int *)sp ;
	for ( i = 0 ; i < argc ; i ++ ) *fp ++ = va_arg( args, int ) ;
#if	defined(SVR4)
	t->context[1] = (int)sp ;
	t->context[2] = (int)pc ;
#else	/* SVR4 */
	t->context[2] = (int)sp ;
	t->context[3] = (int)pc ;
#endif	/* SVR4 */

	t->sigBlocking = -1 ;
	t->suspend_blocking = 1 ;
	t->first = 1 ;
#ifdef INTERSITE
	t->foreign_flag=0; /* initialize foreign flag */
#endif
	return( t ) ;
}

/* Only called by thrJumpThread */
static	void
thrStart()
{
	thrEnqueue( &thrReadyThreads, ThrRunningThread ) ;
	thrReschedule() ;	/* Don't replace above lines with thrReady() */
	SigUnBlock( 0 ) ;
	ThrUnBlockSuspend( 0 ) ;
}

/* Don't static for INLINE */
void
thrSwitch( Thread t )
{
/*	register Thread	run_thread = ThrRunningThread ; */
  volatile Thread run_thread;
  run_thread = ThrRunningThread;

	run_thread->errno = errno ;
	run_thread->debugFlags = OzDebugFlags ;
	if ( SETJMP(run_thread->context) ) {
		while ( thrDefunctThreads ) {
			register Thread defunct ;
			defunct = thrDefunctThreads ;
			thrDefunctThreads = thrDefunctThreads->next ;
			stkFree( defunct->stack, defunct->stack_size ) ;
			defunct->status = FREE ;
			defunct->next = thrFreeThreads ;
			thrFreeThreads = defunct ;
		}
/*		errno = run_thread->errno ;
		OzDebugFlags = run_thread->debugFlags ;
*/
		return ;			/* to signaled pc */
	}

	ThrRunningThread = t ;
	t->status = RUNNING ;
	errno = t->errno ;
	OzDebugFlags = t->debugFlags ;

	run_thread->sigBlocking = sigBlocking ;
	if (run_thread->sigBlocking && !t->sigBlocking)
		SigDisable() ;
	else if (!run_thread->sigBlocking && t->sigBlocking)
		thrAllocSignalStack( &(t->signal_stack) ) ;

	if (!run_thread->sigBlocking || !t->sigBlocking)
		SIGSTACK(&(t->signal_stack), &(run_thread->signal_stack));
	else if ( t != run_thread ) {
		t->signal_stack = run_thread->signal_stack ;
		run_thread->signal_stack.ss_sp = NULL ;
		SIGSTACK_FLAGS(run_thread->signal_stack) = 0 ;
	}

	sigBlocking = t->sigBlocking;
	if (run_thread->sigBlocking && !t->sigBlocking) {
		thrFreeSignalStack( &(run_thread->signal_stack) );
	} else if (!run_thread->sigBlocking && t->sigBlocking) {
		SigEnable() ;
	}

	if ( t->first ) {	/* first dispatch */
		register void	(*pc)() ;
		register void	*sp ;
#if	defined(SVR4)
	sp = (char *)t->context[1] ;
	pc = (void (*))t->context[2] ;
#else	/* SVR4 */
	sp = (char *)t->context[2] ;
	pc = (void (*))t->context[3] ;
#endif	/* SVR4 */
		t->first = 0 ;
		thrJumpThread( thrStart, pc, ThrExit, sp ) ;
		/* NOT REACHED */
	}
	LONGJMP( t->context, 1 ) ;
	/* NOT REACHED */
}

static	void
thrIdle( int ticks )
{
	ThrBlockSuspend() ;

	/* Startup module with multithread */
	ThrStartupIO() ;

	/* Start alarm */
	thrIdleTimes = 0 ;
	SigUalarm( ticks, ticks ) ;

	/* OZ++ System Startup */
	ThrFork( startup, 0, MAX_PRIORITY, 0 ) ;

	/* Dispatch */
	for (;;) {
		SigPause() ;
		SigBlock() ;
		thrReschedule() ;
		SigUnBlock( 0 ) ;
	}
}

static	void
thrHandlerSIGALRM( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION	SIGALRM Deferrable
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */
	Thread	t ;

	/* Timer & Timeout service */
	if ( thrTimeoutThreads ) {
		thrTimeoutThreads->timeout_val -- ;
		while( thrTimeoutThreads ) {
			t = thrTimeoutThreads ;
			if ( t->timeout_val ) break ;
			thrTimeoutThreads = t->next_timeout ;
			t->on_timeout_queue = 0 ;

			/* Timeout sercice ? */
			if ( t->wait_cv ) thrDequeue( t->wait_cv, t ) ;

			/* Schedule */
			thrReady( t ) ;
		}
	}

	thrYield() ;
	if ( ThrRunningThread == thrIdleThread ) {
		if ( ! ++ thrIdleTimes ) thrIdleTimes = 1 ;
	}
}

static	void
thrHandlerSIGSEGV( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION	SIGSEGV Not deferrable
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */

	ThrRunningThread->suspend_count ++ ;
	ThrRunningThread->status = SUSPEND ;
	thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
	thrEnqueue( &thrSuspendThreads, ThrRunningThread ) ;
	if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
	ThrError( "%s(%s) on thread %d [0x%x]",
			SigName(signo), SigDetail(signo,code),
			ThrRunningThread->tid, ThrRunningThread ) ;
	ThrError( "pc=0x%x sp=0x%x addr=0x%x.\n",
			GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;

	thrSwitch( thrReadyThreads ) ;		/* Don't call thrReschedule() */

	/*
	 * MOST IMPORTANT
	 * Following some lines don't remove becase to must be saved these.
	 */
	ThrPrintf( "RESUME thread %d [0x%x] from %s\n",
		ThrRunningThread->tid, ThrRunningThread, SigName(signo) ) ;
	ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
}

static	void
thrHandlerSIGHUP( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION	SIGHUP Not deferrable
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */

	ThrPrintf( "%s on thread %d [0x%x]\n", SigName(signo),
			ThrRunningThread->tid, ThrRunningThread ) ;
	if ( gregs ) {
		ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
	}

	SigPrintf( "%s shutdown executor...\n", SigName(signo) ) ;

	ThrStop( SIGHUP ) ;

	/*
	 * MOST IMPORTANT
	 * Following some lines don't remove becase to must be saved these.
	 */
	ThrPrintf( "RESUME thread %d [0x%x] from %s\n",
		ThrRunningThread->tid, ThrRunningThread, SigName(signo) ) ;
	if ( gregs ) {
		ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
	}
}

/* Don't static for INLINE */
void
thrTimeout( Thread t, int timeout )
{
	Thread	*pt ;

	for ( pt = &thrTimeoutThreads ; *pt ; pt = &((*pt)->next_timeout) ) {
		if ( (*pt)->timeout_val >= timeout ) break ;
		timeout -= (*pt)->timeout_val ;
	}
	t->timeout_val = timeout ;
	if ( (t->next_timeout=*pt) ) t->next_timeout->timeout_val -= timeout ;
	*pt = t ;
	t->on_timeout_queue = 1 ;
}

/* Don't static for INLINE */
int
thrUnTimeout( Thread t )
{
	if ( thrTimeoutThreads == t ) thrTimeoutThreads = t->next_timeout ;
	else {
		Thread tt ;
		for ( tt = thrTimeoutThreads ; tt ; tt = tt->next_timeout ) {
			if ( tt->next_timeout == t ) {
				tt->next_timeout = t->next_timeout ;
				break ;
			}
		}
	}
	if ( t->next_timeout ) t->next_timeout->timeout_val += t->timeout_val ;
	t->on_timeout_queue = 0 ;
	return( t->timeout_val ) ;
}

/* Don't static for INLINE */
void
thrSuspend()			/* called from ThrUnBlockSuspend() only */
{
	int	mask ;

	mask = SigBlock() ;
	ThrRunningThread->suspend_blocking = 0 ;
	if ( ThrRunningThread->suspend_count
		&& ThrRunningThread->status == RUNNING ) {
		ThrRunningThread->status = SUSPEND ;
		thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
		thrEnqueue( &thrSuspendThreads, ThrRunningThread ) ;
		if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
		thrSwitch( thrReadyThreads ) ;/* Don't call thrReschedule() */
	}
	SigUnBlock( mask ) ;
}

void
ThrPrintf( const char *aFormat, ... )
{
	va_list	args ;

	va_start( args, aFormat ) ;
	PrnFormat( (PRNOUT *)write, (void *)LOGGING, aFormat, args ) ;
	va_end( args ) ;
}

void
ThrVprintf( const char *aFormat, va_list args )
{
	PrnFormat( (PRNOUT *)write, (void *)LOGGING, aFormat, args ) ;
}

void
ThrError( const char *aFormat, ... )
{
	va_list	args ;

	va_start( args, aFormat ) ;
	SigPrintf( "*ERROR* %r\n", aFormat, args ) ;
	va_end( args ) ;
}

void
ThrPanic( const char *aFormat, ... )
{
	va_list	args ;

	va_start( args, aFormat ) ;
	SigAbort( "*PANIC* %r\n", aFormat, args ) ;
	/* NOT REACHED */
	va_end( args ) ;
}

unsigned
ThrSleep( unsigned seconds )
{
	int	mask ;

	/* Request Timer service to scheduler */
	mask = SigBlock() ;
	ThrRunningThread->status = WAIT_TIMER ;
	thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
	thrTimeout( ThrRunningThread, seconds * SigClockTicks ) ;
	if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
	thrSwitch( thrReadyThreads ) ;		/* Don't call thrReschedule() */
	SigUnBlock( mask ) ;
	return( seconds * SigClockTicks ) ;
}

void
ThrYield()
{
	int	mask ;

	mask = SigBlock() ;
	thrYield() ;
	SigUnBlock( mask ) ;
}

void
ThrExit()
{
	SigBlock() ;
	ThrRunningThread->status = DEFUNCT ;
	thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
	if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
	else {
		ThrRunningThread->next = thrDefunctThreads ;
		thrDefunctThreads = ThrRunningThread ;
	}
	thrSwitch( thrReadyThreads ) ;		/* Don't call thrReschedule() */
	/* NOT REACHED */
	ThrPanic( "OzExitThread(): DEFUNCT thread is scheduled." ) ;
}

Thread
ThrFork( void (*pc)(), int stackSize, int priority, int argc, ... )
{
	Thread	t ;
	va_list	args ;
	int	mask ;

	mask = SigBlock() ;
	va_start( args, argc ) ;
	t = thrCreate( pc, stackSize, priority, argc, args ) ;
	va_end( args ) ;
	if ( t ) {
		t->StdIn = ThrRunningThread->StdIn ;
		t->StdOut = ThrRunningThread->StdOut ;
		t->StdErr = ThrRunningThread->StdErr ;
#ifdef INTERSITE
		t->foreign_flag = (ThrRunningThread->foreign_flag) & 1;
#endif
		thrSwitch( t ) ;		/* Don't call thrReschedule() */
	}
	SigUnBlock( mask ) ;

	return( t ) ;
}

Thread
ThrCreate( void (*pc)(), void *channel, int stackSize,
			int priority, unsigned int debugFlags, int argc, ... )
{
	Thread	t ;
	int	mask ;
	va_list	args ;

	mask = SigBlock() ;
	va_start( args, argc ) ;
	t = thrCreate( pc, stackSize, priority, argc, args ) ;
	va_end( args ) ;
	if ( t ) {
		t->debugFlags = debugFlags ;
		t->StdIn = ThrRunningThread->StdIn ;
		t->StdOut = ThrRunningThread->StdOut ;
		t->StdErr = ThrRunningThread->StdErr ;
		t->channel = channel ;
	}
	SigUnBlock( mask ) ;
	return( t ) ;
}

void
ThrSchedule( Thread t )
{
	int	mask ;

	mask = SigBlock() ;
	if ( t->status == CREATE ) {
		thrSwitch( t ) ;		/* Don't call thrReschedule() */
	}
	SigUnBlock( mask ) ;

	return ;
}

int
ThrMapTable( int (func)(), void *arg )
{
	Thread	t ;
	int	count = 0 ;
	int	ret ;
	int	mask ;

	for ( t = thrThreadTable ; t < thrThreadTableBreak ; t ++ ) {
		mask = SigBlock() ;
		ret = t->status != FREE ? func( t, arg ) : 1 ;
		SigUnBlock( mask ) ;
		if ( ret == 0 ) count ++ ;
		if ( ret < 0 ) break ;
	}

	return( count ) ;
}

int
ThrSuspend( Thread t )
{
	int	ret = -1 ;
	int	mask ;

	mask = SigBlock() ;
	if ( t == NULL ) t = ThrRunningThread ;

	switch( t->status ) {
	case	FREE:
	case	DEFUNCT:
		break ;
	case	WAIT_SUSPEND:
	case	WAIT_TIMER:
	case	WAIT_COND:
	case	WAIT_LOCK:
	case	SUSPEND:
		t->suspend_count ++ ;
		ret = (t->suspend_count == 1) ? 0 : t->suspend_count ;
		break ;
	case	WAIT_IO:
	case	CREATE:
	case	READY:
		t->suspend_count ++ ;
		if ( t->suspend_blocking == 0 ) {
			if ( t->status == READY ) {
				t->status = SUSPEND ;
				thrDequeue( &thrReadyThreads, t ) ;
				thrEnqueue( &thrSuspendThreads, t ) ;
			}
			ret = 0 ;
		} else {
			ThrRunningThread->status = WAIT_SUSPEND ;
			thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
			thrEnqueue( &t->suspend_waiters, ThrRunningThread );
			thrSwitch( thrReadyThreads ) ;
						/* Don't call thrReschedule() */
			if ( t->status == DEFUNCT ) {
				if ( t->suspend_count == 1 ) {
					t->next = thrDefunctThreads ;
					thrDefunctThreads = t ;
					ret = -2 ;
				} else t->suspend_count -- ;
			} else ret = 0 ;
		}
		break ;
	case	RUNNING:	/* t == ThrRunningThread */
		t->suspend_count ++ ;
		if ( ! t->suspend_blocking ) {
			t->status = SUSPEND ;
			thrDequeue( &thrReadyThreads, t ) ;
			thrEnqueue( &thrSuspendThreads, t ) ;
			if ( t->suspend_waiters ) thrWakeupWaiters() ;
			thrSwitch( thrReadyThreads ) ;
						/* Don't call thrReschedule() */
		}
		ret = 0 ;
		break ;
	default:
		ThrError( "ThrSuspend(0x%x): illegal status = %d.",
				t, t->status ) ;
	}

	SigUnBlock( mask ) ;

	return( ret ) ;
}

int
ThrResume( Thread t )
{
	int	ret = -1 ;
	int	mask ;

	mask = SigBlock() ;

	if ( 0 < t->suspend_count ) {
		if ( (-- t->suspend_count) == 0 ) {
			switch( t->status ) {
			case SUSPEND:
				thrDequeue( &thrSuspendThreads, t ) ;
				thrReady( t ) ;
				break ;
			case DEFUNCT:
				t->next = thrDefunctThreads ;
				thrDefunctThreads = t ;
				break ;
			default:
				/* Nothing */
			}
			ret = 0 ;
		} else ret = t->suspend_count ;
	}

	SigUnBlock( mask ) ;

	return( ret ) ;
}

int
ThrKill( Thread t )
{
	int	ret = -1 ;
	int	mask ;

	mask = SigBlock() ;

	if ( t->status == SUSPEND ) {
		t->suspend_count ++ ;
		if ( t->suspend_waiters ) thrWakeupWaiters() ;
		thrDequeue( &thrSuspendThreads, t ) ;
		t->status = DEFUNCT ;
#if	0		/* Very danger thread, don't reuse such thread */
			t->next = thrDefunctThreads ;
			thrDefunctThreads = t ;
#endif
		ret = 0 ;
	}

	SigUnBlock( mask ) ;

	return( ret ) ;
}

int
ThrSetStdIn( int aStdIn )
{
	int	mask ;
	int	stdIn ;

	if ( aStdIn < 0 ) return( -1 ) ;

	mask = SigBlock() ;
	stdIn = ThrRunningThread->StdIn ;
	ThrRunningThread->StdIn = aStdIn ;
	SigUnBlock( mask ) ;

	return( stdIn ) ;
}

int
ThrGetStdIn()
{
	int	mask ;
	int	StdIn ;

	mask = SigBlock() ;
	StdIn = ThrRunningThread->StdIn ;
	SigUnBlock( mask ) ;

	return( StdIn ) ;
}

int
ThrSetStdOut( int aStdOut )
{
	int	mask ;
	int	stdOut ;

	if ( aStdOut < 0 ) return( -1 ) ;

	mask = SigBlock() ;
	stdOut = ThrRunningThread->StdOut ;
	ThrRunningThread->StdOut = aStdOut ;
	SigUnBlock( mask ) ;

	return( stdOut ) ;
}

int
ThrGetStdOut()
{
	int	mask ;
	int	StdOut ;

	mask = SigBlock() ;
	StdOut = ThrRunningThread->StdOut ;
	SigUnBlock( mask ) ;

	return( StdOut ) ;
}

int
ThrSetStdErr( int aStdErr )
{
	int	mask ;
	int	stdErr ;

	if ( aStdErr < 0 ) return( -1 ) ;

	mask = SigBlock() ;
	stdErr = ThrRunningThread->StdErr ;
	ThrRunningThread->StdErr = aStdErr ;
	SigUnBlock( mask ) ;

	return( stdErr ) ;
}

int
ThrGetStdErr()
{
	int	mask ;
	int	StdErr ;

	mask = SigBlock() ;
	StdErr = ThrRunningThread->StdErr ;
	SigUnBlock( mask ) ;

	return( StdErr ) ;
}

int
ThrSetPriority( int  aPriority )
{
	int	mask ;
	int	priority ;

	if ( aPriority <= 0 || MAX_PRIORITY <= aPriority ) return( -1 ) ;

	mask = SigBlock() ;
	priority = ThrRunningThread->priority ;
	ThrRunningThread->priority = aPriority ;
	thrYield() ;
	SigUnBlock( mask ) ;

	return( priority ) ;
}

int
ThrGetPriority()
{
	int	mask ;
	int	priority ;

	mask = SigBlock() ;
	priority = ThrRunningThread->priority ;
	SigUnBlock( mask ) ;

	return( priority ) ;
}

int
ThrIdle( unsigned seconds )
{
	u_int	cStamp ;
	u_int	iStamp ;
	u_int	work ;
	int	mask ;
	int	priority ;

	mask = SigBlock() ;
	priority = ThrRunningThread->priority ;
	ThrRunningThread->priority = MAX_PRIORITY ;
	cStamp = SigClockTimes ;
        iStamp = thrIdleTimes ;
	SigUnBlock( mask ) ;

	ThrSleep( seconds ) ;

	mask = SigBlock() ;
	work = SigClockTimes ;
        if ( cStamp > work ) cStamp = work + (~0 - cStamp) ;
        else cStamp = work - cStamp ;
        if ( iStamp > thrIdleTimes ) iStamp = thrIdleTimes + (~0 - iStamp) ;
        else iStamp = thrIdleTimes - iStamp ;
	ThrRunningThread->priority = priority ;
	thrYield() ;
	SigUnBlock( mask ) ;

	return( (iStamp * 100) / cStamp ) ;
}

int
ThrStart( int tmax, int ticks )
{
	Thread	t ;

	/*
	 *	Initialize scheduler module
	 */
	if ( (ThrPageSize = GETPAGESIZE()) <= 0 ) {
		ThrPanic( "GETPAGESIZE(): %m." ) ;
	}
	if ( (ThrDevZero = open( "/dev/zero", O_RDWR ) ) < 0 ) {
		ThrPanic( "open(/dev/zero): %m." ) ;
	}
	if ( tmax < 2 || THREAD_ID_MAX < tmax ) {
		ThrPanic( "ThrStart() : Invalid thread max = %d.", tmax ) ;
	}
	thrThreadTable = malloc( sizeof(ThreadRec) * tmax ) ;
	if ( thrThreadTable == NULL ) {
		ThrPanic( "ThrStart() Can't malloc Thread table[%d]: %m.",
				tmax ) ;
	}
	thrThreadTableBreak = thrThreadTable + tmax ;
	t = thrThreadTableBreak ;
	while ( thrThreadTable != t -- ) {
		t->tid = 0 ;
		t->next = thrFreeThreads ;
		thrFreeThreads = t ;
	}

	/*
	 *	Initialize other modules without multithread.
	 */
	StkInitialize() ;
	SigInitialize() ;
	BrkInitialize() ;

	/*
	 *	Startup multithread scheduler.
	 */
	SigAction( SIGALRM, thrHandlerSIGALRM ) ;
	SigAction( SIGSEGV, thrHandlerSIGSEGV ) ;
	SigAction( SIGBUS, thrHandlerSIGSEGV ) ;
	SigAction( SIGILL, thrHandlerSIGSEGV ) ;
	SigAction( SIGFPE, thrHandlerSIGSEGV ) ;
	SigAction( SIGTERM, thrHandlerSIGHUP ) ;
	SigAction( SIGHUP, thrHandlerSIGHUP ) ;

	/* Create idle thread (tid=0) */
	ThrRunningThread = &thrMain ;
	thrMain.StdIn = 0 ;
	thrMain.StdOut = 1 ;
	thrMain.StdErr = 2 ;
	thrMain.status = READY ;
	thrMain.first = 0 ;
	thrIdleThread = ThrCreate( thrIdle, NULL, 0, 0, 0, 1, ticks ) ;

	/* Multithread scheduler start. */
	sigBlocking = 0 ;
	thrSwitch( thrIdleThread ) ;

	/*
	 *	Cleanup multithread scheduler.
	 */
	SigAction( SIGALRM, SIG_IGN ) ;
	SigAction( SIGSEGV, SIG_DFL ) ;
	SigAction( SIGBUS, SIG_DFL ) ;
	SigAction( SIGILL, SIG_DFL ) ;
	SigAction( SIGFPE, SIG_DFL ) ;
	SigAction( SIGTERM, SIG_DFL ) ;
	SigAction( SIGHUP, SIG_DFL ) ;
	SigAction( SIGTRAP, SIG_DFL ) ;

	/*
	 *	Shutdown other modules without multithread.
	 */
	BrkShutdown() ;
	SigShutdown() ;
	StkShutdown() ;

	/*
	 *	Shutdown scheduler module
	 */
	close( ThrDevZero ) ;
	free( thrThreadTable ) ;

	return( thrMain.aborted ) ;
}

void
ThrStop( int status )
{
	int	mask ;

	SigAction( SIGTERM, SIG_IGN ) ;
	SigAction( SIGHUP, SIG_IGN ) ;

	mask = SigBlock() ;
	ThrRunningThread->priority = MAX_PRIORITY ;
	thrYield() ;
	SigUnBlock( mask ) ;

	/* OZ++ System Cleanup */
	cleanup() ;

	/* Cleanup module with multithread */
	ThrCleanupIO() ;

	/* Stop scheduler */
	SigDisable() ;

	thrMain.aborted = status ;
	thrSwitch( &thrMain ) ;
	/* NOT REACH */
}
