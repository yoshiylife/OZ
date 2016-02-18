/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <errno.h>
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "comm.h"
#include "circuits.h"
#include "ncl/exec_table.h"

#include <netinet/tcp.h>
#include <stropts.h>
  
#define DEBUGMESSAGE 0
  
#define MAX_RECV_TERMINAL_UNIX 3
#define MAX_SEND_TERMINAL_UNIX 3
#define MAX_RECV_TERMINAL_INET 5
#define MAX_SEND_TERMINAL_INET 5
#define MAX_RETRY 3
#define COMM_CIRCUIT_PRIORITY 3
#define NORMAL_PRIORITY       3
#define STACK_SIZE (20 * 1024)

extern	int	bzero( char *, int ) ;
extern	int	bcopy( char *, char *, int ) ;
  
extern void AddressInQuestion(long long exid, struct sockaddr_in *old_address);
extern ExecTable AddressRequest(long long exid);
extern void sockaddrcopy(struct sockaddr_in *from , struct sockaddr_in *to);

/* debug manager accept port */
int     DmUnixServPort ;
int     DmInetServPort ;


static SendTermRec sendterm_unix[MAX_SEND_TERMINAL_UNIX];
static SendTermRec sendterm_inet[MAX_SEND_TERMINAL_INET];
static RecvTermRec recvterm_unix[MAX_RECV_TERMINAL_UNIX];
static RecvTermRec recvterm_inet[MAX_RECV_TERMINAL_INET];

static OZ_MonitorRec SendTermLock;
static OZ_MonitorRec RecvTermLock;
static OZ_ConditionRec SendTermAvailUnix;
static OZ_ConditionRec RecvTermAvailUnix;
static OZ_ConditionRec SendTermAvailInet;
static OZ_ConditionRec RecvTermAvailInet;
static int free_recv_term_unix;
static int free_recv_term_inet;
static int free_send_term_unix;
static int free_send_term_inet;

commBuff SendListUnix;
commBuff SendListInet;
commBuff RecvList;
OZ_MonitorRec SendListUnixLock;
OZ_MonitorRec SendListInetLock;
OZ_MonitorRec RecvListLock;
OZ_ConditionRec SendListUnixAvail;
OZ_ConditionRec SendListInetAvail;
OZ_ConditionRec RecvListAvail;

struct sockaddr_in MyNetworkAddress;
extern	long long	OzExecutorID;

static int ListenPort;

char buf[80];
int optval;

/* debug purpose only */
static void
  NoPrintf(s,arg0, arg1, arg2,arg3,
	   arg4,arg5, arg6,arg7)
{
  if(DEBUGMESSAGE)
    OzDebugf((char *)s,arg0,arg1,arg2,arg3,arg4,arg5,arg6,arg7);
  return;
}

#if 0
/* not yet finished implementation */
stat_of_terminal(int kind,int index)
{
  SendTerm st;
  RecvTerm rt;
  
  switch(kind)
    {
    case 3: /* inet send */
      if(index>=MAX_SEND_TERMINAL_INET || index<0)
	return;
      st = &(sendterm_inet[index]);
      OzDebugf("status of inet receive terminal no. %d\n",index);
      goto disp_send_term;
    case 1: /* unix send */
      if(index>=MAX_SEND_TERMINAL_UNIX || index<0)
	return;
      st = &(sendterm_unix[index]);
      OzDebugf("status of unix receive terminal no. %d\n",index);
      
    disp_send_term:
      
    case 2: /* inet receiver */
    case 0: /* unix receive */
    disp_recv_term:
    }
}
#endif

static void   DumpAddress(struct sockaddr_in *a)
{ unsigned char *b; int i;
  
  b=(unsigned char *)a;
  
  for(i=0;i<16;i++) NoPrintf("%02x ",*b++); 
  NoPrintf("\n");
}


static	int
sendbuff(int s, commBuff buff)
{ 
  int ii;
#if 0
  OzDebugf("sendbuff: fd %d, buffer@ %x (size %d)\n",s,buff,buff->bufsize);
#endif
  
  if(buff->bufsize ==0)
    return(0);
  
  ii=OzSend(s, (char *)(&(buff->bufsize)),(buff->bufsize)+4,0);
  if(ii<0)
    { OzDebugf("sendbuff: %m\n");
      OzDebugf("Fail to send (fd:%d)\n",s);
    }
  /*
    NoPrintf("sendbuff: begin fd(%d)\n",s);
    if((i=OzSend<(s,&(buff->bufsize),4,0))<0)
    { OzDebugf("send: %m\n");
    OzDebugf("Fail to send buffer-size (%d)\n",buff->bufsize);
    }
    if(i<=0)
    return(i);
    if((ii=OzSend(s,buff->buf,buff->bufsize,0))<0)
    { OzDebugf("send2: %m\n");
    OzDebugf("size was sent,but contents are not\n");
    }
    NoPrintf("sendbuff: end (%d) (%d)\n",i,ii);
    */
  return(ii);
}

static	int
ReadFullSize(int s, unsigned char *cp, int length)
{
  int sent,unsent,i;
  
  for(sent=0,unsent=length; unsent>0;)
    {
      i = OzRecv(s,cp,unsent,0) ;
      if ( i <= 0 ) return( i ) ;
      sent += i;
      cp += i;
      unsent -= i;
    }
  return(length);
}

