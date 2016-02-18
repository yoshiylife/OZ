/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* multithread system include */
#include "thread/signal.h"
#include "thread/thread.h"
#include "thread/shell.h"
#include "thread/breakpoint.h"
#include "oz++/ozlibc.h"

#include "main.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"

#include "common.h"
#include "dyload.h"
#include "cl.h"

#include "ot.h"
#include "channel.h"

/*
 *	System calls
 */

extern	etext, edata, end ;


static	void
print_status( TStat ts, int sc )
{
	static	char	*strTable[] = {
		"FREE      ",
		"CREATE    ",
		"READY     ",
		"RUNNING   ",
		"SUSPEND   ",
		"WAIT IO   ",
		"WAIT LOCK ",
		"WAIT COND ",
		"WAIT SUSPEND",
		"WAIT TIMER",
		"DEFUNCT   "
	} ;

	if ( ts == SUSPEND && sc == 1 ) OzPrintf( "%s", strTable[READY] ) ;
	else OzPrintf( "%s", strTable[ts] ) ;
}

static	int
print_pc( caddr_t pc )
{
	void		*handle ;
	DlInfoRec	dli ;
	OZ_ClassID	cid ;

	if ( DlIsCore( pc ) ) cid = 0LL ;
	else cid = DlIsClass( pc ) ;
	handle = DlOpen( cid ) ;
	if ( handle == NULL ) {
		if ( cid ) OzPrintf( " %016lx:0x%08x", cid, pc ) ;
		else OzPrintf( " 0x%08x", pc ) ;
		goto error ;
	}
	if ( DlAddr( handle, pc, &dli ) < 0 ) {
		if ( cid ) OzPrintf( " %016lx:0x%08x", cid, pc ) ;
		else OzPrintf( " 0x%08x", pc ) ;
		goto error ;
	}
	if ( dli.sname != NULL ) {
		char	*ptr ;
		char	*buff ;
		OzPrintf( " in " ) ;
		buff = OzMalloc( OzStrlen(dli.sname) + 1 ) ;
		if ( buff == NULL ) ptr = (char *)dli.sname ;
		else {
			OzStrcpy( buff, dli.sname ) ;
			ptr = OzStrchr( buff, ':' ) ;
			if ( ptr ) *ptr = '\0' ;
			ptr = buff ;
		}
		if ( cid ) OzPrintf( "%016lx:%s", cid, ptr ) ;
		else OzPrintf( "<%s>", ptr ) ;
		if ( buff != NULL ) OzFree( buff ) ;
	}

	if ( dli.sline ) {
		if ( dli.fname == NULL || cid ) {
			OzPrintf( " [at %d]", dli.sline ) ;
		} else OzPrintf( " at %s:%d", dli.fname, dli.sline ) ;
	}

error:
	if ( handle != NULL ) DlClose( handle ) ;
	return( 0 ) ;
}

