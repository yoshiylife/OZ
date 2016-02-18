/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Multithread system: UNIX file I/O and Unix process module
 *
 *	IMPORTANT:
 *		You can only call Sig..., Thr... or thr... 
 *		You must be block signal before calling thr...
 */
/* unix system include */
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/resource.h>
#include <sys/file.h>
#include <sys/filio.h>
#include <sys/termios.h>
#include <sys/param.h>
#include <errno.h>
#ifdef	SVR4
#include <sys/conf.h>
#else	SVR4
#include <vfork.h>
#endif	SVR4
#include <stropts.h>
/* multithread system include */
#include "thread.h"
#include "unix-io.h"
#include "thread/signal.h"
#include "thread/stack.h"

/*
 * Don't include any other module
 */


#undef	DEBUG_WAIT_IO
#define	DEBUG_KILL
#define	DEBUG_CHILD

#define	MULTI_WAITIO


/*
 *	System calls
 *		(Except unix standard[unistd.h])
 */
#if	!defined(SVR4)
int	select( int width, fd_set *readfds, fd_set *writefds,
			fd_set *exceptfds, struct timeval *timeout ) ;
pid_t	waitpid( pid_t pid, int *stat_lock, int options ) ;
int	ioctl( int fd, int request, caddr_t arg ) ;
int	execvp( const char *file, char *const argv[] ) ;
int	setpgrp( int , int ) ;
#endif


/*
 *	Debug trace flag
 */
#if	defined(DEBUG_WAIT_IO)||defined(DEBUG_KILL)||defined(DEBUG_CHILD)
static	int	thrTraceIO = 0 ;
#endif


/*
 *	Local variables
 */
struct	fd_waiters	{
	int	count ;
	fd_set	usedfds ;
	fd_set	tempfds ;
	Thread	t[FD_SETSIZE] ;
} ;
static	struct fd_waiters	read_waiters ;
static	struct fd_waiters	write_waiters ;

typedef	struct proc*	proc ;
static	struct	{
	fd_set		usedfds ;
	fd_set		tempfds ;
	fd_set		exitfds ;
	proc		procs[FD_SETSIZE] ;
				} except_waiters ;

static	struct	termios	thrDefaultTC ;
static	pid_t	mypid ;


/*
 *	Unix process manage
 */
struct	proc	{
	int	ref_count ;
	pid_t	pid ;		/* hash key (ZERO: unix proc exit) */
	Thread	t ;
	int	signal ;
	int	status ;
} ;

static	struct	{
	size_t	max ;
	proc	proc ;
} ptab ;

static	proc
allocProc( pid_t pid )
{
	u_int	first ;
	u_int	index ;
	proc	proc ;

	proc = ptab.proc ;
	first = index = pid % ptab.max ;
	while ( proc[index].ref_count ) {
		if ( pid == proc[index].pid ) return( NULL ) ;
		index = (index + 1) % ptab.max ;
		if ( index == first ) return( NULL ) ;
	}
	proc += index ;
	proc->ref_count = 1 ;
	proc->pid = pid ;
	proc->t = NULL ;

	return( proc ) ;
}

static	int
freeProc( proc proc )
{
	if ( -- proc->ref_count == 0 ) {
		proc->pid = 0 ;
		proc->t = NULL ;
		return( 0 ) ;
	}
	return( proc->ref_count ) ;
}

static	void
sigallProc( int signo )
{
	int	i ;
	proc	proc ;

	for ( i = 0, proc = ptab.proc ; i < ptab.max ; i ++, proc ++ ) {
		if ( proc->ref_count && proc->pid ) {
#if	defined(DEBUG_KILL)
if ( thrTraceIO ) SigPrintf( "Kill %d\n", proc->pid ) ;
#endif
			kill ( proc->pid, signo ) ;
		}
	}
}

