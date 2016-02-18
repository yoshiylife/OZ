/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <sys/types.h>
#include <sys/uio.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/mount.h>
#include <errno.h>
#include <stdarg.h>
#include <netinet/tcp.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "executor/executor.h"
#include "oz++/type.h"

#include "channel.h"
#include "ot.h"
#include "g-invoke.h"
#include "common.h"

#include "mem.h"
#include "encode.h"
#include "decode.h"
#include "except.h"
#include "comm.h"
#include "comm-hash.h"
#include "comm-buff.h"
#include "p-table.h"

#include "ncl/ex_ncl_event.h"
#include "ncl/exec_table.h"
#include "ex-addr-table.h"

extern	int	bzero( char *, int ) ;
extern	int	bcopy( char *, char *, int ) ;

/* Many messages for debugging will be displayed if DEBUGMESSAGE is
defied as 1 */

#define DEBUGMESSAGE 0
#define EXCEPTDEBUG 0

/* property of callee thread */
#define CALLEE_PRIORITY 3
#define CALLEE_STACKSIZE 20480
#define COMM_DAEMON_PRIORITY 3
#define DAEMON_STACK_SIZE 10240

extern	long long OzExecutorID;
struct sockaddr_in MyNetworkAddress={AF_INET};
int MyArchitectureType=1;

/* current debug message flags */
extern unsigned int OzDebugFlags;


/* interface between circuits and channel */
commBuff SendListUnix=(commBuff)0;
commBuff SendListInet=(commBuff)0;
commBuff RecvList=(commBuff)0;
OZ_MonitorRec SendListUnixLock;
OZ_MonitorRec SendListInetLock;
OZ_MonitorRec RecvListLock;
OZ_ConditionRec SendListUnixAvail;
OZ_ConditionRec SendListInetAvail;
OZ_ConditionRec RecvListAvail;

#define ERROR_TYPE_ABORTED -1
#define ERROR_OBJECT_NOT_FOUND -2
#define ERROR_CANT_CREATE_CHANNEL -3
/* static variable to handle remote channels */

/* memory area of channel is reserved for reuse upto xxx_CHANN_RESERVE_MAX */
#define RCV_CHANN_RESERVE_MAX 10
#define SND_CHANN_RESERVE_MAX 10

static  OZ_MonitorRec RemSndChannLock;
static  commHashTable RemSndHash;
static  RemoteSendChannel RemSndChannelRoot;
static  RemoteSendChannel RemSndReserve;
static  int       RemSndReserveCount;

static  OZ_MonitorRec RemRcvChannLock;
static  commHashTable RemRcvHash;
static  RemoteRecvChannel RemRcvChannelRoot;
static  RemoteRecvChannel RemRcvReserve;
static  int       RemRcvReserveCount;

#ifdef INTERSITE
int
OzIsObjectForeign(OZ_Header oh)
{
  OZ_Header h;

  if(oh==0)
    return(0);
  else if(oh->h == -2)
    {
      h = oh;
      h -= (oh->e +1);
      return(h->p);
    }
  else
    return(0);
}

int
OzIsThreadForeign()
{
  if(ThrRunningThread->foreign_flag & 0x01)
    return(1);
  else
    return(0);
}
#endif

static void
NoPrintf(s,arg0, arg1, arg2,arg3,
	 arg4,arg5, arg6,arg7)
{
  if(DEBUGMESSAGE)
    OzDebugf((char *)s,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7);
  return;
}

static void   DumpAddress(struct sockaddr_in *a)
{ unsigned char *b; int i;

  b=(unsigned char *)a;

  for(i=0;i<16;i++) NoPrintf("%02x ",*b++); 
  NoPrintf("\n");
}

/* message-Id */
/* message-Id is an identifier of RPC session and is unique in whole system
* at a time. message-Id is reused after the session identified has been
* finished.
* message-Id is (unique_number | executor-Id).
* 
* GEN_ID_SHIFT + log2(GEN_SECT_NUM) = 24(bits).
* GEN_SECT_MASK = log2(GEN_SECT_NUM) ones from LSB.
* GEN_ID_MASK = GEN_ID_SHIFT ones from LSB */

#define GEN_SECT_MASK 0x0f
#define GEN_SECT_NUM 16
#define GEN_ID_MASK 0x0fffff
#define GEN_ID_SHIFT 20
#define UNIQUE_NUMBER_MASK 0x0ffffff

/* structure of message_id_generator */
static struct _MessageIdGen{
  long long exec_id;
  int unique_no;
  int be_careful;
  int usage[GEN_SECT_NUM];
} MessageIdGen;


void 
initMessageId()
{
  int i;

  MessageIdGen.exec_id = OzExecutorID;
  MessageIdGen.unique_no = 0;
  MessageIdGen.be_careful = 0;
  for(i=0;i<GEN_SECT_NUM;i++)
    MessageIdGen.usage[i]=0;
}

/* MessageIdGen structure is not monitor-ed, but assumed to be
* used within monitor(RemSendChannLock) of RemoteSendChannel. */
long long 
getMessageId()
{
  int i;
  long long new_id;

  i=MessageIdGen.unique_no++;

  if((i & GEN_ID_MASK)==0)
    {
      i &= UNIQUE_NUMBER_MASK;
      MessageIdGen.unique_no &= UNIQUE_NUMBER_MASK;
      if(MessageIdGen.usage[i>>GEN_ID_SHIFT]==0)
	MessageIdGen.be_careful = 0;
      else
	MessageIdGen.be_careful = 1;
    }

  new_id = MessageIdGen.exec_id | i;
  if((MessageIdGen.be_careful)
     &&(SearchCommHash(RemSndHash,new_id)!=(void *)0))
    return(getMessageId());
  else
    {
      MessageIdGen.usage[i>>GEN_ID_SHIFT]++;
      return(new_id);
    }
}

void
releaseMessageId(long long id)
{
  int i,sect;

  i=(int)(id & UNIQUE_NUMBER_MASK);
  sect=i>>GEN_ID_SHIFT;
  MessageIdGen.usage[sect]--;
  return;
}


/* send-receive */
/* sendList and recvList is used as interface between channel and 
* send-receive routines */

#define COMM_CALL_IND  0x01010000
#define COMM_CALL_ARG  0x01020000
#define COMM_ABORT     0x03010000
#define COMM_RESULT    0x04010000
#define COMM_EXCEPTION 0x04020000
#define COMM_ERROR     0x04030000



/* status of caller */
#define CALLING   1
#define ABORTING  2
#define WAITING   3
#define FINISHED  4

/* status of callee */
#define CALLED    1
#define ABORTED   2


/* void ('v') is void but treated as four byte argument in this program */
/* returned value of void type is meaningless                           */
#define IsEightByteArg(c) (c=='l' || c=='d' || c=='P' || c=='G')
#define IsFourByteArg(c)  (c=='i' || c=='s' || c=='c' || c=='f' || c=='v')
#define IsPointerArg(c)   (c=='A' || c=='O' || c=='S' || c=='R')

static inline int
isPointerArray(long long type)
{
  return((type==OZ_LOCAL_OBJECT)||(type==OZ_STATIC_OBJECT)||(type==OZ_ARRAY));
}


/* copy struct sockaddr_in */
void
sockaddrcopy(struct sockaddr_in *from , struct sockaddr_in *to)
{
  bcopy((char *)from , (char *)to, 16);
}


/* inline functions */
inline static RemoteSendChannel
send_to_remote_channel(OzSendChannel chan)
{
  return((RemoteSendChannel)chan);
}

inline static OzSendChannel
remote_to_send_channel(RemoteSendChannel chan)
{
  return((OzSendChannel)chan);
}

inline static RemoteRecvChannel
recv_to_remote_channel(OzRecvChannel chan)
{
  return((RemoteRecvChannel)chan);
}

inline static OzRecvChannel
remote_to_recv_channel(RemoteRecvChannel chan)
{
  return((OzRecvChannel)chan);
}


