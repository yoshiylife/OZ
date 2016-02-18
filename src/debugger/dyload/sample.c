/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* producer consumer */
#include <stdio.h>

#include "switch.h"
#include "thr.h"
#include "mon.h"
#include "shell.h"
#include "oz++/ozlibc.h"

#define	BUFFER_SIZE	10

static	OZ_MonitorRec	lock;
static	OZ_ConditionRec	full, empty;
static	int		count = 0;

void
put()
{
	OzExecEnterMonitor( &lock ) ;

	while( count == BUFFER_SIZE ) OzExecWaitCondition( &lock, &full ) ;
	OzOutput( -1, "enter item: count = %d\n", count ) ;
	if ( count ++ == 0 ) OzExecSignalConditionAll( &empty ) ;

	OzExecExitMonitor( &lock ) ;
}

void
get()
{
	OzExecEnterMonitor( &lock ) ;

	while( count == 0 ) OzExecWaitCondition( &lock, &empty ) ;
	OzOutput( -1, "remove item: count = %d\n", count ) ;
	if ( count -- == BUFFER_SIZE ) OzExecSignalConditionAll( &full ) ;

	OzExecExitMonitor( &lock ) ;
}

int
producer( const char *count )
{
	int	cnt ;

	if ( count == NULL ) cnt = 1 ;
	else cnt = OzStrtol( count, NULL, 0 ) ;
	while( cnt -- ) put() ;
	return( 0 ) ;
}

int
consumer( const char *count )
{
	int	cnt ;

	if ( count == NULL ) cnt = 1 ;
	else cnt = OzStrtol( count, NULL, 0 ) ;
	while( cnt -- ) get() ;
	return( 0 ) ;
}

void
_start()
{
	OzInitializeMonitor( &lock ) ;

	OzShAppendCmd( "produce", "[count]", "Test producer", producer ) ;
	OzShAppendCmd( "consume", "[count]", "Test consumer", consumer ) ;
}