static	void
exitedProc( pid_t pid, int status )
{
	u_int	first ;
	u_int	index ;
	proc	proc ;

	/* Search unix process by pid */
	proc = ptab.proc ;
	first = index = pid % ptab.max ;
	while( proc[index].ref_count ) {
		if( pid == proc[index].pid ) break ;
		index = (index + 1) % ptab.max ;
		if ( index == first ) return ;
	}
	proc += index ;
	if ( proc->ref_count == 0 ) return ;

	if ( WIFEXITED( status ) ) {
		proc->signal = 0 ;
		proc->status = WEXITSTATUS( status ) ;
		proc->pid = 0 ;
	} else if ( WIFSIGNALED( status ) ) {
		proc->signal = WTERMSIG( status ) ;
		proc->status = 0 ;
		proc->pid = 0 ;
	} else if ( WIFSTOPPED( status ) ) {
		proc->signal = WSTOPSIG( status ) ;
		proc->status = 0 ;
		proc->pid = 0 ;
	}

	if ( proc->pid == 0 && proc->t ) thrReady( proc->t ) ;

	return ;
}

static	void
initProc()
{
	if ( ptab.proc == NULL ) {
		ptab.max = sysconf( _SC_CHILD_MAX ) ;
		ptab.proc = (proc)stkAlloc( sizeof(struct proc) * ptab.max ) ;
	}
}

static	void
shutProc()
{
	if ( ptab.proc != NULL ) {
		stkFree( (void *)ptab.proc, sizeof(struct proc) * ptab.max ) ;
	}
}

int
thrWaitIO( int fd, int mode, int timeout )
{
struct	fd_waiters	*waiters = mode ? &write_waiters : &read_waiters ;
		int	rval = -1 ;	/* Abnormal */

#if	defined(DEBUG_WAIT_IO)
if ( thrTraceIO )
{
extern	int	fd_pikopiko ;
if ( fd != fd_pikopiko )
SigPrintf( "wait (%3d) %s  wait r:%3d w:%3d\n", fd,
		waiters == &read_waiters ? "ri" : "wi",
		read_waiters.count, write_waiters.count ) ;
}
#endif

	/* Check arguments */
	if ( fd < 0 || FD_SETSIZE <= fd ) {
		errno = EBADF ;
		goto error ;
	}

#ifndef	MULTI_WAITIO
	/* Already exist a thread ? */
	if ( waiters->t[fd] ) {
		/* for debug */
		errno = EEXIST ;
		abort() ;
		goto error ;
	}
#endif	!MULTI_WAITIO

	/* Setup fds */
	FD_SET( fd, &waiters->usedfds ) ;
	FD_SET( fd, &except_waiters.usedfds ) ;
	waiters->count ++ ;

	/* Reschdule */
	ThrRunningThread->status = WAIT_IO ;
	thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
#ifndef	MULTI_WAITIO
	waiters->t[fd] = ThrRunningThread ;
#else	!MULTI_WAITIO
	thrEnqueue( &waiters->t[fd], ThrRunningThread ) ;
	ThrRunningThread->wait_io = &waiters->t[fd] ;
#endif	!MULTI_WAITIO
	if ( timeout ) {
		/* Request Timer service form scheduler */
		thrTimeout( ThrRunningThread, timeout ) ;
	}
	if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
	thrSwitch( thrReadyThreads ) ;		/* Don't call thrReschedule() */

#ifndef	MULTI_WAITIO
	/* Already Detach ? */
	if ( waiters->t[fd] == 0 ) {
		errno = EBADF ;
		goto error ;
	} else waiters->t[fd] = 0 ;
#endif	!MULTI_WAITIO

	/* Clear fds*/
	if ( FD_ISSET( fd, &waiters->usedfds ) == 0 ) {
		if ( FD_ISSET( fd, &read_waiters.usedfds ) == 0
			&& FD_ISSET( fd, &write_waiters.usedfds ) == 0 ) {
			FD_CLR( fd, &except_waiters.usedfds ) ;
		}
	}
	FD_CLR( fd, &waiters->usedfds ) ;
	waiters->count -- ;

	/* Normal */
	rval = 0 ;

error:
#if	defined(DEBUG_WAIT_IO)
if ( thrTraceIO )
{
extern	int	fd_pikopiko ;
if ( fd != fd_pikopiko )
SigPrintf( "wait (%3d) %s  wait r:%3d w:%3d\n", fd,
		waiters == &read_waiters ? "ro" : "wo",
		read_waiters.count, write_waiters.count ) ;
}
#endif
	return( rval ) ;
}

