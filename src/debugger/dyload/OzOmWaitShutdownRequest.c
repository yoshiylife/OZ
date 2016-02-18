/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include "shell.h"
#include "executor/ncl-if.h"
#include "oz++/ozlibc.h"

static	int
Wait()
{
	int	ret ;

	ret = OzOmWaitShutdownRequest() ;
	OzOutput( -1, "OzOmWaitShutdownRequest() = %d\n", ret ) ;

	return( 0 ) ;
}

static	int
Request()
{
	int	ret ;

	ret = OzOmShutdownRequest() ;
	OzOutput( -1, "OzOmShutdownRequest() = %d\n", ret ) ;

	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "wait" ) ;
	OzShAppendCmd( "wait", "", "test OzWaitShutdownRequest", Wait ) ;
	OzShRemoveCmd( "request" ) ;
	OzShAppendCmd( "request", "", "test OzShutdownRequest", Request ) ;
}
