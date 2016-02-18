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
cons()
{
static	char	*msg = "OZ++ Executor console message test.\n" ;
	OzWrite( 0, msg, OzStrlen(msg) ) ;
	return( 0 ) ;
}

void
_start()
{
	OzShAppendCmd( "cons", "", "output string to console", cons ) ;
}