static	int
recvbuff(int s,commBuff buff)
{
  int rval;
  
  NoPrintf("recvbuff: begin fd(%d)\n",s);
  rval=ReadFullSize(s,(unsigned char *)(&(buff->bufsize)),4);
  if(rval <= 0)
    return(rval);
  else
    return(ReadFullSize(s,(unsigned char *)(&(buff->buf)),buff->bufsize));
}

void
report_send_error(commBuff buff,int error)
{
  RemoteSendChannel src; 
  RemoteRecvChannel rrc;
  
  OzDebugf("Send Error (%d) buf@%d channel(%d)\n",error,(int)buff,(int)buff->channel);
  
  
  if(buff->channeltype==SCHAN) 
    { if((src=(RemoteSendChannel)(buff->channel))==(RemoteSendChannel)0)	
	return;
      
      OzExecEnterMonitor(&(src->lock));
#if 0
      /* prevent error communication */
      exid = src->send_channel.callee & 0xffffffffff000000LL;
      ThrFork(AddressInQuestion,4096*3,3,2,exid);
#endif
      /* error report */ 
      src->rval=error; 
      src->ret_type=ERROR;
      OzExecSignalCondition(&(src->receive_response));
      OzExecExitMonitor(&(src->lock)); 
    } 
  else 
    { 
      if((rrc=(RemoteRecvChannel)(buff->channel))==(RemoteRecvChannel)0)
	return;
      OzExecEnterMonitor(&(rrc->lock));
      rrc->error=error; 
      OzExecExitMonitor(&(rrc->lock));
    }
}

void
report_recv_error(commBuff buff,int error)
{ 
  RemoteSendChannel src;
  RemoteRecvChannel rrc;
  
  NoPrintf("Recv Error (%d)\n",error);
  if(buff->channeltype==SCHAN) 
    { if((src=(RemoteSendChannel)(buff->channel))==(RemoteSendChannel)0)
	return; 
      OzExecEnterMonitor(&(src->lock));
      /* error report */ 
      src->rval=error;
      src->ret_type=ERROR; 
      OzExecSignalCondition(&(src->receive_response));
      OzExecExitMonitor(&(src->lock)); 
    } 
  else 
    { if((rrc=(RemoteRecvChannel)(buff->channel))==(RemoteRecvChannel)0)
	return;
      OzExecEnterMonitor(&(rrc->lock));
      rrc->error=error;
      OzExecExitMonitor(&(rrc->lock));
    } 
}

static	int
  create_socket(int domain,int protocol)
{
  int fd;
  int optval;

  fd = OzSocket(domain,SOCK_STREAM,protocol);
  if(fd>=0)
    {
      optval=1;
      OzSetsockopt(fd,6,TCP_NODELAY,(const char *)&optval,4); 
      OzSetsockopt(fd,SOL_SOCKET,SO_KEEPALIVE, (const char *)&optval,4);
    }
  else
    {
      OzDebugf("circuits: create_socket : %m\n");
      OzDebugf("socket create failure : domain %d\n",domain);
    }
  return(fd);
}