int putCommBuff(SendBuff sb,unsigned char *s, int count);

inline int
putCommBuffTwo(SendBuff sb, short s)
{
  return(putCommBuff(sb,(unsigned char *)&s,2));
}

inline int
putCommBuffFour(SendBuff sb, int i)
{
  return(putCommBuff(sb,(unsigned char *)&i,4));
}

inline int
putCommBuffEight(SendBuff sb, long long l)
{
  return(putCommBuff(sb,(unsigned char *)&l,8));
}

/* basic send and send buffer operation routines */
commBuff
newSndCommBuff(SendBuff sb)
{
  commBuff cb;
  int i;
  sb->list = cb = GetCommBuff();

  sockaddrcopy(&(sb->networkAddr),&(cb->networkAddr));
  cb->channel = sb->chan;
  if(sb->channeltype==SCHANN)
    cb->channeltype=SCHAN;
  else
    cb->channeltype=RCHAN;
    cb->bufsize = 0 ;
    i=putCommBuffFour( sb, sb->packetType ) ;
    i=putCommBuffFour( sb, MyArchitectureType ) ;
    i=putCommBuffEight( sb, *(sb->messageId) ) ;
  return(cb);
}

void
sendCommBuffUnix(commBuff commbuff)
{
  commBuff cb;

  OzExecEnterMonitor(&SendListUnixLock);
  if(SendListUnix==(commBuff)0)
    SendListUnix=commbuff;
  else
    {
      for(cb = SendListUnix ;cb->next != (commBuff)0; cb=cb->next)
	;
      cb->next = commbuff;
    }

  OzExecSignalCondition(&SendListUnixAvail);
  OzExecExitMonitor(&SendListUnixLock);
}

void
sendCommBuffInet(commBuff commbuff)
{
  commBuff cb;

  OzExecEnterMonitor(&SendListInetLock);
  if(SendListInet==(commBuff)0)
    SendListInet=commbuff;
  else
    {
      for(cb = SendListInet ;cb->next != (commBuff)0; cb=cb->next)
	;
      cb->next = commbuff;
    }
  OzExecSignalCondition(&SendListInetAvail);
  OzExecExitMonitor(&SendListInetLock);
}

void
sendCommBuff(SendBuff sb,commBuff commbuff)
{
  if(sb->destination == UNIX)
    sendCommBuffUnix(commbuff);
  else
    sendCommBuffInet(commbuff);
}

void
sendSndCommBuff(SendBuff sb)
{


  sendCommBuff(sb,sb->list);

  sb->list = (commBuff)0;
}

void
send_and_allocSndCommBuff(SendBuff sb)
{
#ifdef INTERSITE
  /* reset tail flag, because this packet is not last one */
  *((int *)(sb->list->buf)) &= COMM_TAIL_MASK;
#endif

  sendSndCommBuff(sb);
  newSndCommBuff(sb);
}


/* modify on 9-oct-95 by Y.Hamazaki */
/* change recursion to do loop */
int
putCommBuff(SendBuff sb,unsigned char *s, int count)
{
  commBuff p;
  int tailcount;

  do {
    p= sb->list;
    if(p->bufsize+count<=COMM_BUFF_SIZE)
      {
	bcopy(s,p->bp,count);
	p->bp += count;
	p->bufsize += count;
	if(p->bufsize==COMM_BUFF_SIZE)
	  send_and_allocSndCommBuff(sb);
	count=0;
      }
    else
      {
	tailcount = p->bufsize+count-COMM_BUFF_SIZE;
	count -= tailcount;
	bcopy(s,p->bp,count);
	p->bp += count;
	p->bufsize += count;
	send_and_allocSndCommBuff(sb);
	s+=count;
	count = tailcount;
      }
  }  while(count>0);
  
  return(0);
}


/* basic receve and receive buffer operation routines */
void
readBuff(commBuff buf,int offset,int size,unsigned char *dest)
{
  commBuff cb;
  unsigned char *p;
  int i;

  if(offset > buf->bufsize)
    {
      cb=buf->next;
      p=cb->bp+(offset-buf->bufsize);
      bcopy(p,dest,size);
    }
  else if(offset+size-1 < buf->bufsize)
    {
      p=buf->bp+offset;
      bcopy(p,dest,size);
    }
  else
    {
      i=buf->bufsize - offset;
      p=buf->bp + offset;
      bcopy(p,dest,i);
      dest+=i;
      p=(buf->next)->bp;
      bcopy(p,dest,size-i);
    }
}

void
readCommBuff(ReceiveBuff rbuf,int offset,int size, unsigned char *dest)
{
  commBuff cb;
  unsigned char *p,*endp;

  OzExecEnterMonitor(rbuf->lockp);
  while(rbuf->list==(commBuff)0)
    OzExecWaitCondition(rbuf->lockp,&(rbuf->buffAvail));
  cb=rbuf->list;

  p=cb->bp;
  endp=cb->bp+cb->bufsize;

  if(p+offset+size >endp)
    {
      while(cb->next==(commBuff)0)
	OzExecWaitCondition(rbuf->lockp,&(rbuf->buffAvail));
    }

  readBuff(cb,offset,size,dest);
  OzExecExitMonitor(rbuf->lockp);
  return;
}


/* getCommBuff locks channel. Don't forget to exit from channel's 
monitor lock before call this routine */
void
getCommBuff(ReceiveBuff rbuf,int size,unsigned char *dest)
{
  commBuff cb;
#if 0
NoPrintf("getCommBuff  to %x (size %d bytes) list : %x\n",dest,size,rbuf->list);
#endif
  OzExecEnterMonitor(rbuf->lockp);
#if 0
if(rbuf->list != 0)
  NoPrintf("rbuf->list->bufsize %d \n",rbuf->list->bufsize);
#endif

  while(size>0){
    while(rbuf->list==(commBuff)0)
      OzExecWaitCondition(rbuf->lockp,&(rbuf->buffAvail));
    cb=rbuf->list;
    if(cb->bufsize >= size)
      {
	bcopy(cb->bp,(char *)dest,size);
	if((cb->bufsize-=size)==0)
	  {
	    rbuf->list=rbuf->list->next;
	    cb->next=(commBuff)0;
	    FreeCommBuff(cb);
	  }
	else
	  {
	    cb->bp+=size;
	  }
	OzExecExitMonitor(rbuf->lockp);
	return;
      }
    else
      {
	bcopy(cb->bp,(char *)dest,cb->bufsize);
	dest+=cb->bufsize;
	size-=cb->bufsize;
	rbuf->list=rbuf->list->next;
	cb->next=(commBuff)0;
	FreeCommBuff(cb);
      }
  }
  OzExecExitMonitor(rbuf->lockp);
  
}



/* receive routines */
short
getTwoByte(commBuff cb)
{
  short s;
  bcopy(cb->bp,(char *)&s,2);
  cb->bp+=2;
  cb->bufsize-=2;
  return(s);
}

int
getFourByte(commBuff cb)
{
  int i;
  bcopy(cb->bp,(char *)&i,4);
  cb->bp+=4;
  cb->bufsize-=4;
  return(i);
}

long long
getEightByte(commBuff cb)
{
  long long ll;
  bcopy(cb->bp,(char *)&ll,8);
  cb->bp+=8;
  cb->bufsize-=8;
  return(ll);
}


/* sendAbort send ABORT packet to remote receiver channel */
static void
sendAbort(RemoteSendChannel rchann)
{
  commBuff cb;
  SendBuff sb;

  sb=&(rchann->send_buff);

  cb = GetCommBuff();
  sockaddrcopy(&(sb->networkAddr),&(cb->networkAddr));
  *((int *)(cb->bp))=COMM_ABORT;
  cb->bp+=sizeof(int);
  *((int*)(cb->bp))=MyArchitectureType;
  cb->bp+=sizeof(int);
  *((long long*)(cb->bp))=*(sb->messageId);
  cb->bp+=sizeof(long long);
  cb->bufsize = sizeof(int)*2+sizeof(long long);
  cb->channeltype=SCHAN;
  cb->channel=rchann;

  sendCommBuff(sb,cb);

  rchann=sb->chan;
  /* change abort status */
  OzExecEnterMonitor(&(rchann->lock));
  rchann->aborted = 1;
  rchann->abort   = 0;
  OzExecExitMonitor(&(rchann->lock));
}