int
thrCookedIO( int fd )
{
	/* Change tty to canonical(cooked) mode */
#if	defined(SVR4)
	if ( ioctl( fd, I_PUSH, "ldterm" ) ) {
		ThrError( "thrCookedIO ioctl(0,I_PUSH,ldterm): %m." ) ;
	} else if ( ioctl( fd, TCSETS, (caddr_t)&thrDefaultTC ) ) {
		ThrError( "thrCookedIO ioctl(%d,TCSETS,): %m.", fd ) ;
	}
#else	/* SVR4 */
	if ( ioctl( fd, TCSETS, (caddr_t)&thrDefaultTC ) ) {
		ThrError( "thrCookedIO ioctl(%d,TCSETS,): %m.", fd ) ;
	}
#endif
	return( 0 ) ;
}

int
thrAttachIO( int fd, pid_t pid )
{
	int	rval = -1 ;	/* Abnormal */
#if	defined(SVR4)
	int	flags ;
#else
	int	one = 1 ;
#endif

	/* Check arguments */
	if ( fd < 0 || FD_SETSIZE <= fd ) {
		errno = EBADF ;
		goto error ;
	}

	/* attach unix process */
	if ( pid ) {
		if ( (except_waiters.procs[fd] = allocProc( pid )) == NULL ) {
			errno = ENOMEM ;
			goto error ;
		}
	} else except_waiters.procs[fd] = NULL ;

	/* Change to non-block mode */
#if	defined(SVR4)
	if ( (flags = fcntl( fd,F_GETFL )) < 0 ) {
		ThrError( "thrAttachIO fcntl(%d,F_GETFL): %m.", fd ) ;
		goto error ;
	}
	flags |= O_NONBLOCK ;
	if ( fcntl( fd, F_SETFL, flags ) < 0 ) {
		ThrError( "thrAttachIO fcntl(%d,F_SETFL,0x%x): %m.",fd,flags ) ;
		goto error ;
	}
	flags = S_INPUT | S_OUTPUT | S_ERROR | S_MSG | S_HANGUP ;
	if ( ioctl( fd, I_SETSIG, flags ) < 0 ) {
		ThrError( "thrAttachIO ioctl(%d,F_SETFL,0x%x): %m.",fd,flags ) ;
		goto error ;
	}
#else	/* SVR4 */
	if ( ioctl( fd, FIONBIO, (caddr_t)&one ) < 0 ) {
		ThrError( "thrAttachIO ioctl(%d,FIONBIO): %m.",fd ) ;
		goto error ;
	}
	if ( ioctl( fd, FIOASYNC, (caddr_t)&one ) < 0 ) {
		ThrError( "thrAttachIO ioctl(%d,FIOASYNC): %m.",fd ) ;
		goto error ;
	}
	if ( ioctl( fd, FIOSETOWN, (caddr_t)&mypid ) < 0 ) {
#if	0	/* too many errors */
		ThrError( "thrAttachIO ioctl(%d,FIOSETOWN,%d): %m.",fd,mypid ) ;
#endif
		goto error ;
	}
#endif

	/* Normal */
	rval = 0 ;

error:
	return( rval ) ;
}

