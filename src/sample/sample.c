/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdio.h>

/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

/* producer consumer */

#define	BUFFER_SIZE	10
#define	MAX		10

static	OZ_MonitorRec	lock[MAX] ;
static	OZ_ConditionRec	full[MAX] ;
static	OZ_ConditionRec	empty[MAX] ;
static	int		count[MAX] ;

static	void
put( int n, int m )
{
	OzExecEnterMonitor( lock+n ) ;

	while( count[n] == BUFFER_SIZE ) OzExecWaitCondition( lock+n, full+n ) ;
	if ( m ) OzPrintf( "enter item: count[%d] = %d\n", n, count[n] ) ;
	if ( count[n] ++ == 0 ) OzExecSignalConditionAll( empty+n ) ;

	OzExecExitMonitor( lock+n ) ;
}

static	void
get( int n, int m )
{
	OzExecEnterMonitor( lock+n ) ;

	while( count[n] == 0 ) OzExecWaitCondition( lock+n, empty+n ) ;
	if ( m ) OzPrintf( "remove item: count[%d] = %d\n", n, count[n] ) ;
	if ( count[n] -- == BUFFER_SIZE ) OzExecSignalConditionAll( full+n ) ;

	OzExecExitMonitor( lock+n ) ;
}

static	int
produce( char *name, int argc, char *argv[], int sline, int eline )
{
	int	cnt ;
	int	n ;
	int	m = 1 ;

	if ( argc < 3 ) return( -1 ) ;
	if ( argc == 4 ) m = 0 ;
	cnt = OzStrtol( argv[1], NULL, 0 ) ;
	n = OzStrtol( argv[2], NULL, 0 ) ;
	if ( MAX <= n ) return( -1 ) ;
	while ( cnt -- ) put( n, m ) ;

	return( 0 ) ;
}

static	int
consume( char *name, int argc, char *argv[], int sline, int eline )
{
	int	cnt ;
	int	n ;
	int	m = 1 ;

	if ( argc < 3 ) return( -1 ) ;
	if ( argc == 4 ) m = 0 ;
	cnt = OzStrtol( argv[1], NULL, 0 ) ;
	n = OzStrtol( argv[2], NULL, 0 ) ;
	if ( MAX <= n ) return( -1 ) ;
	while ( cnt -- ) get( n, m ) ;

	return( 0 ) ;
}

static	int
disturb( char *name, int argc, char *argv[], int sline, int eline )
{
	int	i ;
	int	cnt ;
	int	n ;
	int	m = 1 ;

	if ( argc < 3 ) return( -1 ) ;
	if ( argc == 4 ) m = 0 ;
	cnt = OzStrtol( argv[1], NULL, 0 ) ;
	n = OzStrtol( argv[2], NULL, 0 ) ;
	if ( MAX <= n ) return( -1 ) ;
	for ( i = 0 ; i < cnt ; i ++ ) {
		OzExecEnterMonitor( lock+n ) ;
		if ( m ) {
			if ( (i % 10000) == 0 )
				OzPrintf( "disturb: %d\n", i, cnt ) ;
		}
		OzExecExitMonitor( lock+n ) ;
	}

	return( 0 ) ;
}

static	int
loop( char *name, int argc, char *argv[], int sline, int eline )
{
	int	i ;
	int	cnt ;
	int	m = 1 ;

	if ( argc < 2 ) return( -1 ) ;
	if ( argc == 3 ) m = 0 ;
	cnt = OzStrtol( argv[1], NULL, 0 ) ;
	for ( i = 0 ; i < cnt ; i ++ ) {
		if ( m ) {
			if ( (i % 100000) == 0 )
				OzPrintf( "loop: %d/%d\n", i, cnt ) ;
		}
	}
	return( 0 ) ;
}

static	int
foreground( char *name, int argc, char *argv[], int sline, int eline )
{
	int	ret ;
	OzShell( "sh -c 'produce 1000		0'", &ret ) ;
	OzShell( "sh -c 'consume 1000		0'", &ret ) ;
	OzShell( "sh -c 'disturb 1000000	0'", &ret ) ;
	OzShell( "sh -c 'produce 1000		1'", &ret ) ;
	OzShell( "sh -c 'consume 1000		1'", &ret ) ;
	OzShell( "sh -c 'disturb 1000000	1'", &ret ) ;
	OzShell( "sh -c 'produce 1000		2'", &ret ) ;
	OzShell( "sh -c 'consume 1000		2'", &ret ) ;
	OzShell( "sh -c 'disturb 1000000	2'", &ret ) ;
	OzShell( "sh -c 'loop 10000000'", &ret ) ;
	return( 0 ) ;
}

static	int
background( char *name, int argc, char *argv[], int sline, int eline )
{
	int	ret ;
	OzShell( "produce 1000		3 &", &ret ) ;
	OzShell( "consume 1000		3 &", &ret ) ;
	OzShell( "disturb 1000000	3 &", &ret ) ;
	OzShell( "produce 1000		4 &", &ret ) ;
	OzShell( "consume 1000		4 &", &ret ) ;
	OzShell( "disturb 1000000	4 &", &ret ) ;
	OzShell( "produce 1000		5 &", &ret ) ;
	OzShell( "consume 1000		5 &", &ret ) ;
	OzShell( "disturb 1000000	5 &", &ret ) ;
	OzShell( "loop 10000000 &", &ret ) ;
	return( 0 ) ;
}

