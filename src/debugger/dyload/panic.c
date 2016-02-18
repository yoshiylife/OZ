/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include "switch.h"
#include "main.h"
#include "thr.h"
#include "shell.h"

static	int
loop()
{
	int	i ;
	i = 0 ;
	OzDebugf( "Loop: %d\n", ++ i ) ;
	return( 0 ) ;
}

static	int
panic()
{
	OzForkThread( loop, THREAD_STACK_SIZE, MAX_PRIORITY, 0 ) ;
	ThrPanic( "TEST" ) ;
	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "panic" ) ;
	OzShAppendCmd( "panic", "", "call ThrPanic", panic ) ;
}