int
thrDetachIO( int fd )
{
#ifdef	MULTI_WAITIO
	Thread	t ;
#endif	MULTI_WAITIO
	int	rval = -1 ;	/* Abnormal */
#if	defined(SVR4)
	int	flags ;
#else
	int	zero = 0 ;
#endif

	/* Check arguments */
	if ( fd < 0 || FD_SETSIZE <= fd ) {
		errno = EBADF ;
		goto error ;
	}

	/* Remove wait to read */
	FD_CLR( fd, &read_waiters.usedfds ) ;
	if ( read_waiters.t[fd] ) {
#ifndef	MULTI_WAITIO
		if ( read_waiters.t[fd]->status == WAIT_IO ) {
			thrReady( read_waiters.t[fd] ) ;
		}
		read_waiters.t[fd] = 0 ;
		read_waiters.count -- ;
#else	!MULTI_WAITIO
		while ( (t = read_waiters.t[fd]) ) {
			read_waiters.count -- ;
			thrReady( t ) ;
		}
#endif	!MULTI_WAITIO
	}

	/* Remove wait to write */
	FD_CLR( fd, &write_waiters.usedfds ) ;
	if ( write_waiters.t[fd] ) {
#ifndef	MULTI_WAITIO
		if ( write_waiters.t[fd]->status == WAIT_IO ) {
			thrReady( write_waiters.t[fd] ) ;
		}
		write_waiters.t[fd] = 0 ;
		write_waiters.count -- ;
#else	!MULTI_WAITIO
		while ( (t = write_waiters.t[fd]) ) {
			write_waiters.count -- ;
			thrReady( t ) ;
		}
#endif	!MULTI_WAITIO
	}

	/* Clear exception */
	FD_CLR( fd, &except_waiters.usedfds ) ;

#if	defined(SVR4)
	if ( (flags = fcntl(fd,F_GETFL)) < 0 ) {
		ThrError( "thrDetachIO fcntl(%d,F_GETFL): %m.", fd ) ;
		goto error ;
	}
	flags &= ~O_NONBLOCK ;
	if ( fcntl( fd, F_SETFL, flags ) < 0 ) {
		ThrError( "thrDetachIO fcntl(%d,F_SETFL,0x%x): %m.",fd,flags ) ;
		goto error ;
	}
	if ( ioctl( fd, I_SETSIG, 0 ) < 0 ) {
		ThrError( "thrDetachIO ioctl(%d,F_SETSIG,0): %m.", fd ) ;
		goto error ;
	}
	if ( 3 <= fd && isatty( fd ) ) {
		if ( ioctl( fd, I_POP, 0 ) < 0 ) {
			ThrError( "thrDetachIO ioctl(%d,I_POP,0): %m.", fd ) ;
			goto error ;
		}
	}
#else	/* SVR4 */
	if ( ioctl( fd, FIONBIO, (caddr_t)&zero ) < 0 ) {
		ThrError( "thrDetachIO ioctl(%d,FIONBIO): %m.",fd ) ;
		goto error ;
	}
	if ( ioctl( fd, FIOASYNC, (caddr_t)&zero ) < 0 ) {
		ThrError( "thrDetachIO ioctl(%d,FIOASYNC): %m.",fd ) ;
		goto error ;
	}
#endif	/* SVR4 */

	/* detach unix process */
	if ( except_waiters.procs[fd] ) {
		freeProc( except_waiters.procs[fd] ) ;
		except_waiters.procs[fd] = NULL ;
	}

	/* Normal */
	rval = 0 ;

error:
	return( rval ) ;
}

int
thrWatchIO( int fd, int *status )
{
	int	rval = -1 ;	/* Abnormal */
	proc	proc = NULL ;

	/* Check arguments */
	if ( fd < 0 || FD_SETSIZE <= fd ) {
		errno = EBADF ;
		goto error ;
	}

	proc = except_waiters.procs[fd] ;

	/* Associate with unix process ? */
	if ( proc == NULL ) {
		errno = ESRCH ;
		goto error ;
	}

	/* Wait until unix process terminated */
	proc->ref_count ++ ;
	if ( proc->pid ) {
		proc->t = ThrRunningThread ;
		ThrRunningThread->status = WAIT_IO ;
		thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
		if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;
		thrSwitch( thrReadyThreads ) ;	/* Don't call thrReschedule() */
	}
	if ( status ) *status = proc->status ;
	rval = proc->signal ;
	freeProc( proc ) ;

error:
	return( rval ) ;
}

int
thrKillIO( int fd, int sig )
{
	int	ret = -1 ;	/* Abnormal */
	proc	proc ;

	/* Check arguments */
	if ( fd < 0 || FD_SETSIZE <= fd ) {
		errno = EBADF ;
		goto error ;
	}

	proc = except_waiters.procs[fd] ;
	if ( proc && proc->pid ) {
		ret = kill( proc->pid, sig ) ;
		if ( ret == 0 ) ret = proc->pid ;
		else {
			errno = ESRCH ;
			ret = -1 ;
		}
	} else ret = 0 ;

error:
	return( ret ) ;
}

