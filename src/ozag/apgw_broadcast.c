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
  
#include "apgw.h"
#include "apgw_defs.h"
#include "comm-packets.h"
#include "apgw_sitetbl.h"
#include "apgw_ethash.h"
  
#include "ncl_defs.h"
#include "ex_ncl_event.h"
  
  extern ApgwEnvRec	envofapgw;
extern HashTableRec	ex_tbl;
extern HashTableRec	site_tbl;

extern char		*ipaddr2str(long addr);

extern int		SendRncl(ReceivePort np, long id, char *datap, int size);
extern int		SendApgw(ReceivePort np, int id, char *datap, int size);
extern SiteTable	ApgwSearchSiHash(HashTable hp, int siteid);
extern void		fr_connect_tbl(int fd);
extern void		set_ee_methodaddr(struct sockaddr_in *sin);
extern SiteTable	siteid2apgwaddr(int id, struct sockaddr_in *addr);
extern SiteTable	gt_sitetblrec(int site_id);
extern SendPort  find_send_tbl(long long exid);

AddressRequestWaiterRec  waiting_address_resolve[MAX_APGW_SEND];

extern int one_of_local_site; /* defined in apgw_sitetbl.c */

int 
  get_timeval(struct timeval *tv)
{
  struct timezone time_zone;
  
  time_zone.tz_minuteswest= -(60*9);
  time_zone.tz_dsttime = DST_NONE;
  gettimeofday(tv,&time_zone);
  return(0);
}

int
  init_address_resolve()
{
  bzero(waiting_address_resolve,sizeof(AddressRequestWaiterRec)*MAX_APGW_SEND);
}

int
  send_address_request(long long exid)
{
  EventDataRec   hh;
  int req_site,my_site;
  SiteTable req_stbl,my_stbl;
  SolutAddress sa;
  EventHeader head;
  int i;
  char s[256];
  
  bzero((char *)(&hh), SZ_EventData);
  head = &(hh.head);
  sa = &(hh.data.so_addr);
  head->arch_id = SPARC;
  head->event_num = AG_AR_QUERY;
  sa->unknown_exid = exid;
  
  req_site = GET_SITEID(exid);
  req_stbl = gt_sitetblrec(req_site);
  
  if(req_stbl==0)
    {
      /* update site-table dynamically */
      if((i=update_site_table())<=0)
	{
	  sprintf(s,"Send_address_request:Unknown site(%x)",req_site);
	  printf("%s\n",s);
	  syslog(s);
	  return(1);
	}
      else if((req_stbl = gt_sitetblrec(req_site))==0)
	{
	  syslog("site table updated");
	  sprintf(s,"Send_address_request:Unknown site(%x) after updating site table",req_site);
	  printf("%s\n",s);
	  syslog(s);
	  return(1);
	}
    }
  
  if(req_stbl->loc == LOCAL_SITE)
    {
      head->req_siteid = 0xffff;
      
      sa->req_exid = 0xffff000000000000LL;
      
      /* first argument of SendRncl is not used */
      i=SendRncl((ReceivePort)0,req_site,(char *)&hh, SZ_EventData);
#ifdef BEBUG
      printf("AddressResolve by OZAG:send AG_AR_QUERY to RNCL\n");
#endif
      
      if(i==0)
	return(1); /* error */
      else
	return(0); /* success */
    }
  else
    {
      my_site = one_of_local_site;
      
      head->req_siteid = my_site;
      sa->req_exid = ((long long)my_site )<< 48 ;
      i = SendApgw((ReceivePort)0, req_site,(char *)&hh, SZ_EventData);
#ifdef DEBUG
      printf("AddressResolve by OZAG:send AG_AR_QUERY to OZAG(%x)\n",req_site);
#endif
      if(i==0)
	return(1); /* error */
      else
	return(0); /* success */
    }
}

