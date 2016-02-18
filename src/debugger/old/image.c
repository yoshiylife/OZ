/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/param.h>
#include <oz++/class-type.h>
#include "class.h"

#include <common.h>

#define	LOOP	for(;;)
#define	OK	0
#define	NG	(-1)
#define	BUFSIZ	1024

char	*CmdName ;
char	*OzRoot = NULL ;
char	*OzClassPath = NULL ;
char	*ImageFile = NULL ;

int	Mode = 1 ;

void	Errorf( char *aFormat, ... ) ;

/*
 *	Dummy
 */
int	DebugFlagsDM() { return( -1 ) ; }
int	AnswerDM() { return( -1 ) ; }
int	RequestDM() { return( -1 ) ; }
long long	OzSiteID ;

Config( int aPort )
{
	OZ_Object	object ;
	char		aObject[BUFSIZ] ;

	object = (OZ_Object)8 ; /* Skip dummy & architecture id */
	object ++ ;

	sprintf( aObject, "%#08x", object ) ;
	SubObjectConfig( aPort, aObject ) ;
}

void
Errorf( char *aFormat, ... )
{
	va_list	args ;

	if ( CmdName != NULL ) fprintf( stderr, "%s: ", CmdName ) ;
	va_start( args, aFormat ) ;
	vfprintf( stderr, aFormat, args ) ;
	va_end( args ) ;
	fflush( stderr ) ;
}

void
Usage()
{
	char	*cmdName = CmdName ;
	CmdName = NULL ;
	Errorf( "Usage: %s [-C <class path>]\n", cmdName ) ;
	exit( 1 ) ;
}

int
CmdLine( int argc, char *argv[] )
{
extern  char    *optarg ;
extern  int     optind, opterr ;
	char    ch, *ptr ;
	int	err = 0 ;
	int	p ;

	for ( ptr = argv[0] + strlen( argv[0] ) ; ptr != argv[0] ; -- ptr ) {
		if ( *ptr == '/' ) {
			++ ptr ;
			break ;
		}
	}
	CmdName = ptr ;

	while ( (ch=getopt( argc, argv, "hC:" )) != EOF ) {
		switch( ch ) {
		case 'C' :
			OzClassPath = optarg ;
			break ;
		case 'h' :
			err ++ ;
			break ;
		default :
			Errorf( "Unknown option '%c'\n", ch ) ;
			err ++ ;
		}
		if ( err ) break ;
	}

	if ( err || argc < 1 || argc == optind ) Usage() ;

	return( optind ) ;
}

int
main( int argc, char *argv[] )
{
	int	ind ;
	char	*cmdName ;

	ind = CmdLine( argc, argv ) ;
	if ( ind != argc ) Usage() ;

	if ( OzRoot == NULL ) {
		OzRoot = getenv( "OZROOT" ) ;
		if ( OzRoot == NULL ) {
			Errorf( "Oh my god, please setenv OZROOT !!\n" ) ;
			exit( 1 ) ;
		}
	}

	if ( OzClassPath == NULL ) {
		OzClassPath = malloc( MAXPATHLEN ) ;
		sprintf( OzClassPath, "%s/lib/boot-class", OzRoot ) ;
	}

	return( 0 ) ;

error:
	return( 1 ) ;
}
