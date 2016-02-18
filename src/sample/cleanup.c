/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Sample system cleanup except for multithread system module
 *		Cleanup all modules with multithread.
 */
/* multithread system include */
#include "thread/thread.h"
#include "thread/timer.h"

extern	void	ThrLibcFine() ;

void
cleanup()
{
	TimerFinish() ;
	ThrLibcFine() ;
	ThrPrintf( "Sample system shutdown complete.\n" ) ;
}
