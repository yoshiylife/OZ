/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "switch.h"
#include "main.h"
#include "shell.h"
#include "thr.h"
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

	if ( suspend ) {
		OzOutput( -1, strTable[SUSPEND] ) ;
		if ( ts != SUSPEND ) OzOutput( -1, "[%s]", strTable[ts] ) ;
		if ( 1 < suspend ) OzOutput( -1, "(%d)", suspend ) ;
	} else OzOutput( -1, strTable[ts] ) ;
}

static	int
print_pc( caddr_t pc )
{
	ClassCode	code = NULL ;
	caddr_t		addr ;
	char		*name ;
	char		*file ;
	int		line ;
	char		*buff ;
	char		*ptr ;

	addr = DlFindAddr( pc, &code, &name ) ;
	if ( name != NULL ) {
		OzOutput( -1, " in " ) ;
		buff = OzMalloc( OzStrlen(name) + 1 ) ;
		if ( buff == NULL ) ptr = name ;
		else {
			OzStrcpy( buff, name ) ;
			ptr = OzStrchr( buff, ':' ) ;
			if ( ptr ) *ptr = '\0' ;
			ptr = buff ;
		}
		if ( code ) OzOutput( -1, "%016lx::%s", code->cid, ptr ) ;
		else OzOutput( -1, "<%s>", ptr ) ;
		if ( buff != NULL ) OzFree( buff ) ;
	}

	line = DlFindLine( pc, &code, &file ) ;
	if ( code != NULL ) file = NULL ;

	if ( line ) {
		if ( file ) OzOutput(-1, " at %s:%d", file, line ) ;
		else OzOutput( -1, " (at %d)", line ) ;
	}

	if ( code ) ClReleaseCode( code ) ;

	return( code == NULL ? 0 : 1 ) ;
}

static	void
dump_stack( OZ_Thread t, int mode )
{
	int	signo ;
	void	*pc ;
	frame_t	*sp ;

	if ( t == OzRunningThread ) {
		OzOutput( -1, "%d Running.\n", t->id ) ;
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

	if ( t->signal_stack.ss_onstack ) {
		sp = (frame_t *)sp->r_i6 ;
		signo = sp->r_i0 ;
		pc = (void *)sp->r_i1 ;
		sp = (frame_t *)sp->r_i2 ;
	} else signo = 0 ;
	OzOutput( -1, "%d ", t->id ) ;
	print_status( t->status, t->suspend_count ) ;
	if ( signo ) OzOutput( -1, " %s", OzStrsignal(signo) );

	if ( mode ) {
		int	user = 0 ;
		void	*top = pc ;
		void	*next ;
		for (;;) {
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
			pc = (void *)sp->r_i7 ;
			sp = (frame_t *)sp->r_i6 ;
			if ( sp->r_i6 == 0 ) break ;
			OzOutput( -1, "0x%08x", pc+8 ) ;
			print_pc( pc ) ;
			OzOutput( -1, "\n" ) ;
		}
	}

	OzResumeThread( t ) ;
}


typedef	struct	{
	int		id ;
	OZ_Thread	t ;
} TKey ;

static	int
dump_sub( OZ_Thread t, TKey *key )
{
	if ( t->id != key->id ) return( 1 ) ;
	if ( OzRunningThread == t ) {
		OzOutput( -1, "Don't dump self thread %d.\n", t->id ) ;
		return( -1 ) ;
	}
	OzSuspendThread( t ) ;
	key->t = t ;
	return( 0 ) ;
}

static	int
dump( char *aStrTID, char *aFlag )
{
	TKey		key ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.id = OzStrtol( aStrTID, 0, 0 ) ;

	if ( OzMapThreadTable( dump_sub, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n", key.id ) ;
		return( -1 ) ;
	}

	dump_stack( key.t, 0 ) ;

	return( 0 ) ;
}


static	int
threads_sub( OZ_Thread t, void *dummy )
{
	if ( t->channel != NULL ) return( 1 ) ;
	dump_stack( t, 1 ) ;
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
threads( char *aStrSeq )
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
methods( char *aStrCID )
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

void
_start()
{
	ShRemoveCmd( "dump" ) ;
	ShAppendCmd( "dump", "<thread ID>", "dump thread stack", dump ) ;
	ShRemoveCmd( "threads" ) ;
	ShAppendCmd( "threads", "[object number]", "list thread", threads ) ;
	ShRemoveCmd( "methods" ) ;
	ShAppendCmd( "methods", "<class ID>", "list methods", methods ) ;
}