/* sender_thread is thread program which send a message */ 
/* to a circuit */
static	void
  sender_thread
  (SendTerm st, int domain, int protocol, OZ_Condition free_condition,
   int *count)
{ 
  commBuff b;
  int i,retry,istat;
  struct sockaddr *addr;
  long long exid;
  
  int error_no;
  ExecTable dest;
  RemoteSendChannel src;
  RemoteRecvChannel rrc;
  struct sockaddr uaddr;

  while(1) 
    { /* infinit loop */ 
    loop_top_senderT:
      i=0;
      OzExecEnterMonitor(&(st->lock)); 
      while((st->buff==0)&&(st->status!=ST_TERM)&&(st->status!=ST_EXCP)) 
	OzExecWaitCondition(&(st->lock),&(st->send_req)); 
      if(st->status==ST_EXCP) 
	{/* exception */
	  NoPrintf("sender_thread detect exception \n");
	  for(b=st->buff;b;b=b->next)	
	    {
	      report_send_error(b,CommErrException);
	    }
	  OzClose(st->fd);
	  st->status=ST_IDLE;
	  st->executor_migrated=0;
	  if(st->buff != (commBuff)0)
	    FreeCommBuff(st->buff);	
	  st->buff=(commBuff)0;
	  OzExecExitMonitor(&(st->lock));	
	  OzExecEnterMonitor(&SendTermLock);
	  (*count)++;
	  OzExecSignalCondition(free_condition);
	  OzExecExitMonitor(&SendTermLock);
	  goto loop_top_senderT;
	}
      else if((b=st->buff)) 
	{
	  if(st->status==ST_PREP)
	    { 	
	      
	      for(retry=0,i=-1;(i<0) && (retry<MAX_RETRY);retry++)
		{
		  st->fd = create_socket(domain,protocol);
		  NoPrintf("sender_thread: try to connect fd(%d)\n",st->fd);
		  DumpAddress(&(st->destination));
		  
		  if ( domain == AF_UNIX ) {
		    addr = (struct sockaddr *)&st->destination ;
		    i = OzConnect(st->fd,addr,strlen(addr->sa_data)+2) ;
		    NoPrintf("circuits.c: UNIX connect\n");
		  } 
		  else {
		    i = OzConnect(st->fd,(struct sockaddr *)(&(st->destination)), sizeof(struct sockaddr_in) ) ;
		    NoPrintf("circuits.c: INET connect\n");
		  }
		  
		  if( (i < 0) && !(st->executor_migrated) )	
		    { /* fail to connect. destination executor may be
			 absent or moved to other location */

		      NoPrintf("circuits.c: retry start\n");
		      NoPrintf("sender_thread: fail to connect and try to re-connect new location\n");
		      error_no=errno;
		      OzDebugf("sender_thread: connect fail reason: %m\n");
		      OzClose(st->fd);
		      for(b=st->buff,exid=0LL;((b!=0) && (exid==0LL));b=b->next)	
			{
			  if((b->channeltype==SCHAN) && (b->channel != 0))
			    {
			      src = (RemoteSendChannel)(b->channel);
			      OzExecEnterMonitor(&(src->lock));
			      exid = ((src->send_channel.callee) 
				      & 0xffffffffff000000LL);
			      OzDebugf("re-connect exid: %08x%08x\n",
				       (int)(exid>>32),(int)(exid &0xffffffffLL));
			      OzExecExitMonitor(&(src->lock));
			    }
			  else if((b->channeltype==RCHAN) && (b->channel != 0))
			    {
			      rrc = (RemoteRecvChannel)(b->channel);
			      OzExecEnterMonitor(&(rrc->lock));
			      exid = ((rrc->receive_channel.caller) 
				      & 0xffffffffff000000LL);
			      OzDebugf("re-connect exid: %08x%08x\n",
				       (int)(exid>>32),(int)(exid &0xffffffffLL));
			      OzExecExitMonitor(&(rrc->lock));
			    }
			}
		      if(exid==0LL) /* no information for re-connection */
			{
			  OzDebugf(" no way to find executor-Id, abundon to re-connect\n");
			  for(b=st->buff;b;b=b->next)
			    report_send_error(b,CommErrConn);
			  if(st->buff != (commBuff)0)
			    FreeCommBuff(st->buff);
			  st->buff=(commBuff)0;
			  st->status=ST_IDLE;
			  st->executor_migrated=0;
			  OzExecExitMonitor(&(st->lock));
			  OzExecEnterMonitor(&SendTermLock);	
			  (*count)++;
			  OzExecSignalCondition(free_condition);
			  OzExecExitMonitor(&SendTermLock);		
			  goto loop_top_senderT;
			}
		      else /* try to find new location of destination executor and reconnect */
			{
			  /* find new location of executor */
			  AddressInQuestion(exid, &(st->destination));
			  dest = AddressRequest(exid);

			  NoPrintf("sender_thread: try again to connect \n",st->fd);
			  st->executor_migrated=1;

			  if((domain==PF_UNIX) &&  
			     (dest->location==ET_LOCAL))
			    { /* reconnect same domain (UNIX) */
			      st->fd = create_socket(PF_UNIX,0);
			      bzero((char *)&(uaddr),16);
			      uaddr.sa_family = AF_UNIX;
			      OzSprintf(uaddr.sa_data,"/tmp/Oz%06x",
					(int)((exid>>24)&0xffffffLL));
			      i = OzConnect(st->fd,
					    &(uaddr),strlen(uaddr.sa_data)+2);
			      sockaddrcopy((struct sockaddr_in *)&(uaddr),
					   &(st->destination_secondary));
			    }
			  else if((domain==PF_INET) &&
				  (dest->location!=ET_LOCAL))
			    { /* reconnect same domain (INET) */
			      sockaddrcopy(&(dest->addr),
					   &(st->destination_secondary));
			      /* try to connect new location */
			      st->fd = create_socket(PF_INET,IPPROTO_TCP);
			      i = OzConnect(st->fd,
					    (struct sockaddr *)(&(st->destination_secondary)), 
					    sizeof(struct sockaddr_in) ) ;
			    }
			  else if((domain==PF_UNIX) &&
				  (dest->location!=ET_LOCAL))
			    { /* reconnect different domain (UNIX->INET)*/
			      sockaddrcopy(&(dest->addr),
					   &(st->destination_secondary));
			      st->fd = create_socket(PF_INET,IPPROTO_TCP);
			      i = OzConnect(st->fd,
					    (struct sockaddr *)(&(st->destination_secondary)), 
					    sizeof(struct sockaddr_in) ) ;
			    }
			  else
			    { /* reconnect different domain (INET->UNIX)*/
			      st->fd = create_socket(PF_UNIX,0);
			      bzero((char *)&(uaddr),16);
			      uaddr.sa_family = AF_UNIX;
			      OzSprintf(uaddr.sa_data,"/tmp/Oz%06x",
					(int)((exid>>24)&0xffffffLL));
			      i = OzConnect(st->fd,
					    &(uaddr),strlen(uaddr.sa_data)+2);
			      sockaddrcopy((struct sockaddr_in *)&(uaddr),
					   &(st->destination_secondary));
			    }
			}
		    }
		}
	      if(i<0) /* Can't connect after several retry */	 
		{ /* unexpected error , may not reached */
		  OzDebugf("connect: %m\n");
		  for(b=st->buff;b;b=b->next)	
		    {	 
		      report_send_error(b,CommErrConn);
		    }
		  OzClose(st->fd);
		  if(st->buff != (commBuff)0)
		    FreeCommBuff(st->buff);
		  st->buff=(commBuff)0;	 
		  st->status = ST_IDLE;	
		  st->executor_migrated=0;
		  OzExecExitMonitor(&(st->lock));
		  OzExecEnterMonitor(&SendTermLock);	
		  (*count)++;
		  OzExecSignalCondition(free_condition);
		  OzExecExitMonitor(&SendTermLock);	
		  goto loop_top_senderT;
		}	 
	    }
	  
	  NoPrintf("sender thread: connect returns %d\n",i);
	  
	  OzExecSignalCondition(&(st->check_start));
	  b = st->buff;
	  while(st->buff)
	    {
	      NoPrintf("sender_thread:send a packet\n");
	      istat = sendbuff(st->fd,st->buff);
	      if(istat<0)
		{
		  st->status=ST_EXCP;
		  OzExecExitMonitor(&(st->lock));
		  goto loop_top_senderT;
		}
	      st->buff=st->buff->next;
	    }
	  NoPrintf("sender_thread: free commbuff pre\n");
	  FreeCommBuff(b);
	  NoPrintf("sender_thread: free commbuff post\n"); 
	}
      if(st->status==ST_TERM)
	{
	  NoPrintf("sender_thread: treminating\n");
	  OzClose(st->fd);
	  st->status=ST_IDLE;
	  st->executor_migrated=0;
	  OzExecExitMonitor(&(st->lock));
	  OzExecEnterMonitor(&SendTermLock);
	  (*count)++;
	  OzExecSignalCondition(free_condition);
	  OzExecExitMonitor(&SendTermLock);
	} 
      else if(st->status==ST_PREP) 
	{	
	  if(st->executor_migrated)
	    {
	      OzDebugf("sender_thread: release circuit for migrated executor\n");
	      st->status=ST_IDLE;
	      st->executor_migrated=0;
	      OzClose(st->fd);
	      OzExecExitMonitor(&(st->lock));
	      OzExecEnterMonitor(&SendTermLock);
	      (*count)++;
	      OzExecSignalCondition(free_condition);
	      OzExecExitMonitor(&SendTermLock);	      
	    }
	  else
	    {
	      st->status=ST_CONN;
	      OzExecExitMonitor(&(st->lock));
	    }
	}
      else
	{
	  OzExecExitMonitor(&(st->lock));
	}
    }
}


