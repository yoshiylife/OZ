/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * To use multithread
 *
 * IMPORTANT: Don't call any functions which name is ahead of thr
 *		
 */
#ifndef	_THREAD_H_
#define	_THREAD_H_
/* Don't move following some lines to after */

/* unix system include */
#include <sys/types.h>
#include <stdarg.h>
#include <signal.h>
#include <setjmp.h>

/* multithread system include */
#include "thread/testandset.h"

/*
 * Don't include any other module
 */

#define INTERSITE
/* Do change file mode to async & non-block */
#define	CONSOLE	1

#ifndef	INLINE
#define	INLINE	inline extern
#endif	!INLINE

#define	MAX_PRIORITY		0x7fffffff

#ifndef	_OZ_THREAD
#define	_OZ_THREAD
typedef	struct	ThreadStr	*OZ_Thread ;
#endif	!_OZ_THREAD

#ifndef	_OZ_MONITOR
#define	_OZ_MONITOR
typedef	struct	MonitorStr	*OZ_Monitor ;
#endif	!_OZ_MONITOR

#ifndef	_OZ_CONDITION
#define	_OZ_CONDITION
typedef	struct	ConditionStr	*OZ_Condition ;
#endif	!_OZ_CONDITION

typedef	struct	MonitorStr	OZ_MonitorRec ;
typedef	struct	ConditionStr	OZ_ConditionRec ;

typedef	struct	ThreadStr	*Thread ;
typedef	struct	ThreadStr	ThreadRec ;
typedef	struct	MonitorStr	*Monitor ;

typedef	enum	{
	FREE,
	CREATE,
	READY,
	RUNNING,
	SUSPEND,
	WAIT_IO,
	WAIT_LOCK,
	WAIT_COND,
	WAIT_SUSPEND,
	WAIT_TIMER,
	DEFUNCT
} TStat ;

#if	!defined(SVR4)
typedef	struct sigstack		stack_t ;
#endif	/* SVR4 */

struct	ThreadStr {
	Thread	next ;
	Thread	prev ;
	Thread	next_timeout ;		/* threads to wait timer */
	int	timeout_val ;		/* difference time */
	int	on_timeout_queue ;	/* NoneZero: in next_timeout */
	int	priority ;		/* thread priority
					 * Ref. thrEnqueue(), thrDequeue()
					 */
	TStat	status ;		/* thread status */
	char	*holding_spin_lock ;	/* pointer to spin lock instance
					 * Ref. thrAcquire(), thrRelease()
					 */

	/* read only */
	int	tid ;			/* thread identifyer */
	int	stack_size ;		/* thread stack size */
	char	*stack ;		/* thread stack top */
	char	*stack_bottom ;		/* thread stack bottom(break) */
	int	first ;			/* NoneZero: first dispatch */

	/* direct reference from other module */
	int	aborted ;	/* condition variable aborted flag */
	int	abortable ;	/* condition variable abortable flag */
	int	StdIn ;		/* standard input */
	int	StdOut ;	/* standard output */
	int	StdErr ;	/* standard error */
	Thread	*wait_cv ;	/* wait to signaled condition */
	Thread	*wait_io ;	/* wait to SIGIO */
	Monitor	wait_ml ;	/* wait to locked monitor */

	/* suspend */
	Thread	suspend_waiters ;	/* threads to wait suspend */
	int	suspend_count ;		/* count to suspend */
	char	suspend_blocking ;	/* saved suspend blocking flag */
	char	suspend_pad[3] ;	/* Padding */

	/* saved at each thread */
	jmp_buf	context ;	/* saved thread context */
	stack_t	signal_stack ;	/* saved signal stack */
	int	sigBlocking ;	/* saved signal blocking flag */
	int	errno ;		/* saved 'errno' */
	u_int	debugFlags ;	/* saved debug message control flags */

	/* oz++ system depend */
	Thread	b_prev ;	/* thread link in object table */
	Thread	b_next ;	/* thread link in object table */
	void	*channel ;
	void	*exceptions ;
	char   	*implementation_top ;
	void	*args ;
	int	arg_size ;
#ifdef INTERSITE
	/* flag if thread is foreign */
	unsigned int foreign_flag;
#endif
} ;

struct	MonitorStr {
	char	spin_lock ;
	char	locked ;
	short	tid ;
	Thread	t ;
} ;

struct	ConditionStr {
	char	abortable ;
	char   	pad[3] ;
	Thread	t ;
} ;


/*
 *	Global variables
 */
extern	u_int	OzDebugFlags ;
extern	int	ThrDevZero ;
extern	int	ThrPageSize ;
extern	Thread	ThrRunningThread ;


/*
 *	Public functions
 */
/* thread.c */
extern	Thread	ThrFork( void (*pc)(), int stackSize,
			int priority, int argc, ... ) ;
extern	Thread	ThrCreate( void (*pc)(), void *channel, int stackSize,
			int priority, unsigned int debugFlags, int nArg, ... ) ;
extern	void	ThrYield() ;
extern unsigned	ThrSleep( unsigned seconds ) ;
extern	void	ThrSchedule( Thread t ) ;
extern	int	ThrMapTable( int (func)(), void *arg ) ;
extern	int	ThrSuspend( Thread t ) ;
extern	int	ThrResume( Thread t ) ;
extern	int	ThrKill( Thread t ) ;
extern	void	ThrExit() ;
extern	void	ThrStop( int status ) ;
extern	void	ThrPrintf( const char *aFormat, ... ) ;
extern	void	ThrVprintf( const char *aFormat, va_list args ) ;
extern	void	ThrError( const char *aFormat, ... ) ;
extern	void	ThrPanic( const char *aFormat, ... ) ;
extern	int	ThrSetStdIn( int aStdIn ) ;
extern	int	ThrGetStdIn() ;
extern	int	ThrSetStdOut( int aStdOut ) ;
extern	int	ThrGetStdOut() ;
extern	int	ThrSetStdErr( int aStdErr ) ;
extern	int	ThrGetStdErr() ;
extern	int	ThrSetPriority( int  aPriority ) ;
extern	int	ThrGetPriority() ;
extern	int	ThrIdle( unsigned seconds ) ;
/* unix-io.c */
extern	int	ThrAttachIO( int fd ) ;


/*
 *	Inline functions
 */
extern	void	thrSuspend() ;
INLINE	int
ThrBlockSuspend()
{
	return TestAndSet( &ThrRunningThread->suspend_blocking ) ;
}

INLINE	void
ThrUnBlockSuspend( int block )
{
	if ( block ) return ;
	thrSuspend() ;
}

#endif	!_THREAD_H_