/* encoder for communication */
static int
encode_comm(int (*writefunc)(), SendBuff func_arg, OZ_Header entry)
{
  int offset;

#if 1
  if(entry == 0)
    offset = 0;
  else 
    {
      if(entry->h == LOCAL)
	offset = entry->e +1;
      else
	offset = 0;
    }
  if(putCommBuffFour(func_arg, offset)<0)
    return(-1);
  if(entry == 0)
    {  (*writefunc)(func_arg,&entry,4);
       return(0);
     }
#else
  if(entry->h == LOCAL)
    offset = entry->e +1;
  else
    offset = 0;
  if(putCommBuffFour(func_arg, offset)<0)
    return(-1);
  if(entry == 0)
    {  (*writefunc)(func_arg,&entry,4);
       return(0);
     }
#endif
  return(OzEncode(writefunc,(void *)func_arg,entry,ENC_COMM));
}

/* decoder */

/* decode_comm decode an item from rbuf with format fmt.
*  if item is object, the object is created on heap and pointer to object
*  is returned. Otherwise, value is returned. */

void
decode_comm(ReceiveBuff rbuf,char fmt,void *result,Heap heap
#ifdef INTERSITE
	    ,int foreign_flag
#endif
)
{
  OzDecode(readCommBuff,getCommBuff,rbuf,fmt,result,heap
#ifdef INTERSITE
	   ,foreign_flag
#endif
);
}

/* lengthofStrings returns length of string in received comm buffer
* including null terminator. (ex. When "ABC" is on buffer, 4 will be
* returned */
int
lengthofString(ReceiveBuff rbuf)
{
  int i;
  commBuff cb;
  unsigned char *p,*endp;

  OzExecEnterMonitor(rbuf->lockp);

 GetBuffAgain_LOS:

  while(rbuf->list==(commBuff)0)
    OzExecWaitCondition(rbuf->lockp,&(rbuf->buffAvail));
  cb=rbuf->list;

  /* If buffer is empty, free it */
  if(cb->bufsize<=0)
    {
      rbuf->list = rbuf->list->next;
      cb->next=0;
      FreeCommBuff(cb);
      goto GetBuffAgain_LOS;
    }

  p=cb->bp;
  endp=cb->bp+cb->bufsize;
  for(i=0;(*p) != '\0';i++)
    {
      if((++p)>endp)
	{
	  while(cb->next==(commBuff)0)
	    OzExecWaitCondition(rbuf->lockp,&(rbuf->buffAvail));
	  cb=cb->next;
	  p=cb->bp;
	  endp=p+cb->bufsize;
	}
    }
  OzExecExitMonitor(rbuf->lockp);
  return(i+1);
}

/* calculate total size of argument(s) in bytes from format strings */
int
sizeofArgs(char *fmt)
{
  int sizeAccum;

  for(sizeAccum=0; *fmt!='\0'; fmt++)
    {
      if(IsEightByteArg(*fmt))
	sizeAccum+=8;
      else
	sizeAccum+=4;
    }

  return(sizeAccum);
}


/* needAbort checks abort flags and return TRUE if this channel is aborted */
/* but Abort packet is not sent (abort==1 && aborted==0). */
int
needAbort(RemoteSendChannel rchann)
{
  int i;
  OzExecEnterMonitor(&(rchann->lock));
  i = (rchann->abort && !rchann->aborted);
  OzExecExitMonitor(&(rchann->lock));
  return(i);
}


/* send channel operations */
static void
send_cvid_remote(OzSendChannel chan, OID cvid)
{
  RemoteSendChannel rchann;

  rchann = send_to_remote_channel(chan);
  rchann->cvid = cvid;
  return;
}

static void 
send_slot_remote(OzSendChannel chan, int slot1,int slot2)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);

  NoPrintf("SendSlot(%x)\n",rchann);
#ifdef INTERSITE
  rchann->send_buff.packetType = COMM_CALL_IND | rchann->foreign_thread_flag;
#else 
  rchann->send_buff.packetType = COMM_CALL_IND; 
#endif

  newSndCommBuff(&(rchann->send_buff));
  putCommBuffEight(&(rchann->send_buff),rchann->caller);
  putCommBuffEight(&(rchann->send_buff),rchann->send_channel.callee);
  putCommBuffEight(&(rchann->send_buff),rchann->cvid);
  putCommBuffTwo(&(rchann->send_buff),slot1);
  putCommBuffTwo(&(rchann->send_buff),slot2);
  putCommBuffEight(&(rchann->send_buff),((OzRecvChannel)ThrRunningThread->channel)->pid);
  /* add debug message flags */
  putCommBuffFour(&(rchann->send_buff),OzDebugFlags);
#ifdef INTERSITE
  rchann->send_buff.packetType = COMM_CALL_ARG | rchann->foreign_thread_flag;
#else
  rchann->send_buff.packetType = COMM_CALL_ARG;
#endif

  if(needAbort(rchann))
    { /* abort before creating remote receiver channel */
      ThrAbortThread(ThrRunningThread);
    }
  else
    {
      send_and_allocSndCommBuff(&(rchann->send_buff));
      OzExecEnterMonitor(&(rchann->lock));
      rchann->status = CALLING;
      OzExecExitMonitor(&(rchann->lock));
    }

  return;
}


static void 
send_args_remote(OzSendChannel chan, char *fmt, va_list args)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);

  NoPrintf("SendArgs(%x)\n",rchann);
  /* put format into buffer */
  if(putCommBuff(&(rchann->send_buff),(unsigned char *)fmt,strlen(fmt)+1)<0)
    return;

  /* first character of fmt indicates result's format */
  rchann->result_format = *fmt;
  fmt++;

  for(;*fmt!='\0';fmt++)
    {
      if(IsFourByteArg(*fmt))
	{
	  if(putCommBuffFour(&(rchann->send_buff), va_arg(args,int))<0)
	    break;
	}
      else if(IsEightByteArg(*fmt))
	{
	  if(putCommBuffEight(&(rchann->send_buff), va_arg(args, long long))<0)
	    break;
	}
      else /* pointer argument */
	{
	  if(encode_comm(putCommBuff, &(rchann->send_buff),va_arg(args,OZ_Header))<0)
	    break;
	}
    }
  if(needAbort(rchann))
    sendAbort(rchann);
}

static void send_exception_list_remote
  (OzSendChannel chan, Oz_ExceptionCatchTable exception_list)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);
  int size;
  size = sizeof(Oz_ExceptionCatchTableRec)
    +sizeof(OZ_ExceptionIDRec)
      *((exception_list->number_of_entries>1)? 
	exception_list->number_of_entries -1 : 0);
  putCommBuff(&(rchann->send_buff),(unsigned char *)exception_list,size);
#if 1 /* debug by Y.H */
  if(needAbort(rchann))
    {
      sendAbort(rchann);
      ThrAbortThread(ThrRunningThread);
    }
  else
    {
      sendSndCommBuff(&(rchann->send_buff));
      OzExecEnterMonitor(&(rchann->lock));
      rchann->status = WAITING;
      OzExecExitMonitor(&(rchann->lock));
    }
#else
  sendSndCommBuff(&(rchann->send_buff));
  if(needAbort(rchann))
    sendAbort(rchann);
  else
    {
      OzExecEnterMonitor(&(rchann->lock));
      rchann->status = WAITING;
      OzExecExitMonitor(&(rchann->lock));
    }