/* check disconnect request from receive terminal */
static	void
  send_checker(SendTerm st)
{ 
  int rval;
  char buf[3];
  int zero_count=0;
  
  while(1) 
    {
      OzExecEnterMonitor(&(st->lock)); 
      OzExecWaitCondition(&(st->lock),&(st->check_start));
      OzExecExitMonitor(&(st->lock));
      
      NoPrintf("send_checker: start to check\n");
    repeat:
      rval=OzRecv(st->fd,buf,1,0);
      NoPrintf("send_checker: receive from receive side(fd: %d) %d\n",st->fd,rval);
      
      if(rval>0)	
	{ /* circuit disconnect request */
	  zero_count=0;
	  NoPrintf("circuit disconnection is requested\n");	
#if 1 /* ONIDEBUG */
	  OzDebugf("circuits.c: circuit disconnection is requested\n");
#endif
	  OzExecEnterMonitor(&(st->lock));
	  st->status = ST_TERM;
	  OzExecSignalCondition(&(st->send_req));
	  OzExecExitMonitor(&(st->lock));
	}
      else if(rval==0)
	{ /* unexpected disconnection of circuit */
	  zero_count++;
	  if(zero_count >100)
	    {
	      OzDebugf("send_checker:Disconnected (fd:%d)\n",st->fd);
	      zero_count=0;
	      
	      OzExecEnterMonitor(&(st->lock));
	      if(st->buff)
		{ st->status = ST_PREP;
		  st->fd = 0;
		}
	      else
		st->status = ST_TERM;
	      st->rval=rval;
	      OzExecSignalCondition(&(st->send_req));
	      OzExecExitMonitor(&(st->lock));
	    }
	  else
	    goto repeat;
	}
      else
	{ /* exception ocuured */
	  zero_count=0;
	  OzExecEnterMonitor(&(st->lock));
	  if(st->status == ST_IDLE)
	    OzDebugf("send_checker:: disconnection of migrated executor\n");
	  else
	    {
	      if((errno==EBADF) || (errno==ENOTCONN))
		{ 
		  OzDebugf("send_checker:: read exception because of disconnection\n");
		  if(st->buff)
		    st->status = ST_PREP;
		  else
		    st->status = ST_TERM;
		}
	      else
		{
		  st->status = ST_EXCP;	
		  OzDebugf("send_checker: %m\n");
		  OzDebugf("send_checker read exception: fd %d, errno %d\n",
			   st->fd,errno);
		}

	      st->rval=rval;	 
	      st->errno=errno;
	      OzExecSignalCondition(&(st->send_req));
	    }
	  OzExecExitMonitor(&(st->lock));
	}
    }
}

