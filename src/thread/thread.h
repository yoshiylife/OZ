/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * IMPORTANT:
 *	Only include from multithread system modules.
 *	Don't include this file from other modules.
 */
#ifndef	_THREAD_H_
/* multithread system include */
#include "thread/signal.h"
#include "thread/thread.h"

/*
 * Don't include any other module
 */


#ifndef	INLINE
#define	INLINE	inline extern
#endif	!INLINE


/*
 *	Internal variables, but need to inline statement.
 */
extern	Thread	thrReadyThreads ;
extern	Thread	thrSuspendThreads ;


/*
 *	Internal functions, but need to inline statement.
 */
void	thrTimeout( Thread t, int timeout ) ;
int	thrUnTimeout( Thread t ) ;
void	thrSwitch( Thread t ) ;

/*
 *	Inline functions
 */
INLINE	void
thrEnqueue( Thread *queue, Thread t )
{
	if (!*queue) {
		*queue = t->prev = t->next = t;
	} else {
		Thread	tt;

		tt = *queue;
		while (tt->priority >= t->priority)
			if ((tt = tt->next) == *queue)
				break;
		t->prev = tt->prev;
		t->prev->next = t;
		t->next = tt;
		tt->prev = t;
		if ((*queue)->priority < t->priority)
			*queue = t;
	}
}

INLINE	void
thrDequeue( Thread *queue, Thread t )
{
	if (t->next == t) {
		*queue = (Thread)0;
	} else {
		t->prev->next = t->next;
		t->next->prev = t->prev;
		if (*queue == t)
			*queue = t->next;
	}
}

INLINE	void
thrReschedule()
{
	if ( ThrRunningThread != thrReadyThreads ) {
		ThrRunningThread->status = READY ;
		thrSwitch( thrReadyThreads ) ;
	} else ThrRunningThread->status = RUNNING ;
}

INLINE	TStat
thrReady( Thread t )
{
	/* for debug */
	if ( t->status == READY || t->status == RUNNING ) {
		ThrPanic( "[0x%x] thrReady(0x%x): status = %d.",
				ThrRunningThread, t, t->status ) ;
	}

	if ( t->wait_io ) {
		thrDequeue( t->wait_io, t ) ;
		t->wait_io = 0 ;
	}
	if ( t->on_timeout_queue ) thrUnTimeout( t ) ;
	if ( t->suspend_count ) {
		t->status = SUSPEND ;
		thrEnqueue( &thrSuspendThreads, t ) ;
	} else {
		t->status = READY ;
		thrEnqueue( &thrReadyThreads, t ) ;
	}
	return( t->status ) ;
}

INLINE	void
thrWakeupWaiters()
{
	Thread	t ;
	if ( ThrRunningThread->suspend_waiters ) {
		while( (t=ThrRunningThread->suspend_waiters) ) {
			t->status = READY ;
			thrDequeue( &ThrRunningThread->suspend_waiters, t ) ;
			thrEnqueue( &thrReadyThreads, t ) ;
		}
	}
}

INLINE	void
thrYield()
{
	thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
	thrEnqueue( &thrReadyThreads, ThrRunningThread ) ;
	thrReschedule() ;
}

INLINE	void
ThrAcquire( char *spin_lock )
{
	Thread	t ;
	int		mask ;

	ThrRunningThread->holding_spin_lock = spin_lock ;
	while ( TestAndSet( spin_lock ) ) {
		mask = SigBlock() ;
		t = ThrRunningThread->next ;
		while ( t->holding_spin_lock != spin_lock ) t = t->next ;
		ThrRunningThread->status = READY ;
		thrSwitch( t ) ;		/* Don't call thrReschedule() */
		SigUnBlock( mask ) ;
	}
}

INLINE	void
ThrRelease( char *spin_lock )
{
	*spin_lock = 0 ;
	ThrRunningThread->holding_spin_lock = 0 ;
}

#endif	!_THREAD_H_