static	void
dump_stack( OZ_Thread t, int mode )
{
	int	signo ;
	int	code ;
	GREGS	*gregs ;
	void	*pc ;
	frame_t	*sp ;
	frame_t	*fp ;
	void	*addr = NULL ;

	if ( t == ThrRunningThread ) {
		OzError( "thread %d Running.", t->tid ) ;
		return ;
	}

#if	defined(SVR4)
	pc = (void *)t->context[2] ;
	sp = (frame_t *)t->context[1] ;
#else	/* SVR4 */
	pc = (void *)t->context[3] ;
	sp = (frame_t *)t->context[2] ;
#endif	/* SVR4 */

	if ( t->signal_stack.ss_onstack ) {
		fp = (frame_t *)sp->r_i6 ;
		signo = fp->r_i0 ;
		code = fp->r_i1 ;
		gregs = (GREGS *)fp->r_i2 ;
		pc = (void *)GREGS_PC(*gregs) ;
		sp = (frame_t *)GREGS_SP(*gregs) ;
		addr = (void *)fp->r_i3 ;
	} else {
		signo = 0 ;
		code = 0 ;
	}

	OzPrintf( "%3d%c", t->tid,
		( signo ? '#' : (1 < t->suspend_count ? '+' : ' ') ) ) ;
	if ( mode == 0 ) {
		int	user ;
		void	*top = pc ;
		void	*next ;
		print_status( t->status, t->suspend_count ) ;
		user = DlIsCore( pc ) ? 0 : 1 ;
		for (;;) {
			if ( (caddr_t)sp < t->stack
				|| t->stack_bottom < (caddr_t)sp ) {
				OzPrintf( " stack overflow" ) ;
				break ;
			}
			next = (void *)sp->r_i7 ;
			sp = (frame_t *)sp->r_i6 ;
			if ( sp->r_i6 == 0 ) break ;
			if ( DlIsCore( next ) == 0 ) user = 1 ;
			else if ( user ) break ;
			pc = next ;
		}
		if ( top == pc ) {
			OzPrintf( " 0x%08x", pc ) ;
			print_pc( pc - (signo == 0 ? 8 : 0) ) ;
		} else {
			OzPrintf( " 0x%08x", pc+8 ) ;
			print_pc( pc ) ;
		}
		if ( t->channel != NULL ) {
			OzRecvChannel	rchan = (OzRecvChannel)t->channel ;
			OzPrintf( " of %016lx", rchan->pid ) ;
		}
		OzPrintf( "\n" ) ;
	} else {
		print_status( t->status, t->suspend_count ) ;
		if ( 1 < t->suspend_count ) {
			OzPrintf( "(+%d) ", t->suspend_count-1 ) ;
		}
		OzPrintf( "[0x%x] ", t ) ;
		if ( t->channel ) {
			OzRecvChannel	rchan = (OzRecvChannel)t->channel ;
			OzPrintf( "pid=%016lx\n", rchan->pid ) ;
			OzPrintf( "caller=%016lx callee=%016lx(0x%x)",
				rchan->caller,rchan->callee,rchan->o->object ) ;
		}
		OzPrintf( "\n" ) ;
		if ( signo ) {
			OzPrintf( "%s(%s)\n", OzStrsignal(signo),
					SigDetail(signo,code) ) ;
			OzPrintf( "<sp=0x%x addr=0x%x>\n", sp, addr ) ;
		} else OzPrintf( "<sp=0x%x>\n", sp ) ;
		OzPrintf( "[0x%x,0x%x]\n", t->stack, t->stack_bottom ) ;
		OzPrintf( "0x%08x", pc ) ;
		print_pc( pc - (signo == 0 ? 8 : 0) ) ;
		OzPrintf( "(0x%x)\n", sp->r_i0 ) ;
		for (;;) {
			if ( (caddr_t)sp < t->stack
				|| t->stack_bottom < (caddr_t)sp ) {
				OzPrintf( " stack overflow\n" ) ;
				break ;
			}
			pc = (void *)sp->r_i7 ;
			sp = (frame_t *)sp->r_i6 ;
			if ( sp->r_i6 == 0 ) break ;
			OzPrintf( "0x%08x", pc+8 ) ;
			print_pc( pc ) ;
			OzPrintf( "(0x%x)\n", sp->r_i0 ) ;
		}
	}
}


typedef	struct	{
	int		tid ;
	OZ_Thread	t ;
	int		(*f)(OZ_Thread t) ;
	int		status ;
} TKey ;

static	int
operate( OZ_Thread t, TKey *key )
{
	if ( t->tid != key->tid ) return( 1 ) ;
	key->t = t ;
	key->status = key->f( t ) ;
	return( 0 ) ;
}

static	int
Where_sub( OZ_Thread t, TKey *key )
{
	if ( t->tid != key->tid ) return( 1 ) ;
	if ( ThrRunningThread == t ) {
		OzPrintf( "Don't dump self thread %d.\n", t->tid ) ;
		return( -1 ) ;
	}
	key->f( t ) ;
	key->t = t ;
	return( 0 ) ;
}