static	void
  sender_inet()
{ 
  struct sockaddr_in *destination;
  commBuff p;
  commBuff sendbuf;
  int i,found,disconnectNext;
  SendTerm st;
  
  disconnectNext=0;
  free_send_term_inet=MAX_SEND_TERMINAL_INET;
  
  while(1) 
    {
      OzExecEnterMonitor(&SendListInetLock);
      while(SendListInet == (commBuff)0) 
	OzExecWaitCondition(&SendListInetLock,&SendListInetAvail);
      sendbuf = SendListInet;
      destination = &(sendbuf->networkAddr);
      SendListInet = SendListInet->next;
      OzExecExitMonitor(&SendListInetLock);
      
      for(i=0,st=sendterm_inet;i<MAX_SEND_TERMINAL_INET && sendbuf ;i++,st++)
 	{
	  OzExecEnterMonitor(&(st->lock));
	  if((st->status==ST_PREP || st->status==ST_CONN)
	     &&(st->destination.sin_port==destination->sin_port)
	     && (st->destination.sin_addr.s_addr == destination->sin_addr.s_addr))	 
	    { /* if connected circuit exist, use it */
	      if(st->buff==(commBuff)0)		
		st->buff=sendbuf;
	      else		
		{
		  for(p=st->buff;p!=(commBuff)0;p=p->next) {
		    if ( p->next == NULL ) {
			p->next=sendbuf;
			break ;
		    }
		  }
		}
	      sendbuf->next=(commBuff)0;
	      OzExecSignalCondition(&(st->send_req));
	      sendbuf=(commBuff)0;
	    }	
	  OzExecExitMonitor(&(st->lock));
	}
      
    RETRY:
      if(sendbuf)
	{

	  for(i=0,st=sendterm_inet;i<MAX_SEND_TERMINAL_INET && sendbuf ;i++,st++)
	    {
	      OzExecEnterMonitor(&(st->lock));
	      if(st->status==ST_IDLE)
		{ /* find unused terminal and use it */
		  st->status=ST_PREP;
		  st->executor_migrated=0;
		  st->buff=sendbuf;
		  bcopy((char *)&(sendbuf->networkAddr),
				(char *)&(st->destination),16);
		  sendbuf->next=(commBuff)0;
		  OzExecSignalCondition(&(st->send_req));
		  OzExecExitMonitor(&(st->lock));
		  sendbuf=(commBuff)0;
		  OzExecEnterMonitor(&SendTermLock);
		  free_send_term_inet--;
		  OzExecExitMonitor(&SendTermLock);
		}	
	      else
		OzExecExitMonitor(&(st->lock));
	    }
	}
      if(sendbuf)
	{ /* If no terminal, wait until terminal available */	
	  for(i=0,found=0;i<MAX_SEND_TERMINAL_INET && !found ; i++)
	    { 
	      st = &(sendterm_inet[(i + disconnectNext) % MAX_SEND_TERMINAL_INET]);
	      OzExecEnterMonitor(&(st->lock));
	      if(st->status==ST_CONN)
		{ 
		  st->status=ST_TERM;
		  found=1;
		  disconnectNext = i+1;
		}
	      OzExecExitMonitor(&(st->lock));
	    }
	  OzExecEnterMonitor(&SendTermLock);
	  while(!free_send_term_inet)
	    OzExecWaitCondition(&SendTermLock,&SendTermAvailInet);
	  OzExecExitMonitor(&SendTermLock);
	  goto RETRY;
	} 
    }
  /* end of while loop */
}

static	void
  sender_unix() 
{ 
  struct sockaddr_in *destination;
  commBuff p;
  commBuff sendbuf;
  int i,found,disconnectNext;
  SendTerm st;
  
  disconnectNext=0;
  free_send_term_inet=MAX_SEND_TERMINAL_UNIX;
  
  while(1) 
    { OzExecEnterMonitor(&SendListUnixLock);
      while(SendListUnix == (commBuff)0) {
	OzExecWaitCondition(&SendListUnixLock,&SendListUnixAvail);
      }
      sendbuf = SendListUnix;
      destination = &(sendbuf->networkAddr);
      SendListUnix = SendListUnix->next;
      OzExecExitMonitor(&SendListUnixLock);
      sendbuf->next=(commBuff)0;
      
      NoPrintf("sender_unix: begin to search apropreate terminal\n");
      
      for(i=0,st=sendterm_unix;i<MAX_SEND_TERMINAL_UNIX && sendbuf ;i++,st++)
 	{
	  OzExecEnterMonitor(&(st->lock));
	  if((st->status==ST_PREP || st->status==ST_CONN)
	     &&(!strncmp((char *)&(st->destination.sin_port),
			 (char *)&(destination->sin_port),14)))	 
	    { /* if connected circuit exist, use it */	
	      NoPrintf("sender_unix: find connected terminal (%d)\n",i);
	      
	      if(st->buff==(commBuff)0)
		st->buff=sendbuf;
	      else	
		{
		  for(p=st->buff;p!=(commBuff)0;p=p->next) {
		    if ( p->next == NULL ) {
			p->next=sendbuf;
			break ;
		    }
		  }
		}
	      OzExecSignalCondition(&(st->send_req));
	      sendbuf=(commBuff)0;
	    }
	  OzExecExitMonitor(&(st->lock));
	}
      
    RETRY:
      if(sendbuf)
	{
	  for(i=0,st=sendterm_unix;i<MAX_SEND_TERMINAL_UNIX && sendbuf ;i++,st++)
	    {
	      OzExecEnterMonitor(&(st->lock));
	      if(st->status==ST_IDLE)
		{ /* find unused terminal and use it */	
		  NoPrintf("sender_unix: find idle terminal (%d)\n",i);
		  st->status=ST_PREP;
		  st->buff=sendbuf;
		  bcopy((char *)&(sendbuf->networkAddr),
				(char *)&(st->destination),16);
		  sendbuf->next=(commBuff)0;
		  OzExecSignalCondition(&(st->send_req));
		  sendbuf=(commBuff)0;
		  OzExecEnterMonitor(&SendTermLock);
		  free_send_term_unix--;
		  OzExecExitMonitor(&SendTermLock);
		}
	      OzExecExitMonitor(&(st->lock));
	    }
	}
      if(sendbuf)
	{ /* If no terminal available, wait until terminal become free */
	  for(i=0,found=0;i<MAX_SEND_TERMINAL_UNIX && !found ; i++)
	    { st = &(sendterm_unix[(i+ disconnectNext++)%MAX_SEND_TERMINAL_UNIX]);
	      OzExecEnterMonitor(&(st->lock));
	      if(st->status==ST_CONN)
		{
		  st->status = ST_TERM;
		  found=1;
		  OzExecSignalCondition(&(st->send_req));
		}
	      OzExecExitMonitor(&(st->lock));
	    }
	  OzExecEnterMonitor(&SendTermLock);
	  while(!free_send_term_unix)
	    OzExecWaitCondition(&SendTermLock,&SendTermAvailUnix);
	  OzExecExitMonitor(&SendTermLock);
	  goto RETRY;
	}
    } /* end of while loop */ 
}


