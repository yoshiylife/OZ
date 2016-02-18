/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_OZLIBC_H_
#define	_OZLIBC_H_
#include	<stdio.h>
#include	<stdlib.h>

/* NOTICE: One function declaration with one line */

/*
 *	UN*X System V level System calls (2)
 */
#include	<sys/types.h>
#include	<sys/uio.h>
#include	<sys/stat.h>
#include	<sys/time.h>
#include	<sys/times.h>
#include	<sys/utsname.h>
#include	<fcntl.h>
#include	<unistd.h>
#include	<time.h>
#include	<utime.h>
/* #include	<limits.h> */

int	OzAccess( const char *path, int amode ) ;

#if	0	/* NO SUPPORT */
int	acct( const char *path ) ;
unsigned	alarm( unsigned sec ) ;
int	brk( void *endds ) ;
int	chdir( const char *path ) ;
#endif	/* NO SUPPORT */

int	OzChmod( const char *path, mode_t mode ) ;
int	OzChown( const char *path, uid_t owner, gid_t group ) ;

#if	0	/* NO SUPPORT */
int	chroot( const char *path ) ;
#endif	/* NO SUPPORT */

int	OzClose( int fildes ) ;
int	OzCreat( const char *path, mode_t mode ) ;

int	OzDup( int fildes ) ;
#if	0	/* NO SUPPORT */
int	exec( const char *path, char *const argv[], char *const envp[] ) ;
void	exit( int status ) ;
int	fcntl( int fildes, int cmd, /* arg */ ... ) ;
pid_t	fork( void ) ;
#endif		/* NO SUPPORT */

pid_t	OzGetpid( void ) ;

#if	0	/* NO SUPPORT */
pid_t	getuid( void ) ;
int	ioctl( int fildes, int request, /* arg */ ... ) ;
#endif		/* NO SUPPORT */

int	Ozkill( pid_t pid, int sig ) ;
int	OzLink( const char *existing, const char *new ) ;
off_t	OzLseek( int fildes, off_t offset, int whence ) ;

#if	0	/* NO SUPPORT */
int	mknod( const char *path, mode_t mode, dev_t dev ) ;
#include	<sys/mount.h> */
int	mount( const char *spec, const char *dir, int mflag,
		/* int fsyp, const char *datapr, size_t datalen */ ... ) ;
#include	<sys/ipc.h>
#include	<sys/msg.h>
int	msgctl( int msgqid, int cmd, /* struct msqid_ds *buf */ ... ) ;
int	msgget( key_t key, int msgflg ) ;
int	msgrcv( int msqid, void *msgp, size_t msgsz, long msgtyp, int msgflg ) ;
int	msgsnd( int msqid, const void *msgp, size_t msgsz, int msgflg ) ;
int		nice( int incr ) ;
#endif	/* NO SUPPORT */

int	OzMkdir( const char *path, mode_t mode ) ;
int	OzMkfifo( const char *path, mode_t mode ) ;
#if	!defined(DEFINE_OzOpen)
int	OzOpen( const char *path, int oflag, /* mode_t mode */ ... ) ;
#endif

#if	0	/* NO SUPPORT */
int	pause( void ) ;
#endif	/* NO SUPPORT */

int	OzPipe( int fildes[2] ) ;

#if	0	/* NO SUPPORT */
#include	<sys/lock.h>
int	plock( intp op ) ;
void	profil( unsigned short *buff, unsigned int bufsiz,
				unsigned int off, unsigned int scale ) ;
int	ptrace( int request, pid_t pid, int addr, int data ) ;
#endif	/* NO SUPPORT */

int	OzRead( int fildes, void *buf, size_t nbyte ) ;

#if	0	/* NO SUPPORT */
#include	<sys/sem.h> */
int	semctl( int semid, int semnum, int cmd, /* union semun arg */ ... ) ;
int	semget( key_t key, int nsems, int semflg ) ;
int	semop( int semid, struct sembuf *sops, size_t nsops ) ;
int	setpgrp( void ) ;
int	setuid( uid_t uid ) ;
int	setgid( gid_t gid ) ;
#include	<sys/shm.h>
int	shmctl( int shmid, int cmd, struct shmid_ds *buf ) ;
int	shmget( key_t key, int size, int shmflg ) ;
int	shmat( int shmid, void *shmaddr, int shmflg ) ;
int	shmdt( void *shmaddr ) ;
#include	<signal.h>
void	(*signal( int sig, void (*disp)(int)))(int) ;
#endif	/* NO SUPPORT */

