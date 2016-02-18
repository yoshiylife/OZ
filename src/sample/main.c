/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Sample System start
 *
 */
/* unix system include */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <ctype.h>
#include <malloc.h>

#include "main.h"

/*
 *	System calls
 */
#if	!defined(SVR4)
extern	int	rename( const char *old, const char *new ) ;
#endif	/* SVR4 */

/*
 *	Prototype declaration for C Library functions
 */
#if	!defined(SVR4)
extern	void	moncontrol( int mode ) ;
extern	int	printf( const char *format, ... ) ;
extern	int	fprintf( FILE *stream, const char *format, ... ) ;
extern	int	getopt( int argc, char **argv, char *optstring ) ;
extern	long	strtol( char *str, char **ptr, int base ) ;
extern	int	tolower( int c ) ;
extern	void	perror( char *s ) ;
#endif	/* SVR4 */

/*
 *	External Function Signature without include file
 */
extern	int	ThrStart() ;

extern	char	*optarg ;
extern	int	optind, opterr ;

/*
 *	Global variable
 *		( Refered by all module )
 */
int		OzClockTicks = 50 ;	/* clock ticks per second */
					/* thread scheduling time slice */
					/* unit with micro second */
int		OzThreadMax = 256 ;	/* thread max concurrently */
int		OzDebugging = 0 ;	/* None-Zero: debug mode */
					/*         2: export all symbols */
static	int	profileFlag = 0 ;	/* 0: Do't profile, else: do profile */
static	char	*cmdName ;

static	void
usage()
{
	fprintf( stderr, "Usage: %s [ghpv]\n",cmdName ) ;
	fprintf( stderr, "       [-M <thread max>]\n" ) ;
	fprintf( stderr, "       [-T <slice time(milli seconds)>[u]]\n" ) ;
}

static	int
cmdline( int argc, char *argv[] )
{
	char	*p, ch ;
	int	err = 0 ;

	opterr = 0 ;

	while( (ch=getopt( argc, argv, "ghpvM:T:" )) != -1 ) {
		switch( ch ) {
		case 'g':	/* Debugging mode on */
			OzDebugging = 1 ;
			break ;
		case 'h':	/* help */
			printf( "OZ++ Executor: %s\n", OzVersion ) ;
			usage() ;
			exit( 0 ) ;
			break ;
		case 'p':	/* Profile ON */
			profileFlag = 1 ;
			break ;
		case 'M':
			OzThreadMax = strtol( optarg, 0, 0 ) ;
			if ( OzThreadMax <= 0 ) err ++ ;
			break ;
		case 'T':	/* time slice (default: milli seconds) */
			OzClockTicks = strtol( optarg, &p, 0 ) ;
			if ( OzClockTicks <= 0 ) err ++ ;
			break ;
		case 'v':	/* version */
			printf( "Sample: %s\n", OzVersion ) ;
			exit( 0 ) ;
			break ;
		case '?':	/* undefine option */
			err ++ ;
			break ;
		default	:	/* Not support option */
			fprintf( stderr, "%s: Ignore '%c'\n", argv[0], ch ) ;
			err ++ ;
		}
	}
	if ( err ) {
		usage() ;
		exit( 1 ) ;
	}

	return( optind ) ;
}

int
main( int argc, char *argv[] )
{
	int	i ;
	char	*ptr ;

	for ( ptr = argv[0] + strlen( argv[0] ) ; ptr != argv[0] ; -- ptr ) {
		if ( *ptr == '/' ) {
			++ ptr ;
			break ;
		}
	}
	cmdName = ptr ;

	/* Parse command line */
	i = cmdline( argc, argv ) ;
	if ( argc > i ) {
		/* Too many arguments */
		while( argc > i ) {
		    fprintf( stderr, "%s: Ignore '%s'\n", argv[0], argv[i++] ) ;
		}
	}

	if ( (i = open( "/dev/null", O_RDWR )) < 0 ) {
		perror( "open(/dev/tty)" ) ;
		exit(-1) ;
	}
	close( 0 ) ; dup2( i, 0 ) ;
	close( 1 ) ; dup2( i, 1 ) ;
	close( i ) ;
#if	1
	if ( (i = open( "ozlog", O_WRONLY|O_TRUNC|O_CREAT, 0666 )) < 0 ) {
		perror( "open(ozlog)" ) ;
		exit(-1) ;
	}
#else
	if ( (i = open( "/dev/tty", O_WRONLY, 0666 )) < 0 ) {
		perror( "open(ozlog)" ) ;
		exit(-1) ;
	}
#endif
	close( 2 ) ; dup2( i, 2 ) ;
	close( i ) ;

	setsid() ;


	/* malloc_debug( 3 ) ; */

	/* Multithread system start */
#if	!defined(SVR4)
	if ( profileFlag ) moncontrol( 1 ) ;
#endif
	i = ThrStart( OzThreadMax, OzClockTicks ) ;
#if	!defined(SVR4)
	if ( profileFlag ) moncontrol( 0 ) ;
#endif

	return( i ) ;
}