static	int
Where( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	mode = 1 ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], NULL, 0 ) ;
	key.f = ThrSuspend ;

	if ( ThrMapTable( Where_sub, &key ) <= 0 ) {
		OzPrintf( "Not found thread %d.\n", key.tid ) ;
		return( -1 ) ;
	}

	if ( 2 < argc ) mode = OzStrtol( argv[2], NULL, 0 ) ;
	dump_stack( key.t, mode ) ;

	ThrResume( key.t ) ;

	return( 0 ) ;
}

static	int
monitor( char *name, int argc, char *argv[], int sline, int eline )
{
 extern	int	quicktest()	;
	int		result = -2 ;
	OZ_Header	header ;
	OZ_Monitor	monitor ;
	TKey		key ;
	OzRecvChannel	chan ;
	OZ_Thread	t ;

	if ( argc < 3  ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], 0, 0 ) ;
	key.f = ThrSuspend ;
	header = (OZ_Header)OzStrtoul( argv[2], 0, 0 ) ;

	if ( ThrMapTable( Where_sub, &key ) <= 0 ) {
		OzError( "Not found thread %d.", key.tid ) ;
		goto error ;
	}

	chan = (OzRecvChannel)key.t->channel ;
	if ( chan == NULL ) {
		OzPrintf( "No channel\n" ) ;
		goto error ;
	}
	if ( ! quicktest( header, chan->o->heap, 1 ) ) {
		OzError( "part[0x%0x] NG", header ) ;
		goto error ;
	}
	if ( header->h == LOCAL || header->h == STATIC ) {
		header -= header->e+1 ;
	} else {
		OzError( "not object" ) ;
		goto error ;
	}
	if ( ! quicktest( header, chan->o->heap, 1 ) ) {
		OzError( "all[0x%0x] NG\n", header ) ;
		goto error ;
	}
	monitor = (OZ_Monitor)header->t ;
	if ( ! quicktest( monitor, chan->o->heap, 1 ) ) {
		OzError( "monitor[0x%x] NG\n", monitor ) ;
		goto error ;
	}
	OzPrintf( "Thread %d locking.\n", monitor->tid ) ;
	if ( (t = monitor->t) ) {
		do {
			dump_stack( t, 0 ) ;
			t = t->next ;
		} while ( t != monitor->t ) ;
	} else OzPrintf( "No thread wait to lock.\n" ) ;
	result = 0 ;

error:
	ThrResume( key.t ) ;

	return( result ) ;
}

static	int
Condition( char *name, int argc, char *argv[], int sline, int eline )
{
	OZ_Thread	t ;
	TKey		key ;
	int		mask ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], 0, 0 ) ;
	key.f = ThrSuspend ;

	if ( ThrMapTable( Where_sub, &key ) <= 0 ) {
		OzError( "Not found thread %d.", key.tid ) ;
		return( -2 ) ;
	}

	mask = SigBlock() ;
	if ( key.t->wait_cv ) {
		t = *(key.t->wait_cv) ;
		do {
			dump_stack( t, 0 ) ;
			t = t->next ;
		} while ( t != *(key.t->wait_cv) ) ;
	}
	SigUnBlock( mask ) ;

	ThrResume( key.t ) ;

	return( 0 ) ;
}

static	int
threads_sub( OZ_Thread t, void *dummy )
{
	if ( t->tid == 0 || t == ThrRunningThread ) return( 1 ) ;
	if ( t->channel != NULL ) return( 1 ) ;
	ThrSuspend( t ) ;
	dump_stack( t, 0 ) ;
	ThrResume( t ) ;
	return( 0 ) ;
}

typedef	struct	{
	OID			oid ;
	ObjectTableEntry	entry ;
} OKey ;

static	int
threads_aux( ObjectTableEntry entry, OKey *key )
{
	if ( entry->oid == key->oid ) {
		key->entry = entry ;
		OtGlobalObjectSuspend( entry ) ;
		return( 0 ) ;
	}
	return( 1 ) ;
}

