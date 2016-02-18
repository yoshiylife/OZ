/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <sys/types.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/file.h>
#include <sys/param.h>
#include <net/if.h>
#include <netinet/in.h>
#include <nlist.h>
#include <stdio.h>
#include <signal.h>
#include <errno.h>
#include <utmp.h>
#include <ctype.h>
#include <netdb.h>
#include <syslog.h>
#include <pwd.h>
  
#include "ncl_defs.h"
  
#include "apgw.h"
#include "apgw_defs.h"
#include "apgw_sitetbl.h"
#include "apgw_ethash.h"
#include "apgw_mthash.h"
#include "comm-packets.h"

  extern HashTableRec	ex_tbl;
extern HashTableRec	msg_tbl;
extern HashTableRec	site_tbl;

extern ExecTable    ApgwSearchEtHash(HashTable hp, long long eid);
extern MsgTable	    ApgwEnterMtHash(HashTable hp, long long mid,
				    long long caller, long long callee);
extern MsgTable	    ApgwSearchMtHash(HashTable hp, long long mid);
extern int		SendRncl(ReceivePort gnp, int id, char *dp, int size);
extern SiteTable	ApgwSearchSiHash(HashTable hp, int siteid);

extern MessageBuffer get_message_buffer();
extern void          free_message_buffer(MessageBuffer mb);

extern SendMessage(MessageBuffer mb, long long dist);

extern int set_last_access_receive(ReceivePort rp);

void discard_packet(ReceivePort rp,MessageBuffer mb)
{
  close(rp->fd);
  rp->fd=0;
  free_message_buffer(mb);
  return;
}

int
SendError(MessageBuffer mb)
{
  CommError ce;
  long long destination;

  printf("SendError: mb %x dest %08x%08x\n",mb,
	 (int)(((mb->exid_error_report)>>32)&INTEGER_MASK),
	 (int)((mb->exid_error_report)&INTEGER_MASK));
  if((destination = mb->exid_error_report) == 0LL)
    { free_message_buffer(mb);
      return(0); /* do nothing if nowhere to send */
    }
  ce = (CommError)(mb->buffer);
  ce->head.kind = COMM_ERROR;
  ce->error_code = ERROR_CODE;
  mb->buffer_size = SZ_COMM_ERROR;
  mb->exid_error_report=0LL;
  SendMessage(mb,destination);
  return(0);
}