#endif
}



static int 
recv_return_remote(OzSendChannel chan)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);
  int kind ;
  int ival;
  int abortflag=0;
  int flag ;
#ifdef INTERSITE
  int foreign_flag;
#endif

  NoPrintf("RecvRemoteReturn\n");
  if(needAbort(rchann))
    {
      sendAbort(rchann);
      abortflag=1;
    }

  flag = 1 ;
  OzExecEnterMonitor(&(rchann->lock));
  while(rchann->status != FINISHED)
      OzExecWaitCondition(&(rchann->lock),&(rchann->recv_buff.buffAvail));
  kind = *((int *)rchann->recv_buff.list->buf) ;

#ifdef INTERSITE
  foreign_flag = kind & COMM_UNTRUST_FLAG;
  kind &= COMM_FLAGS_MASK;
#endif

  /* clear next of previous receive channel */
  OzExecEnterMonitor(&(rchann->send_channel.prev->vars.lock));
  rchann->send_channel.prev->vars.next = (OzSendChannel)0;
  OzExecExitMonitor(&(rchann->send_channel.prev->vars.lock));

  if( (rchann->abort || rchann->abort) && (kind != COMM_EXCEPTION) )
    { /* if receive RESULT or ERROR packet while aborted, change it to ABORT exception */
      rchann->ret_type=EXCEPTION;
      rchann->exception.cid=0LL;
      rchann->exception.val=1;
      rchann->rval=0;
      abortflag=1;
    }
  else
    switch( kind )
      {
      case COMM_ERROR:
	rchann->ret_type=ERROR;
	rchann->rval =  *((int *)rchann->recv_buff.list->bp);
	
#if 1 /* debug */
	if(rchann->recv_buff.list)
	  FreeCommBuff(rchann->recv_buff.list);
	rchann->recv_buff.list = (commBuff)0;
#else
	FreeCommBuff(rchann->recv_buff.list);
#endif
	if(rchann->rval == ERROR_OBJECT_NOT_FOUND)
	  {
	    rchann->ret_type=EXCEPTION;
	    rchann->exception.cid=0LL;
	    rchann->exception.val=3;
	    rchann->rval=0;
#ifdef EXCEPTDEBUG
	    OzDebugf("Object_NOT_FOUND error occured on remote method invocation,raise OzExceptionObjectNotFound exception\n");
#endif
	  }
	break;
      case COMM_RESULT:
	rchann->ret_type=NORMAL;
	NoPrintf("result format is (%c)\n",rchann->result_format);
	if(IsEightByteArg(rchann->result_format))
	  rchann->rval = *((long long *)rchann->recv_buff.list->bp);
	else if(IsFourByteArg(rchann->result_format))
	  rchann->rval = *((int*)(rchann->recv_buff.list->bp));
	else /* complex result */
	  {
	    flag = 0 ;
	    OzExecExitMonitor(&(rchann->lock));
	    decode_comm(&(rchann->recv_buff),
			rchann->result_format,&ival,
			OtGetHeap()
#ifdef INTERSITE
			,foreign_flag
#endif
			);
	    rchann->send_channel.vars.rval = rchann->rval = ival;
	  }
	
	NoPrintf("result is %08x%08x\n",rchann->rval);
	if(rchann->recv_buff.list)
	  FreeCommBuff(rchann->recv_buff.list);
	rchann->recv_buff.list = (commBuff)0;
	break;
	
      case COMM_EXCEPTION:
#ifdef EXCEPTDEBUG
	OzDebugf("exception packet is received\n");
	OzDebugf("rbuf size is %d\n",rchann->recv_buff.list->bufsize);
#endif
	rchann->rval=0LL;
	rchann->ret_type=EXCEPTION;
	flag = 0 ;
	OzExecExitMonitor(&(rchann->lock));
	getCommBuff(&(rchann->recv_buff),sizeof(OZ_ExceptionIDRec)
		    ,(unsigned char *)(&(rchann->exception)));
#ifdef EXCEPTDEBUG
	OzDebugf("exception ID is %08x%08x : %08x \n", 
		 (int)(rchann->exception.cid >>32),
		 (int)(rchann->exception.cid & 0xffffffffLL),
		 rchann->exception.val);
#endif
	getCommBuff(&(rchann->recv_buff),sizeof(char)
		    ,(unsigned char *)(&(rchann->exception_fmt)));
	rchann->exception_param = 0LL;
#ifdef EXCEPTIONDEBUG
	OzDebugf("recv_return_remote: received format is (%c)\n",
		 rchann->exception_fmt);
#endif
	if(IsEightByteArg(rchann->exception_fmt))
	  getCommBuff(&(rchann->recv_buff),sizeof(long long)
		      ,(unsigned char *)(&(rchann->exception_param)));
	else if(IsFourByteArg(rchann->exception_fmt))
	  getCommBuff(&(rchann->recv_buff),sizeof(long)
		      ,(unsigned char *)(&(rchann->exception_param)));
	else /* complex result */
	  {
	    
	    decode_comm(&(rchann->recv_buff),
			rchann->exception_fmt,&ival,
			OtGetHeap()
#ifdef INTERSITE
			,foreign_flag
#endif
			);
	    rchann->send_channel.vars.eparam = rchann->exception_param = ival;
	  }

#ifdef EXCEPTIONDEBUG
	OzEPrintf("exception parameter is %08x%08x\n",rchann->exception_param);
#endif
	if(rchann->recv_buff.list !=0)
	  FreeCommBuff(rchann->recv_buff.list);
	rchann->recv_buff.list = (commBuff)0;

	if(rchann->abort && (rchann->exception.cid!=0LL || rchann->exception.val!=1))
	  { /* if aborted and aborted exception is not returned, change it to abort exception */
	    rchann->exception.cid=0LL;
	    rchann->exception.val=1;
	  }
	break;
      }
  /*
   * Following one line too OzExecExitMonitor(&rchann->lock) sometime.
   */
  if ( flag ) OzExecExitMonitor(&(rchann->lock));
  
  /* remove entry from RemoteSendChannel hashtable */
  OzExecEnterMonitor(&RemSndChannLock);
  RemoveCommHash(RemSndHash,rchann->send_channel.peer.msgID);
  OzExecExitMonitor(&RemSndChannLock);
#ifdef EXCEPTIONDEBUG
  OzDebugf("recv_return_remote exit\n");
#endif
  if(abortflag)
    ThrAbortThread(ThrRunningThread);
 
  return(rchann->ret_type);
}


static long long 
recv_value_remote(OzSendChannel chan)
{

  RemoteSendChannel rchann = send_to_remote_channel(chan);
  NoPrintf("RecvValueRemote\n");
  return(rchann->rval);
}

static OZ_ExceptionIDRec
recv_exception_remote(OzSendChannel chan)
 {
   RemoteSendChannel rchann;
#ifdef EXCEPTDEBUG
   OzDebugf("recv_exception_remote called\n");
#endif
   
   rchann = send_to_remote_channel(chan);
   return(rchann->exception);
 }

static char
recv_exception_fmt_remote(OzSendChannel chan)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);
#ifdef EXCEPTDEBUG
   OzDebugf("recv_exception_fmt_remote called\n");
#endif

  return(rchann->exception_fmt);
}


static long long
recv_exception_param_remote(OzSendChannel chan)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);
#ifdef EXCEPTDEBUG
   OzDebugf("recv_exception_param_remote called\n");
#endif

  return(rchann->exception_param);
}

static void 
send_abort_remote(OzSendChannel chan)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);
  OzExecEnterMonitor(&(rchann->lock));
  rchann->abort = 1;
  OzExecExitMonitor(&(rchann->lock));
  if(rchann->status == WAITING)
    sendAbort(rchann);
  return;
}

