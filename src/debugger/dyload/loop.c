/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include "shell.h"
#include "mon.h"
#include "oz++/ozlibc.h"
#include "executor/monitor.h"

static	OZ_MonitorRec	lock ;

static	int
loop( char *aStrCount )
{
	unsigned int	i ;
	unsigned int	count ;

	if ( aStrCount == NULL ) return( 1 ) ;
	count = OzStrtoul( aStrCount, 0, 0 ) ;
	for ( i = 1 ; i <= count ; i ++ ) {
		OzExecEnterMonitor( &lock ) ;
		if ( i % 10000 == 0 ) OzOutput( -1, "%u/%u\n", i, count ) ;
		OzExecExitMonitor( &lock ) ;
	}
	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "loop" ) ;
	OzShAppendCmd( "loop", "<count>", "loop", loop ) ;
}
