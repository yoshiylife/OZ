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
#include "dyload.h"
#include "cl.h"
#include "ot.h"
#include "channel.h"
#include "oz++/ozlibc.h"

#include "print.h"

static	void
threads_print( OZ_Thread t )
{
	void	*pc ;
	frame_t	*sp ;

#if	#system(bsd)
	pc = (void *)t->context[3] ;
	sp = (frame_t *)t->context[2] ;
#endif
#if	#system(svr4)
	pc = (void *)t->context[2] ;
	sp = (frame_t *)t->context[1] ;
#endif

	OzOutput( -1, "[0x%08x] %d\t", t, t->id ) ;
	if ( t->signal_stack.ss_onstack ) {
		sp = (frame_t *)sp->r_i6 ;
		OzOutput( -1, "%s ", OzStrsignal(sp->r_i0) ) ;
		pc = (void *)sp->r_i1 ;
		sp = (frame_t *)sp->r_i2 ;
		OzOutput( -1, "0x%08x", pc ) ;
		print( pc ) ;
	} else {
		OzOutput( -1, "0x%08x", pc ) ;
		print( pc-8 ) ;
	}
	if ( t->channel != NULL ) {
		OzRecvChannel	rchan = (OzRecvChannel)t->channel ;
		OzOutput( -1, " on %016lx", rchan->pid ) ;
	}
	OzOutput( -1, "\n" ) ;
}

static	int
threads_sub( OZ_Thread t, void *dummy )
{
	if ( t == OzRunningThread
		|| t->status == FREE
		|| t->channel != NULL ) return( 1 ) ;
	threads_print( t ) ;
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
			threads_print( t ) ;
		} while( (t=t->b_next) != key.entry->threads ) ;
	}

	OtGlobalObjectResume( key.entry ) ;
	return( 0 ) ;
}

void
_start()
{
	ShRemoveCmd( "threads" ) ;
	ShAppendCmd( "threads", "[object number]", "list thread", threads ) ;
}