static void 
send_free_remote(OzSendChannel chan)
{
  RemoteSendChannel rchann = send_to_remote_channel(chan);
  RemoteSendChannel tmp;

  if(rchann->send_buff.list != (commBuff)0)
    FreeCommBuff(rchann->send_buff.list);
  if(rchann->recv_buff.list != (commBuff)0)
    FreeCommBuff(rchann->recv_buff.list);

  OzExecEnterMonitor(&RemSndChannLock);
  if(rchann->next !=(RemoteSendChannel)0)
    rchann->next->prev=rchann->prev;
  if(rchann->prev != (RemoteSendChannel)0)
    rchann->prev->next=rchann->next;
  else
    RemSndChannelRoot=rchann->next;

  releaseMessageId(rchann->send_channel.peer.msgID);

  if(RemSndReserveCount >= SND_CHANN_RESERVE_MAX)
    OzFree(rchann);
  else
    {
      tmp=RemSndReserve;
      RemSndReserve=rchann;
      rchann->next=tmp;
      RemSndReserveCount++;
    }
  OzExecExitMonitor(&RemSndChannLock);

  return;
}

static  OzSendChannelOpsRec     
send_ops_remote = {
  send_cvid_remote,
  send_slot_remote,
  send_args_remote,
  send_exception_list_remote,
  recv_return_remote,
  recv_value_remote,
  recv_exception_remote,
  recv_exception_fmt_remote,
  recv_exception_param_remote,
  send_abort_remote,
  send_free_remote
  };


static OID
recv_cvid_remote(OzRecvChannel chan)
{
  RemoteRecvChannel rchann;

  rchann = recv_to_remote_channel(chan);
  OzExecEnterMonitor(&(rchann->lock));
  if(rchann->status == ABORTED)
    {
      OzExecExitMonitor(&(rchann->lock));
      return(0LL);
    }
  OzExecExitMonitor(&(rchann->lock));

  return(rchann->receive_channel.vars.cvid);
}

static int 
recv_slot_remote(OzRecvChannel chan)
{
  RemoteRecvChannel rchann;

  rchann = recv_to_remote_channel(chan);
  OzExecEnterMonitor(&(rchann->lock));
  if(rchann->status == ABORTED)
    {
      OzExecExitMonitor(&(rchann->lock));
      return(-1);
    }
  OzExecExitMonitor(&(rchann->lock));

  if(rchann->slot_select++)
    return(rchann->receive_channel.vars.slot2);
  else
    return(rchann->receive_channel.vars.slot1);
}

static char 
*recv_format_remote(OzRecvChannel chan)
{
  RemoteRecvChannel rchann;
  int size;

  rchann = recv_to_remote_channel(chan);

  size=lengthofString(&(rchann->recv_buff));
  rchann->receive_channel.vars.fmt=(char *)OzMalloc(size);
  getCommBuff(&(rchann->recv_buff),size,
	      (unsigned char *)rchann->receive_channel.vars.fmt);
  rchann->result_format = *(rchann->receive_channel.vars.fmt);
  return(rchann->receive_channel.vars.fmt);
}


static void 
*recv_args_remote(OzRecvChannel chan)
{
	/*
	 *	argument ObjectTableEntry entry is removed.
	 *	Channel recv_args() op have only one argument.
	 */
  RemoteRecvChannel rchann = recv_to_remote_channel(chan);
  int size;
  void **arg;
  char *fmt,f;

  fmt = (char *)rchann->receive_channel.vars.fmt;
  fmt++;
  /* reserve eight-byte of space for va_args usage */
  size=sizeofArgs(fmt);
  rchann->receive_channel.vars.args=(void *)OzMalloc(size+12);
  arg=(void **)(rchann->receive_channel.vars.args);
#if 0
OzDebugf("args : %x \n",arg);
#endif
  /* move pointer eight-byte forward */
  *((int *)arg) = size ;
  arg++;
  arg++;
  arg++;


  for(;(*fmt)!='\0';fmt++)
    {
      f= *fmt;
      decode_comm(&(rchann->recv_buff),f,arg,
		  rchann->receive_channel.o->heap
#ifdef INTERSITE
		  ,rchann->foreign_flag
#endif
		  );
      arg++;
      if(IsEightByteArg(*fmt))
	arg++;
    }

  return(rchann->receive_channel.vars.args);
}

static Oz_ExceptionCatchTable 
recv_exception_list_remote(OzRecvChannel chan)
{
  RemoteRecvChannel rchann;
  int i,size;

  rchann = recv_to_remote_channel(chan);
  /* exception list */
#if 0  
  size=lengthofExceptionList(&(rchann->recv_buff));
#else
  readCommBuff(&(rchann->recv_buff),0,4,(unsigned char *)(&size));
#endif

  i=sizeof(Oz_ExceptionCatchTableRec);
  i+=(size>=1)? sizeof(OZ_ExceptionIDRec)*(size-1) : 0;
  rchann->receive_channel.vars.elist=(Oz_ExceptionCatchTable)OzMalloc(i);
  getCommBuff(&(rchann->recv_buff),i,
	      (unsigned char *)rchann->receive_channel.vars.elist);
#if 0
  NoPrintf("end of Recv_exception_list_remote\n");
#endif
  OzExecEnterMonitor(&(rchann->receive_channel.vars.lock));
  rchann->receive_channel.vars.readyToInvoke = 1;
  OzExecExitMonitor(&(rchann->receive_channel.vars.lock));
  return(rchann->receive_channel.vars.elist);
}

static void 
send_return_remote(OzRecvChannel chan, int ret_type)
{
  RemoteRecvChannel rchann;

  rchann = recv_to_remote_channel(chan);
  rchann->ret_type=ret_type;
}


static void 
send_value_remote(OzRecvChannel chan, long long rval)
{
  int i;
  RemoteRecvChannel rrc;

  rrc = recv_to_remote_channel(chan);

#ifdef INTERSITE
  rrc->send_buff.packetType=COMM_RESULT_T;
#else
  rrc->send_buff.packetType=COMM_RESULT;
#endif

  rrc->send_buff.list=newSndCommBuff(&(rrc->send_buff));
  if(IsFourByteArg(rrc->result_format))
    {
      i=rval;
      putCommBuff(&(rrc->send_buff),(unsigned char *)&i,4);
#if 0
NoPrintf("four byte result\n");
#endif
    }
  else if(IsEightByteArg(rrc->result_format))
    putCommBuff(&(rrc->send_buff),(unsigned char *)&rval,8);
  else
    { i=rval;
      encode_comm(putCommBuff,&(rrc->send_buff),(OZ_Header)i);
#if 0
NoPrintf("object result\n");
#endif
    }
  sendSndCommBuff(&(rrc->send_buff));
}

static void 
send_exception_remote(OzRecvChannel chan, OZ_ExceptionIDRec exception,
		      long long param, char fmt)
{
  RemoteRecvChannel rrc;

#ifdef EXCEPTDEBUG
   OzDebugf("send_exception_remote called\n");
#endif

  rrc = recv_to_remote_channel(chan);

#ifdef INTERSITE
  rrc->send_buff.packetType=COMM_EXCEPTION_T;
#else
  rrc->send_buff.packetType=COMM_EXCEPTION;
#endif 

  newSndCommBuff(&(rrc->send_buff));
  putCommBuff(&(rrc->send_buff),(unsigned char *)&exception,
	      sizeof(OZ_ExceptionIDRec));
/* next two line of program is temporal */
  if(fmt=='\0')
    fmt = 'v';
  putCommBuff(&(rrc->send_buff),(unsigned char *)&fmt,1);
  if(IsEightByteArg(fmt))
    putCommBuff(&(rrc->send_buff),(unsigned char *)(&param),
		sizeof(long long));
  else if(IsFourByteArg(fmt))
    putCommBuff(&(rrc->send_buff),(unsigned char *)(&param),
		sizeof(long));
  else /* complex type */
    encode_comm(putCommBuff, &(rrc->send_buff),(OZ_Header)((int)(param)));
  sendSndCommBuff(&(rrc->send_buff));
}

