/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	OZ++ System start
 *
 *		Set OZ++ System global variables.
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

#include "switch.h"
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
char		*OzRoot = NULL ;	/* OZ++System root directory(abs) */
long long	OzExecutorID = 0 ;	/* Executor ID include site-id */
int		OzStandAlone = 1 ;	/* zero     : Fork from Necleus */
					/* otherwise: StandAlone */
int		OzClockTicks = 50 ;	/* ticks per seconds */
int		OzHeapSize = 16 * 1024 * 1024 ;
					/* limit size of heap without GC */
					/* unit with byte */
int		OzThreadMax = 256 ;	/* thread max concurrently */
int		OzGIMonitor = 1 ;	/* None-Zero: Monitor global invoke */
int		OzForkShell = 0 ;	/* None-Zero: Fork executor shell */
int		OzDaemon = 0 ;		/* None-Zero: daemon mode */
int		OzDebugging = 0 ;	/* None-Zero: debug mode */
int		OzExportAll = 0 ;	/* None-Zero: export all symbols */
int		OzIconify = 1 ;		/* Flag of console iconify */

int		OzArgc ;
char		**OzArgv ;

static	int	profileFlag = 0 ;	/* 0: Do't profile, else: do profile */
static	int	siteid = 1 ;
static	char	*cmdName ;

static	void
usage()
{
	fprintf( stderr, "Usage: %s [adghiopsv] <executor-id(hex)>\n",cmdName );
	fprintf( stderr, "       [-H <object heap size(mega bytes)>[k]]\n" ) ;
	fprintf( stderr, "       [-M <thread max>]\n" ) ;
	fprintf( stderr, "       [-S <site id(hex)>]\n" ) ;
	fprintf( stderr, "       [-T <slice time(milli seconds)>[u]]\n" ) ;
}

static	int
cmdline( int argc, char *argv[] )
{
	char	*p, ch ;
	int	err = 0 ;

	opterr = 0 ;

	while( (ch=getopt( argc, argv, "adghiopsvH:M:S:T:Z" )) != -1 ) {
		switch( ch ) {
		case 'a':	/* export all symbols of executor */
			OzExportAll = 2 ;
			break ;
		case 'd':	/* Daemon mode on */
			OzDaemon = 1 ;
			break ;
		case 'g':	/* Debugging mode on */
			OzDebugging = 1 ;
			break ;
		case 'h':	/* help */
			printf( "OZ++ Executor: %s\n", OzVersion ) ;
			usage() ;
			exit( 0 ) ;
			break ;
		case 'i':	/* Global invoke monitor off */
			OzGIMonitor = 0 ;
			break ;
		case 'o':	/* No iconify console */
			OzIconify = 0 ;
			break ;
		case 'p':	/* Profile ON */
			profileFlag = 1 ;
			break ;
		case 's':	/* Fork executor shell at first */
			OzForkShell = 1 ;
			break ;
		case 'H':	/* heap size (default: mega bytes) */
			OzHeapSize = strtol( optarg, &p, 0 ) ;
			*p = tolower( *p ) ;
			if ( *p == 'k' ) OzHeapSize *= 0x0400 ;	/* kilo bytes */
			else OzHeapSize *= 0x0100000 ;		/* mega bytes */
			if ( OzHeapSize <= 0 ) err ++ ;
			break ;
		case 'M':
			OzThreadMax = strtol( optarg, 0, 0 ) ;
			if ( OzThreadMax <= 0 ) err ++ ;
			break ;
		case 'S':	/* site id */
			siteid = strtol( optarg, NULL, 16 ) ;
			break ;
		case 'T':	/* time slice (default: milli seconds) */
			OzClockTicks = strtol( optarg, &p, 0 ) ;
			if ( OzClockTicks < 0 ) err ++ ;
			break ;
		case 'v':	/* version */
			printf( "OZ++ Executor: %s\n", OzVersion ) ;
			exit( 0 ) ;
			break ;
		case 'Z':	/* Fork from Necleus */
			OzStandAlone = 0 ;
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

static	int
logFile( char *aFile, int aFlag, int aMode )
{
static	char	suffix[] = ".bak" ;
	int	size ;
	char	*fbak ;

	/* Create backup file */
	if ( access( aFile, F_OK ) == 0 ) {
		size = strlen( aFile ) + sizeof(suffix) ;
		if ( (fbak = malloc( size )) != NULL ) {
			strcpy( fbak, aFile ) ;
			strcat( fbak, suffix ) ;
			if ( access( fbak, F_OK ) == 0 ) unlink( fbak ) ;
			rename( aFile, fbak ) ;
			free( fbak ) ;
		}
	}

	return( open( aFile, aFlag, aMode ) ) ;
}

int
main( int argc, char *argv[] )
{
	int	i ;
	char	*ptr ;

	OzArgc = argc ;
	OzArgv = argv ;

	for ( ptr = argv[0] + strlen( argv[0] ) ; ptr != argv[0] ; -- ptr ) {
		if ( *ptr == '/' ) {
			++ ptr ;
			break ;
		}
	}
	cmdName = ptr ;

	/* Parse command line */
	i = cmdline( argc, argv ) ;
	if ( argc > i ) {/* CAUTION: argc is greater than 1, i is zero origin */
		if ( OzStandAlone ) {
			/* Setup Executor-ID. */
			OzExecutorID = siteid ;
			OzExecutorID <<= 16 ;
			OzExecutorID |= strtol( argv[i++], NULL, 16 ) ;
			OzExecutorID <<= 24 ;
		}
		/* Too many arguments */
		while( argc > i ) {
		    fprintf( stderr, "%s: Ignore '%s'\n", argv[0], argv[i++] ) ;
		}
	} else {
		/* No more argument */
		if ( OzStandAlone ) {
			/* Not specify Executor-ID needly. */
			usage() ;
			return( 3 ) ;
		}
	}

	if ( (OzRoot=getenv("OZROOT")) == NULL ) {
		perror( "Can't get enviroment OZROOT" ) ;
		return( 4 ) ;
	}

	i = logFile( "ozlog", O_WRONLY|O_TRUNC|O_CREAT, 0666 ) ;
	if ( i < 0 ) {
		perror ( "Can't open 'ozlog'" ) ;
		return( 5 ) ;
	}
	dup2( i, 2 ) ;
	close( i ) ;

	if ( OzDaemon ) {
		i = open( "/dev/tty", O_RDWR, 0 ) ;
		if ( i < 0 ) {
			perror( "Can't open daemon terminal" ) ;
			return( 6 ) ;
		}
		dup2( i, 0 ) ;
		dup2( i, 1 ) ;
		close( i ) ;
	}

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

	close( 2 ) ;

	return( i ) ;
}
