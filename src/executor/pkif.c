/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdio.h>
/* multithread system include */
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"

static	int		pikopiko_fd ;
static	OZ_MonitorRec	pikopiko_lock ;
static	char		title[16] ;
static	char		*argv[3] = { "OZ++:pikopiko", title, NULL } ;


int
PkSwitch( int sw )
{
	char	buf[4] ;
	int	result = 0 ;	/* Normal */

	OzExecEnterMonitor( &pikopiko_lock ) ;
	if ( sw ) {
	/* on */
		if ( 0 < pikopiko_fd ) {
			OzWrite( pikopiko_fd, "2\n", 2 ) ;
			OzClose( pikopiko_fd ) ;
		}
		pikopiko_fd = OzVspawn( "pikopiko", argv ) ;
		if ( OzRead( pikopiko_fd, buf, 3 ) <= 0 ) {
			OzClose( pikopiko_fd ) ;
			pikopiko_fd = -1 ;
			result = -1 ;
		}
	} else {
	/* off */
		OzWrite( pikopiko_fd, "2\n", 2 ) ;
		OzKill( pikopiko_fd, 9 ) ;
		OzClose( pikopiko_fd ) ;
		pikopiko_fd = -1 ;
	}
	OzExecExitMonitor( &pikopiko_lock ) ;

	return( result ) ;
}

void
PkBiff()
{
	char	buf[4] ;

	OzExecEnterMonitor( &pikopiko_lock ) ;
	if ( 0 < pikopiko_fd ) {
		OzWrite( pikopiko_fd, "1\n", 2 ) ;
		OzRead( pikopiko_fd, buf, 3 ) ;
		OzWrite( pikopiko_fd, "0\n", 2 ) ;
		OzRead( pikopiko_fd, buf, 3 ) ;
	}
	OzExecExitMonitor( &pikopiko_lock ) ;
}

static	int
pkCmdIndicator( char *name, int argc, char *argv[], int sline, int eline )
{
	int	flag = -1 ;

	if ( argc > 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2  ) {
		if ( OzStrcmp( argv[1], "on" ) == 0
			|| OzStrcmp( argv[1], "1" ) == 0 ) flag = 1 ;
		if ( OzStrcmp( argv[1], "off" ) == 0
			|| OzStrcmp( argv[1], "0" ) == 0 ) flag = 0 ;
		if ( flag < 0 ) {
			*argv = NULL ;
			return( -1 ) ;
		}
		if ( OzGIMonitor == flag ) OzPrintf( "Already" ) ;
		else {
			OzPrintf( "Set" ) ;
			OzGIMonitor = flag ;
			PkSwitch( OzGIMonitor ) ;
		}
	} else {
		flag = OzGIMonitor ;
		OzPrintf( "Now" ) ;
	}
	OzPrintf( " global access indicator %s\n", flag ? "on" : "off" ) ;

	return( 0 ) ;
}

int
PkInit()
{
	int	exid ;

	OzInitializeMonitor( &pikopiko_lock ) ;
	exid = (OzExecutorID >> 24) & 0x0ffffff ;
	OzSprintf( title, "Executor %x", exid ) ;
	pikopiko_fd = -1 ;

	OzShAppend( "set", "indicator", pkCmdIndicator, "[on|off]",
		"Global access indicator on/off" ) ;

	return( 0 ) ;
}

int
PkFine()
{
	OzExecEnterMonitor( &pikopiko_lock ) ;
	if ( 0 < pikopiko_fd ) {
		OzWrite( pikopiko_fd, "2\n", 2 ) ;
		OzKill( pikopiko_fd, 9 ) ;
		OzClose( pikopiko_fd ) ;
		pikopiko_fd = -1 ;
	}
	OzExecExitMonitor( &pikopiko_lock ) ;

	OzShRemove( "set", "indicator" ) ;

	return( 0 ) ;
}
