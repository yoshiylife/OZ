/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _CIRCUITS_H_
#define _CIRCUITS_H_
#include <sys/types.h>
#include <sys/uio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/mount.h>

#include "thread/thread.h"

#include "channel.h"
#include "ot.h"
#include "mem.h"
#include "encode.h"
#include "comm.h"
#include "comm-hash.h"
#include "comm-buff.h"
#include "p-table.h"
#include "comm-error.h"
#include "executor/executor.h"

#define OZPORT 0

/* state of send terminal
* ST_IDLE : this terminal is no used
* ST_PREP : this terminal is preparing for send (i.e. connecting)
* ST_SEND : this terminal is busy to send
* ST_TERM : this terminal is requested to terminate
* ST_CONN : this terminal is connected but no jobs now
* ST_EXCP : exception or unexpected disconnection occured
*/

/* state of receive terminal
* RT_IDLE : this terminal is not used
* RT_RECV : this terminal is receiving or at least connecting state
* RT_TERM : this terminal is receiving and disconnect request was sent
*/


typedef struct _SendTremRec {
  OZ_Thread ts,tc;
  OZ_MonitorRec lock;
  OZ_ConditionRec send_req;
  OZ_ConditionRec check_start;
  enum {ST_IDLE, ST_PREP, ST_SEND, ST_TERM, ST_CONN, ST_EXCP}  status;
  int fd;
  int rval,errno;
  commBuff buff;
  struct sockaddr_in destination;
  struct sockaddr_in destination_secondary;
  int executor_migrated;
}SendTermRec, *SendTerm;


typedef struct {
  OZ_Thread t;
  OZ_MonitorRec lock;
  OZ_ConditionRec recv_data;
  int fd;
  commBuff buff;
  enum {RT_IDLE,RT_RECV,RT_TERM} status;
  int disconn_req;
}RecvTermRec, *RecvTerm;

#endif !_CIRCUITS_H_
