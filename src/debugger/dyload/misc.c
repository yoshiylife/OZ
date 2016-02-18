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
#include "mon.h"
#include "oz++/ozlibc.h"

typedef	struct	{
	int		tid ;
	OZ_Thread	t ;
	int		(*f)(OZ_Thread t) ;
} TKey ;

static	int
operate( OZ_Thread t, TKey *key )
{
	if ( t->tid != key->tid ) return( 1 ) ;
	key->t = t ;
	key->f( t ) ;
	return( 0 ) ;
}

static	int
Suspend( char *aStrTID )
{
	TKey	key ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.tid = OzStrtol( aStrTID, 0, 0 ) ;
	key.f = OzSuspendThread ;

	if ( OzMapThreadTable( operate, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n",  key.tid ) ;
		return( -1 ) ;
	}

	OzOutput( -1, "[0x%08x]\n", key.t ) ;

	return( 0 ) ;
}

static	int
Resume( char *aStrTID )
{
	TKey	key ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.tid = OzStrtol( aStrTID, 0, 0 ) ;
	key.f = OzResumeThread ;

	if ( OzMapThreadTable( operate, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n",  key.tid ) ;
		return( -1 ) ;
	}

	OzOutput( -1, "[0x%08x]\n", key.t ) ;

	return( 0 ) ;
}

static	int
Abort( char *aStrTID )
{
	TKey	key ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.tid = OzStrtol( aStrTID, 0, 0 ) ;
	key.f = OzAbortThread ;

	if ( OzMapThreadTable( operate, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n",  key.tid ) ;
		return( -1 ) ;
	}

	OzOutput( -1, "[0x%08x]\n", key.t ) ;

	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "suspend" ) ;
	OzShAppendCmd( "suspend", "<thread id>", "suspend thread", Suspend ) ;
	OzShRemoveCmd( "resume" ) ;
	OzShAppendCmd( "resume", "<thread id>", "resume thread", Resume ) ;
	OzShRemoveCmd( "abort" ) ;
	OzShAppendCmd( "abort", "<thread id>", "abort thread", Abort ) ;
}