static	int
priority( char *name, int argc, char *argv[], int sline, int eline )
{
	int	ret ;
	OzShell( "sh -c 'nice;produce 1000	6'", &ret ) ;
	OzShell( "sh -c 'nice;consume 1000	6'", &ret ) ;
	OzShell( "sh -c 'nice;disturb 1000000	6'", &ret ) ;
	OzShell( "sh -c 'nice;produce 1000	7'", &ret ) ;
	OzShell( "sh -c 'nice;consume 1000	7'", &ret ) ;
	OzShell( "sh -c 'nice;disturb 1000000	7'", &ret ) ;
	OzShell( "sh -c 'nice;produce 1000	8'", &ret ) ;
	OzShell( "sh -c 'nice;consume 1000	8'", &ret ) ;
	OzShell( "sh -c 'nice;disturb 1000000	8'", &ret ) ;
	OzShell( "sh -c 'nice;loop 10000000'", &ret ) ;
	return( 0 ) ;
}

static	int
silent( char *name, int argc, char *argv[], int sline, int eline )
{
	int	ret ;
	OzShell( "produce 1000		3 1 &", &ret ) ;
	OzShell( "consume 1000		3 1 &", &ret ) ;
	OzShell( "disturb 1000000	3 1 &", &ret ) ;
	OzShell( "produce 1000		4 1 &", &ret ) ;
	OzShell( "consume 1000		4 1 &", &ret ) ;
	OzShell( "disturb 1000000	4 1 &", &ret ) ;
	OzShell( "produce 1000		5 1 &", &ret ) ;
	OzShell( "consume 1000		5 1 &", &ret ) ;
	OzShell( "disturb 1000000	5 1 &", &ret ) ;
	OzShell( "loop 10000000 1 &", &ret ) ;
	return( 0 ) ;
}

static	int
sigsegv( char *name, int argc, char *argv[], int sline, int eline )
{
	int	*addr = (int *)0x2000 ;
	*addr = 0 ;
	return( 0 ) ;
}

static	int
sigbus( char *name, int argc, char *argv[], int sline, int eline )
{
	int	data ;
	char	*addr ;

	addr = (char *)&data ;
	addr ++ ;
	*((int *)addr) = 0 ;

	return( 0 ) ;
}

static	int
overflow( char *name, int argc, char *argv[], int sline, int eline )
{
	char	data[1024] ;
	OzPrintf( "%s: Level %d\n", name, sline, data ) ;
	overflow( name, argc, argv, sline+1, eline ) ;
	return( 0 ) ;
}

void
sample()
{
	int	i ;

	for ( i = 0 ; i < MAX ; i ++ ) {
		OzInitializeMonitor( lock+i ) ;
		OzExecInitializeCondition( full+i, 0 ) ;
		OzExecInitializeCondition( empty+i, 0 ) ;
		count[i] = 0 ;
	}

	OzShAppend( "sample", "", NULL, "", "Sample commands" ) ;
	OzShAppend( "sample", "produce", produce, "<count> <#>", "producer" ) ;
	OzShAppend( "sample", "consume", consume, "<count> <#>", "consumer" ) ;
	OzShAppend( "sample", "disturb", disturb, "<count> <#>", "distrub" ) ;
	OzShAppend( "sample", "loop", loop, "<count>", "loop" ) ;
	OzShAppend( "test", "", NULL, "", "Test commands" ) ;
	OzShAppend( "test", "foreground", foreground, "",
		"Test in foregorund" ) ;
	OzShAppend( "test", "background", background, "",
		"Test in backgorund" ) ;
	OzShAppend( "test", "priority", priority, "",
		"Test in priority" ) ;
	OzShAppend( "test", "silent", silent, "",
		"Test in silent" ) ;
	OzShAppend( "test", "sigsegv", sigsegv, "", "Test SIGSEGV" ) ;
	OzShAppend( "test", "sigbus", sigbus, "", "Test SIGBUS" ) ;
	OzShAppend( "test", "overflow", overflow, "", "Test stack overflow" ) ;

	OzShAlias( "sample", "produce", "produce" ) ;
	OzShAlias( "sample", "consume", "consume" ) ;
	OzShAlias( "sample", "disturb", "disturb" ) ;
	OzShAlias( "sample", "loop", "loop" ) ;
	OzShAlias( "test", "foreground", "fgt" ) ;
	OzShAlias( "test", "background", "bgt" ) ;
	OzShAlias( "test", "priority", "prt" ) ;
	OzShAlias( "test", "silent", "slt" ) ;
	OzShAlias( "test", "sigsegv", "sigsegv" ) ;
	OzShAlias( "test", "sigbus", "sigbus" ) ;
	OzShAlias( "test", "overflow", "overflow" ) ;
}
