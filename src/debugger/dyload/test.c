/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "signal.h"
#include "threads.h"

void
test()
{
	int	mask ;
	mask = SigBlock() ;
	SigAction( SIGINT, SIG_IGN ) ;
	SigUnBlock( mask ) ;
}
