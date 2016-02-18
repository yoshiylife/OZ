/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * To use synchronization
 *
 */
#ifndef	_MONITOR_H_
#define	_MONITOR_H_
/* multithread system include */
#include "thread/thread.h"

/* executor include */
#include "executor/monitor.h"

/*
 * Don't include any other module
 */

#ifndef	_OZ_THREAD
typedef	struct ThreadStr	*OZ_Thread ;
#endif	!_OZ_THREAD


extern	void	OzInitializeMonitor( OZ_Monitor ml ) ;
extern	int	ThrAbortThread( Thread t ) ;
extern	int	ThrClearThread( Thread t ) ;

#endif	!_MONITOR_H_