static void recv_free_remote(OzRecvChannel chan)
{
  RemoteRecvChannel rchann = recv_to_remote_channel(chan);
  RemoteRecvChannel tmp;

  if (chan->o) OtReleaseEntry( chan->o ) ;
			/*
			 * OtGetEntry() at receiver_daemon()
			 */

  /* free allocated work area attached to remote channel */
  if(rchann->send_buff.list != (commBuff)0)
    FreeCommBuff(rchann->send_buff.list);
  if(rchann->recv_buff.list != (commBuff)0)
    FreeCommBuff(rchann->recv_buff.list);
  if(rchann->receive_channel.vars.fmt)
    OzFree(rchann->receive_channel.vars.fmt) ;
  if(rchann->receive_channel.vars.args)
    OzFree(rchann->receive_channel.vars.args) ;
/*
  if(rchann->receive_channel.vars.elist)
    OzFree(rchann->receive_channel.vars.elist) ;
*/
		/* commented because 'ExInitializeExceptionHandlerWith'
		 * frees it. */

  OzExecEnterMonitor(&RemRcvChannLock);
  /* remote from remote recv channel list */
  if(rchann->next !=(RemoteRecvChannel)0)
    rchann->next->prev=rchann->prev;

  if(rchann->prev != (RemoteRecvChannel)0)
    rchann->prev->next=rchann->next;
  else
    RemRcvChannelRoot=rchann->next;

  /* remove entry from remote recv channel hash */
  RemoveCommHash(RemRcvHash,rchann->receive_channel.vars.peer.msgID);

  /* Free memory if enough reserve exist , otherwise reserve it */
  if(RemRcvReserveCount >= RCV_CHANN_RESERVE_MAX)
    OzFree(rchann);
  else
    {
      tmp=RemRcvReserve;
      RemRcvReserve=rchann;
      rchann->next=tmp;
      RemRcvReserveCount++;
    }

  OzExecExitMonitor(&RemRcvChannLock);

  return;
}


static  OzRecvChannelOpsRec     
recv_ops_remote = {
  recv_cvid_remote,
  recv_slot_remote,
  recv_format_remote,
  recv_args_remote,
  recv_exception_list_remote,
  send_return_remote,
  send_value_remote,
  send_exception_remote,
  recv_free_remote
  };

/* create remote channel */
OzSendChannel 
OzCreateRemoteSendChannel(OID caller, OID callee)
{
  RemoteSendChannel rchann,rsc;
  ExecTable dest;

  OzExecEnterMonitor(&RemSndChannLock);

  if(RemSndReserveCount != 0)
    {
      rchann = RemSndReserve;
      RemSndReserve = RemSndReserve->next;
      RemSndReserveCount--;
    }
  else
    rchann = (RemoteSendChannel)(OzMalloc(sizeof(RemoteSendChannelRec)));

  /* link double-linked list of remote send channels  */
  rsc = RemSndChannelRoot;
  RemSndChannelRoot = rchann;
  rchann->next = rsc;
  rchann->prev = (RemoteSendChannel)0;
  if ( rsc != (RemoteSendChannel)0 )
    rsc->prev = rchann;

  /* initialize */
  rchann->send_channel.ops = &send_ops_remote;
  rchann->send_channel.callee = callee;
  rchann->send_channel.peer.msgID = getMessageId();
  rchann->send_channel.prev = (OzRecvChannel)ThrRunningThread->channel;

  /* register to hashtable */
  EnterCommHash(RemSndHash, rchann->send_channel.peer.msgID,(void *)rchann);

  OzExecExitMonitor(&RemSndChannLock);

  /* initialize (cont.) */
  OzInitializeMonitor(&(rchann->lock));
  OzExecInitializeCondition(&(rchann->receive_response),1);
  rchann->caller = caller;
  rchann->cvid = 0LL;
  rchann->receive_slot_id = 0;
  rchann->result_format = 'v';
  rchann->ret_type = -1;
  rchann->rval = 0LL;
  rchann->exception.cid = 0LL;
  rchann->exception.val = 0;
  rchann->exception.pad = 0;
  rchann->exception_fmt = 'v';
  rchann->exception_param = 0LL;
  rchann->abort=0;
  rchann->aborted=0;
  rchann->status =0;
#ifdef INTERSITE
  if(ThrRunningThread->foreign_flag & 0x00000001)
    rchann->foreign_thread_flag = COMM_UNTRUST_FLAG;
  else
    rchann->foreign_thread_flag = 0;
  
  OzDebugf("CreateRemoteSendChannel: rchann->packet_flag = %d(thread untrust %d)\n",
	   rchann->foreign_thread_flag,ThrRunningThread->foreign_flag);
#endif

  if((dest = AddressRequest(callee & (long long)0xffffffffff000000LL))
     ==(ExecTable)0)
    { /* address resolution failure : executor not found */
      return((OzSendChannel)0);
    }
  NoPrintf("Result of AddressRequest is %x (location %d)\n",dest,dest->location);
#if 0 /* ONIDEBUG */
OzDebugf("Result of AddressRequest is %x (location %d)\n",dest,dest->location);
#endif
  if(dest->location==ET_LOCAL)
    { rchann->send_buff.destination=UNIX;
      bzero((char *)&(rchann->send_buff.networkAddr),16);
      rchann->send_buff.networkAddr.sin_family=AF_UNIX;
      OzSprintf((char *)(&(rchann->send_buff.networkAddr.sin_port)),
	      "/tmp/Oz%06x",(int)((callee>>24)&0xffffff));
      NoPrintf("NewRSC:destination is ET_LOCAL %s\n",rchann->send_buff.networkAddr.sin_port);
#if 0 /* ONIDEBUG */
OzDebugf("NewRSC:destination is ET_LOCAL %s\n",rchann->send_buff.networkAddr.sin_port);

#endif
    }
  else
    { rchann->send_buff.destination=INET;
      sockaddrcopy(&(dest->addr),&(rchann->send_buff.networkAddr));
      bzero( (char *)(&(rchann->send_buff.networkAddr))+8,8);
      NoPrintf("NewRSC:destination is ET_INSITE or ET_OUTSITE of address below\n");
#if 0 /* ONIDEBUG */
OzDebugf("NewRSC:destination is ET_INSITE or ET_OUTSITE of address below\n");
#endif
      DumpAddress(&(rchann->send_buff.networkAddr));
    }

  rchann->send_buff.list = (commBuff)0;
  rchann->send_buff.lockp = &(rchann->lock);
  rchann->send_buff.channeltype=SCHANN;
  rchann->send_buff.chan = rchann;
  rchann->send_buff.messageId = &(rchann->send_channel.peer.msgID);

  OzExecInitializeCondition(&(rchann->recv_buff.buffAvail),0);
  rchann->recv_buff.lockp = &(rchann->lock);
  rchann->recv_buff.list=(commBuff)0;
  if(ThrClearThread(ThrRunningThread)){
    rchann->aborted = 1;
  }

  /* set channel link pointers */

  OzExecEnterMonitor(&(rchann->send_channel.prev->vars.lock));
  rchann->send_channel.prev->vars.next = (OzSendChannel)rchann;
  OzExecExitMonitor(&(rchann->send_channel.prev->vars.lock));
  return(&(rchann->send_channel));
}


/* callee thread program */
void 
callee_thread(RemoteRecvChannel chan)
{

  GiGlobalInvokeStub(remote_to_recv_channel(chan));
  return;
}