static	void
  receiver_thread(RecvTerm rt, OZ_Condition avail_condition, int *count)
{ 
  commBuff buff,b; 
  int rval;
  int zero_count=0;
  
  for(;;)
    {
      OzExecEnterMonitor(&(rt->lock));
      while(rt->status==RT_IDLE)
	OzExecWaitCondition(&(rt->lock),&(rt->recv_data));
      OzExecExitMonitor(&(rt->lock));
      
      NoPrintf("receiver_thread: I'm not Idle!\n");
      buff=(commBuff)GetCommBuff();
      NoPrintf("receiver_thread: prepare communication buffer\n");
      rval=recvbuff(rt->fd,buff);
      NoPrintf("receiver_thread: receive a packet (size:%d)\n",rval);
      
#if 0
      /* dump received packet for debugging */
      for(p = &(buff->buf[0]), i=0, ii=0 ;
	  i<rval ;
	  i++,ii++,p++)
	{
	  NoPrintf("%02x ",*p);
	  if((ii%16)==15)
	    NoPrintf("\n");
	}
#endif
      
      if(rval==0)
	{ /* connection closed by sending side */
	  zero_count++;
	  if(zero_count>100)
	    { /* read returns zero many time, send disconnect request */
	      /* if error occured in sending, connection is broken    */
	      OzDebugf("receiver_thread: Connection closed (fd:%d)\n",rt->fd);
	      zero_count = 0;
	      if(OzSend(rt->fd,"e",1,0) < 0)
		{
		  OzExecEnterMonitor(&(rt->lock));
		  OzClose(rt->fd);
		  rt->fd=0;
		  rt->status=RT_IDLE;
		  OzExecExitMonitor(&(rt->lock));
		  OzExecEnterMonitor(&RecvTermLock);
		  (*count)++;
		  OzExecSignalCondition(avail_condition);
		  OzExecExitMonitor(&RecvTermLock);
		}
	    }
	}
      else if(rval>0)
	{ /* buffer treatment */
	  zero_count=0;
	  OzExecEnterMonitor(&(rt->lock));
	  rt->status=RT_RECV;
	  OzExecExitMonitor(&(rt->lock));
	  OzExecEnterMonitor(&RecvListLock);
	  if(RecvList==(commBuff)0)
	    { RecvList=buff;
	      buff->next=(commBuff)0; }
	  else
	    {
	       for(b=RecvList;b!=(commBuff)0;b=b->next) {
		    if ( b->next == NULL ) {
			b->next=buff;
			buff->next=(commBuff)0;
			break ;
		    }
		}
	    }
	  NoPrintf("receiverThread: receive a buffer and add to list\n");
	  OzExecSignalCondition(&RecvListAvail);
	  OzExecExitMonitor(&RecvListLock);
	}
      else if (rval<0)
	{ OzDebugf("receiver_thread: %m\n");
	  zero_count=0;
	  NoPrintf("Receive_thread:receive returns %d, fd=%d status %d\n",
		   rval,rt->fd,rt->status);
	  OzExecEnterMonitor(&(rt->lock));
	  OzClose(rt->fd);
	  rt->fd=0;
	  rt->status=RT_IDLE;
	  OzExecExitMonitor(&(rt->lock));
	  OzExecEnterMonitor(&RecvTermLock);
	  (*count)++;
	  OzExecSignalCondition(avail_condition);
	  OzExecExitMonitor(&RecvTermLock);
	}
      
      /* Don't need below a line becase to not have monitor previously */
      /* OzExecExitMonitor(&(rt->lock)); */
    }
}

static	void
  receiver_unix(int s)
{
  int i;
  
  RecvTerm rt;
  int disconnectNext,victims;
  int ns;
  struct sockaddr_in dummy_address;
  int dummy_int;
  
  disconnectNext=0;
  while(1) {
    
    NoPrintf("receiver_unix: accept pre\n");
    ns=OzAccept(s,(struct sockaddr *)(&dummy_address),&dummy_int);
    NoPrintf("receiver_unix: Accepted (UNIX_DOMAIN)\n");
    
    if(ns<0)
      { OzDebugf("receiver_unix:accept: %m\n");
	OzDebugf("Accept error\n");
	OzDebugf("receiver_unix: thread terminated\n");
	return;
      }
    
  RETRY_UNIX_RECV:
    for(i=0,rt=recvterm_unix;ns && (i<MAX_RECV_TERMINAL_UNIX);i++,rt++)
      { 
	if(rt->status == RT_IDLE)
	  { OzExecEnterMonitor(&(rt->lock));
	    rt->status = RT_RECV;
	    rt->fd=ns;
	    ns=0;
	    free_recv_term_unix--;
	    OzExecSignalCondition(&(rt->recv_data));
	    OzExecExitMonitor(&(rt->lock));
	    NoPrintf("Use terminal %d fd(%d)\n",i,rt->fd);
	    break;
	  }
      }
    if(ns) /* no free terminal */
      {
	NoPrintf("Try to disconnect receive terminal unix\n");
	for(i=0,victims=2;i<MAX_RECV_TERMINAL_UNIX && victims>0;i++)
	  { rt=&(recvterm_unix[(disconnectNext+i)%MAX_RECV_TERMINAL_UNIX]);
	    NoPrintf("Send disconnect request to %x (%d + %d)\n",rt,disconnectNext,i);
	    OzExecEnterMonitor(&(rt->lock));
	    rt->disconn_req=1;
	    if(rt->status != RT_TERM) 
	      { OzSend(rt->fd,"e",2,0);
		rt->status=RT_TERM;
		NoPrintf("send! %x %d\n",rt,rt->fd);
		victims--;
	      }
	    OzExecExitMonitor(&(rt->lock));
	  }
	
	disconnectNext = (disconnectNext+2)%MAX_RECV_TERMINAL_UNIX;
	OzExecEnterMonitor(&RecvTermLock);
	while(free_recv_term_unix==0)
	  OzExecWaitCondition(&RecvTermLock,&RecvTermAvailUnix);
	OzExecExitMonitor(&RecvTermLock);
	goto RETRY_UNIX_RECV;
      }
  }
}