static	int
Threads( char *name, int argc, char *argv[], int sline, int eline )
{
	OKey	key ;

	if ( argc < 2 ) {
		ThrMapTable( threads_sub, NULL ) ;
		return( 0 ) ;
	}

	key.oid = OzExecutorID | OzStrtol( argv[1], 0, 16 ) ;

	if ( OtMapObjectTable( threads_aux, &key ) <= 0 ) {
		OzError( "Not found object %016lx.", key.oid ) ;
		return( -2 ) ;
	}

	if ( key.entry->threads != NULL ) {
		OZ_Thread	t = key.entry->threads ;
		do {
			dump_stack( t, 0 ) ;
		} while( (t=t->b_next) != key.entry->threads ) ;
	}

	OtGlobalObjectResume( key.entry ) ;
	return( 0 ) ;
}


typedef	struct {
	OZ_ClassID	cid ;
	ClassCode	code ;
} CKey ;

static	int
methods_sub( ClassCode code, CKey *key )
{
	if ( code->cid == key->cid ) {
		/* Get ClassCode [Don't call ClGetCode()] */
		OzExecEnterMonitor( &code->lock ) ;
		if ( code->state == CL_LOADED ) {
			key->code = code ;
			code->ref_count ++ ;
		}
		OzExecExitMonitor( &code->lock ) ;
		return( 0 ) ;
	}
	return( 1 ) ;
}

static	int
Methods( char *name, int argc, char *argv[], int sline, int eline )
{
	CKey	key ;
	int	i ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( OzStrlen( argv[1] ) < 16 ) {
		key.cid = OzExecutorID | OzStrtoul( argv[1], 0, 16 ) ;
	} else {
		key.cid = OzStrtoull( argv[1], 0, 16 ) ;
	}
	key.code = NULL ;

	if ( ClMapCode( methods_sub, &key ) == 0 ) {
		OzError( "Not found class %016lx.",  key.cid ) ;
		return( -2 ) ;
	}
	if ( key.code == NULL ) {
		OzError( "Not loaded class %016lx.",  key.cid ) ;
		return( -2 ) ;
	}

	for ( i = 0 ; i < key.code->fp_table->number_of_entry ; i ++ ) {
		OzPrintf( "0x%08x", key.code->fp_table->functions[i] ) ;
		print_pc( (caddr_t)key.code->fp_table->functions[i] ) ;
		OzPrintf( "\n" ) ;
	}
	ClReleaseCode( key.code ) ;

	return( 0 ) ;
}

static	int
Break_sub( BrkPoint bp, void *dummy )
{
	OzPrintf( "%d ", bp->bid ) ;
	OzPrintf( "%s ", (bp->status == brkEnable) ? "enable" : "disable" );
	OzPrintf( "0x%x", bp->pc ) ;
	print_pc( (caddr_t)bp->pc ) ;
	OzPrintf( "\n") ;
	return( 0 ) ;
}

static	int
Break( char *name, int argc, char *argv[], int sline, int eline )
{
	BrkPoint	bp = NULL ;
	char		*p ;
	caddr_t		addr ;
	OZ_ClassID	cid ;
	void		*handle ;
	int		line ;

	if ( argc < 2 ) {
		if ( BrkMap( Break_sub, NULL ) == 0 ) {
			OzPrintf( "No breakpoints\n" ) ;
		}
		return( 0 ) ;
	}

	cid = OzStrtoull( argv[1], &p, 16 ) ;
	if ( p - argv[1] < 16 ) cid |= OzExecutorID ;

	handle = DlOpen( cid ) ;
	if ( handle == NULL ) {
		OzError( "Not found %016lx", cid ) ;
		goto error ;
	}
	++ p ;
	if ( *p == '\0' ) {
		*argv = NULL ;
		goto error ;
	}
	if ( '0' <= *p && *p <= '9' ) {
		line = OzStrtol( p, NULL, 0 ) ;
		if ( line <= 0 ) {
			*argv = NULL ;
			goto error ;
		}
		addr = DlSrc( handle, "/private.c", line ) ;
		if ( addr == NULL ) {
			OzError( "Not found %016lx:%d", cid, line ) ;
			goto error ;
		}
		bp = BrkInsert( (u_long)addr ) ;
		if ( bp == NULL ) {
			OzError( "Can't break at %016lx:%d[0x%x]",
					cid, line, addr ) ;
			goto error ;
		}
	} else {
		addr = DlSym( handle, p ) ;
		if ( addr == NULL ) {
			OzError( "Not found %016lx:%s", cid, p ) ;
			goto error ;
		}
		addr += 4 ;
		bp = BrkInsert( (u_long)addr ) ;
		if ( bp == NULL ) {
			OzError( "Can't break at %016lx:%s[0x%x]",
					cid, p, addr ) ;
			goto error ;
		}
	}

	OzPrintf( "breakpoint %d at 0x%x", bp->bid, addr ) ;
	print_pc( addr ) ;
	OzPrintf( "\n" ) ;

error:
	if ( handle != NULL ) DlClose( handle ) ;
	return( bp ? 0 : -2 )  ;
}

