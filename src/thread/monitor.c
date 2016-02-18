/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Multithread system: synchronization module
 *
 *		Mutual exlusion and Condition variable implementation
 *
 *	IMPORTANT:
 *		You can only call Sig..., Thr... or thr... 
 *		You must be block signal before calling thr...
 *
 */
/* multithread system include */
#include "thread.h"
#include "thread/testandset.h"
#include "thread/signal.h"
#include "thread/monitor.h"

#if	!defined(NOEXCEPT)
#include "executor/exception.h"
#include "oz++/sysexcept.h"
#endif

/*
 * Don't include any other module
 */


void
OzInitializeMonitor( OZ_Monitor ml )
{
	ml->spin_lock = 0 ;
	ml->locked = 0 ;
	ml->t = 0 ;
}

void
OzExecInitializeCondition( OZ_Condition cv, int abortable )
{
	cv->abortable = abortable ;
	cv->t = 0 ;
}

void
OzExecEnterMonitor( OZ_Monitor ml )
{
	int	mask ;
	int	block ;

	block = ThrBlockSuspend() ;
	ThrAcquire( &ml->spin_lock ) ;
	while ( ml->locked ) {
		mask = SigBlock() ;
		ThrRunningThread->status = WAIT_LOCK ;
		ThrRunningThread->wait_ml = ml ;
		thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
		thrEnqueue( &(ml->t), ThrRunningThread ) ;
		if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
		if ( ThrRunningThread->tid == ml->tid ) {
			ThrError( "Thread %d is dead locked monitor=0x%x.",
					ThrRunningThread->tid, ml ) ;
		}
		ThrRelease( &ml->spin_lock ) ;
		thrSwitch( thrReadyThreads ) ;	/* Don't call thrReschedule() */
		SigUnBlock( mask ) ;
		ThrAcquire( &ml->spin_lock ) ;
	}
	ml->locked = 1 ;
	ml->tid = ThrRunningThread->tid ;
	ThrRelease( &ml->spin_lock ) ;
	ThrUnBlockSuspend( block ) ;
}

void
OzExecExitMonitor( OZ_Monitor ml )
{
	Thread	t ;
	int	mask ;
	int	block ;

	block = ThrBlockSuspend() ;
	ThrAcquire( &ml->spin_lock ) ;
	if ( ! ml->locked ) {
		ThrError( "Thread %d haven't locked monitor=0x%x.",
				ThrRunningThread->tid, ml ) ;
	}
	ml->locked = 0 ;
	if ( (t = ml->t) ) {
		mask = SigBlock() ;
		while ( (t = ml->t) ) {
			thrDequeue( &ml->t, t ) ;
			if ( thrReady( t ) == READY ) {
				break ;		/* CAUTION: Most important. */
			}
		}
		ThrRelease( &ml->spin_lock ) ;
		thrReschedule() ;
		SigUnBlock( mask ) ;
	} else ThrRelease( &ml->spin_lock ) ;
	ThrUnBlockSuspend( block ) ;
}

void
OzExecWaitConditionWithTimeout(OZ_Monitor ml, OZ_Condition cv, int timeout)
{
	Thread	t ;
	int	mask ;
	int	block ;
	int	aborted = 0 ;

	block = ThrBlockSuspend() ;
	ThrAcquire( &ml->spin_lock ) ;
	mask = SigBlock() ;
	if ( ThrRunningThread->aborted && cv->abortable ) {
		aborted = 1 ;
		ThrRelease( &ml->spin_lock ) ;
		SigUnBlock( mask ) ;
		ThrUnBlockSuspend( block ) ;
	} else {
		ThrRunningThread->status = WAIT_COND ;
		thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
		thrEnqueue( &cv->t, ThrRunningThread ) ;
		if ( ! ml->locked ) {
			ThrError( "Thread %d haven't locked "
					"monitor=0x%x with condition=0x%x.",
					ThrRunningThread->tid, ml, cv ) ;
		}
		ml->locked = 0 ;
		while ( (t = ml->t) ) {
			thrDequeue( &ml->t, t ) ;
			if ( thrReady( t ) == READY ) break ;
		}
		if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
		ThrRelease( &ml->spin_lock ) ;
		ThrRunningThread->wait_cv = &cv->t ;
		ThrRunningThread->abortable = cv->abortable ? 1 : 0 ;
		if ( timeout ) {
			/* Request Timeout service to scheduler */
			thrTimeout( ThrRunningThread, timeout ) ;
		}
		thrSwitch( thrReadyThreads ) ;	/* Don't call thrReschedule() */
		ThrRunningThread->wait_cv = 0 ;
		if ( ThrRunningThread->aborted && cv->abortable ) {
			aborted = 1 ;
		}
		SigUnBlock( mask ) ;
		ThrUnBlockSuspend( block ) ;
		OzExecEnterMonitor( (OZ_Monitor)ml );
	}
	if ( aborted ) {
		ThrRunningThread->aborted = 0 ;
#if	!defined(NOEXCEPT)
		OzExecRaise( OzExceptionAbort, 0, 0 ) ;
#endif
	}
}

void
OzExecSignalCondition( OZ_Condition cv )
{
	Thread	t ;
	int	mask ;

	mask = SigBlock() ;
	while ( (t = cv->t) ) {
		thrDequeue( &cv->t, t ) ;
		if ( thrReady( t ) == READY ) {
			break ;		/* CAUTION: Most important. */
		}
	}
	thrYield() ;
	SigUnBlock( mask ) ;
}

void
OzExecSignalConditionAll( OZ_Condition cv )
{
	Thread	t ;
	int	mask ;

	mask = SigBlock() ;
	while ( (t = cv->t) ) {
		thrDequeue( &cv->t, t ) ;
		thrReady( t ) ;
	}
	thrYield() ;
	SigUnBlock( mask ) ;
}

int
ThrAbortThread( Thread t )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	t->aborted = 1 ;
	if ( t->status == WAIT_COND && t->abortable ) {
		thrDequeue( t->wait_cv, t ) ;
		t->wait_cv = 0 ;
		thrReady( t ) ;
		thrYield() ;
		rval = 1 ;
	} else rval = 0 ;
	SigUnBlock( mask ) ;

	return( rval ) ;
}

int
ThrClearThread( Thread t )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = t->aborted ;
	t->aborted = 0 ;
	SigUnBlock( mask ) ;

	return( rval ) ;
}

int
OzExecThreadShouldBeAborted()
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = ThrRunningThread->aborted ;
	SigUnBlock( mask ) ;
	return( rval ) ;
}
