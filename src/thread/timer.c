/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <sys/time.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "thread/timer.h"
#include "oz++/ozlibc.h"

/*
 *	System calls
 */

typedef	struct	TimeRecordStr*	TimeRecord ;
struct	TimeRecordStr	{
	struct	timeval	s ;
	struct	timeval	e ;
} ;

static	TimeRecord	table = NULL ;
static	int		max ;
static	int		count = 0 ;
static	OZ_MonitorRec	lock ;
static	struct timeval	zero ;
static	struct timezone	dummy ;

int
TimerInit( int aMax )
{
	int	size ;
	max = aMax ;

	size = max * sizeof(struct TimeRecordStr) ;
	

	OzInitializeMonitor( &lock ) ; 

	OzExecEnterMonitor( &lock ) ;

	if ( table == NULL ) {
		if ( (table=(TimeRecord)OzMalloc( size )) == NULL ) {
			OzError( "TimerInit(%d) OzMalloc(%d): %m.",aMax,size ) ;
		}
		OzGettimeofday( &zero, &dummy ) ;
	} else OzError( "TimerInit(%d): already called.", aMax ) ;

	OzExecExitMonitor( &lock ) ;

	return( 0 ) ;
}

int
TimerMark( int aTag )
{
	TimeRecord	tr ;

	if ( table == NULL ) {
		OzError( "TimeMark(%d): Not initialized.", aTag ) ;
		return( aTag ) ;
	}

	OzExecEnterMonitor( &lock ) ;

	if ( aTag ) {
		tr = table + aTag-1 ;
		if ( 0 < aTag && aTag <= max ) OzGettimeofday( &tr->e, &dummy );
		else OzError( "TimerMark(%d): invalid tag.", aTag ) ;
	} else {
		if ( count < max ) {
			tr = table+count ;
			OzGettimeofday( &tr->s, &dummy ) ;
			aTag = ++ count ;
		} else {
			OzError( "TimerMark(%d): "
				"table overflow [Max:%d].", aTag, max ) ;
		}
	}

	OzExecExitMonitor( &lock ) ;

	return( (int)aTag ) ;
}

int
TimerStart()
{
	return( TimerMark( 0 ) ) ;
}

int
TimerEnd( int aTag )
{
	return( TimerMark( aTag ) ) ;
}

int
TimerFinish()
{
	int	i, adj, mic ;
	TimeRecord	tr = table ;

	OzExecEnterMonitor( &lock ) ;

	ThrPrintf( "No   Start       Finish      Duration    [sec]\n" ) ;
	for ( i = 0 ; i < count ; i ++, tr ++ ) {

		adj = ( tr->e.tv_usec < tr->s.tv_usec ) ? 1 : 0 ;
		mic = 1000000*adj + tr->e.tv_usec - tr->s.tv_usec ;

		ThrPrintf( "%04d:%04d.%06d %04d.%06d %04d.%06d\n",
				i,
				tr->s.tv_sec-zero.tv_sec, tr->s.tv_usec,
				tr->e.tv_sec-zero.tv_sec, tr->e.tv_usec,
				tr->e.tv_sec-tr->s.tv_sec-adj, mic	) ;
	}
	OzFree( table ) ;
	table = NULL ;
	count = 0 ;

	OzExecExitMonitor( &lock ) ;

	return( 0 ) ;
}
