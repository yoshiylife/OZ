/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include "shell.h"
#include "oz++/ozlibc.h"

static	int
Mktime( char *aStrCount )
{
	unsigned int	i ;
	unsigned int	count ;
	struct tm	tm ;
	time_t		t1, t2 ;

	if ( aStrCount == NULL ) return( 1 ) ;
	count = OzStrtoul( aStrCount, 0, 0 ) ;
	for ( i = 1 ; i <= count ; i ++ ) {
		t1 = OzTime( NULL ) ;
		OzDate( &t1, &tm ) ;
		t2 = OzMktime( &tm ) ;
		if ( t1 != t2 ) OzOutput( -1, "t1 != t2\n" ) ;
		if ( i % 100 == 0 ) OzOutput( -1, "%u/%u\n", i, count ) ;
	}
	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "mktime" ) ;
	OzShAppendCmd( "mktime", "<loop count>", "test OzMktime", Mktime ) ;
}