static	int
Delete( char *name, int argc, char *argv[], int sline, int eline )
{
	int	id ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	id = OzStrtol( argv[1], 0, 0 ) ;
	if ( BrkDelete( id ) ) {
		OzError( "Can't delete breakpoint %d.\n", id ) ;
		return( -2 ) ;
	}
	return( 0 )  ;
}

static	int
Clear( char *name, int argc, char *argv[], int sline, int eline )
{
	u_long	addr ;
	int	ret ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	addr = OzStrtoul( argv[1], 0, 0 ) ;
	ret = BrkClear( addr ) ;
	if ( addr < 0 ) {
		OzError( "Can't clear breakpoint at 0x%x.", addr ) ;
		return( -2 ) ;
	} else if ( ret == 0 ) {
		OzPrintf( "No breakpoint at 0x%x.\n", addr ) ;
	} else {
		OzPrintf( "Clear %d breakpoint at 0x%x.\n", ret, addr ) ;
	}
	return( 0 )  ;
}

static	int
Enable( char *name, int argc, char *argv[], int sline, int eline )
{
	int	id ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	id = OzStrtol( argv[1], 0, 0 ) ;
	if ( BrkEnable( id ) ) {
		OzError( "Can't enable breakpoint %d.", id ) ;
		return( -2 ) ;
	}
	return( 0 )  ;
}

static	int
Disable( char *name, int argc, char *argv[], int sline, int eline )
{
	int	id ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	id = OzStrtol( argv[1], 0, 0 ) ;
	if ( BrkDisable( id ) ) {
		OzError( "Can't disable breakpoint %d.", id ) ;
		return( -2 ) ;
	}
	return( 0 )  ;
}

static	int
Cont( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey		key ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], 0, 0 ) ;
	key.f = ThrSuspend ;

	if ( ThrMapTable( Where_sub, &key ) <= 0 ) {
		OzError( "Not found thread %d.", key.tid ) ;
		return( -1 ) ;
	}
	ThrResume( key.t ) ;

	if ( BrkContinue( key.t ) ) {
		OzError( "Can't cont thread %d.", key.tid ) ;
		return( -2 ) ;
	}
	ThrResume( key.t ) ;
	return( 0 )  ;
}

static	int
Suspend( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], 0, 0 ) ;
	key.f = ThrSuspend ;

	if ( ThrMapTable( operate, &key ) <= 0 ) {
		OzError( "Not found thread %d.",  key.tid ) ;
		return( -2 ) ;
	}

	OzPrintf( "[0x%08x]\n", key.t ) ;

	return( 0 ) ;
}

static	int
Resume( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], 0, 0 ) ;
	key.f = ThrResume ;

	if ( ThrMapTable( operate, &key ) <= 0 ) {
		OzError( "Not found thread %d.",  key.tid ) ;
		return( -2 ) ;
	}

	OzPrintf( "[0x%08x]\n", key.t ) ;

	return( 0 ) ;
}