int	OzRmdir( const char *path ) ;
int	OzStat( const char*path, struct stat *buf ) ;
int	OzLstat( const char *path, struct stat *buf ) ;
int	OzFstat( int fildes, struct stat *buf ) ;

#if	0	/* NO SUPPORT */
int	stime( const time_t *tp ) ;
#endif	/* NO SUPPORT */

int	OzSymlink( const char *name1, const char *name2 ) ;

#if	0	/* NO SUPPORT */
void	sync( void ) ;
#endif	/* NO SUPPORT */

time_t	OzTime( time_t *tloc ) ;
clock_t	OzTimes( struct tms *buffer ) ;
time_t	OzMktime( struct tm *timeptr ) ;

#if	0	/* NO SUPPORT */
#include	<ulimit.h> 
long	ulimit( int cmd, /* newlimit */ ... ) ;
mode_t	umask( mode_t cmask ) ;
#include	<sys/mount.h>
int	umount( const char *file ) ;
#endif	/* NO SUPPORT */

int	OzUname( struct utsname *name ) ;
int	OzUnlink( const char *path ) ;

#if	0	/* NO SUPPORT */
#include	<ustat.h>
int	ustat( dev_t dev, struct ustat *buf ) ;
#endif	/* NO SUPPORT */

int	OzUtime( const char *path, const struct utimbuf *times ) ;

#if	0	/* NO SUPPORT */
pid_t	wait( int *stat_loc ) ;
#endif	/* NO SUPPORT */

int	OzWrite( int fildes, const void *buf, size_t nbyte ) ;

int	OzRename( const char *old, const char *new ) ;

int	OzDup2( int fildes, int fildes2 ) ;


/*
 *	BSD level System calls(2)
 */
/* #include	<sys/time.h> */
/* #include	<sys/types.h> */
/* #include	<sys/uio.h> */
#include	<sys/socket.h>
int	OzSocket( int domain, int type, int protocol ) ;
int	OzBind( int s, struct sockaddr *name, int namelen ) ;
int	OzListen( int s, int backlog ) ;
int	OzAccept( int s, struct sockaddr *addr, int *addrlen ) ;
int	OzConnect( int s, struct sockaddr *name, int namelen ) ;
int	OzShutdown( int s, int how ) ;
int	OzSend( int s, const char *msg, int len, int flags ) ;
int	OzSendto( int s, const char *msg, int len, int flags,
				struct sockaddr *to, int tolen ) ;
int	OzSendmsg( int s, struct msghdr *msg, int flags ) ;
int	OzRecv( int s, char *buf, int len, int flags ) ;
int	OzRecvfrom( int s, char *buf, int len, int flags,
				struct sockaddr *from, int *fromlen ) ;
int	OzRecvmsg( int s, struct msghdr *msg, int flags ) ;
int	OzGetsockopt( int s, int level, int optname,
				char *optval, int *optlen ) ;
int	OzSetsockopt( int s, int level, int optname,
				const char *optval, int optlen ) ;
int	OzGetsockname( int s, struct sockaddr *name, int *namelen ) ;
int	OzGetpeername( int s, struct sockaddr *name, int *namelen ) ;
int	OzGettimeofday( struct timeval *tp, struct timezone *tzp ) ;


/*
 *	C Library Functions
 */
/*	string(3)	*/
#include	<string.h>
int	OzStrcmp( const char *s1, const char *s2 ) ;
int	OzStrncmp( const char *s1, const char *s2 , size_t n ) ;
char*	OzStrcat( char *dst, const char *src ) ;
char*	OzStrncat( char *dst, const char *src , size_t n ) ;
char*	OzStrcpy( char *dst, const char *src ) ;
char*	OzStrncpy( char *dst, const char *src , size_t n ) ;
size_t	OzStrlen( const char *s1 ) ;
char*	OzStrchr( const char *s, int c ) ;
char*	OzStrrchr( const char *s, int c ) ;

/*	ctype(3V)	*/
#include	<ctype.h>
int	OzIsupper( int c ) ;
int	OzIslower( int c ) ;

/*	printf(3V)	*/
#if	1
int	OzPrintf( const char *format, /* args */ ... ) ;
#endif
char*	OzSprintf( char *s, const char *format, /* args */ ... ) ;