RemoteRecvChannel
OzCreateRemoteRecvChannel(OID caller, OID callee, long long messageId, 
			  OID cvid,short slot1, short slot2,PID pid,
			  commBuff buff,ObjectTableEntry entry,
			  unsigned int dmflags
#ifdef INTERSITE
			  ,int foreign_flag
#endif
			  )
{
  RemoteRecvChannel rchann,rsc;
  ExecTable dest;

  OzExecEnterMonitor(&RemRcvChannLock);
  if(RemRcvReserveCount != 0)
    {
      rchann = RemRcvReserve;
      RemRcvReserve = RemRcvReserve->next;
      RemRcvReserveCount--;
    }
  else
    rchann = (RemoteRecvChannel)(OzMalloc(sizeof(RemoteRecvChannelRec)));

  /* initialize recv_buff and related members to prepare receiving packet */
  OzInitializeMonitor(&(rchann->lock));
  OzExecInitializeCondition(&(rchann->recv_buff.buffAvail),0);
  rchann->recv_buff.list = buff;
  rchann->recv_buff.lockp = &(rchann->lock);

  /* register to hashtable */
  EnterCommHash(RemRcvHash, messageId,(void *)rchann);

  rchann->receive_channel.ops = &recv_ops_remote;
  rchann->receive_channel.caller = caller;
  rchann->receive_channel.callee = callee;
  rchann->receive_channel.pid = pid;
  rchann->receive_channel.o=entry;

  OzInitializeMonitor(&(rchann->receive_channel.vars.lock));
  rchann->receive_channel.vars.peer.msgID = messageId;
  rchann->receive_channel.vars.next = 0 ;
  rchann->receive_channel.vars.readyToInvoke = 0;
  rchann->receive_channel.vars.cvid = cvid;
  rchann->receive_channel.vars.slot1 = slot1;
  rchann->receive_channel.vars.slot2 = slot2;
  rchann->receive_channel.vars.args = 0;
  rchann->receive_channel.vars.fmt = 0;
  rchann->receive_channel.vars.elist = 0;

  rchann->slot_select = 0 ;
  rchann->receive_slot_id = 0;
  rchann->result_format = 'v';
  rchann->ret_type = -1;
#ifdef INTERSITE
  rchann->foreign_flag = foreign_flag;
#endif
  /* debug message flags */
  rchann->dmflags = dmflags;

  if((dest = AddressRequest(caller & (long long)0xffffffffff000000LL))
     ==(ExecTable)0)
    { /* address resolution failure : executor not found */
      OzDebugf("CreateRemoteRecvChannel: Fail to create: address resolution failure %08x%08x\n",caller);
      OzExecExitMonitor(&RemRcvChannLock);
      return((RemoteRecvChannel)0);
    }

  if(dest->location==ET_LOCAL)
    { rchann->send_buff.destination=UNIX;
      bzero((char *)&(rchann->send_buff.networkAddr),16);
      rchann->send_buff.networkAddr.sin_family=AF_UNIX;
      OzSprintf((char *)(&(rchann->send_buff.networkAddr.sin_port)),
	      "/tmp/Oz%06x",(int)((caller>>24)&0xffffff));
    }
  else
    { rchann->send_buff.destination=INET;
      sockaddrcopy(&(dest->addr),&(rchann->send_buff.networkAddr));
    }

  rchann->send_buff.channeltype=RCHANN;
  rchann->send_buff.chan = rchann;
  rchann->send_buff.messageId = &(rchann->receive_channel.vars.peer.msgID);
/*   rchann->send_buff.abort = &(rchann->aborted); */
  rchann->send_buff.lockp = &(rchann->lock);
  rchann->send_buff.packetType = 0;
  rchann->send_buff.list = (commBuff)0;

  /* link double-linked list of remote recv channels  */
  rsc = RemRcvChannelRoot;
  RemRcvChannelRoot = rchann;
  rchann->next = rsc;
  rchann->prev = (RemoteRecvChannel)0;
  if ( rsc != (RemoteRecvChannel)0 )
    rsc->prev = rchann;
  OzExecExitMonitor(&RemRcvChannLock);
#if 1 /* debugmessage flag is implemented on remote channel */
  rchann->receive_channel.t
    =ThrCreate((void *)callee_thread, rchann,
		    CALLEE_STACKSIZE, CALLEE_PRIORITY,
		    /* dflags */rchann->dmflags, 1, rchann);
#else
  rchann->receive_channel.t
    =ThrCreate((void *)callee_thread, rchann,
		    CALLEE_STACKSIZE, CALLEE_PRIORITY,
		    /* dflags */0, 1, rchann);
#endif

#ifdef INTERSITE
  rchann->receive_channel.t->foreign_flag = rchann->foreign_flag;
#endif

  ThrSchedule(rchann->receive_channel.t);

  return(rchann);
}

/* this routine report Error which occures before start of method execution */
static void
sendError(commBuff cb,OID caller,int reason)
{
  ExecTable dest;

  cb->bp=cb->buf;
#ifdef INTERSITE
  (int)(*cb->bp)=COMM_ERROR_T;
#else
  (int)(*cb->bp)=COMM_ERROR;
#endif

  cb->bp+=4;
  (int)(*cb->bp)=MyArchitectureType;
  cb->bp+=12; /* skip message-Id, because no need to change */
  (int)(*cb->bp)=reason;
  cb->bufsize=20;
  cb->channel=0;
  cb->channeltype=RCHAN;

  if((dest = AddressRequest(caller & (long long)0xffffffffff000000LL))
     ==(ExecTable)0)
    { /* address resolution failure : executor not found */
      return;
    }

  if(dest->location==ET_LOCAL)
    {
      bzero((char *)&(cb->networkAddr),16);
      cb->networkAddr.sin_family=AF_UNIX;
      OzSprintf((char *)(&(cb->networkAddr.sin_port)),
	      "/tmp/Oz%06x",(int)((caller>>24)&0xffffff));
      sendCommBuffUnix(cb);
    }
  else
    {
      sockaddrcopy(&(dest->addr),&(cb->networkAddr));
      sendCommBuffInet(cb);
    }
  return;
}