static	void
  receiver_inet(int s) /* s is binded socket */
{
  int i;
  RecvTerm rt;
  int disconnectNext,victims;
  int ns;
  
  free_recv_term_inet=MAX_RECV_TERMINAL_INET;
  disconnectNext=0;
  OzListen(s, 5);
  while(1) {
    ns=OzAccept(s,0,0);
    
    if(ns<0)
      { OzDebugf("receiver_unix:accept: %m\n");
	OzDebugf("Accept error\n");
	OzDebugf("receiver_unix: thread terminated\n");
	return;
      }
    
  RETRY_INET_RECV:
    for(i=0,rt=recvterm_inet;ns && (i<MAX_RECV_TERMINAL_INET);i++,rt++)
      { if(rt->status == RT_IDLE)
	  { OzExecEnterMonitor(&(rt->lock));
	    rt->status = RT_RECV;
	    rt->fd=ns;
	    ns=0;
	    free_recv_term_inet--;
	    OzExecSignalCondition(&(rt->recv_data));
	    OzExecExitMonitor(&(rt->lock));
	    break;
	  }
      }
    if(ns) /* no free terminal */
      {
	for(i=0,victims=2;i<MAX_RECV_TERMINAL_INET && victims>0;i++)
	  { rt=&(recvterm_inet[(disconnectNext+i)%MAX_RECV_TERMINAL_INET]);
	    OzExecEnterMonitor(&(rt->lock));
	    rt->disconn_req=1;
	    if(rt->status != RT_TERM) 
	      { OzSend(rt->fd,"e",2,0);
		rt->status=RT_TERM;
		NoPrintf("send! %x %d\n",rt,rt->fd);
		victims--;
	      }
	    OzExecExitMonitor(&(rt->lock));
	  }
	
	disconnectNext = (disconnectNext+2)%MAX_RECV_TERMINAL_INET;
	OzExecEnterMonitor(&RecvTermLock);
	while(free_recv_term_inet==0)
	  OzExecWaitCondition(&RecvTermLock,&RecvTermAvailInet);
	OzExecExitMonitor(&RecvTermLock);
	goto RETRY_INET_RECV;
      }
  }
}

