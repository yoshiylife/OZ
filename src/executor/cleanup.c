/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	OZ++ System Cleanup except for multithread system module
 *		Cleanup all modules with multithread.
 */
/* multithread system include */
#include "thread/thread.h"
#include "thread/timer.h"

#include "switch.h"
#include "main.h"
#include "pkif.h"

extern	void	ThrLibcFine() ;
extern	void	CloseCircuits() ;

void
cleanup()
{
	CloseCircuits() ;
	PkFine() ;
#ifdef TIMER
	TimerFinish() ;
#endif /* TIMER */
	ThrLibcFine() ;
	ThrPrintf( "OZ++ System shutdown complete.\n" ) ;
}