static	void
thrHandlerSIGIO( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION	SIGIO Deferrable
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */
	/*
	 * But, this handler's stack never have been refered.
	 */
 static	struct	timeval	timeout = {0, 0} ;
	int	nready ;
	int	i ;
#ifdef	MULTI_WAITIO
	Thread	t ;
#endif	MULTI_WAITIO

	if ( read_waiters.count == 0 && write_waiters.count == 0 ) return ;

	read_waiters.tempfds = read_waiters.usedfds ;
	write_waiters.tempfds = write_waiters.usedfds ;
	except_waiters.tempfds = except_waiters.usedfds ;
	nready = select( FD_SETSIZE,
			&read_waiters.tempfds,
			&write_waiters.tempfds,
			&except_waiters.tempfds, &timeout ) ;
	if ( nready <= 0 ) return ;

	for ( i = 0 ; i < FD_SETSIZE ; i ++ ) {

		/* Check read & exception (don't macro, for debug) */
		if ( FD_ISSET( i, &read_waiters.tempfds )
			|| FD_ISSET( i, &except_waiters.tempfds ) ) {
#ifndef	MULTI_WAITIO
			if ( read_waiters.t[i]
				&& read_waiters.t[i]->status == WAIT_IO ) {
				thrReady( read_waiters.t[i] ) ;
				nready  -- ;
#if	defined(DEBUG)
if ( thrTraceIO )
{
extern	int	fd_pikopiko ;
if ( i != fd_pikopiko )
SigPrintf( "ready(%3d) r   wait r:%3d w:%3d\n", i,
		read_waiters.count, write_waiters.count ) ;
}
#endif
			}
#else	!MULTI_WAITIO
			while ( (t = read_waiters.t[i]) ) {
				thrReady( t ) ;
				nready  -- ;
			}
#endif	!MULTI_WAITIO
		}
		if ( nready <= 0 ) break ;

		/* Check write & exception (don't macro, for debug) */
		if ( FD_ISSET( i, &write_waiters.tempfds )
			|| FD_ISSET( i, &except_waiters.tempfds ) ) {
#ifndef	MULTI_WAITIO
			if ( write_waiters.t[i]
				&& write_waiters.t[i]->status == WAIT_IO ) {
				thrReady( write_waiters.t[i] ) ;
				nready  -- ;
#if	defined(DEBUG)
if ( thrTraceIO )
{
if ( i != fd_pikopiko )
SigPrintf( "ready(%3d) w   wait r:%3d w:%3d\n", i,
		read_waiters.count, write_waiters.count ) ;
}
#endif
			}
#else	!MULTI_WAITIO
			while ( (t = write_waiters.t[i]) ) {
				thrReady( t ) ;
				nready  -- ;
			}
#endif	!MULTI_WAITIO
		}
		if ( nready <= 0 ) break ;

	}

}

static	void
thrHandlerSIGCHLD( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION	SIGIO Deferrable
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */
	/*
	 * But, this handler's stack never have been refered.
	 */
	int	status ;
	int	pid ;

	while ( (pid=waitpid( (pid_t)-1, &status, WNOHANG )) > 0 ) {
#if	defined(DEBUG_CHILD)
if ( thrTraceIO ) SigPrintf( "\nSIGCHLD Catch %d\n", pid ) ;
#endif
		exitedProc( pid, status ) ;
	}
}

pid_t
thrSpawn( int pty, int tty, int err, const char *path, char *const argv[] )
{
 static	int	flag ;
	pid_t	pid ;
	int	i ;

	flag = 0 ;
	pid = vfork() ;
	if ( pid == 0 ) {
		/* Child process */
#if	0
#ifdef	SVR4
		setpgrp() ;
#else	SVR4
		setpgrp(getpid(),getpid()) ;
#endif	SVR4
#endif
		if ( pty < 0 ) {
			dup2( tty, 0 ) ;
			dup2( tty, 1 ) ;
		}
		for ( i = 3 ; i < NOFILE ; i ++ ) {
			if ( i != pty ) close( i ) ; /* Don't use OzClose() */
		}
		execvp( path, argv ) ;
		ThrError( "thrSpawn execvp(%s,): %m.", path ) ;
		flag = 1 ;
		_exit( 1 ) ;	/* child process */
	}
	return( flag ? -1 : pid ) ;
}