int
  InitCommCircuits()
{
  int i,s,us;
  SendTerm st;
  RecvTerm rt;
  struct sockaddr_in addr;
  struct sockaddr uaddr;
  int addr_size;
  OZ_Thread t;
  
  OzInitializeMonitor(&SendTermLock);
  OzInitializeMonitor(&RecvTermLock);
  OzExecInitializeCondition(&SendTermAvailUnix,1);
  OzExecInitializeCondition(&SendTermAvailInet,1);
  OzExecInitializeCondition(&RecvTermAvailUnix,1);
  OzExecInitializeCondition(&RecvTermAvailInet,1);
  
  /* create INET listen port */
 retry:
  if((ListenPort=s=OzSocket(PF_INET,SOCK_STREAM,IPPROTO_TCP))<0)
    { OzDebugf("Socket creation failure \n");
      return(-1);
    }
  bzero((char *)&addr,sizeof(addr));
  addr.sin_port=OZPORT;
  
  if((OzBind(s,(struct sockaddr *)(&addr),sizeof(addr)))<0)
    { OzDebugf("CircuitInitalization:BindFailure INET\n");
      OzClose(s);
      return(-1);
    }
  
  addr_size=sizeof(MyNetworkAddress);
  OzGetsockname(s,(struct sockaddr *)&MyNetworkAddress,&addr_size);
  
  if((DmInetServPort=OzSocket(PF_INET,SOCK_STREAM,IPPROTO_TCP))<0)
    { OzDebugf("Socket creation failure \n");
      return(-1);
    }
  addr.sin_port = MyNetworkAddress.sin_port+1;
  
  if(OzBind(DmInetServPort,(struct sockaddr *)(&addr),sizeof(addr))<0)
    { OzClose(s);
      OzClose(DmInetServPort);
      goto retry;
    }
  
  /* create UNIX listen port */
  uaddr.sa_family=AF_UNIX;
  bzero(uaddr.sa_data,14);
  OzSprintf(uaddr.sa_data,"/tmp/Oz%06x",(int)((OzExecutorID>>24)&0xffffff));
  free_recv_term_unix=MAX_RECV_TERMINAL_UNIX;
  NoPrintf("receiver_unix ADDRESS:");
  DumpAddress((struct sockaddr_in *)&uaddr);
  if((us=OzSocket(PF_UNIX,SOCK_STREAM,0))<0)
    { OzDebugf("Socket create failure(UNIX_DOMAIN)");
      return(-1);
    }
  if(OzBind(us, &uaddr, strlen(uaddr.sa_data)+2)<0)
    { OzDebugf("receiver_unix: Bind failure (UNIX_DOMAIN)\n");
      OzClose(us);
      return(-1);
    }
  if(OzListen(us, 5)<0)
    { OzDebugf("receiver_unix: Listen failure (UNIX_DOMAIN)\n");
      return(-1);
    }
  NoPrintf("receiver_unix: Start to listen (UNIX_DOMAIN)\n");
  
  OzSprintf(uaddr.sa_data,"/tmp/Dm%06x",(int)((OzExecutorID>>24)&0xffffff));
  NoPrintf("receiver_unix ADDRESS:");
  DumpAddress((struct sockaddr_in *)&uaddr);
  if((DmUnixServPort=OzSocket(PF_UNIX,SOCK_STREAM,0))<0)
    { OzDebugf("Socket create failure(UNIX_DOMAIN:DM)");
      return(-1);
    }
  if(OzBind(DmUnixServPort, &uaddr, strlen(uaddr.sa_data)+2)<0)
    { OzDebugf("receiver_unix: Bind failure (UNIX_DOMAIN:DM)\n");
      OzClose(DmUnixServPort);
      return(-1);
    }
  
  
  t =  ThrFork(sender_inet,STACK_SIZE,COMM_CIRCUIT_PRIORITY,0);
  t =  ThrFork(sender_unix,STACK_SIZE,COMM_CIRCUIT_PRIORITY,0);
  t =  ThrFork(receiver_unix,STACK_SIZE,COMM_CIRCUIT_PRIORITY,1,us);
  t =  ThrFork(receiver_inet,STACK_SIZE,COMM_CIRCUIT_PRIORITY,1,s);
  
  for(i=0,st=sendterm_unix;i<MAX_SEND_TERMINAL_UNIX;i++,st++)
    {
      OzInitializeMonitor(&(st->lock));
      OzExecInitializeCondition(&(st->send_req),1);
      OzExecInitializeCondition(&(st->check_start),1);
      st->status=ST_IDLE;
      st->buff=(commBuff)0;
      st->executor_migrated = 0;
      st->ts = ThrFork(sender_thread,STACK_SIZE,COMM_CIRCUIT_PRIORITY,
			    5,st,PF_UNIX,0,
			    &SendTermAvailUnix,&free_send_term_unix);
      st->tc = ThrFork(send_checker,STACK_SIZE,COMM_CIRCUIT_PRIORITY,1,st);
    }
  for(i=0,st=sendterm_inet;i<MAX_SEND_TERMINAL_INET;i++,st++)
    {
      OzInitializeMonitor(&(st->lock));
      OzExecInitializeCondition(&(st->send_req),1);
      st->status=ST_IDLE;
      st->buff=(commBuff)0;
      st->executor_migrated = 0;
      st->ts = ThrFork(sender_thread,STACK_SIZE,COMM_CIRCUIT_PRIORITY,
			    5,st,PF_INET,IPPROTO_TCP,
			    &SendTermAvailInet,&free_send_term_inet);
      st->tc = ThrFork(send_checker,STACK_SIZE,COMM_CIRCUIT_PRIORITY,1,st);
    }
  
  for(i=0,rt=recvterm_unix;i<MAX_RECV_TERMINAL_UNIX;i++,rt++)
    {
      OzInitializeMonitor(&(rt->lock));
      OzExecInitializeCondition(&(rt->recv_data),1);
      rt->status=RT_IDLE;
      rt->buff = (commBuff)0;
      rt->fd=0;
      rt->t = ThrFork(receiver_thread,STACK_SIZE,COMM_CIRCUIT_PRIORITY,3,rt,
			   &RecvTermAvailUnix,&free_recv_term_unix);
    }
  
  for(i=0,rt=recvterm_inet;i<MAX_RECV_TERMINAL_INET;i++,rt++)
    {
      OzInitializeMonitor(&(rt->lock));
      OzExecInitializeCondition(&(rt->recv_data),1);
      rt->status=RT_IDLE;
      rt->buff = (commBuff)0;
      rt->fd=0;
      rt->t = ThrFork(receiver_thread,STACK_SIZE,COMM_CIRCUIT_PRIORITY,3,rt,
			   &RecvTermAvailInet,&free_recv_term_inet);
    }
  
  return(MyNetworkAddress.sin_port);
}


void
CloseCircuits()
{
  int i;
  char b[16];
  
  for(i=0;i<MAX_SEND_TERMINAL_INET;i++)
    if(sendterm_inet[i].fd != 0)
      OzClose(sendterm_inet[i].fd);
  for(i=0;i<MAX_RECV_TERMINAL_INET;i++)
    if(recvterm_inet[i].fd != 0)
      { OzSend(recvterm_inet[i].fd, "e",1,0);
	OzClose(recvterm_inet[i].fd);
      }
  if(0<ListenPort) OzClose(ListenPort);
  if(0<DmUnixServPort) OzClose(DmUnixServPort);
  if(0<DmInetServPort) OzClose(DmInetServPort);
  OzSprintf(b,"/tmp/Oz%06x",(int)((OzExecutorID>>24)&0xffffff));
  unlink(b);
  OzSprintf(b,"/tmp/Dm%06x",(int)((OzExecutorID>>24)&0xffffff));
  unlink(b);
  return;
}