int	ee_method_call(ReceivePort np)
{
  int		size, nb, kind,tail;
  char		*p;
  CommCallInd	ccip;
  CommHead	cchp;
  ExecTable	outp, inp;
  MsgTable	mp;
  SiteTable	stp;
  char s[256];

  MessageBuffer mb;
  long long msg_id;
  int i;
  
#ifdef	DEBUG
  printf(" + Received message from executor\n");
#endif

  mb = get_message_buffer();
  if(mb == (MessageBuffer)0)
    {
      printf("exmessage:Can't receive message because no buffer!\n");
      return(-1);
    }

  nb = read(np->fd, (char *)&(mb->buffer_size), sizeof(int));
  if((nb <= 0) || (mb->buffer_size <0) ||(mb->buffer_size >MESSAGE_BUFFER_SIZE))
    {
      sprintf(s,"exmessage:Illigal packet or disconnected? %d bytes read as size, size=%d (Packet discarded)",nb,mb->buffer_size);
      syslog(s);
      printf("%s\n",s);
      discard_packet(np,mb);
      return(0);
    }

  nb = read(np->fd, mb->buffer, mb->buffer_size);
  if(nb <= 0)
    {
      sprintf(s,"exmessage: Can't receive.(may be disconnected) result %d (size %d)",nb,mb->buffer_size);
      syslog(s);
      printf("%s\n",s);
      discard_packet(np,mb);
      return(0);
  }

  set_last_access_receive(np);

  kind = *((long *)mb->buffer);
  printf(" packet type is %8x\n",kind);

  /* set untrust flag in the packet. */
  tail = kind & COMM_TAIL_FLAG;
  kind &= COMM_UT_MASK;
  *((long *)mb->buffer) |= COMM_UNTRUST_FLAG;

  switch(kind) {
  case COMM_CALL_IND:
    ccip	= (CommCallInd)(mb->buffer);
#ifdef	DEBUG
    printf("### Message kind is CALL_IND ### => Receive size(%d Bytes)\n",
	   mb->buffer_size);
    printf("  ArchID: %d, MsgID: 0x%08x%08x, slot1: 0x%08x, slot2: 0x%08x\n", 
	   ccip->head.arch_id, 
	   (int)((ccip->head.msg_id>>32)&INTEGER_MASK), 
	   (int)(ccip->head.msg_id&INTEGER_MASK),
	   ccip->slot1,
	   ccip->slot2);
    printf("  caller: 0x%08x%08x, callee: 0x%08x%08x\n", 
	   (int)((ccip->caller>>32)&INTEGER_MASK), 
	   (int)(ccip->caller&INTEGER_MASK), 
	   (int)((ccip->callee>>32)&INTEGER_MASK), 
	   (int)(ccip->callee&INTEGER_MASK));
    printf("  ClassID: 0x%08x%08x, ProcID: 0x%08x%08x\n",
	   (int)((ccip->class_id>>32)&INTEGER_MASK), 
	   (int)(ccip->class_id&INTEGER_MASK), 
	   (int)((ccip->proc_id>>32)&INTEGER_MASK), 
	   (int)(ccip->proc_id&INTEGER_MASK));
#endif

    if((ccip->caller==0LL) || (ccip->callee==0LL) || 
       (ccip->class_id ==0LL) || (ccip->head.msg_id ==0LL))
      { /* illegal packet */
	sprintf(s,"exmessage:Illigal packet caller:0x%08x%08x callee:0x%08x%08x class_id:0x%08x%08x message_id:0x%08x%08x",
		(int)((ccip->caller>>32)&INTEGER_MASK), 
		(int)(ccip->caller&INTEGER_MASK), 
		(int)((ccip->callee>>32)&INTEGER_MASK), 
		(int)(ccip->callee&INTEGER_MASK),
		(int)((ccip->class_id>>32)&INTEGER_MASK), 
		(int)(ccip->class_id&INTEGER_MASK), 
		(int)((ccip->head.msg_id>>32)&INTEGER_MASK), 
		(int)(ccip->head.msg_id&INTEGER_MASK));
	syslog(s);
	printf("%s\n",s);
	free_message_buffer(mb);
	return(-4);
      }
    
    
    if((stp = ApgwSearchSiHash(&site_tbl,GET_SITEID(ccip->callee)))==NULL)
      {
	sprintf(s,"exmessage:Unknown callee site!  caller:0x%08x%08x callee:0x%08x%08x class_id:0x%08x%08x message_id:0x%08x%08x",
		(int)((ccip->caller>>32)&INTEGER_MASK), 
		(int)(ccip->caller&INTEGER_MASK), 
		(int)((ccip->callee>>32)&INTEGER_MASK), 
		(int)(ccip->callee&INTEGER_MASK),
		(int)((ccip->class_id>>32)&INTEGER_MASK), 
		(int)(ccip->class_id&INTEGER_MASK), 
		(int)((ccip->head.msg_id>>32)&INTEGER_MASK), 
		(int)(ccip->head.msg_id&INTEGER_MASK));
	syslog(s);
	printf("%s\n",s);
	free_message_buffer(mb);
	return(-4);
      }


    mb->exid_error_report = ccip->caller&EXID_MASK;

    if((stp->loc == LOCAL_SITE) && (stp->stype==CONSERVATIVE_SITE))
      {
	SendError(mb);
	sprintf(s,"exmessage:Reject invocation to conservative site!  caller:0x%08x%08x callee:0x%08x%08x class_id:0x%08x%08x message_id:0x%08x%08x",
		(int)((ccip->caller>>32)&INTEGER_MASK), 
		(int)(ccip->caller&INTEGER_MASK), 
		(int)((ccip->callee>>32)&INTEGER_MASK), 
		(int)(ccip->callee&INTEGER_MASK),
		(int)((ccip->class_id>>32)&INTEGER_MASK), 
		(int)(ccip->class_id&INTEGER_MASK), 
		(int)((ccip->head.msg_id>>32)&INTEGER_MASK), 
		(int)(ccip->head.msg_id&INTEGER_MASK));
	syslog(s);
	printf("%s\n",s);
	free_message_buffer(mb);
	return(1);
      }
    
    mp = ApgwEnterMtHash(&msg_tbl, ccip->head.msg_id,
			 (ccip->caller & EXID_MASK),
			 (ccip->callee & EXID_MASK));
    if(mp == (MsgTable)0)
      {
	SendError(mb);
	printf("PANIC! Can't expand message table\n");
	return(-5);
      }
    
    sprintf(s,"exmessage:New invocation starts: caller:0x%08x%08x callee:0x%08x%08x class_id:0x%08x%08x message_id:0x%08x%08x",
	    (int)((ccip->caller>>32)&INTEGER_MASK), 
	    (int)(ccip->caller&INTEGER_MASK), 
	    (int)((ccip->callee>>32)&INTEGER_MASK), 
	    (int)(ccip->callee&INTEGER_MASK),
	    (int)((ccip->class_id>>32)&INTEGER_MASK), 
	    (int)(ccip->class_id&INTEGER_MASK), 
	    (int)((ccip->head.msg_id>>32)&INTEGER_MASK), 
	    (int)(ccip->head.msg_id&INTEGER_MASK));
    
    syslog(s);
    printf("%s\n",s);
    SendMessage(mb, mp->callee);
    return(1);
    break;

  case COMM_CALL_ARG:
    cchp	= (CommHead)(mb->buffer);
#ifdef	DEBUG
    printf("### Message kind is CALL_ARG ### => Receive size(%d Bytes)\n", 
	   mb->buffer_size);
    printf("  ArchID: %d, MsgID: 0x%08x%08x\n", 
	   cchp->arch_id, 
	   (int)((cchp->msg_id>>32)&INTEGER_MASK),
	   (int)(cchp->msg_id & INTEGER_MASK));
#endif

    if((mp = ApgwSearchMtHash(&msg_tbl, cchp->msg_id)) == (MsgTable)0) {
      printf("exmessage(call_args): Can't found MessageID(0x%08x%08x) on Message table. Packet discarded\n", 
	     (int)((cchp->msg_id>>32)&INTEGER_MASK),
	     (int)(cchp->msg_id&INTEGER_MASK));
      free_message_buffer(mb);
      break;
    }

    mb->exid_error_report = mp->caller;
    
    SendMessage(mb,mp->callee);

    break;

  case COMM_ABORT:
    cchp	= (CommHead)(mb->buffer);
#ifdef	DEBUG
    printf("### Message kind is ABORT ### => Receive size(%d Bytes)\n", mb->buffer_size);
    printf("  ArchID: %d, MsgID: 0x%08x%08x\n",
	   cchp->arch_id, 
	   (int)((cchp->msg_id>>32)&INTEGER_MASK),
	   (int)(cchp->msg_id & INTEGER_MASK));
#endif

    if((mp = ApgwSearchMtHash(&msg_tbl, cchp->msg_id)) == (MsgTable)0) {
      printf("exmessage(call_abort): Can't found MessageID(0x%08x%08x) on Message table. Packet discarded\n",
	     (int)((cchp->msg_id>>32)&INTEGER_MASK), 
	     (int)(cchp->msg_id&INTEGER_MASK));
      free_message_buffer(mb);
      break;
    }
    msg_id = cchp->msg_id;
    mb->exid_error_report = 0LL;
    SendMessage(mb,mp->callee);
    ApgwRemoveMtHash(&msg_tbl,msg_id);
    sprintf(s,"exmessage(abort): invocation %08x%08x aborted",V_EXID(msg_id));
    syslog(s);
    printf("%s\n",s);
    break;

  case COMM_RESULT:
  case COMM_EXCEPTION:
  case COMM_ERROR:
    cchp	= (CommHead)(mb->buffer);
#ifdef	DEBUG
    printf("### Message kind is Result,Exception or Error ### => Receive size(%d Bytes)\n", mb->buffer_size);
    printf("  ArchID: %d, MsgID: 0x%08x%08x\n",
	   cchp->arch_id, 
	   (int)((cchp->msg_id>>32)&INTEGER_MASK),
	   (int)(cchp->msg_id & INTEGER_MASK));
#endif
    if((mp = ApgwSearchMtHash(&msg_tbl, cchp->msg_id)) == (MsgTable)0) {
      printf("exmessage(result,exception or error): Can't found MessageID(0x%08x%08x) on Message table. Packet discarded\n",
	     (int)((cchp->msg_id>>32)&INTEGER_MASK),
	     (int)(cchp->msg_id&INTEGER_MASK));
      free_message_buffer(mb);
      break;
    }
    msg_id = cchp->msg_id;    
    mb->exid_error_report = 0LL;
    SendMessage(mb, mp->caller);
    if(tail)
      {
	ApgwRemoveMtHash(&msg_tbl,msg_id);
	sprintf(s,"exmessage: invocation %08x%08x finished",V_EXID(msg_id));
	syslog(s);
#ifdef DEBUG
	printf("%s\n",s);
#endif
      }
    break;
    
  default:
    printf("exmessage:Unknow packet (kind %d). Packet discarded\n",kind);
    free_message_buffer(mb);
    break;
  }
}

