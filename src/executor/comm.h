/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMM_H_
#define _COMM_H_
/* unix system include */
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
/* multithread system include */
#include "thread/thread.h"

#include "channel.h"

/*
#define COMM_BUFF_SIZE 1024
*/
#define COMM_BUFF_SIZE 512

/* structure for communication buffer */
typedef struct _CommBuff {
  struct _CommBuff *next;
  struct sockaddr_in networkAddr;
  int bufsize;
  unsigned char buf[COMM_BUFF_SIZE];
  unsigned char *bp;
  void *channel;
  enum {RCHAN,SCHAN} channeltype;
} commBuffRec, *commBuff;


typedef struct _ReceiveBuff {
  commBuff list;
  OZ_Monitor lockp;
  OZ_ConditionRec buffAvail;
} ReceiveBuffRec, *ReceiveBuff;


typedef struct _SendBuff {
  commBuff list;
  OZ_Monitor lockp;
  struct sockaddr_in networkAddr;
  enum {UNIX,INET} destination;
  void *chan;
  enum {SCHANN,RCHANN} channeltype;
  int packetType;
  long long *messageId;
  int *abort;
} SendBuffRec, *SendBuff;

typedef struct _RemoteSendChannel{
  OzSendChannelRec send_channel;

  OZ_MonitorRec lock;
  OZ_ConditionRec receive_response;

  struct _RemoteSendChannel  *prev, *next;

  OID caller;
  OID cvid;
  int receive_slot_id;

#ifdef INTERSITE
  /* flag which set if RemoteSendChannel is created by foreing thread */
  unsigned int foreign_thread_flag;
#endif

  /* for receive value */
  char result_format;
  int ret_type;
  long long  rval;
  OZ_ExceptionIDRec exception;
  char exception_fmt;
  long long exception_param;

  /* status & flags */
  int abort;
  int aborted;
  int status;

  /* RPC status and communication buffer */
  SendBuffRec    send_buff;
  ReceiveBuffRec recv_buff;
} *RemoteSendChannel, RemoteSendChannelRec;


typedef struct _RemoteRecvChannel{
  OzRecvChannelRec receive_channel;

  OZ_MonitorRec lock;
  struct _RemoteRecvChannel  *next, *prev;

  /* communication Identifier */

  int slot_select;
  /* receive paramaters */
  int receive_slot_id;

  /* for return value */
  char result_format;
  int ret_type;

#ifdef INTERSITE
  /* flag which set if RemoteRecvChannel is created according to foreign packet*/
  unsigned int foreign_flag;
#endif
  /* for DebugMessage (added on 19-may-1995) */
  unsigned int dmflags;

  int aborted;
  int error;
  int status;

  /* communication buffer */
  SendBuffRec     send_buff;
  ReceiveBuffRec  recv_buff;

} *RemoteRecvChannel, RemoteRecvChannelRec;


#define COMM_CALL_IND  0x01010000
#define COMM_CALL_ARG  0x01020000
#define COMM_ABORT     0x03010000
#define COMM_RESULT    0x04010000
#define COMM_EXCEPTION 0x04020000
#define COMM_ERROR     0x04030000

#ifdef INTERSITE
/* bit0 (LSB) indicates that packet is come from other site.      */
/* This bit will be set by OZAG.                                  */
/* bit1 indicates that this packet is last one.                   */
/* This bit will be used by OZAG to detect last packet of session */
#define COMM_TAIL_FLAG		0x00000001
#define COMM_TAIL_MASK		0xfffffffe
#define COMM_UNTRUST_MASK	0xfffffffd
#define COMM_UNTRUST_FLAG	0x00000002
#define COMM_FLAGS_MASK         0xfffffffc

#define COMM_CALL_IND_U		(COMM_CALL_IND|COMM_UNTRUST_FLAG)
#define COMM_CALL_ARG_U		(COMM_CALL_ARG|COMM_UNTRUST_FLAG)
#define COMM_RESULT_T		(COMM_RESULT|COMM_TAIL_FLAG)
#define COMM_EXCEPTION_T	(COMM_EXCEPTION|COMM_TAIL_FLAG)
#define COMM_RESULT_U		(COMM_RESULT|COMM_UNTRUST_FLAG)
#define COMM_EXCEPTION_U	(COMM_EXCEPTION|COMM_UNTRUST_FLAG)
#define COMM_RESULT_TU		(COMM_CALL_IND|COMM_UNTRUST_FLAG|COMM_TAIL_FLAG)
#define COMM_EXCEPTION_TU	(COMM_EXCEPTION|COMM_UNTRUST_FLAG|COMM_TAIL_FLAG)
#define COMM_ERROR_T		(0x04030000|COMM_TAIL_FLAG)
#define COMM_ERROR_TU		(0x04030000|COMM_TAIL_FLAG)

/* COMM_ERROR and COMM_ERROR_UNTRUST will not be used,
 because ERROR packet is short to fit single packet and
be tagged with COMM_ERROR_T or COMM_ERROR_TU */
#endif

#endif /* _COMM_H_ */