int
  request_address_resolve(long long exid)
{
  AddressRequestWaiter arw,arwx;
  int flag,i;
  
  for(arw=waiting_address_resolve,i=0,arwx=(AddressRequestWaiter)0;
      i<MAX_APGW_SEND;i++,arw++)
    { if(arw->exid == exid)
	return(0); /* already in address resolution process */
      if(arw->exid == 0)
	{
	  arwx=arw;
	}
    }
  
  if(arwx)
    {
      arwx->exid = exid;
      arwx->retry_count = ADDRESS_RETRY;
      get_timeval(&(arwx->start_time));
      return(send_address_request(exid));
    }
  else
    { return(-1); }
}

void
  free_address_resolve_waiter(long long exid)
{
  AddressRequestWaiter arw;
  int flag,i;
  
  for(arw=waiting_address_resolve,i=0 ;
      i<MAX_APGW_SEND ; i++,arw++)
    { if(arw->exid == exid)
	{
	  arw->exid = 0LL;
	  return;
	}
    }
  return;
}



int
  exceed_time(struct timeval *from, struct timeval *to)
{
  int sec,usec;
  
  usec = to->tv_usec - from->tv_usec;
  sec = to->tv_sec - from->tv_sec;
  if(usec <0)
    { usec += 1000000;
      sec--;
    }
  
  return(sec >= ADDRESS_TIMEOUT);
}

int
  check_timeout(int flag)
{
  AddressRequestWaiter arw;
  struct timeval current_time;
  SendPort sp;
  MessageBuffer mb,mb2;
  int i;
  
  get_timeval(&current_time);
  
  for(arw=waiting_address_resolve,i=0;
      i<MAX_APGW_SEND;i++,arw++)
    { if(arw->exid == 0LL)
	continue;
      
      if(flag || (exceed_time(&(arw->start_time),&current_time)))
	{
	  if((--arw->retry_count)<0)
	    { /* all retrial is failed */
	      sp = find_send_tbl(arw->exid);
	      if(sp != (SendPort)0)
		{
		  for(mb=sp->waiting;mb;)
		    { mb2 = mb->next;
		      mb->next=0;
		      SendError(mb);
		      mb = mb2;
		    }
		  free_send_port(sp);
		  arw->exid=0LL;
		}
	    }
	  else
	    {
	      arw->start_time.tv_sec = current_time.tv_sec;
	      arw->start_time.tv_usec = current_time.tv_usec;
	      if(send_address_request(arw->exid))
		{ /* no way to send request */
		  sp = find_send_tbl(arw->exid);
		  if(sp != (SendPort)0)
		    {
		      for(mb=sp->waiting;mb;)
			{ mb2 = mb->next;
			  mb->next=0;
			  SendError(mb);
			  mb = mb2;
			}
		    }
		  free_send_port(sp);
		}
	    }
	}
    }
  
}



#ifdef	DEBUG
static void     
  msg_monitor(EventData hp, char *kind)
{
  SolutAddress    sop;
  long long       keid;
  long		req_n;
  
  sop	= &(hp->data.so_addr);
  keid	= sop->unknown_exid;
  req_n	= hp->head.req_nclid_sav?hp->head.req_nclid_sav:hp->head.req_nclid;
  printf(" + Received request of address solution: Unkown Exid: %08x%08x\n", V_EXID(keid));
  if(sop->req_exid == 0LL) {
    printf("    Type(%s), Requester(DEBUGGER)\n", kind);
  } else {
    printf("    Type(%s), Requester(Site: %04x, Exid: %06x, ", kind,
	   GET_SITEID(hp->data.so_addr.req_exid), GET_EXID(hp->data.so_addr.req_exid));
    printf("Host: %s)\n", ipaddr2str(req_n));
  }
}

static void     
  msg_monitor1(EventData hp)
{
  BroadcastParam	bpp;
  
  printf(" + Received request of search class&name\n");
  bpp = &(hp->data.sc_name.params);
  printf("   = sender(%08x%08x) id(%x) P1(%08x%08x) P2(%08x)\n", V_EXID(bpp->sender), bpp->id, V_EXID(bpp->param1), bpp->param2);
}
#endif