/*	directory(3V)	*/
#include	<dirent.h>
DIR*		OzOpendir( const char *filename ) ;
struct dirent*	OzReaddir( DIR *dirp ) ;
long		OzTelldir( DIR *dirp ) ;
void		OzSeekdir( DIR *dirp, long loc ) ;
void		OzRewinddir( DIR *dirp ) ;
int		OzClosedir( DIR *dirp ) ;


/*	crypt(3)	*/
#if	defined(SVR4)
#include	<crypt.h>
#endif	/* SVR4 */
char*	OzCrypt( const char *key, const char *salt ) ;
#if		0	/* Missing ? */
void	OzSetkey( const char *key ) ;
#endif
void	OzEncrypt( char *block, int edflag ) ;

/*	trig(3M)	*/
#include	<math.h>
double	OzSin( double x ) ;
double	OzCos( double x ) ;
double	OzTan( double x ) ;
double	OzAsin( double x ) ;
double	OzAcos( double x ) ;
double	OzAtan( double x ) ;
double	OzAtan2( double y, double x ) ;

/*	exp(3M)	*/
double	OzExp( double x ) ;
#if	defined(SVR4)
double	OzExp2( double x ) ;
double	OzExp10( double x ) ;
double	OzLog2( double x ) ;
#endif	/* SVR4 */
double	OzLog( double x ) ;
double	OzLog10( double x ) ;
double	OzPow( double x, double y ) ;

/*	malloc(3V)	*/
/* #include	<malloc.h> */
void*	OzMalloc( size_t size ) ;
void	OzFree( void *ptr ) ;
void*	OzRealloc( void *ptr, size_t size ) ;

/*	memory(3)	*/
/* #include	<memory.h> */
void*	OzMemccpy( void *s1, const void *s2, int c, size_t n ) ;
void*	OzMemchr( const void *s, int c, size_t n ) ;
int	OzMemcmp( const void *s1, const void *s2, size_t n ) ;
void*	OzMemcpy( void *s1, const void *s2, size_t n ) ;
void*	OzMemset( void *s, int c, size_t n ) ;

/*	miscellaneous	*/
char*	OzGetenv( const char *name ) ;
unsigned	OzSleep( unsigned seconds ) ;
/* int	OzUsleep( unsigned useconds ) ; */
long			OzStrtol( const char *str, char **ptr, int base ) ;
unsigned long		OzStrtoul( const char *str, char **ptr, int base ) ;
long long		OzStrtoll( const char *str, char **ptr, int base ) ;
unsigned long long	OzStrtoull( const char *str, char **ptr, int base ) ;

/*
 *	OZ++ System original functions
 */
/*	file copy	*/
int	OzCopy( const char *aSrcPath, const char *aDstPath ) ;

/*	file output with format(printf)	*/
int	OzOutput( int fd, const char *format, ... ) ;

/*	date	*/
int	OzDate( time_t *aClock, struct tm *aTM ) ;

/*	unix process operation */
int	OzVspawn( const char *path, char *const argv[] ) ;
int	OzWatch( int fd, int *status ) ;
int	OzKill( int fd, int sig ) ;

/*	system message */
char	*OzStrerror( int aErrnum ) ;
char	*OzStrsignal( int aSignum ) ;

/*	miscellaneous	*/
int	OzError( const char *aFormat, ... ) ;
int	OzDebugf( const char *aFormat, ... ) ;
int	OzCreateKterm( char *label, int iconic ) ;
int	OzConsole( const char *path, /* arg0, arg1, */ ... /* NULL */ ) ;
int	OzLogFile( char *aLogFile, int aFlag, int aMode ) ;
void	OzShutdownExecutor() ;
int	OzIdleTime() ;
int	OzDisplay( const char *aFormat, ... ) ;
int	OzSetStdIn( int aStdIn ) ;
int	OzGetStdIn() ;
int	OzSetStdOut( int aStdOut ) ;
int	OzGetStdOut() ;
int	OzSetStdErr( int aStdErr ) ;
int	OzGetStdErr() ;
int	OzSetPriority( int  aPriority ) ;
int	OzGetPriority() ;
int	OzBlockSuspend() ;
void	OzUnBlockSuspend( int block ) ;
int	OzReadLine( char *buf, int size ) ;
int	OzSystem( const char *path, char *const argv[] ) ;
int	OzSetDebug( int mode ) ;
int	OzGetDebug() ;
#endif	/* ! _OZLIBC_H_ */
