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

static	int
suspend( char *aAddr )
{
	OZ_Thread	t ;

	if ( aAddr == NULL ) return( 1 ) ;

	t = (void *)OzStrtoul( aAddr, 0, 16 ) ;

	OzSuspendThread( t ) ;

	return( 0 ) ;
}

static	int
resume( char *aAddr )
{
	OZ_Thread	t ;

	if ( aAddr == NULL ) return( 1 ) ;

	t = (void *)OzStrtoul( aAddr, 0, 16 ) ;

	OzResumeThread( t ) ;

	return( 0 ) ;
}

void
_start()
{
	ShRemoveCmd( "suspend" ) ;
	ShAppendCmd( "suspend", "<thread>", "suspend thread", suspend ) ;
	ShRemoveCmd( "resume" ) ;
	ShAppendCmd( "resume", "<thread>", "resume thread", resume ) ;
}