static	int
Kill( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], 0, 0 ) ;
	key.f = ThrKill ;

	if ( ThrMapTable( operate, &key ) <= 0 ) {
		OzError( "Not found thread %d.\n",  key.tid ) ;
		return( -2 ) ;
	}
	if ( key.status < 0 ) {
		OzError( "Not suspended thread %d.",  key.tid ) ;
		return( -2 ) ;
	}
	if ( key.status != 0 ) {
		OzError( "Not killed thread %d.",  key.tid ) ;
		return( -2 ) ;
	}

	OzPrintf( "[0x%08x]\n", key.t ) ;

	return( 0 ) ;
}

static	int
Abort( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.tid = OzStrtol( argv[1], 0, 0 ) ;
	key.f = ThrAbortThread ;

	if ( ThrMapTable( operate, &key ) <= 0 ) {
		OzError( "Not found thread %d.",  key.tid ) ;
		return( -2 ) ;
	}

	OzPrintf( "[0x%08x]\n", key.t ) ;

	return( 0 ) ;
}

static	ClassCode
Load_sub( OZ_ClassID cid )
{
	ClassCode	result ;
	OZ_ExceptionRec	e_rec ;

	OzExecInitializeExceptionHandler( &e_rec, 1 ) ;
	OzExecPutEidIntoCatchTable( &e_rec, OzExceptionAny ) ;
	OzExecRegisterExceptionHandlerFor( &e_rec ) ;
	if ( SETJMP(e_rec.jmp) == 0 ) {
		result = ClGetCode( cid ) ;
	} else {
		OzExecHandlingException( &e_rec ) ;
		result = NULL ;
	}
	OzExecUnregisterExceptionHandler() ;

	return( result ) ;
}

static	int
Load( char *name, int argc, char *argv[], int sline, int eline )
{
	ClassCode	code ;
	OZ_ClassID	cid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( OzStrlen( argv[1] ) < 16 ) {
		cid = OzExecutorID | OzStrtoul( argv[1], 0, 16 ) ;
	} else {
		cid = OzStrtoull( argv[1], 0, 16 ) ;
	}

	code = Load_sub( cid ) ;
	if ( code == NULL ) {
		OzError( "Not found code %016lx.",  cid ) ;
		return( -2 ) ;
	}
	ClReleaseCode( code ) ;
	return( 0 ) ;
}

int
DgInit()
{
	OzShAppend( "debugger", "", NULL, "", "Debugger commands" ) ;
	OzShAppend( "debugger", "where", Where,
			"<thread id>", "dump thread stack" ) ;
	OzShAppend( "debugger", "threads", Threads, "[object number]",
			"list thread" ) ;
	OzShAppend( "debugger", "methods", Methods, "<class id>",
			"list methods" ) ;
	OzShAppend( "debugger", "monitor", monitor,
			"<thread id> <object address>",
			"print thread locked monitor and threads waited" ) ;
	OzShAppend( "debugger", "condition", Condition, "<thread id>",
			"list wait threads for condition" ) ;
	OzShAppend( "debugger", "break", Break, "<class id>:<line number>",
			"set breakpoint" ) ;
	OzShAppend( "debugger", "continue", Cont, "<thread id>",
			"continue from breakpoint" ) ;
	OzShAppend( "debugger", "delete", Delete, "<breakpoint id>",
			"clear breakpoint" ) ;
	OzShAppend( "debugger", "clear", Clear, "<breakpoint address>",
			"clear breakpoint address" ) ;
	OzShAppend( "debugger", "enable", Enable, "<breakpoint id>",
			"enable breakpoint" ) ;
	OzShAppend( "debugger", "disable", Disable, "<breakpoint id>",
			"disable breakpoint" ) ;
	OzShAppend( "debugger", "suspend", Suspend, "<thread id>",
			"suspend thread" ) ;
	OzShAppend( "debugger", "resume", Resume, "<thread id>",
			"resume thread" ) ;
	OzShAppend( "debugger", "abort", Abort, "<thread id>",
			"abort thread" ) ;
	OzShAppend( "debugger", "kill", Kill, "<thread id>",
			"kill thread" ) ;
	OzShAppend( "debugger", "load", Load, "<class id>",
			"load class code" ) ;
	return( 0 ) ;
}
