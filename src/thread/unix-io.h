/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_UNIX_IO_H_
#define	_UNIX_IO_H_
/*
 * Don't include any other module
 */

extern	int	thrWaitIO( int fd, int mode, int timeout ) ;
extern	int	thrCookedIO( int fd ) ;
extern	int	thrAttachIO( int fd, pid_t pid ) ;
extern	int	thrDetachIO( int fd ) ;
extern	int	thrKillIO( int fd, int sig ) ;
extern	int	thrWatchIO( int fd, int *status ) ;
extern	int	thrConsole( char *aPtyName ) ;
extern	pid_t	thrSpawn( int, int, int, const char *, char *const [] ) ;

#endif	!_UNIX_IO_H_
