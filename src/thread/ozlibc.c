/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Multithread system: Standard C library module
 *
 */
/* unix system include */
#include <unistd.h>
#include <errno.h>
#include <stdarg.h>
#include <memory.h>
#include <malloc.h>
/* multithread system include */
#include "strtobin4.h"
#include "strtobin8.h"
#include "thread/print.h"
#include "thread/thread.h"
#include "thread/monitor.h"

#include "oz++/ozlibc.h"

/*
 * Don't include any other module
 */

/*
 *	Declaration of System calls & System Functions
 */
#if	!defined(SVR4)
extern	time_t	time( time_t *tloc ) ;
extern	int	getsockopt( int s, int level, int optname, char *optval,
			int *optlen ) ;
extern	int	setsockopt( int s, int level, int optname, const char *optval,
			int optlen ) ;
extern	int	getsockname( int s, struct sockaddr *name, int *namelen ) ;
extern	int	getpeername( int s, struct sockaddr *name, int *namelen ) ;
extern	int	*encrypt( char *block, int edflag ) ;
extern	int	symlink( const char *name1, const char *name2 ) ;
extern	int	rename( const char *old, const char *new ) ;
extern	int	stat( const char *path, struct stat *buf ) ;
extern	int	lstat( const char *path, struct stat *buf ) ;
extern	int	fstat( int fildes, struct stat *buf ) ;
#endif	/* SVR4 */
extern	int	gettimeofday( struct timeval *tp, struct timezone *tzp ) ;

/* Exclusive lock for no reentrant function */
static	OZ_MonitorRec	ozlibc_lock ;

/* Exclusive lock for debug message to ozlog */
static	OZ_MonitorRec	ozlog_lock ;

static	int	debug = 0 ;

/*
 *	Setup & Cleanup OZ++ Library for C
 */
int
ThrLibcInit( int flag )
{
	OzInitializeMonitor( &ozlibc_lock ) ;
	OzInitializeMonitor( &ozlog_lock ) ;
	debug = flag ;
	return( 0 ) ;
}

int
ThrLibcFine()
{
	/* Lock this module becase to jump up single thread system */
	OzExecEnterMonitor( &ozlibc_lock ) ;

	return( 0 ) ;
}


/*
 *	UN*X System V level System calls (2)
 */

int
OzAccess( const char *path, int amode )
{
	return( access( path, amode ) ) ;
}

int
OzChmod( const char *path, mode_t mode )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Chmod is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( chmod( path, mode ) ) ;
}

int
OzChown( const char *path, uid_t owner, gid_t group )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Chown is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( chown( path, owner, group ) ) ;
}

pid_t
OzGetpid( void )
{
	return( getpid() ) ;
}

int
OzLink( const char *existing, const char *new )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Link is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( link( existing, new ) ) ;
}

off_t
OzLseek( int fildes, off_t offset, int whence )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Lseek is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( lseek( fildes, offset, whence ) ) ;
}

int
OzMkdir( const char *path, mode_t mode )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Mkdir is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( mkdir( path, mode ) ) ;
}

int
OzMkfifo( const char *path, mode_t mode )
{
	return( mkfifo( path, mode ) ) ;
}

int
OzRmdir( const char *path )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Rmdir is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( rmdir( path ) ) ;
}

int
OzStat( const char*path, struct stat *buf )
{
	return( stat( path, buf ) ) ;
}

int
OzLstat( const char *path, struct stat *buf )
{
	return( lstat( path, buf ) ) ;
}

int
OzFstat( int fildes, struct stat *buf )
{
	return( fstat( fildes, buf ) ) ;
}

int
OzSymlink( const char *name1, const char *name2 )
{
	return( symlink( name1, name2 ) ) ;
}

time_t
OzTime( time_t *tloc )
{
	return( time( tloc ) ) ;
}

clock_t
OzTimes( struct tms *buffer )
{
	return( times( buffer ) ) ;
}

time_t
OzMktime( struct tm *timeptr )
{
#if	defined(SVR4)
	return( mktime( timeptr ) ) ;
#else	/* SVR4 */
	return( timegm( timeptr ) ) ;
#endif	/* SVR4 */
}

