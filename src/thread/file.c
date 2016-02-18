/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Multithread system: Standard file operation module
 *
 */
/* unix system include */
#define	DEFINE_OzOpen
#include <unistd.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <errno.h>
#include <fcntl.h>
/* multithread system include */
#include "unix-io.h"
#include "thread/print.h"
#include "thread/signal.h"
#include "thread/thread.h"
#include "thread/monitor.h"

#include "oz++/ozlibc.h"

/*
 * Don't include any other module
 */


#undef	DEBUG
#undef	DEBUG_OPEN
#undef	DEBUG_CLOSE
#undef	DEBUG_READ
#undef	DEBUG_WRITE
#undef	DEBUG_SEND

#define	LOOP	for(;;)
#define	WAITIO_READ	0	/* Zero    : wait to read */
#define	WAITIO_WRITE	1	/* NoneZero: wait to write */

#if	defined(SVR4)
#define	EWOULDBLOCK	EAGAIN
#endif	/* SVR4 */

/*
 *	System calls
 *		(Except unix standard[unistd.h])
 */
#if	!defined(SVR4)
int	socket( int domain, int type, int protocol ) ;
int	bind( int s, const struct sockaddr *name, int namelen ) ;
int	listen( int s, int backlog ) ;
int	accept( int s, struct sockaddr *addr, int *addrlen ) ;
int	connect( int s, struct sockaddr *name, int namelen ) ;
int	shutdown( int s, int how ) ;
int	send( int s, const char *msg, int len, int flags ) ;
int	sendto( int s, const char *msg, int len, int flags,
				struct sockaddr *to, int tolen ) ;
int	sendmsg( int s, struct msghdr *msg, int flags ) ;
int	recv( int s, char *buf, int len, int flags ) ;
int	recvfrom( int s, char *buf, int len, int flags,
				struct sockaddr *from, int *fromlen ) ;
int	recvmsg( int s, struct msghdr *msg, int flags ) ;
int	socketpair( int d, int type, int protocol, int sv[2] ) ;
int	readv( int fd, struct iovec *iov, int iovcnt ) ;
int	writev( int fd, struct iovec *iov, int iovcnt ) ;
#endif	/* SVR4 */

static	char	clrCodes[] = { 0x1b, '[', 'H', 0x1b, '[', '2', 'J' } ;

#ifdef INTERSITE
/* read/write operation for files are inhibited for foreign thread */
/* But premitted for socket, because it need to communicate with  */
/* spawned process */
int
foreignOk(int fd)
{
  struct stat buf;
  int i;

  if((ThrRunningThread->foreign_flag & 0x01)==0)
    return(1); /* it's OK for not-foreign thread */

  if((i=OzFstat(fd,&buf))<0)
    {
      OzError("OzFstat returns %d (fd=%d)\n",i,fd);
      return(0);
    }
  else if(S_ISSOCK(buf.st_mode))
    return(1);
  else
    {
      OzError("foreignOK is NO!, because it not socket \n");
      return(0);
    }
}
#endif

int
OzOpen( const char *path, int flags, mode_t mode )
{
	int	rval ;
	int	mask ;

#if	defined(DEBUG_OPEN)
	errno = 0 ;
#endif
#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzError("File Open is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif

	mask = SigBlock() ;
	rval = open( path, flags|O_NOCTTY, mode ) ;
	if ( rval >= 0 ) {
#if	defined(DEBUG_OPEN)
	  ThrPrintf( "OzOpen(%s) = %d\n", path, rval ) ;
	  if ( errno ) ThrPrintf( "Error[%d]:%m\n", errno ) ;
#endif
	  thrAttachIO( rval, 0 ) ;
	}
	SigUnBlock( mask ) ;
	return ( rval ) ;
}