/* daemon programs */
/* receiver_daemon take a communication buffer from RecvList,
* and deliver it to remote channels.
* When that buffer is CALL_IND (indication of gloval invoke),
* remote receive channel is created by this program.
*/
void
receiver_daemon()
{
  commBuff cb,buff;
  OID caller,callee;
  short slot1,slot2;
  ObjectTableEntry entry;
  long long messageId;
  int kind, arch;
  RemoteSendChannel rs;
  RemoteRecvChannel rr;
  PID pid;
  OID cvid;
  unsigned int dmflags; /* debug message flags */
#ifdef INTERSITE
  int foreign_flag;
#endif

  for(;;)
    {
      OzExecEnterMonitor(&RecvListLock);
      while(RecvList==(commBuff)0)
	OzExecWaitCondition(&RecvListLock,&RecvListAvail);
      buff=RecvList;
      RecvList=RecvList->next;
      OzExecExitMonitor(&RecvListLock);

     NoPrintf("receiverDaemon: %x\n",buff);
      kind = *((int*)buff->bp); buff->bp+=sizeof(int);
      arch = *((int*)buff->bp); buff->bp+=sizeof(int);
      messageId = *((long long*)buff->bp); buff->bp+=sizeof(long long);
      buff->bufsize-=(sizeof(int)*2+sizeof(long long));
      buff->next=(commBuff)0;
      NoPrintf("receiverDaemon: %x\n",kind);
OzDebugf("receiverDaemon:kind of packet %x\n",kind);
#ifdef INTERSITE
      if(kind & COMM_UNTRUST_FLAG)
	foreign_flag=1;
      else
	foreign_flag=0;

      kind &= COMM_FLAGS_MASK;
#endif

      switch(kind)
	{
	case COMM_CALL_IND:
	  caller=getEightByte(buff);
	  callee=getEightByte(buff);
	  cvid=getEightByte(buff);
	  slot1=getTwoByte(buff);
	  slot2=getTwoByte(buff);
	  pid=getEightByte(buff);
	  dmflags=getFourByte(buff);

	  if((entry=OtGetEntry(callee))==(ObjectTableEntry)0)
	    {  /* object not fount */
	      sendError(buff,caller,ERROR_OBJECT_NOT_FOUND);
	      break; /* can't progress any more ? */
	    }
	  /*
	   * calling OtReleaseEntry(callee) on recv_free_remote()
	   */

	  if((rr=OzCreateRemoteRecvChannel
	      (caller,callee,messageId,cvid,slot1,slot2,pid
	       ,buff
	       ,entry, dmflags
#ifdef INTERSITE
	       ,foreign_flag
#endif
	       ))
	     ==(RemoteRecvChannel)0)
	    {  /* can't create remote receive channel */
/*	      sendError(buff,caller,ERROR_CANT_CREATE_CHANNEL); */
	      FreeCommBuff(buff);
	    }
	  break;
	case COMM_CALL_ARG:
	  OzExecEnterMonitor(&RemRcvChannLock);
	  if((rr=SearchCommHash(RemRcvHash,messageId))
	     !=(RemoteRecvChannel)0)
	    {

	      OzExecEnterMonitor(&(rr->lock));
	      
	      if(rr->recv_buff.list==(commBuff)0)
		rr->recv_buff.list=buff;
	      else
		{
		  for(cb=rr->recv_buff.list ; cb->next!=(commBuff)0 ; cb=cb->next)
		    ;
		  cb->next=buff;
		}
	      OzExecSignalCondition(&(rr->recv_buff.buffAvail));
	      OzExecExitMonitor(&(rr->lock));
	    }
	  else
	    { /* if remote channel is not found, ignore this packet */
	      FreeCommBuff(buff);
	    }
	  OzExecExitMonitor(&RemRcvChannLock);
	  break;
	case COMM_ABORT:
	  OzExecEnterMonitor(&RemRcvChannLock);
	  if((rr=SearchCommHash(RemRcvHash,messageId))
	     !=(RemoteRecvChannel)0)
	    {
	      OzExecEnterMonitor(&rr->lock);
	      if(rr->receive_channel.vars.next)
		rr->receive_channel.vars.next
		  ->ops->send_abort(rr->receive_channel.vars.next);
	      else
		ThrAbortThread(rr->receive_channel.t);
	      OzExecExitMonitor(&rr->lock);
	      FreeCommBuff(buff);
	    }
	  else
	    { /* if remote channel is not found, ignore this packet */
	      FreeCommBuff(buff);
	    }
	  OzExecExitMonitor(&RemRcvChannLock);
	  break;	  
	case COMM_RESULT:
	case COMM_EXCEPTION:
	case COMM_ERROR:
	  OzExecEnterMonitor(&RemSndChannLock);
NoPrintf("ReceiverDaemon:response packet \n");
	 
	  if((rs=(RemoteSendChannel)SearchCommHash(RemSndHash,messageId))
	     !=(void *)0)
	    {
NoPrintf("RecverDaemon:RSC %x\n",rs);
	      OzExecEnterMonitor(&rs->lock);
NoPrintf("buff.list %x\n",rs->recv_buff.list);
	      buff->next=(commBuff)0;
	      if(rs->recv_buff.list==(commBuff)0)
		rs->recv_buff.list=buff;
	      else
		{
		  for(cb=rs->recv_buff.list;cb->next!=(commBuff)0;cb=cb->next)
		    ;
		  cb->next=buff;
		}
NoPrintf("add to list\n");

	      rs->status = FINISHED ;
	      OzExecSignalCondition(&(rs->recv_buff.buffAvail));
	      OzExecExitMonitor(&(rs->lock));
	    }	  
	  else
	    { /* if remote channel is not found, ignore this packet */
NoPrintf("RecvDaemon:Receive a response packet but no channel exist(messageID %08x%08x ) \n",messageId);
	      FreeCommBuff(buff);
	    }
NoPrintf("RecvDaemon:End of response packet treatment\n");
	  OzExecExitMonitor(&RemSndChannLock);
	  break;
      }
    }
}


void
InitComm()
{
  OZ_Thread t;

  RemSndHash = CreateCommHash();
  RemRcvHash = CreateCommHash();
  RemSndChannelRoot = (RemoteSendChannel)0;
  RemRcvChannelRoot = (RemoteRecvChannel)0;
  OzInitializeMonitor(&RemSndChannLock);
  OzInitializeMonitor(&RemRcvChannLock);
  RemSndReserveCount = RemRcvReserveCount=0;

  SendListUnix = SendListInet = RecvList = (commBuff)0;
  OzInitializeMonitor(&SendListUnixLock);
  OzInitializeMonitor(&SendListInetLock);
  OzInitializeMonitor(&RecvListLock);
  OzExecInitializeCondition(&SendListUnixAvail,0);
  OzExecInitializeCondition(&SendListInetAvail,0);
  OzExecInitializeCondition(&RecvListAvail,0);

  t= ThrFork(receiver_daemon,DAEMON_STACK_SIZE,COMM_DAEMON_PRIORITY,0);
  initMessageId();
  return;
}


/* routines for Debugger */
 /* find remote_receive_channel by message-Id */
OzRecvChannel 
OzSearchRemoteRecvChannel(long long messageID)
{
#if	1
  OzRecvChannel rchan ;
  OzExecEnterMonitor(&RemRcvChannLock);
  rchan = (OzRecvChannel)SearchCommHash(RemRcvHash,messageID);
  OzExecExitMonitor(&RemRcvChannLock);
  return( rchan ) ;
#else
  return((OzRecvChannel)SearchCommHash(RemRcvHash,messageID));
#endif
}

 /* connect Debug Manager of executor where the object exists   */
 /* OzConnectDebugManager returns file descripter if successed, */
 /* otherwize returns -1.                                       */
int
OzConnectDebugManager(OID aId)
{
  struct sockaddr_in addr;
  ExecTable dest;
  int fd;
  int optval;

  /* by yoshi */
  if ( (aId & 0xffffffffff000000LL) == OzExecutorID )
    { bzero((char *)&(addr),16);
      addr.sin_family=AF_UNIX;
      OzSprintf((char *)(&(addr.sin_port)),
	      "/tmp/Dm%06x",(int)((aId>>24)&0xffffff));
      fd = OzSocket(PF_UNIX,SOCK_STREAM,0);
      if(OzConnect(fd,(struct sockaddr *)(&addr),sizeof(struct sockaddr_in))<0)
	return(-2);
      else
	return(fd);
    }

  if((dest = AddressRequest(aId & (long long)0xffffffffff000000LL))
     ==(ExecTable)0)
    { /* address resolution failure : executor not found */
      return(-1);
    }

  if(dest->location==ET_LOCAL)
    { bzero((char *)&(addr),16);
      addr.sin_family=AF_UNIX;
      OzSprintf((char *)(&(addr.sin_port)),
	      "/tmp/Dm%06x",(int)((aId>>24)&0xffffff));
      fd = OzSocket(PF_UNIX,SOCK_STREAM,0);
      if(OzConnect(fd,(struct sockaddr *)(&addr),sizeof(struct sockaddr_in))<0)
	return(-2);
      else
	return(fd);
    }
  else
    { sockaddrcopy(&(dest->addr),&(addr));
      addr.sin_port++;
      fd = OzSocket(PF_INET,SOCK_STREAM,0);
      optval=1;
      OzSetsockopt(fd,6,TCP_NODELAY,(const char *)&optval,4);
      if(OzConnect(fd,(struct sockaddr *)(&addr),sizeof(struct sockaddr_in))<0)
	return(-2);
      else
	return(fd);
    }

}

int
OzDebugManagerAddress(OID exid, struct sockaddr_in *networkAddr)
{
  ExecTable dest;

  if((dest = AddressRequest(exid & (long long)0xffffffffff000000LL))
     ==(ExecTable)0)
    { /* address resolution failure : executor not found */
      return(-1);
    }

  sockaddrcopy(&(dest->addr),networkAddr);
  if(dest->location==ET_LOCAL)
    return(0);
  else
    return(1);
}
