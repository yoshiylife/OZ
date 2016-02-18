/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include "switch.h"
#include "main.h"
#include "shell.h"

static	int
sigsegv()
{
	int	*null = (int *)0x2000 ;
	*null = 0x12345678 ;
	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "sigsegv" ) ;
	OzShAppendCmd( "sigsegv", "", "raise SIGSEGV", sigsegv ) ;
}
