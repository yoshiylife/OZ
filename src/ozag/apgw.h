/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _APGW_H_
#define _APGW_H_

#include "apgw_defs.h"
#include <netinet/in.h>
#include <sys/time.h>

typedef	struct	{
  long	apgwid;		/* Own IP Address 		*/
  long	filler;
  char	ozroot[128];
  char	tmpbuf[128];
} ApgwEnvRec, *ApgwEnv;

typedef struct _MessageBufferRec {
  long long exid_error_report;
  struct _MessageBufferRec *next;
  int buffer_size;
  char buffer[MESSAGE_BUFFER_SIZE];
} MessageBufferRec, *MessageBuffer;

#define SZ_MsgBuff sizeof(MessageBufferRec)

typedef struct  {
  int	fd;
  int	sin_port;
  int	(*func)();
  char	service_name[16];
} AcceptPortRec, *AcceptPort;

typedef struct  {
  AcceptPort	ap;
  int		fd;
  unsigned int  last_access;
  int           disconnect_flag;
} ReceivePortRec, *ReceivePort;

typedef struct {
  long long exid;
  int fd;
  unsigned int last_access;
  struct sockaddr_in addr;
  MessageBuffer waiting;
} SendPortRec, *SendPort;

typedef struct _HashTableRec {
  int	size;
  int	count;
  void	*tp;
} HashTableRec, *HashTable;

typedef struct _AddressRequestWaiter {
  long long exid;
  struct timeval start_time;
  int  retry_count;
}AddressRequestWaiterRec, *AddressRequestWaiter;


extern void syslog(char *message);

#endif _APGW_H_