int      
  aa_broadcast_req(ReceivePort np)
{
  struct sockaddr_in	sin;
  int			size, nb, siteid;
  EventDataRec		hh;
  unsigned long		caller_sid, callee_sid;
  SiteTable		caller_sp, callee_sp;
  BroadcastParam		bpp;
  SolutAddress		dp;
  int rval;
  
  printf("aa_broadcast_req\n");
  
  if((nb = read(np->fd, (char *)&hh, SZ_EventData)) < 0)
    { perror("aa_broadcast_req(read):");
      printf("read returns %d\n",nb);
      return(nb);
    }
  else if(nb==0)
    {
      close(np->fd);
      np->fd=0;
      return(0);
    }
#if 0
  printf("aa_broadcast_req (event_num %d)\n",hh.head.event_num);
#endif
  
  switch(hh.head.event_num) {
  case NCL_NN_PRIMARY:
  case NCL_NN_SECONDARY:
    dp	= &(hh.data.so_addr);
#ifdef	DEBUG
    msg_monitor(&hh, "PRIMARY");
    
#endif
    caller_sid = hh.head.req_siteid;
    if((caller_sp = gt_sitetblrec(caller_sid)) == (SiteTable)0)
      break;
    callee_sid = GET_SITEID(dp->unknown_exid);
    if((callee_sp = gt_sitetblrec(callee_sid)) == (SiteTable)0)
      break;
    
    ApgwEnterEtHash(&ex_tbl, dp->req_exid, &(dp->req_exaddr), ET_INSITE);
    
    hh.head.event_num	= AG_AR_QUERY;
    
    /* modified by Y.H on 9-mar-97
       if(caller_sp->stype == CLOSE_SITE) {
       */
    
    if(1) {
      set_ee_methodaddr(&(dp->req_exaddr));
    }
    
    
    if(callee_sp->loc == LOCAL_SITE) {
      hh.head.req_nclid_sav	= hh.head.req_nclid;
      hh.head.req_nclid	= callee_sp->rnclid;
      SendRncl(np, callee_sid, (char *)&hh, SZ_EventData);
#ifdef  DEBUG
      printf(" + Send message(AG_AR_QUERY) to RNCL(%s) of site(%04x)\n", ipaddr2str(callee_sp->rnclid), callee_sid);
#endif
    } else {
      SendApgw(np, callee_sid, (char *)&hh, SZ_EventData);
#ifdef  DEBUG
      printf(" + Send message(AG_AR_QUERY) to APGW of site(%04x)\n", callee_sid);
#endif
    }
    return(nb);
    break;
    
  case NCL_NN_REPLY:
    dp	= &(hh.data.so_addr);
#ifdef	DEBUG
    msg_monitor(&hh, "REPLY");
#endif
    callee_sid	= GET_SITEID(dp->unknown_exid);
    if((callee_sp = gt_sitetblrec(callee_sid)) == (SiteTable)0)
      break;
    ApgwEnterEtHash(&ex_tbl, dp->unknown_exid, &(dp->address), ET_INSITE);
    
    rval = awake_port(dp->unknown_exid);
    if(rval !=0)
      free_address_resolve_waiter(dp->unknown_exid);
    
    if(dp->req_exid == 0xffff000000000000LL)
      { printf("Delete reply message, because request by myself\n");
	break; /* this adderss request is created by my self */
      }
    
    /* modified by Y.Hamazaki on 9-mar-97
       if(callee_sp->stype == CLOSE_SITE) {
       */
    
    if(1){
      set_ee_methodaddr(&(dp->address));
    }
    
    caller_sid	= (unsigned long)hh.head.req_siteid;
    
#if 0
    printf("test:: siteid %x\n",caller_sid);
#endif
    if((caller_sp = gt_sitetblrec(caller_sid)) == (SiteTable)0)
      break;
    
    hh.head.event_num	= AG_AR_REPLY;
    hh.head.req_nclid	= hh.head.req_nclid_sav;
    hh.head.req_nclid_sav	= 0L;
    if(caller_sp->loc == LOCAL_SITE) {
      SendRncl(np, caller_sid, (char *)&hh, SZ_EventData);
#ifdef  DEBUG
      printf(" + Send message(REPLY) to RNCL(%s) of site(%04x)\n", ipaddr2str(caller_sp->rnclid), caller_sid);
#endif
    } else {
      SendApgw(np, caller_sid, (char *)&hh, SZ_EventData);
#ifdef  DEBUG
      printf(" + Send message(REPLY) to APGW of site(%04x)\n", caller_sid);
#endif
    }
    break;
    
  case AG_AR_QUERY:
    dp	= &(hh.data.so_addr);
#ifdef	DEBUG
    msg_monitor(&hh, "AG_AR_QUERY");
#endif
    ApgwEnterEtHash(&ex_tbl, dp->req_exid, &(dp->req_exaddr), ET_OUTSITE);

    callee_sid = (int)((dp->unknown_exid >>48)&0xffffLL);
    if((callee_sp = gt_sitetblrec(callee_sid)) == (SiteTable)0)
      break;

    hh.head.req_nclid_sav	= hh.head.req_nclid;
    hh.head.req_nclid	= callee_sp->rnclid;

    SendRncl(np, callee_sid, (char *)&hh, SZ_EventData);
#ifdef	DEBUG
    printf(" + Send message(AG_AR_QUERY) to RNCL(%s : %08x)\n", ipaddr2str(callee_sp->rnclid),callee_sp->rnclid);
#endif
    break;
    
  case AG_AR_REPLY:
    dp	= &(hh.data.so_addr);
#ifdef	DEBUG
    msg_monitor(&hh, "AG_AR_REPLY");
#endif
    caller_sid = (unsigned long)hh.head.req_siteid;
    ApgwEnterEtHash(&ex_tbl, dp->unknown_exid, &(dp->address), ET_OUTSITE);
    
    rval = awake_port(dp->unknown_exid);
    if(rval != 0)
      free_address_resolve_waiter(dp->unknown_exid);
    
    if((dp->req_exid & 0x0000ffffffffffffLL)==0)
      { printf("Delete AG_AR_REPLY message, because requested by myself\n");
	break;
      }
    SendRncl(np, caller_sid, (char *)&hh, SZ_EventData);
#ifdef	DEBUG
    printf(" + Send message(AG_AR_REPLY) to RNCL(%s)\n", ipaddr2str(caller_sp->rnclid));
#endif
    break;
    
  case NCL_BC_PRIMARY:
  case NCL_BC_SECONDARY:
#ifdef	DEBUG
    msg_monitor1(&hh);
#endif
    bpp = (BroadcastParam)&(hh.data.sc_name.params);
    if(bpp->param1 != 0LL) {
      callee_sid = GET_SITEID(bpp->param1);
      if((callee_sp = gt_sitetblrec(callee_sid)) == (SiteTable)0)
	break;
      if(callee_sp->loc == LOCAL_SITE) {
	SendRncl(np, callee_sid, (char *)&hh, SZ_EventData);
#ifdef  DEBUG
	printf(" + Send message(SEARCH_C_N) to RNCL(%s) of site(%04x)\n", ipaddr2str(callee_sp->rnclid), callee_sid);
#endif
      } else {
	SendApgw(np, callee_sid, (char *)&hh, SZ_EventData);
#ifdef  DEBUG
	printf(" + Send message(SEARCH_C_N) to APGW of site(%04x)\n", callee_sid);
#endif
      }
    } else {
    }
    break;
  default:
    printf("br_addr_req: Got a illegal data(0x%x), Memory broken?\n", hh.head.event_num);
    return(-1);
  }
  return(nb);
}