int
OzCreat( const char *path, mode_t mode )
{
	int	rval ;
	int	mask ;

#ifdef INTERSITE
	if(ThrRunningThread->foreign_flag & 0x01)
	  {
	    OzError("File Create is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif

	mask = SigBlock() ;
	rval = creat( path, mode ) ;
	if ( rval >= 0 ) thrAttachIO( rval, 0 ) ;
	SigUnBlock( mask ) ;
	return ( rval ) ;
}

int
OzDup( int fildes )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = dup( fildes ) ;
	if ( rval >= 0 ) thrAttachIO( rval, 0 ) ;
	SigUnBlock( mask ) ;
	return ( rval ) ;
}

int
OzDup2( int fildes, int fildes2 )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = dup2( fildes, fildes2 ) ;
	if ( rval >= 0 ) thrAttachIO( fildes2, 0 ) ;
	SigUnBlock( mask ) ;
	return ( rval ) ;
}

int
OzPipe( int fildes[2] )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = pipe( fildes ) ;
	if ( rval >= 0 ) {
		thrAttachIO( fildes[0], 0 ) ;
		thrAttachIO( fildes[1], 0 ) ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzClose( int fd )
{
	int	rval ;
	int	mask ;

#if	defined(DEBUG_CLOSE)
	errno = 0 ;
#endif
#ifdef INTERSITE
	if(!foreignOk(fd))
	  {
	    OzError("File Close is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	if ( fd < 3 ) {
		errno = EINVAL ;
		OzError( "OzClose: Invalid fd = %d\n", fd ) ;
		return( -1 ) ;
	}

	mask = SigBlock() ;
	rval = thrDetachIO( fd ) ;
	if ( rval == 0 ) rval = close( fd ) ;
#if	defined(DEBUG_CLOSE)
ThrPrintf( "OzClose(%d) = %d\n", fd, rval ) ;
if ( errno ) ThrPrintf( "Error[%d]:%m\n", errno ) ;
#endif
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzRead( int fd, void *buf, size_t nbyte )
{
	int	rval ;
	int	mask ;

#ifdef INTERSITE
	if(!foreignOk(fd))
	  {
	    OzError("File Read is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	if ( fd < 3 ) {
		errno = EINVAL ;
		OzDebugf( "OzRead: Invalid fd = %d\n", fd ) ;
		return( -1 ) ;
	}

	mask = SigBlock() ;
	LOOP {
		rval = read( fd, buf, nbyte ) ;
#if	defined(DEBUG_READ)
ThrPrintf( "OzRead(%d,%d) = %d, errno = %d\n", fd, nbyte, rval, errno ) ;
#endif
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( fd, WAITIO_READ, 0 ) ) {
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzReadv( int fd, struct iovec *iov, int iovcnt )
{
	int	rval ;
	int	mask ;

#ifdef INTERSITE
	if(!foreignOk(fd))
	  {
	    OzError("File Readv is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	if ( fd < 3 ) {
		errno = EINVAL ;
		OzDebugf( "OzReadv: Invalid fd = %d\n", fd ) ;
		return( -1 ) ;
	}

	mask = SigBlock() ;
	LOOP {
		rval = readv( fd, iov, iovcnt ) ;
#if	defined(DEBUG_READ)
ThrPrintf( "OzReadv(%d,%d) = %d, errno = %d\n", fd, iovcnt, rval, errno ) ;
#endif
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( fd, WAITIO_READ, 0 ) ) {
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzWrite( int fd, const void *buf, size_t nbyte )
{
	int	rval = nbyte ;
	int	wcnt ;
	int	mask ;

#ifdef INTERSITE
	if(!foreignOk(fd))
	  {
	    OzError("File Write is not permitted to foreign thread\n");
	    return(-1);
  }
#endif
#if	0
	if ( fd < 3 ) {
		errno = EINVAL ;
		OzDebugf( "OzWrite: Invalid fd = %d\n", fd ) ;
		return( -1 ) ;
	}
#endif

	mask = SigBlock() ;
	while(  nbyte ) {
		wcnt = write( fd, buf, nbyte ) ;
#if	defined(DEBUG_WRITE)
ThrPrintf( "OzWrite(%d,%d) = %d, errno = %d\n", fd, nbyte, wcnt, errno ) ;
#endif
		if ( wcnt == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( fd, WAITIO_WRITE, 0 ) ) {
				rval = -1 ;
				errno = EIO ;
				break ;
			}
		} else if ( 0 <= wcnt ) {
			buf += wcnt ;
			nbyte -= wcnt ;
		} else {
			rval = -1 ;
			break ;
		}
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzWritev( int fd, struct iovec *iov, int iovcnt )
{
	int	rval ;
	int	mask ;

#ifdef INTERSITE
	if(!foreignOk(fd))
	  {
	    OzError("File Writev is not permitted to foreign thread\n");
	    return(-1);
	  }
#endif
	if ( fd < 3 ) {
		errno = EINVAL ;
		OzDebugf( "OzWritev: Invalid fd = %d\n", fd ) ;
		return( -1 ) ;
	}

	mask = SigBlock() ;
	LOOP {
		rval = writev( fd, iov, iovcnt ) ;
#if	defined(DEBUG_WRITE)
ThrPrintf( "OzWritev(%d,%d) = %d, errno = %d\n", fd, iovcnt, rval, errno ) ;
#endif
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( fd, WAITIO_WRITE, 0 ) ) {
				rval = -1 ;
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzSocket( int domain, int type, int protocol )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = socket( domain, type, protocol ) ;
	if ( rval >= 0 ) thrAttachIO( rval, 0 ) ;
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzBind( int s, struct sockaddr *name, int namelen )
{
	return( bind( s, name, namelen ) ) ;
}

int
OzListen( int s, int backlog )
{
	return( listen( s, backlog ) ) ;
}

int
OzAccept( int s, struct sockaddr *addr, int *addrlen )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	LOOP {
		rval = accept( s, addr, addrlen ) ;
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( s, WAITIO_READ, 0 ) ) {
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	/*
	 *  System call accept() return a new file descriptor created
	 * with same properties of 's'. But, scheduler maybe need to
	 * setup a new file descriptor.
	 *
	 */
	if ( 0 <= rval ) thrAttachIO( rval, 0 ) ;
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzConnect( int s, struct sockaddr *name, int namelen )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = connect( s, name, namelen ) ;
	if ( rval == -1 && errno == EINPROGRESS ) {
		if ( thrWaitIO( s, WAITIO_WRITE, 0 ) ) errno = EIO ;
		else {
			rval = connect( s, name, namelen ) ;
			if( rval == -1 && errno == EISCONN ) rval = 0 ;
		}
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzSend( int s, const char *msg, int len, int flags )
{
	int	rval = len ;
	int	wcnt ;
	int	mask ;

	mask = SigBlock() ;
	while( len ) {
		wcnt = send( s, msg, len, flags );
#if	defined(DEBUG_SEND)
ThrPrintf( "OzSend(%d,%d) = %d, errno = %d\n", s, len, wcnt, errno ) ;
#endif
		if ( wcnt == -1 && errno == EWOULDBLOCK ) {
			/* CAUTION: Timeout and retry */
			if ( thrWaitIO( s, WAITIO_WRITE, 1 ) ) {
				rval = -1 ;
				errno = EIO ;
				break ;
			}
		} else if ( 0 <= wcnt ) {
			msg += wcnt ;
			len -= wcnt ;
		} else {
			rval = -1 ;
			break ;
		}
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzSendto( int s, const char *msg, int len, int flags,
			struct sockaddr *to, int tolen )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	LOOP {
		rval = sendto( s, msg, len, flags, to, tolen ) ;
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( s, WAITIO_WRITE, 0 ) ) {
				rval = -1 ;
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzSendmsg( int s, struct msghdr *msg, int flags )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	LOOP {
		rval = sendmsg( s, msg, flags ) ;
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( s, WAITIO_WRITE, 0 ) ) {
				rval = -1 ;
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzRecv( int s, char *buf, int len, int flags )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	LOOP {
		rval = recv( s, buf, len, flags ) ;
#if	defined(DEBUG_RECV)
ThrPrintf( "OzRecv(%d,%d) = %d, errno = %d\n", s, len, rval, errno ) ;
#endif
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( s, WAITIO_READ, 0 ) ) {
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzRecvfrom( int s, char *buf, int len, int flags,
			struct sockaddr *from, int *fromlen )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	LOOP {
		rval = recvfrom( s, buf, len, flags, from, fromlen ) ;
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( s, WAITIO_READ, 0 ) ) {
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int
OzRecvmsg( int s, struct msghdr *msg, int flags )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	LOOP {
		rval = recvmsg( s, msg, flags ) ;
		if ( rval == -1 && errno == EWOULDBLOCK ) {
			if ( thrWaitIO( s, WAITIO_READ, 0 ) ) {
				errno = EIO ;
				break ;
			}
		} else break ;
	}
	SigUnBlock( mask ) ;
	return( rval ) ;
}

int OzShutdown(int s, int how)
{
	return( shutdown( s, how ) ) ;
}

int
OzCreateKterm( char *label, int iconic )
{
#if	defined(SVR4)
static	char	kt[] = "xterm" ;
#else	SVR4
static	char	kt[] = "kterm" ;
#endif	SVR4
static	char	ti[] = "-title" ;
static	char	ic[] = "-iconic" ;
	char	ptyName[32] ;
	char	buf[32] ;
	char	*argv[6] ;
	pid_t	pid ;
	int	pty ;
	int	tty = -1 ;
	int	mask ;

	mask = SigBlock() ;

	pty = thrConsole( ptyName ) ;
	if ( pty < 0 ) goto error ;
	OzSprintf( buf, "-S%c%c%d", ptyName[8], ptyName[9], pty ) ;

	/* Fork process for kterm */
	argv[0] = kt ;
	argv[1] = ti ;
	argv[2] = label ;
	argv[3] = buf ;
	argv[4] = iconic ? ic : NULL ;
	argv[5] = NULL ;
	pid = thrSpawn( pty, -1, LOGGING, kt, argv ) ;
	if ( pid < 0 ) {
		/* Fork failed */
		ThrError( "OzCreateKterm thrSpawn(): %m." ) ;
		tty = pid ;
	} else {
		close( pty ) ; /* Do't use OzClose() */
		ptyName[5] = 't' ;
		tty = open( ptyName, O_RDWR|O_NOCTTY, 0 ) ;
		if ( tty < 0 ) {
			ThrError( "OzCreateKterm open(%s): %m.", ptyName ) ;
			goto error ;
		}
		thrCookedIO( tty ) ;
		thrAttachIO( tty, pid ) ;
	}

 error:
	SigUnBlock( mask ) ;
	if ( 0 < tty ) {
		OzRead( tty, ptyName, sizeof(ptyName) ) ;
		OzWrite( tty, clrCodes, sizeof(clrCodes) ) ;
	}
	return( tty ) ;
}

int
OzConsole( const char *path, /* arg1, */ ... /* NULL */ )
{
	va_list	args ;
	char	ptyName[32] ;
	char	buf[32] ;
	int	argc = 0 ;
	char	**argv ;
	pid_t	pid ;
	int	pty ;
	int	tty = -1 ;
	int	mask ;

	argv = OzMalloc( sizeof(char *) * 3 ) ;

	argv[argc++] = (char *)path ;
	argv[argc++] = buf ;
	va_start( args, path ) ;
	while ( (argv[argc] = va_arg( args, char * )) ) {
		argc ++ ;
		argv = OzRealloc( argv, sizeof(char *) * (argc+1) ) ;
	}
	va_end( args ) ;

	mask = SigBlock() ;

	pty = thrConsole( ptyName ) ;
	if ( pty < 0 ) goto error ;
	OzSprintf( buf, "-S%c%c%d", ptyName[8], ptyName[9], pty ) ;

	/* Fork process for xterm */
	pid = thrSpawn( pty, -1, LOGGING, path, argv ) ;
	if ( pid < 0 ) {
		/* Fork failed */
		ThrError( "OzConsole thrSpawn(xterm): %m." ) ;
		tty = pid ;
	} else {
		close( pty ) ; /* Do't use OzClose() */
		ptyName[5] = 't' ;
		tty = open( ptyName, O_RDWR, 0 ) ;
		if ( tty < 0 ) {
			ThrError( "OzConsole open(%s): %m.", ptyName ) ;
			goto error ;
		}
		thrCookedIO( tty ) ;
		thrAttachIO( tty, pid ) ;
	}

 error:
	SigUnBlock( mask ) ;
	if ( argv ) OzFree( argv ) ;
	if ( 0 < tty ) {
		OzRead( tty, ptyName, sizeof(ptyName) ) ;
		OzWrite( tty, clrCodes, sizeof(clrCodes) ) ;
	}
	return( tty ) ;
}

int
OzSystem( const char *path, char *const argv[] )
{
	pid_t	pid ;
	int	fd ;
	int	rval = -1 ;
	int	mask ;
	int	status ;
	int	stdOut ;

	stdOut = ThrGetStdOut();
	fd = OzDup( stdOut ) ;

	mask = SigBlock() ;

	/* Fork process for xterm */
	pid = thrSpawn( -1, fd, LOGGING, path, argv ) ;
	if ( pid < 0 ) {
		/* Fork failed */
		ThrError( "OzSystem thrSpawn(%s): %m.", path ) ;
		goto error ;
	}
	thrAttachIO( fd, pid ) ;
	rval = thrWatchIO( fd, &status ) ;
	if ( rval == 0 ) rval = status ;

error:
	thrAttachIO( stdOut, 0 ) ;
	SigUnBlock( mask ) ;
	OzClose( fd ) ;

	return( rval ) ;
}

int
OzVspawn( const char *path, char *const argv[] )
{
	int	mask ;
	int	pid ;
	int	sv[2];

	mask = SigBlock() ;
	socketpair( AF_UNIX, SOCK_STREAM, 0, sv ) ;
	pid = thrSpawn( -1, sv[1], LOGGING, path, argv ) ;
	if ( pid < 0 ) {
		/* Fork failed */
		ThrError( "OzVspawn(%s): %m.", path ) ;
	} else {
		/* Parent process(executor) */
		close( sv[1] ) ; /* Don't use OzClose() */
		thrAttachIO( sv[0], pid ) ;
		pid = sv[0] ;
	}
	SigUnBlock( mask ) ;

	return( pid ) ;
}

int
OzSpawn( const char *command, int arg1, int arg2, int arg3, int arg4,
				int arg5, int arg6, int arg7, int arg8 )
{
	char	*argv[10] ;

	argv[0] = (char *)command ;
	argv[1] = (char *)arg1 ;
	argv[2] = (char *)arg2 ;
	argv[3] = (char *)arg3 ;
	argv[4] = (char *)arg4 ;
	argv[5] = (char *)arg5 ;
	argv[6] = (char *)arg6 ;
	argv[7] = (char *)arg7 ;
	argv[8] = (char *)arg8 ;
	argv[9] = NULL ;

	return( OzVspawn( command, argv ) ) ;
}

int
OzWatch( int fd, int *status )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = thrWatchIO( fd, status ) ;
	SigUnBlock( mask ) ;

	return( rval ) ;
}

int
OzKill( int fd, int sig )
{
	int	rval ;
	int	mask ;

	mask = SigBlock() ;
	rval = thrKillIO( fd, sig ) ;
	SigUnBlock( mask ) ;

	return( rval ) ;
}

/*	system message */
char*
OzStrsignal( int aSignum )
{
	char	*result = NULL ;

#if	defined(SVR4)
	result = strsignal( aSignum ) ;
#else	/* SVR4 */
	extern	char	*sys_siglist[] ;
	if ( 0 <= aSignum && aSignum < NSIG ) result = sys_siglist[aSignum] ;
#endif	/* SVR4 */

	return( result ) ;
}

char*
OzStrerror( int aErrnum )
{
	char	*result = NULL ;
#if	defined(SVR4)
	result = strerror( aErrnum ) ;
#else	/* SVR4 */
	extern	int	sys_nerr ;
	extern	char	*sys_errlist[] ;

	if ( 0<=aErrnum && aErrnum<sys_nerr ) result = sys_errlist[aErrnum] ;
#endif	/* SVR4 */

	return( result ) ;
}

int
OzError( const char *aFormat, ... )
{
	va_list	args ;
	int	stdErr ;
	int	ret ;

	va_start( args, aFormat ) ;
	SigPrintf( "ERROR %r\n", aFormat, args ) ;
	stdErr = ThrGetStdErr() ;
	if ( 3 <= stdErr ) {
		ret = PrnFormat((PRNOUT *)OzWrite,(void *)stdErr,aFormat,args) ;
		OzWrite( stdErr, "\n", 1 ) ;
	} else ret = 0 ;
	va_end( args ) ;

	return( ret ) ;
}
