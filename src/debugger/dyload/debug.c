/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "signal.h"
#include "thr.h"
#include "main.h"
#include "shell.h"
#include "oz++/ozlibc.h"

#include "dyload.h"
#include "cl.h"

#include "ot.h"
#include "channel.h"

static	void
print_status( TStat ts, int suspend )
{
	static	char	*strTable[] = {
		"FREE",
		"CREATE",
		"READY",
		"RUNNING",
		"SUSPEND",
		"WAIT-IO",
		"WAIT-LOCK",
		"WAIT-COND",
		"WAIT-SUSPEND",
		"WAIT-TIMER",
		"ZOMBI"
	} ;

	if ( ts == SUSPEND && suspend == 1 ) {
		OzOutput( -1, "%s", strTable[READY] ) ;
	} else OzOutput( -1, "%s", strTable[ts] ) ;
	if ( 1 < suspend ) OzOutput( -1, "(+%d)", suspend-1 ) ;
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
		if ( cid ) OzOutput( -1, " %016lx:0x%08x", cid, pc ) ;
		else OzOutput( -1, " 0x%08x", pc ) ;
		goto error ;
	}
	if ( DlAddr( handle, pc, &dli ) < 0 ) {
		if ( cid ) OzOutput( -1, " %016lx:0x%08x", cid, pc ) ;
		else OzOutput( -1, " 0x%08x", pc ) ;
		goto error ;
	}
	if ( dli.sname != NULL ) {
		char	*ptr ;
		char	*buff ;
		OzOutput( -1, " in " ) ;
		buff = OzMalloc( OzStrlen(dli.sname) + 1 ) ;
		if ( buff == NULL ) ptr = (char *)dli.sname ;
		else {
			OzStrcpy( buff, dli.sname ) ;
			ptr = OzStrchr( buff, ':' ) ;
			if ( ptr ) *ptr = '\0' ;
			ptr = buff ;
		}
		if ( cid ) OzOutput( -1, "%016lx::%s", cid, ptr ) ;
		else OzOutput( -1, "<%s>", ptr ) ;
		if ( buff != NULL ) OzFree( buff ) ;
	}

	if ( dli.sline ) {
		if ( dli.fname == NULL || cid ) {
			OzOutput( -1, " (at %d)", dli.sline ) ;
		} else OzOutput(-1, " at %s:%d", dli.fname, dli.sline ) ;
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
	void	*pc ;
	frame_t	*sp ;
	frame_t	*fp ;
	void	*addr ;

	if ( t == ThrRunningThread ) {
		OzOutput( -1, "%d Running.\n", t->tid ) ;
		return ;
	}

#if	#system(bsd)
	pc = (void *)t->context[3] ;
	sp = (frame_t *)t->context[2] ;
#endif
#if	#system(svr4)
	pc = (void *)t->context[2] ;
	sp = (frame_t *)t->context[1] ;
#endif

	OzOutput( -1, "%d ", t->tid ) ;
	print_status( t->status, t->suspend_count ) ;
	if ( t->signal_stack.ss_onstack ) {
		fp = (frame_t *)sp->r_i6 ;
		signo = fp->r_i0 ;
		code = fp->r_i1 ;
		pc = (void *)fp->r_i2 ;
		sp = (frame_t *)fp->r_i3 ;
		addr = (void *)fp->r_i4 ;
		if ( mode ) {
			OzOutput( -1, " %s(%d)", OzStrsignal(signo), code ) ;
		} else {
			OzOutput( -1, " %s(code=%d,pc=0x%x,sp=0x%x,addr=0x%x)",
				OzStrsignal(signo), code, pc, sp, addr ) ;
		}
	} else signo = 0 ;

	if ( mode ) {
		int	user ;
		void	*top = pc ;
		void	*next ;
		user = DlIsCore( pc ) ? 0 : 1 ;
		for (;;) {
			if ( (caddr_t)sp < t->stack
				|| t->stack_bottom < (caddr_t)sp ) {
				OzOutput( -1, " stack overflow" ) ;
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
			OzOutput( -1, " 0x%08x", pc ) ;
			print_pc( pc - (signo == 0 ? 8 : 0) ) ;
		} else {
			OzOutput( -1, " 0x%08x", pc+8 ) ;
			print_pc( pc ) ;
		}
		if ( t->channel != NULL ) {
			OzRecvChannel	rchan = (OzRecvChannel)t->channel ;
			OzOutput( -1, " on %016lx", rchan->pid ) ;
		}
		OzOutput( -1, "\n" ) ;
	} else {
		if ( t->channel != NULL ) {
			OzRecvChannel	rchan = (OzRecvChannel)t->channel ;
			OzOutput( -1, " on %016lx\n", rchan->pid ) ;
		} else OzOutput( -1, "\n" ) ;
		OzOutput( -1, "0x%08x", pc ) ;
		print_pc( pc - (signo == 0 ? 8 : 0) ) ;
		OzOutput( -1, "\n" ) ;
		for (;;) {
			if ( (caddr_t)sp < t->stack
				|| t->stack_bottom < (caddr_t)sp ) {
				OzOutput( -1, " stack overflow\n" ) ;
				break ;
			}
			pc = (void *)sp->r_i7 ;
			sp = (frame_t *)sp->r_i6 ;
			if ( sp->r_i6 == 0 ) break ;
			OzOutput( -1, "0x%08x", pc+8 ) ;
			print_pc( pc ) ;
			OzOutput( -1, "(0x%x)\n", sp->r_i0 ) ;
		}
	}
}


typedef	struct	{
	int		tid ;
	OZ_Thread	t ;
} TKey ;

static	int
where_sub( OZ_Thread t, TKey *key )
{
	if ( t->tid != key->tid ) return( 1 ) ;
	if ( ThrRunningThread == t ) {
		OzOutput( -1, "Don't dump self thread %d.\n", t->tid ) ;
		return( -1 ) ;
	}
	OzSuspendThread( t ) ;
	key->t = t ;
	return( 0 ) ;
}

static	int
Where( char *aStrTID, char *aFlag )
{
	TKey		key ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.tid = OzStrtol( aStrTID, 0, 0 ) ;

	if ( OzMapThreadTable( where_sub, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n", key.tid ) ;
		return( -1 ) ;
	}

	dump_stack( key.t, 0 ) ;

	OzResumeThread( key.t ) ;

	return( 0 ) ;
}

static	int
Dump( char *aStrTID, char *aAddr )
{
 extern	int	quicktest()	;
	OZ_Header	header ;
	Monitor		monitor ;
	TKey		key ;
	OzRecvChannel	chan ;

	if ( aStrTID == NULL || aAddr == NULL ) return( 1 ) ;

	key.tid = OzStrtol( aStrTID, 0, 0 ) ;
	header = (OZ_Header)OzStrtoul( aAddr, 0, 0 ) ;

	if ( OzMapThreadTable( where_sub, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n", key.tid ) ;
		return( -1 ) ;
	}

	chan = (OzRecvChannel)key.t->channel ;
	if ( chan == NULL ) {
		OzOutput( -1, "No channel\n" ) ;
		goto error ;
	}
	if ( ! quicktest( header, chan->o->heap, 1 ) ) {
		OzOutput( -1, "part[0x%0x] ng\n", header ) ;
		goto error ;
	}
	if ( header->h == LOCAL || header->h == STATIC ) {
		header -= header->e+1 ;
	} else {
		OzOutput( -1, "not object\n" ) ;
		goto error ;
	}
	if ( ! quicktest( header, chan->o->heap, 1 ) ) {
		OzOutput( -1, "all[0x%0x] ng\n", header ) ;
		goto error ;
	}
	monitor = (Monitor)header->t ;
	if ( ! quicktest( monitor, chan->o->heap, 1 ) ) {
		OzOutput( -1, "monitor[0x%x] ng\n", monitor ) ;
		goto error ;
	}
	OzOutput( -1, "Locked thread %d\n", monitor->tid ) ;

error:
	OzResumeThread( key.t ) ;

	return( 0 ) ;
}

static	int
Waiters( char *aStrTID )
{
	OZ_Thread	t ;
	TKey		key ;
	int		mask ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.tid = OzStrtol( aStrTID, 0, 0 ) ;

	if ( OzMapThreadTable( where_sub, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n", key.tid ) ;
		return( -1 ) ;
	}

	mask = SigBlock() ;
	if ( key.t->wait_cv ) {
		t = *(key.t->wait_cv) ;
		do {
			dump_stack( t, 1 ) ;
			t = t->next ;
		} while ( t != *(key.t->wait_cv) ) ;
	}
	SigUnBlock( mask ) ;

	OzResumeThread( key.t ) ;

	return( 0 ) ;
}

static	int
threads_sub( OZ_Thread t, void *dummy )
{
	if ( t->tid == 0 || t == ThrRunningThread ) return( 1 ) ;
	if ( t->channel != NULL ) return( 1 ) ;
	OzSuspendThread( t ) ;
	dump_stack( t, 1 ) ;
	OzResumeThread( t ) ;
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
Threads( char *aStrSeq )
{
	OKey	key ;

	if ( aStrSeq == NULL ) {
		OzMapThreadTable( threads_sub, NULL ) ;
		return( 0 ) ;
	}

	key.oid = OzExecutorID | OzStrtol( aStrSeq, 0, 0 ) ;

	if ( OtMapObjectTable( threads_aux, &key ) <= 0 ) {
		OzOutput( -1, "Not found object %016lx.\n", key.oid ) ;
		return( -1 ) ;
	}

	if ( key.entry->threads != NULL ) {
		OZ_Thread	t = key.entry->threads ;
		do {
			dump_stack( t, 1 ) ;
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
Methods( char *aStrCID )
{
	CKey	key ;
	int	i ;

	if ( aStrCID == NULL ) return( 1 ) ;

	if ( OzStrlen( aStrCID ) < 16 ) {
		key.cid = OzExecutorID | OzStrtoul( aStrCID, 0, 16 ) ;
	} else {
		key.cid = OzStrtoull( aStrCID, 0, 16 ) ;
	}
	key.code = NULL ;

	if ( ClMapCode( methods_sub, &key ) == 0 ) {
		OzOutput( -1, "Not found class %016lx.\n",  key.cid ) ;
		return( -1 ) ;
	}
	if ( key.code == NULL ) {
		OzOutput( -1, "Not loaded class %016lx.\n",  key.cid ) ;
		return( -1 ) ;
	}

	for ( i = 0 ; i < key.code->fp_table->number_of_entry ; i ++ ) {
		OzOutput( -1, "0x%08x", key.code->fp_table->functions[i] ) ;
		print_pc( (caddr_t)key.code->fp_table->functions[i] ) ;
		OzOutput( -1, "\n" ) ;
	}
	ClReleaseCode( key.code ) ;

	return( 0 ) ;
}

#if	0
static	int
Break( char *aStrAddr )
{
	int		id = -1 ;
	char		*p ;
	caddr_t		addr ;
	OZ_ClassID	cid ;
	void		*handle ;
	int		line ;

	if ( aStrAddr == NULL ) return( 1 ) ;

	cid = OzStrtoull( aStrAddr, &p, 16 ) ;
	if ( p - aStrAddr < 16 ) cid |= OzExecutorID ;

	handle = DlOpen( cid ) ;
	if ( handle == NULL ) {
		OzOutput( -1, "Not found %016lx\n", cid ) ;
		goto error ;
	}
	line = OzStrtol( p+1, NULL, 0 ) ;
	addr = DlSrc( handle, "/private.c", line ) ;
	if ( addr == NULL ) {
		OzOutput( -1, "Not found %016lx:%d\n", cid, line ) ;
		goto error ;
	}

	id = OzBreak( addr ) ;
	if ( id < 0 ) {
		OzOutput( -1, "Can't break at %016lx:%d[0x%x]\n",
				cid, line, addr ) ;
		goto error ;
	}
	OzOutput( -1, "%d at 0x%x.\n", id, addr ) ;

error:
	if ( handle != NULL ) DlClose( handle ) ;
	return( 0 <= id ? 0 : -1 )  ;
}

static	int
Clear( char *aStrID )
{
	int	id ;

	if ( aStrID == NULL ) return( 1 ) ;
	id = OzStrtoul( aStrID, 0, 0 ) ;
	if ( OzClear( id ) ) {
		OzOutput( -1, "Can't clear breakpoint %d.\n", id ) ;
		return( -1 ) ;
	}
	return( 0 )  ;
}

static	int
Cont( char *aStrTID )
{
	TKey		key ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.id = OzStrtol( aStrTID, 0, 0 ) ;

	if ( OzMapThreadTable( where_sub, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n", key.id ) ;
		return( -1 ) ;
	}

	if ( OzCont( key.t ) ) {
		OzOutput( -1, "Can't cont thread %d.\n", key.id ) ;
		return( -1 ) ;
	}
	return( 0 )  ;
}
#endif

void
_start()
{
	OzShRemoveCmd( "where" ) ;
	OzShAppendCmd( "where", "<thread ID>", "dump thread stack", Where ) ;
	OzShRemoveCmd( "threads" ) ;
	OzShAppendCmd( "threads", "[object number]", "list thread", Threads ) ;
	OzShRemoveCmd( "methods" ) ;
	OzShAppendCmd( "methods", "<class ID>", "list methods", Methods ) ;
	OzShRemoveCmd( "dump" ) ;
	OzShAppendCmd( "dump", "<thread ID> <object address>",
				"dump object", Dump ) ;
	OzShRemoveCmd( "waiters" ) ;
	OzShAppendCmd( "waiters", "<thread ID>", "list wait threads", Waiters );
#if	0
	OzShRemoveCmd( "break" ) ;
	OzShAppendCmd( "break", "<classID>:<line number>",
				"set breakpoint", Break ) ;
	OzShRemoveCmd( "cont" ) ;
	OzShAppendCmd( "cont", "<thread id>", "continue from breakpoint", Cont ) ;
	OzShRemoveCmd( "clear" ) ;
	OzShAppendCmd( "clear", "<breakpoint id>", "clear breakpoint", Clear ) ;
#endif
}
