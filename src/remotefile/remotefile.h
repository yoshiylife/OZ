/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* remotefile.h : Header file for remote file transfer */
/* programmed by Y.Hamazaki   */
/* */
/* Update history */
/* programming on 20-feb-1995 */
/* modify for inter-site communication on 24-mar-1996 */

#ifndef _REMOTE_FILE_H_
#define _REMOTE_FILE_H_


/* flags for debug print
#define OFRdDEBUG
#define OFRDEBUG
#define OFSDEBUG
#define OFSdDEBUG
*/

#define INTERSITE

#ifdef INTERSITE
#define OzRemoteFileTransferPort 3774
#else
#define OzRemoteFileTransferPort 3001
#endif


#define OzFileReceiverPort 3002

#define TEMPORARYPATH "tmp"

#define NAMESIZE 256
#define BUFFER_SIZE 8192

/* error codes ( receiver ) */
#define SUCCESS         0
#define EXECLP_ERROR   -1
#define NO_REM_FILE    -2
#define REM_CONN_ER    -3
#define FILE_CREA_FAIL -4
#define COMM_ERROR     -5
#define FILE_WRITE_ER  -6


/* include files */
#include <stdio.h>
#include <signal.h>
#include <errno.h>
#include <ctype.h>
#include <strings.h>
#include <netdb.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/file.h>
#include <sys/wait.h>
#include <sys/param.h>
#include <sys/time.h>
#include <sys/resource.h>

#include <netinet/in.h>
#include <netinet/tcp.h>

/* template defs. */
int socket(int domain, int type, int protocol);
int setsockopt(int s, int level, int optname, char *optval, int optlen);
int bind(int s, struct sockaddr *name, int namelen);
int connect(int s, struct sockaddr *name, int namelen);
int accept(int s, struct sockaddr *addr, int *addrlen);
int listen(int s, int backlog);
int shutdown(int s, int how);
int write(int fd, char *buf, int nbyte);
int read(int fd, char *buf, int nbyte);
int close(int fd);

int sigblock(int mask);
int sigsetmask(int mask);
int sigvec(int sig, struct sigvec *vec, struct sigvec *ovec);
int fork();
int wait3(int *statusp, int options, struct rusage *rusage);

int link(char *path1, char *path2);
int unlink(char *path);

void bzero(char *b1, int length);
void bcopy(char *b1, char *b2, int length);
int atoi(char *str);

int chown(char *path, int owner, int group);
int chdir(char *path);
int chroot(char *path);

int getpid();
char *getenv(char *name);
void perror(char *s);
int gethostname(char *name, int nemelen);

/* timer functions defined in timefuncs.c */
void printtime(struct tm *tm, struct timeval *tv);
void printtimeinterval(struct timeval *from, struct timeval *to);
void gettime(struct tm *tm, struct timeval *tv);
#endif