int
OzUname( struct utsname *name )
{
	return( uname( name ) ) ;
}

int
OzUnlink( const char *path )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Unlink is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( unlink( path ) ) ;
}

int
OzUtime( const char *path, const struct utimbuf *times )
{
	return( utime( path, times ) ) ;
}


/*
 *	BSD level System calls(2)
 */

int
OzGetsockopt( int s, int level, int optname, char *optval, int *optlen )
{
	return( getsockopt( s, level, optname, optval, optlen ) ) ;
}

int
OzSetsockopt( int s, int level, int optname, const char *optval, int optlen )
{
	return( setsockopt( s, level, optname, optval, optlen ) ) ;
}

int
OzGetsockname( int s, struct sockaddr *name, int *namelen )
{
	return( getsockname( s, name, namelen ) ) ;
}

int
OzGetpeername( int s, struct sockaddr *name, int *namelen )
{
	return( getpeername( s, name, namelen ) ) ;
}

int
OzGettimeofday( struct timeval *tp, struct timezone *tzp )
{
	return( gettimeofday( tp, tzp ) ) ;
}

int
OzRename( const char *old, const char *new )
{
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzDebugf("Rename is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	return( rename( old, new ) ) ;
}


/*
 *	C Library Functions
 */

/*	malloc(3)	*/

void*
OzMalloc( size_t size )
{
	char	*rval ;
	int	block ;

	block = ThrBlockSuspend() ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	rval = malloc( size ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	ThrUnBlockSuspend( block ) ;

	return( rval ) ;
}

void*
OzRealloc( void *ptr, size_t size )
{
	char	*rval ;
	int	block ;

	block = ThrBlockSuspend() ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	rval = realloc( ptr, size ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	ThrUnBlockSuspend( block ) ;

	return( rval ) ;
}

void
OzFree( void *ptr )
{
	int	block ;

	block = ThrBlockSuspend() ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	free( ptr ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	ThrUnBlockSuspend( block ) ;
}


/*	string(3)	*/

int
OzStrcmp( const char *s1, const char *s2 )
{
	return( strcmp( s1, s2 ) ) ;
}

int
OzStrncmp( const char *s1, const char *s2, size_t n )
{
	return( strncmp( s1, s2, n ) ) ;
}

char*
OzStrcat( char *dst, const char *src )
{
	return( strcat( dst, src ) ) ;
}

char*
OzStrncat( char *dst, const char *src, size_t n )
{
	return( strncat( dst, dst, n ) ) ;
}

char*
OzStrcpy( char *dst, const char *src )
{
	return( strcpy( dst, src ) ) ;
}

char*
OzStrncpy( char *dst, const char *src, size_t n )
{
	return( strncpy( dst, src, n ) ) ;
}

size_t
OzStrlen( const char *s1 )
{
	return( strlen( s1 ) ) ;
}

char*
OzStrchr( const char *s, int c )
{
	return( strchr( s, c ) ) ;
}

char*
OzStrrchr( const char *s, int c )
{
	return( strrchr( s, c ) ) ;
}


/*	ctype(3V)	*/
int
OzIsupper( int c )
{
	return( isupper( c ) ) ;
}

int
OzIslower( int c )
{
	return( islower( c ) ) ;
}


/*	printf(3V)	*/
#if	!defined(SVR4)
extern	char	*vsprintf( char *s, const char *format, va_list ap ) ;
#endif	/* SVR4 */

static	int
ozSprintf_output( void *aKey, const char *aData, size_t aSize )
{
	size_t  size = aSize ;
	char    **buffer = (char **)aKey ;
	if ( size > 16 ) {
		memcpy( *buffer, aData, size ) ;
		*buffer += size ;
	} else while ( size -- ) * (*buffer) ++ = *aData ++ ;
	return( (int)aSize ) ;
}

char*
OzSprintf( char *s, const char *format, ... )
{
	char	*p = s ;
	va_list	args ;
	int	ret ;

	va_start( args, format ) ;
	ret = PrnFormat( ozSprintf_output, (void *)&p, format, args ) ;
	*p = '\0' ;
	va_end( args ) ;

	return( s ) ;
}

/*	directory(3V)	*/
DIR*
OzOpendir( const char *filename )
{
	DIR	*rval ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	rval = opendir( filename ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	return( rval ) ;
}

struct dirent*
OzReaddir( DIR *dirp )
{
	struct	dirent	*rval ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	rval = readdir( dirp ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	return( rval ) ;
}

long
OzTelldir( DIR *dirp )
{
	long	rval ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	rval = telldir( dirp ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	return( rval ) ;
}

void
OzSeekdir( DIR *dirp, long loc )
{
	OzExecEnterMonitor( &ozlibc_lock ) ;
	seekdir( dirp, loc ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
}

void
OzRewinddir( DIR *dirp )
{
	OzExecEnterMonitor( &ozlibc_lock ) ;
	rewinddir( dirp ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
}

int
OzClosedir( DIR *dirp )
{
	int	ret ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	ret =closedir( dirp ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	return( ret ) ;
}


/*	crypt(3)	*/

char*
OzCrypt( const char *key, const char *salt )
{
extern	char	*crypt() ;
	char	*rval ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	rval = crypt( key, salt ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	return( rval ) ;
}

#if	0	/* Missing ? */
void
OzSetkey( const char *key )
{
	OzExecEnterMonitor( &ozlibc_lock ) ;
	setkey( key ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
}
#endif

void
OzEncrypt( char *block, int edflag )
{
	OzExecEnterMonitor( &ozlibc_lock ) ;
	encrypt( block, edflag ) ;
	OzExecExitMonitor( &ozlibc_lock ) ;
}


/*	trig(3M)	*/

double
OzSin( double x )
{
	return( sin( x ) ) ;
}

double
OzCos( double x )
{
	return( cos( x ) ) ;
}

double
OzTan( double x )
{
	return( tan( x ) ) ;
}

double
OzAsin( double x )
{
	return( asin( x ) ) ;
}

double
OzAcos( double x )
{
	return( acos( x ) ) ;
}

double
OzAtan( double x )
{
	return( atan( x ) ) ;
}

double
OzAtan2( double y, double x )
{
	return( atan2( y, x ) ) ;
}

/*	exp(3M)		*/
double
OzExp( double x )
{
	return( exp( x ) ) ;
}

#if	!defined(SVR4)
double
OzExp2( double x )
{
	return( exp2( x ) ) ;
}

double
OzExp10( double x )
{
	return( exp10( x ) ) ;
}
#endif	/* SVR4 */

double
OzLog( double x )
{
	return( log( x ) ) ;
}

#if	!defined(SVR4)
double
OzLog2( double x )
{
	return( log2( 2 ) ) ;
}
#endif	/* SVR4 */

double
OzLog10( double x )
{
	return( log10( x ) ) ;
}

double
OzPow( double x, double y )
{
	return( pow( x, y ) ) ;
}


/*	memory(3)	*/

void*
OzMemccpy( void *s1, const void *s2, int c, size_t n )
{
	return( memccpy( s1, s2, c, n ) ) ;
}

void*
OzMemchr( const void *s, int c, size_t n )
{
	return( memchr( s, c, n ) ) ;
}

int
OzMemcmp( const void *s1, const void *s2, size_t n )
{
	return( memcmp( s1, s2, n ) ) ;
}

void*
OzMemcpy( void *aDstPtr, const void *aSrcPtr, size_t aSize )
{
	return( memcpy( aDstPtr, aSrcPtr, aSize ) ) ;
}

void*
OzMemset( void *s, int c, size_t n )
{
	return( memset( s, c, n ) ) ;
}


/*	miscellaneous	*/

int
OzStop()
{
	/* for debug break point */
	/* Nothing */
	return( 0 ) ;
}

char*
OzGetenv( const char *name )
{
	return( getenv( name ) ) ;
}

long
OzStrtol( const char *str, char **ptr, int base )
{
	return( strtobin4( (u_char *)str, (u_char **)ptr, base, 1 ) ) ;
}

unsigned long
OzStrtoul( const char *str, char **ptr, int base )
{
	return( strtobin4( (u_char *)str, (u_char **)ptr, base, 0 ) ) ;
}

long long
OzStrtoll( const char *str, char **ptr, int base )
{
	return( strtobin8( (u_char *)str, (u_char **)ptr, base, 1 ) ) ;
}

unsigned long long
OzStrtoull( const char *str, char **ptr, int base )
{
	return( strtobin8( (u_char *)str, (u_char **)ptr, base, 0 ) ) ;
}


/*
 *	OZ++ System original functions
 */
/*	for OzCopy	*/
static	int
ReadBlock( int fd, char *buf, int nbyte )
{
	int	ret = nbyte ;	/* Normal */
	char	*bufbrk = buf + nbyte ;
	int	size ;

	for ( bufbrk = buf + nbyte ; buf < bufbrk ; buf += size ) {
		size = OzRead( fd, buf, bufbrk-buf ) ;
		if ( size <= 0 ) {
			ret = -1 ;	/* Abnormal */
			break ;
		}
	}
	return( ret ) ;
}

/*	file copy	*/
int
OzCopy( const char *aSrcPath, const char *aDstPath )
{
	int	ret = -1 ;	/* Abnormal */
	int	src = -1 ;	/* Not yet open */
	int	dst = -1 ;	/* Not yet open */
	void	*buf = NULL ;	/* Not yet allocate */
	long	blocks ;
	int	bsize ;
	off_t	size = 0 ;
 struct	stat	srcStat ;
 struct	stat	dstStat ;

	/* Get file info. and Check */
	if ( OzStat( aSrcPath, &srcStat ) < 0 ) goto error ;
	if ( ! S_ISREG(srcStat.st_mode) ) {
		errno = EISDIR ;
		goto error ;
	}
	if ( OzStat( aDstPath, &dstStat ) == 0 ) {
		if ( srcStat.st_dev == dstStat.st_dev
			&& srcStat.st_ino == dstStat.st_ino ) {
			errno = EINVAL ;
			goto error ;
		}
		if ( ! S_ISREG(dstStat.st_mode) ) {
			errno = EEXIST ;
			goto error ;
		}
	}

	/* Open source file */
	if ( (src=OzOpen( aSrcPath, O_RDONLY, 0 )) < 0 ) goto error ;

	/* Create destination file */
	if ( (dst=OzCreat( aDstPath, srcStat.st_mode ) ) < 0 ) goto error ;

	/* For performance */
	bsize = srcStat.st_blksize ;
	blocks = srcStat.st_size / bsize ;

	/* alocate read buffer */
	if ( (buf=(void *)OzMalloc( bsize )) == NULL ) goto error ;

	/* Block copy except last block */
	while( blocks ) {
		if ( ReadBlock( src, buf, bsize ) < 0 ) goto error ;
		if ( OzWrite( dst, buf, bsize ) != bsize ) goto error ;
		size += bsize ;
		blocks -- ;
	}

	/* Last one block byte copy */
	if ( size < srcStat.st_size ) {
		bsize = srcStat.st_size - size ;
		if ( ReadBlock( src, buf, bsize ) < 0 ) goto error ;
		if ( OzWrite( dst, buf, bsize ) != bsize ) goto error ;
		size += bsize ;
	}

	ret = size ;	/* Normal */

 error:
	if ( src >= 0 ) OzClose( src ) ;
	if ( dst >= 0 ) {
		OzClose( dst ) ;
		if ( ret < 0 ) OzUnlink( aDstPath ) ;
	}
	if ( buf != NULL ) OzFree( buf ) ;
	return( ret ) ;
}

/*	date	*/
int
OzDate( time_t *aClock, struct tm *aTM )
{
	int	ret ;
 struct	tm	*tm ;
	time_t	clock ;

	clock = ( aClock == NULL ) ? OzTime( NULL ) : *aClock ;
	OzExecEnterMonitor( &ozlibc_lock ) ;
	tm = gmtime( &clock ) ;
	if ( tm && aTM ) {
		*aTM = *tm ;
		ret = 0 ;
	} else ret = -1 ;
	OzExecExitMonitor( &ozlibc_lock ) ;
	return( ret ) ;
}

/*	logging file */
int
OzLogFile( char *aFile, int aFlag, int aMode )
{
static	char	suffix[] = ".bak" ;
	int	size ;
	char	*fbak ;

	/* Create backup file */
	if ( OzAccess( aFile, F_OK ) == 0 ) {
		size = OzStrlen( aFile ) + sizeof(suffix) ;
		if ( (fbak = OzMalloc( size )) != NULL ) {
			OzStrcpy( fbak, aFile ) ;
			OzStrcat( fbak, suffix ) ;
			if ( OzAccess( fbak, F_OK ) == 0 ) OzUnlink( fbak ) ;
			OzRename( aFile, fbak ) ;
			OzFree( fbak ) ;
		}
	}

	return( open( aFile, aFlag, aMode ) ) ;
}

/* output to file with format */
static	int
ozOutput_file( void *aKey, const char *aData, size_t aSize )
{
	int	ret ;
	ret = OzWrite( (int)aKey, aData, aSize ) ;
	return( ret ) ;
}

int
OzOutput( int aOut, const char *aFormat, ... )
{
	va_list	args ;
	int	ret ;

	va_start( args, aFormat ) ;
	if ( aOut < 0 ) aOut = ThrGetStdOut() ;
	if ( aOut < 2 ) aOut = 2 ;
	ret = PrnFormat( ozOutput_file, (void *)aOut, aFormat, args ) ;
	va_end( args ) ;

	return( ret ) ;
}

void
OzShutdownExecutor()
{
	ThrStop( 0 ) ;
}

int
OzIdleTime( int aInterval )
{
	return( ThrIdle( aInterval ) ) ;
}

unsigned
OzSleep( unsigned seconds )
{
	return( ThrSleep( seconds ) ) ;
}

int
OzSetStdIn( int aStdIn )
{
	return( ThrSetStdIn( aStdIn ) ) ;
}

int
OzGetStdIn()
{
	return( ThrGetStdIn() ) ;
}

int
OzSetStdOut( int aStdOut )
{
	return( ThrSetStdOut( aStdOut ) ) ;
}

int
OzGetStdOut()
{
	return( ThrGetStdOut() ) ;
}

int
OzSetStdErr( int aStdErr )
{
	return( ThrSetStdErr( aStdErr ) ) ;
}

int
OzGetStdErr()
{
	return( ThrGetStdErr() ) ;
}

int
OzSetPriority( int  aPriority )
{
	return( ThrSetPriority( aPriority ) ) ;
}

int
OzGetPriority()
{
	return( ThrGetPriority() ) ;
}

int
OzBlockSuspend()
{
	return( ThrBlockSuspend() ) ;
}

void
OzUnBlockSuspend( int block )
{
	return( ThrUnBlockSuspend( block ) ) ;
}

int
OzDebugf( const char *aFormat, ... )
{
	va_list	args ;
	int	ret ;

	va_start( args, aFormat ) ;
	if ( debug ) {
		OzExecEnterMonitor( &ozlog_lock ) ;
		ThrVprintf( aFormat, args ) ;
		OzExecExitMonitor( &ozlog_lock ) ;
	} else ret = 0 ;
	va_end( args ) ;

	return( 0 ) ;
}

int
OzPrintf( const char *aFormat, ... )
{
	va_list	args ;
	int	stdOut ;
	int	ret ;

	va_start( args, aFormat ) ;
	stdOut = ThrGetStdOut() ;
	if ( stdOut < 3 ) {
		OzExecEnterMonitor( &ozlog_lock ) ;
		ThrVprintf( aFormat, args ) ;
		OzExecExitMonitor( &ozlog_lock ) ;
		ret = 0 ;
	} else ret = PrnFormat((PRNOUT *)OzWrite,(void *)stdOut,aFormat,args) ;
	va_end( args ) ;

	return( ret ) ;
}

int
OzReadLine( char *buf, int size )
{
	int	stdIn ;
	int	ret ;

	stdIn = ThrGetStdIn() ;
	if ( stdIn < 3 ) ret = -1 ;
	else ret = OzRead( stdIn, buf, size ) ;

	return( ret ) ;
}

int
OzSetDebug( int mode )
{
	int	ret ;
	ret = debug ;
	debug = mode ;
	return( ret ) ;
}

int
OzGetDebug()
{
	return( debug ) ;
}