int
thrConsole( char *aPtyName )
{
 static	char	hexs[] = "0123456789abcdef" ;
 static	char	ptyname[11] = "/dev/pty??" ;
	int	pty ;
	int	i ;
	char	*p ;

	/* Find pseudo tty name */
	for ( i = 0 ; ptyname[i] ; i ++ ) aPtyName[i] = ptyname[i] ;
	aPtyName[i] = '\0' ;
	ptyname[5] = 'p' ;
	for ( aPtyName[8] = 'p' ; aPtyName[8] <= 'r' ; aPtyName[8] ++ ) {
		for ( p = hexs ; (aPtyName[9]=*p) ; p ++ ) {
			pty = open( aPtyName, O_RDWR, 0 ) ;
			if ( 0 <= pty ) return( pty ) ;
		}
	}
	ThrError( "thrConsole(): Not found %s.", ptyname ) ;

	return( -1 ) ;
}

int
ThrAttachIO( int fd )
{
	int	ret ;
	int	mask ;

	mask = SigBlock() ;
	ret = thrAttachIO( fd, 0 ) ;
	SigUnBlock( mask ) ;

	return( ret ) ;
}

void
ThrStartupIO()
{
	int	mask ;

	mask = SigBlock() ;

	mypid = getpid() ;

	thrDefaultTC.c_iflag = ICRNL | IXON | IMAXBEL ;
	thrDefaultTC.c_oflag = OPOST | ONLCR | XTABS ;
	thrDefaultTC.c_cflag = CBAUD | CSIZE | CREAD ; 
	thrDefaultTC.c_lflag = ISIG | ICANON
			| ECHO | ECHOE | ECHOK | ECHOCTL | ECHOKE
			| PENDIN | IEXTEN ;
#if	!defined(SVR4)
	thrDefaultTC.c_line = 0 ;
#endif

	thrDefaultTC.c_cc[VINTR] = CNUL ;
	thrDefaultTC.c_cc[VQUIT] = CNUL ;
	thrDefaultTC.c_cc[VERASE] = 'h' & 037 ;
	thrDefaultTC.c_cc[VKILL] = CKILL ;
	thrDefaultTC.c_cc[VEOF] = CEOF ;
	thrDefaultTC.c_cc[VEOL] = CEOL ;
	thrDefaultTC.c_cc[VEOL2] = CEOL2 ;
	thrDefaultTC.c_cc[VSWTCH] = CNUL ;
	thrDefaultTC.c_cc[VSTART] = CSTART ;
	thrDefaultTC.c_cc[VSTOP] = CSTOP ;
	thrDefaultTC.c_cc[VSUSP] = CNUL ;
	thrDefaultTC.c_cc[VDSUSP] = CNUL ;
	thrDefaultTC.c_cc[VREPRINT] = CRPRNT ;
	thrDefaultTC.c_cc[VDISCARD] = CNUL ;
	thrDefaultTC.c_cc[VWERASE] = CWERASE ;
	thrDefaultTC.c_cc[VLNEXT] = CLNEXT ;

	initProc() ;

	/* Startup signal handler */
	SigAction( SIGIO, thrHandlerSIGIO ) ;
	SigAction( SIGPIPE, thrHandlerSIGIO ) ;
	SigAction( SIGCHLD, thrHandlerSIGCHLD ) ;

	SigUnBlock( mask ) ;
}

void
ThrCleanupIO()
{
	int	mask ;
	int	i ;

	/* Send SIGTERM to all child unix process */
	mask = SigBlock() ;
	sigallProc( SIGTERM ) ;
	SigUnBlock( mask ) ;

	/* This blank line is very important.
	 * Above line [ThrUnBlockSingal()] mean to catch SIGCHLD.
	 */

	/* Cleanup io ? */
	for ( i = 3 ; i < FD_SETSIZE ; i ++ ) {
		mask = SigBlock() ;	/* Be deliberate */
		if ( FD_ISSET( i, &read_waiters.usedfds )
			|| FD_ISSET( i, &write_waiters.usedfds ) ) {
			if ( thrDetachIO( i ) == 0 ) close( i ) ; 
		}
		SigUnBlock( mask ) ;	/* Be deliberate */
	}

	/* Cleanup signal handler */
	SigAction( SIGIO, SIG_IGN ) ;
	SigAction( SIGPIPE, SIG_IGN ) ;
	SigAction( SIGCHLD, SIG_IGN ) ;

	mask = SigBlock() ;
	shutProc() ;
	SigUnBlock( mask ) ;
}
