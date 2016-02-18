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

static	void
demon( int level )
{
	level ++ ;
	OzOutput( -1, "Level %d\n", level ) ;
	demon( level ) ;
}

static	int
test()
{
	OzForkThread( demon, THREAD_STACK_SIZE, MAX_PRIORITY, 1, 0 ) ;
	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "stackoverflow" ) ;
	OzShAppendCmd( "stackoverflow", "", "do stack over flow", test ) ;
}
