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
#include "apgw_sitetbl.h"
#include "comm-packets.h"
  
#include "ncl.h"
#include "ncl_defs.h"
#include "ncl_table.h"
#include "apgw_ethash.h"
#include "ex_ncl_event.h"
  
extern	int	errno;

extern  HashTableRec ex_tbl;
extern  ExecTable ApgwSearchEtHash(HashTable hp, long long eid);

ApgwEnvRec	envofapgw;

extern int aa_broadcast_req(ReceivePort np);
extern int ee_method_call(ReceivePort np);
extern int delivery_class(ReceivePort np);

extern void command_parser(char *command);

AcceptPortRec	event_act[] = {
  { 0, 0, aa_broadcast_req, "oz-broadcast-gw" },
  { 0, 0, ee_method_call, "oz-mcall-gw" },
  { 0, 0, delivery_class, "oz-delivc-gw" }
};

FILE *logfile;

#define APGW_PORT_NUM	(sizeof(event_act)/sizeof(AcceptPortRec))


SendPortRec     apgw_send_tbl[MAX_APGW_SEND];
ReceivePortRec	apgw_receive_tbl[MAX_APGW_RECEIVE];

unsigned int sequence_number;

MessageBuffer free_message_buffers;
int           number_of_free_msgbuff;

extern void		init_site_table();
extern int		init_localsite_info();
extern int		init_executor_table();
extern int		init_message_table();
extern SiteTable	siteid2apgwaddr(int id, struct sockaddr_in *addr);
extern SiteTable	siteid2rncladdr(int id, struct sockaddr_in *addr);
extern void getSIGCHLD();
void close_logfile();
void syslog(char *message);
/*                                      */
/* buffer management for message buffer */
/*                                      */
int
init_message_buffers()
{
  int i;
  MessageBuffer mb,mb2;

  free_message_buffers = (MessageBuffer)0;
  number_of_free_msgbuff = 0;

  for(i=0;i<MAX_MESSAGE_BUFFER_RESERVE;i++)
    {
      mb = free_message_buffers;
      free_message_buffers = (MessageBuffer)malloc(SZ_MsgBuff);
      if(free_message_buffers == (MessageBuffer)0)
	{ /* on failure of memory allocation */
	  printf("init_message_buffers: Can't allocate enought buffer\n");
	  for(; mb ; mb=mb2)
	    {
	      mb2 = mb->next;
	      free((char *)mb);
	    }
	  return(1); /* error */
	}
      else
	{
	  bzero((char *)free_message_buffers, SZ_MsgBuff);
	  free_message_buffers->next = mb;
	  number_of_free_msgbuff++;
	}
    }
  return(0); /* success */
}

MessageBuffer
  get_message_buffer()
{
  MessageBuffer mb;
  
  if(number_of_free_msgbuff >0)
    {
      mb = free_message_buffers;
      free_message_buffers = free_message_buffers->next;
      mb->next = (MessageBuffer)0;
      number_of_free_msgbuff--;
      return(mb);
    }
  else
    {
      mb=(MessageBuffer)malloc(SZ_MsgBuff);
      if(mb == (MessageBuffer)0)
	{ /* fail to memory allocate */
	  printf("Can't allocate now message buffer\n");
	}
      else
	{
	  bzero((char *)mb,SZ_MsgBuff);
	}
      return(mb);
    }
}

void
  free_message_buffer(MessageBuffer mb)
{
  MessageBuffer mbp;
  
  if(number_of_free_msgbuff < MAX_MESSAGE_BUFFER_RESERVE)
    { /* keep it for reuse */
      bzero((char *)mb,SZ_MsgBuff);
      mbp = free_message_buffers;
      free_message_buffers = mb;
      free_message_buffers->next = mbp;
      number_of_free_msgbuff++;
    }
  else
    { /* free it because enough reserved buffer exists*/
      free((char *)mb);
    }
}

/* misc routines */
int	
  strhtoi(char *str)
{
  int		n, i;
  unsigned int	m, g;
  char		*p;
  
  static char	hd[] = "0123456789abcdef";
  
#if	0
  if(strncmp(str, "0x", 2)) {
    for(p=str; *p!=0x00; p++)
      if(isdigit(*p) == 0) return(-1);
    return(atoi(str));
  }
  
  p = str + 2;
#endif
  p = str;
  for(n=(strlen(p)-1),m=1,g=0; n>=0; n--, m*=16) {
    for(i=0; i<16; i++) {
      if(*(p+n) == hd[i]) {
	g += (m * i);
	break;
      }
    }
    if(i==16) return(-1);
  }
  return((int)g);
}

char	
  *ipaddr2str(long addr)
{
  struct hostent	*hep;
  unsigned long	l;
  
  hep 	= gethostbyaddr((char *)&(addr), sizeof(long), AF_INET);
  if((int)hep) {
    strcpy(envofapgw.tmpbuf, hep->h_name);
  } else {
    l = addr;
    sprintf(envofapgw.tmpbuf, "%d.%d.%d.%d", l>>24,(l>>16)&0xff,(l>>8)&0xff, l&0xff);
  }
  return(envofapgw.tmpbuf);
}

char	
  *ntime(char *dp)
{
  struct tm       *tmp;
  long		tm;
  
  time(&tm);
  tmp     = localtime(&tm);
  sprintf(dp, "%02d/%02d/%02d", tmp->tm_year, tmp->tm_mon+1,tmp->tm_mday);
  sprintf(dp+8, " %02d:%02d:%02d", tmp->tm_hour,tmp->tm_min,tmp->tm_sec);
  return(dp);
}

long	
hostn2addr(char *hostn)
{
  struct hostent	*hp;
  long		addr;
  
  addr = inet_addr(hostn);
  if (addr == (-1)) {
    if (!(hp = gethostbyname(hostn))) {
      fprintf(stderr, "hostn2addr: unknown host(%s)\n", hostn);
      return(0);
    }
    bcopy(hp->h_addr, &addr, sizeof(long));
  }
  return(addr);
}

void	
end_apgw()
{
  AcceptPort		ap, ep;
  
  for(ap=event_act, ep=ap + APGW_PORT_NUM; ap<ep; ap++) {
    close(ap->fd);
  }

  syslog("Application gateway terminated!");
  close_logfile();

  exit(0);
}

#ifdef	DEBUG
int	p_offset[10] = { AA_BROADCAST, EE_METH_CALL, DELIV_CLASS };
#endif

static void	
init_apgw_port()
{
  int			i;
  struct sockaddr_in	sin;
  struct servent		*sp;
  AcceptPort		ap, ep;
  
  bzero((char *)&sin, sizeof(sin));
  for(ap=event_act, ep=ap + APGW_PORT_NUM, i=0; ap<ep; ap++,i++) {
    /*
      if((sp = getservent(ap->service_name, "tcp")) == (struct servent *)NULL) {
      fprintf(stderr, "init_apgw_port: unknown service %s\n", ap->service_name);
      exit(1);
      }
      ap->sin_port	= sp->s_port;
      */

    ap->sin_port	= (unsigned short)PROVISIONAL_PORT - p_offset[i] - 1;

#if DEBUG /* 0 */
    printf("service_name: %-15s   port: %d\n", ap->service_name, ap->sin_port);
#endif
    sin.sin_family	= AF_INET;
    sin.sin_port	= ap->sin_port;
    
    if ((ap->fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
      perror("init_apgw_port: socket");
      exit(1);
    }
    if (bind(ap->fd, &sin, sizeof(sin)) < 0) {
      perror("init_apgw_port: bind");
      (void)fprintf(stderr, "init_apgw_port: Other Apgw start up already ?\n");
      exit(1);
    }
    listen(ap->fd, 5);
  }
}

/*                         */
/* select related routines */
/*                         */
static void	
SetAcceptFd(fd_set *rfds)
{
  AcceptPort		ap, ep;
  
  for(ap=event_act, ep=ap + APGW_PORT_NUM; ap<ep; ap++) {
    FD_SET(ap->fd, rfds);
  }
}

static AcceptPort
FdIsSetAccept(fd_set *rfds)
{
  AcceptPort		ap, ep;
  
  for(ap=event_act, ep=ap + APGW_PORT_NUM; ap<ep; ap++) {
    if(FD_ISSET(ap->fd, rfds))
      { FD_CLR(ap->fd,rfds); /* hamazaki modify */
	return(ap); }
  }
  return(0);
}

static void	
SetReceiveFd(fd_set *rfds)
{
  int		i;
  ReceivePort	np;
  
  for(i=0,np=apgw_receive_tbl; i<MAX_APGW_RECEIVE; i++,np++) {
    if(np->fd == 0) continue;
    
    FD_SET(np->fd, rfds);
  }
}

static ReceivePort
FdIsSetReceive(fd_set *rfds)
{
  int		i;
  ReceivePort	np;
  
  for(i=0,np=apgw_receive_tbl; i<MAX_APGW_RECEIVE; i++,np++) {
    if(np->fd == 0) continue;
    
    if(FD_ISSET(np->fd, rfds))
      { FD_CLR(np->fd,rfds); /* hamazaki modify */
	return(np); }
  }
  return(0);
}

static void
SetSendFd(fd_set *rfds)
{
  int		i;
  SendPort	np;
  
  for(i=0,np=apgw_send_tbl; i<MAX_APGW_SEND; i++,np++) {
    if(np->fd == 0) continue;
    
    FD_SET(np->fd, rfds);
  }
}

static SendPort
FdIsSetSend(fd_set *rfds)
{
  int		i;
  SendPort	np;
  
  for(i=0,np=apgw_send_tbl; i<MAX_APGW_SEND; i++,np++) {
    if(np->fd == 0) continue;
    
    if(FD_ISSET(np->fd, rfds))
      { FD_CLR(np->fd,rfds); /* hamazaki modify */
	return(np); }
  }
  return(0);
}

/* */

SendPort 
find_send_tbl(long long exid)
{
  SendPort sp;
  int i;

  for(i=0,sp=apgw_send_tbl;i<MAX_APGW_SEND;i++,sp++)
    {
      if(sp->exid == exid)
	return(sp);
    }
  return((SendPort)0);
}

void
free_send_port(SendPort sp)
{
  sp->fd=0;
  sp->exid=0LL;
  sp->waiting = (MessageBuffer)0;
  return;
}

static ReceivePort
gt_receive_tbl()
{
  int		i;
  ReceivePort	np;
  
  for(i=0,np=apgw_receive_tbl; i<MAX_APGW_RECEIVE; i++,np++) {
    if(np->fd) continue;
    return(np);
  }
  printf("gt_receive_tbl: %s: Connection table full\n");
  return((ReceivePort)0);
}

/* return value : positive=success, negative=error, zero=table-full */
static int
set_receive_tbl(AcceptPort ap, int flag)
{
  struct sockaddr_in	sin;
  int			size, n, i;
  ReceivePort		np;
  
  size	= sizeof(sin);
  bzero((char *)&sin, size);
  n	= accept(ap->fd, (struct sockaddr *)&sin, &size);
  if(n<0) {
    perror("st_receive_tbl: accept: ");
    return(-1);
  }
  for(i=0,np=apgw_receive_tbl; i<MAX_APGW_RECEIVE; i++,np++) {
    if(np->fd) continue;
    np->ap = ap;
    np->fd = n;
    np->disconnect_flag=flag;
    return(n);
  }
  return(0);
}

void	
fr_receive_tbl(int fd)
{
  int		n, i;
  ReceivePort	np;
  
  for(i=0,np=apgw_receive_tbl; i<MAX_APGW_RECEIVE; i++,np++) {
    if(np->fd == 0 || np->fd != fd) continue;
    
    np->fd	= 0;
    np->ap	= (AcceptPort)0;
    close(fd);
    return;
  }
}

/* check closure of send-port connection */
/* This routine detect sudden shutdown of receiver side */
void
send_checker(SendPort sp)
{
  int rval;
  char buff[32];
  MessageBuffer mb1,mb2;

  rval = read(sp->fd,buff,32);
  close(sp->fd);
  sp->fd=0;
  sp->exid=0LL;
  sp->last_access=0;

  if(sp->waiting != (MessageBuffer)0)
    { /* this part will not be executed (if no bug) */
      mb1=sp->waiting;
      sp->waiting=(MessageBuffer)0;
      for(;mb1;)
	{ mb2=mb1->next;
	  mb1->next=0;
	  SendError(mb1);
	  mb1=mb2;
	}
    }


  return;
}

/* last_access control */
/* Use counter 'last_access' to implement Least Reacently Used */
void
  refresh_last_access()
{
  unsigned int work_last_access, new_sequence,w;
  SendPort sp;
  ReceivePort rp;
  int i;
  
  for(work_last_access=LARGE_UINT,sp=apgw_send_tbl,i=0;
      i<MAX_APGW_SEND; i++,sp++)
    if((sp->fd) && (sp->last_access <work_last_access))
      work_last_access = sp->last_access;
  for(rp=apgw_receive_tbl,i=0;
      i<MAX_APGW_RECEIVE; i++,rp++)
    if((rp->fd) && (rp->last_access <work_last_access))
      work_last_access = rp->last_access;
  
  for(new_sequence=0,sp=apgw_send_tbl,i=0;
      i<MAX_APGW_SEND; i++,sp++)
    { if(sp->fd)
	{
	  sp->last_access -= work_last_access;
	  if(sp->last_access >new_sequence)
	    new_sequence = sp->last_access;
	}}
  
  for(rp=apgw_receive_tbl,i=0;
      i<MAX_APGW_RECEIVE; i++,rp++)
    { if(rp->fd)
	{
	  rp->last_access -= work_last_access;
	  if(rp->last_access >new_sequence)
	    new_sequence = rp->last_access;
	}}
  
  sequence_number = new_sequence;
  return;
}

void
  set_last_access_send(SendPort sp)
{
  if(++sequence_number == 0)
    {
      sp->last_access = LARGE_UINT;
      refresh_last_access();
    }
  sp->last_access = sequence_number;
  return;
}

void
  set_last_access_receive(ReceivePort rp)
{
  if(++sequence_number == 0)
    {
      rp->last_access = LARGE_UINT;
      refresh_last_access();
    }
  rp->last_access = sequence_number;
  return;
}


/* send disconnect request on receiver port */
void
  send_disconnect_request(int count)
{
  ReceivePort rp,rpx;
  int i;
  unsigned int lowest;
  
  for(;count;count--)
    {
      for(rp=apgw_receive_tbl,i=0 ,lowest=LARGE_UINT ,rpx=(ReceivePort)0;
	  i<MAX_APGW_RECEIVE ; rp++,i++)
	{
	  if(rp->fd && !(rp->disconnect_flag) && (rp->last_access<lowest))
	    {
	      lowest = rp->last_access;
	      rpx = rp;
	    }
	  if(rpx)
	    {
	      write(rp->fd,"e",1);
	      rp->disconnect_flag=2;
	    }
	}
    }
  return;
}


/* send object-communication packet */
void 
SendMessage(MessageBuffer mb, long long destination)
{
  ExecTable et;
  SendPort sp,spe,free_sp;
  MessageBuffer mbp;
  int i,flag,rval;
  unsigned int least_access;

#if 0
  printf("SendMessage enter\n");
#endif

  /* find send port already assigned */
  for(i=0,flag=0,free_sp=(SendPort)0,sp=apgw_send_tbl;i<MAX_APGW_SEND;i++,sp++)
    {
      if(sp->exid == destination)
	{
	  flag=1;
	  break;}
      if(sp->exid==0LL)
	{
	  free_sp =sp;
	}
    }
  
  if(flag)
    { /* Send Port exists */
      if(sp->fd != 0)
	{ /* found connected port */
	  
	  if((i = write(sp->fd, (char *)(&(mb->buffer_size)),sizeof(int))) <sizeof(int))
	    { /* error */
	      perror("SendMessage(write):");
	      SendError(mb);
	      free_send_port(sp);
	      return;
	    }
	  if((i = write(sp->fd, mb->buffer, mb->buffer_size)) < mb->buffer_size)
	    { /* error */
	      perror("SendMessage(write):");
	      SendError(mb);
	      free_send_port(sp);
	      return;
	    }
	  set_last_access_send(sp);
	  free_message_buffer(mb);
#if 0
	  printf("Message sent using connected send port\n");
#endif
	  return;
	}
      else if(sp->waiting != (MessageBuffer)0)
	{ /* send port is waiting for address resolution */
	  for(mbp=sp->waiting;
	      mbp->next != (MessageBuffer)0;mbp=mbp->next)
	    ;
	  mbp->next=mb;
#if 0
	  printf("message is appended on waiting port\n");
#endif
	  return;
	}
      else
	{ /* if reach here, it's bug */
	  printf("Invalid send port ?? sp(%x) fd(%x) waiting(%x) exid(%08x%08x)\n",
		 sp,sp->fd,sp->waiting,
		 (int)(((sp->exid)>>32)&INTEGER_MASK),
		 (int)((sp->exid)&INTEGER_MASK));
	  return;
	}
    }
  else
    {
      if(!free_sp)
	{
	  for(free_sp=(SendPort)0,sp=apgw_send_tbl,least_access=LARGE_UINT,i=0;
	      i<MAX_APGW_SEND;i++,sp++)
	    {
	      if((sp->waiting ==(MessageBuffer)0) 
		 && (sp->last_access <least_access))
		{
		  free_sp=sp;
		  least_access = sp->last_access;
		}
	    }
	  if(!free_sp)
	    {
	      printf("PANIC! No free send port\n");
	      SendError(mb);
	      return;
	    }
	  else
	    { /* reuse send port */
	      close(free_sp->fd);
#if 0
	      printf("reuse send port\n");
#endif
	    }
	}
      sp=free_sp;
      sp->exid = destination;
      sp->fd=0;
      sp->waiting=(MessageBuffer)0;
      
      et = ApgwSearchEtHash(&ex_tbl,destination);
      if(et != (ExecTable)0)
	{ /* found in executor table */
	  bcopy((char *)(&(et->addr)),(char *)(&(sp->addr)),
		sizeof(struct sockaddr_in));
	  sp->fd = socket(PF_INET,SOCK_STREAM,0);
	  rval = connect(sp->fd,(struct sockaddr *)(&(sp->addr)),
			 sizeof(struct sockaddr_in));
	  if(rval <0)
	    { /* fail to connect */
	      close(sp->fd);
	      sp->fd=0;
	      ApgwRemoveEtHash(&ex_tbl,destination);
	    }
	  else
	    {
	      if((i = write(sp->fd, (char *)(&(mb->buffer_size)),sizeof(int))) <sizeof(int))
		{ /* error */
		  perror("SendMessage(write):");
		  SendError(mb);
		  free_send_port(sp);
		  return;
		}
	      if((i = write(sp->fd, mb->buffer, mb->buffer_size)) < mb->buffer_size)
		{ /* error */
		  perror("SendMessage(write):");
		  SendError(mb);
		  free_send_port(sp);
		  return;
		}
	      set_last_access_send(sp);
	      free_message_buffer(mb);
#if 0
	      printf("Message sent\n");
#endif
	      return;
	    }
	}

      if(sp->fd == 0)
	{
#if 0
	  printf("No valid destination address, try to resolve\n");
#endif
	  sp->waiting = mb;
	  if(request_address_resolve(destination))
	    { /* No way to resolve address */
	      printf("Fail to request address resolve\n");
	      SendError(mb);
	      free_send_port(sp);
	    }
	}

    }
  return;
}






/* awaik send port which waiting address resolve */
int
awake_port(long long exid)
{
  SendPort sp;
  ExecTable et;
  MessageBuffer mb,mb2;
  int rval,flag,i;

  sp = find_send_tbl(exid);
  if(sp && sp->waiting)
    {
      et = ApgwSearchEtHash(&ex_tbl,exid);
      if(et == 0)
	return(0); /* fail to address resolve */
      bcopy((char *)(&(et->addr)),(char *)(&(sp->addr)),
	    sizeof(struct sockaddr_in));
      sp->fd = socket(PF_INET,SOCK_STREAM,0);
      rval = connect(sp->fd,(struct sockaddr *)(&(sp->addr)),
		     sizeof(struct sockaddr_in));
      if(rval <0)
	{ /* fail to connect */
	  close(sp->fd);
	  sp->fd=0;
	  ApgwRemoveEtHash(&ex_tbl,exid);
	  return(0); /* fail to connect */
	}
      else
	{ /* success to connect */
	  for(mb=sp->waiting,flag=0; mb && !flag ;)
	    {
	      mb2 = mb->next;
	      
	      if((i = write(sp->fd, (char *)(&(mb->buffer_size)),sizeof(int))) <sizeof(int))
		{ /* error */
		  close(sp->fd);
		  sp->fd=0;
		  flag=1;
		}
	      else if((i = write(sp->fd, mb->buffer, mb->buffer_size)) < mb->buffer_size)
		{ /* error */
		  close(sp->fd);
		  sp->fd=0;
		  flag=1;
		}
	      mb=mb2;
	    }
	  if(!flag)
	    {
	      set_last_access_send(sp);
	      for(mb = sp->waiting;mb;)
		{
		  mb2 = mb->next;
		  free_message_buffer(mb);
		  mb = mb2;
		}
	      sp->waiting = (MessageBuffer)0;
#if 0
	      printf("Success to address resolve. All data sent\n");
#endif
	      return(1); /* success */
	   }
	  else
	    return(0); /* error */
	}
    }
  else
    return(-1); /* do nothing */
}



int	
SendRncl(ReceivePort gnp, int siteid, char *datap, int size)
{
  int			fd;
  struct sockaddr_in	peer;
  ReceivePort		np;
  SiteTable		stp;
  
  if((stp = siteid2rncladdr(siteid, &peer)) == (SiteTable)0) {
    printf("SendRncl: Can't found SiteID(0x%04x) on site-table\n", siteid);
    return(-1);
  }
  if((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("SendRncl: socket:");
    return(-1);
  }
  if(connect(fd, (struct sockaddr *)&peer, sizeof(peer)) < 0) {
    perror("SendRncl: connect:");
#ifdef	DEBUG
    printf(" + Relay nucleus(%s) is not active?\n", ipaddr2str(stp->rnclid));
#endif
    return(-1);
  }
  if(write(fd, datap, size) < 0) {
    perror("SendRncl: write:");
#ifdef	DEBUG
    printf(" + Relay nucleus(%s) is not active?\n", ipaddr2str(stp->rnclid));
#endif
    return(-1);
  }

  close(fd);
  return(fd);
}

/* send packet (broadcast) to AGPG */
int	
SendApgw(ReceivePort gnp, int siteid, char *datap, int size)
{
  int			fd;
  struct sockaddr_in	peer;
  ReceivePort		np;
  SiteTable		stp;
  
  if((stp = siteid2apgwaddr(siteid, &peer)) == (SiteTable)0) {
    printf("SendApgw: Site-ID(%04x) not found on SITE table\n", siteid);
    return(0);
  }
  if((fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("SendApgw: socket");
    return(0);
  }
  if(connect(fd, (struct sockaddr *)&peer, sizeof(peer)) < 0) {
    perror("SendApgw: connect");
#ifdef	DEBUG
    printf(" + APGW(%s) of other site(%04x) is not active?\n", ipaddr2str(stp->apgwaddr), siteid);
#endif
    return(0);
  }
  if(write(fd, datap, size) < 0) {
    perror("SendApgw: write");
#ifdef	DEBUG
    printf(" + APGW(%s) of other site(%04x) is not active?\n", ipaddr2str(stp->apgwaddr), siteid);
#endif
    return(0);
  }
#if	0
  np	= gt_receive_tbl();
  np->ap	= gnp->ap;
  np->fd	= fd;
#endif
  close(fd);
  return(fd);
}


int 
count_free_rport()
{
  ReceivePort rp;
  int i,free;

  for(rp=apgw_receive_tbl,i=0,free=0;i<MAX_APGW_RECEIVE;i++,rp++)
    {
      if(rp->fd == 0)
	free++;
    }
  return(free);
}




static void	
accept_event()
{
  AcceptPort	ap;
  ReceivePort	rp;
  SendPort      sp;

  int		nfd;
  char		ntm[128];
  fd_set		rfds;
  struct timeval timeout;
  int free_rport_num;
  char s[256];
  int *ip;

  /* for console input */
  char command[256];
  int cmd_len;

  bzero((char *)apgw_receive_tbl, sizeof(ReceivePortRec)*MAX_APGW_RECEIVE);

  for(;;) {
    fflush(stdout);

    FD_ZERO(&rfds);
    SetAcceptFd(&rfds);
    SetReceiveFd(&rfds);
    SetSendFd(&rfds);
    
    /* for console input */
    FD_SET(0,&rfds);

    timeout.tv_sec= ADDRESS_TIMEOUT;
    timeout.tv_usec=0;
#if 0
    printf("accept_event: top\n");
#endif
    
    nfd = select(getdtablesize(), &rfds, NULL, NULL, &timeout);
    if(nfd < 0) 
      {
	perror("APGW> select: ");
	if(errno==EINTR)
	  continue;
	ip = (int *)(&rfds);
	sprintf(s,"select error nfd=%d, rfds=%08x %08x %08x %08x %08x %08x %08x %08x",
		nfd,ip[0],ip[1],ip[2],ip[3],ip[4],ip[5],ip[6],ip[7]);
	syslog(s);

	FD_ZERO(&rfds);
	sprintf(s,"FD_ZERO      rfds=%08x %08x %08x %08x %08x %08x %08x %08x",
		ip[0],ip[1],ip[2],ip[3],ip[4],ip[5],ip[6],ip[7]);
	syslog(s);
	SetAcceptFd(&rfds);
	sprintf(s,"SetAcceptFd  rfds=%08x %08x %08x %08x %08x %08x %08x %08x",
		ip[0],ip[1],ip[2],ip[3],ip[4],ip[5],ip[6],ip[7]);
	syslog(s);
	SetReceiveFd(&rfds);
	sprintf(s,"SetReceiveFd rfds=%08x %08x %08x %08x %08x %08x %08x %08x",
		ip[0],ip[1],ip[2],ip[3],ip[4],ip[5],ip[6],ip[7]);
	syslog(s);
	SetSendFd(&rfds);
	sprintf(s,"SetSendFd    rfds=%08x %08x %08x %08x %08x %08x %08x %08x",
		ip[0],ip[1],ip[2],ip[3],ip[4],ip[5],ip[6],ip[7]);
	syslog(s);
	
	break;
      }
    else if(nfd>0)
      {
#if 0
	ip = (int *)(&rfds);
	sprintf(s,"select OK nfd=%d, rfds=%08x %08x %08x %08x %08x %08x %08x %08x",
		nfd,ip[0],ip[1],ip[2],ip[3],ip[4],ip[5],ip[6],ip[7]);
	syslog(s);
#endif

	/* for console input */
	if(FD_ISSET(0,&rfds))
	  {
	    FD_CLR(0,&rfds);
	    bzero(command,256);
	    if((cmd_len = read(0,command,256))<=0)
	      { /* ignore */
		continue;
	      }
	    command[cmd_len-1]='\0';
	    command_parser(command);
	  }


	while(sp= FdIsSetSend(&rfds))
	  {
	    send_checker(sp);
	  }
	
	while(rp= FdIsSetReceive(&rfds))
	  {
#if DEBUG
	    printf("receive event: rp=(%x)\n",(int)rp);
#endif
	    if((*(rp->ap->func))(rp) < 0)
	      {
		printf("error occuerd at %s\n",rp->ap->service_name);
	      }
	  }
	
	free_rport_num = count_free_rport();
	
	while((ap = FdIsSetAccept(&rfds)) && (free_rport_num>0))
	  {
	    if(ap == &(event_act[1]))
	      set_receive_tbl(ap,0);
	    else
	      set_receive_tbl(ap,1);
	    free_rport_num--;
#ifdef DEBUG
	    printf("Connection accept(%s)\n", ap->service_name);
#endif
	  }

	if(free_rport_num < TOO_FEW_FREE_RPORT)
	  send_disconnect_request(TOO_FEW_FREE_RPORT - free_rport_num);

	check_timeout(0);
      }
    else
      {
	check_timeout(1);
      }
  }
}

  static void	init_apgwopt(int argc, char *argv[])
{
  int		i;
  struct hostent	*hp;
  char		*p;
  char		buf[32];
  
  bzero((char *)&envofapgw, sizeof(ApgwEnvRec));
  gethostname(buf, 32);
  if (!(hp = gethostbyname(buf))) {
    fprintf(stderr, "init_apgwopt: %s: unknown host\n", buf);
    exit(1);
  }
  bcopy(hp->h_addr, &(envofapgw.apgwid), sizeof(long));
  
  if((p = (char *)getenv("OZROOT")) == (char *)NULL) {
    (void)printf("init_apgwopt: Please set enveronment value OZROOT\n
");
    exit(1);
  }
  strcpy(envofapgw.ozroot, p);
}

main(int argc, char *argv[])
{
  init_apgwopt(argc, argv);
  
  printf("################################################################################\n");
  printf("# Copyright(c) 1994,1995,1996,1997 Information-technology Promotion Agency, Japan   #\n");
  printf("#                                                                              #\n");
  printf("# All rights reserved. No guarantee.                                           #\n");
  printf("# This technology is a result of the Open Fundamental Software Technology      #\n");
  printf("# Project of Information-technology Promotion Agency, Japan(IPA).              #\n");
  printf("################################################################################\n");
  printf("### OZ++ System Application GateWay(Version 1.0) Started ###\n");
  
  init_site_table();
  if(init_localsite_info())
    exit(1);
  if(init_executor_table())
    exit(1);
  if(init_message_table())
    exit(1);

  if(create_logfile())
    exit(1);

  init_apgw_port();
  init_message_buffers();
  init_address_resolve();

  
  signal(SIGPIPE, SIG_IGN);
  signal(SIGHUP, end_apgw);
  signal(SIGTERM, end_apgw);
  
  signal(SIGCHLD, getSIGCHLD);

  syslog("Application Gateway started!");

  accept_event();
}


/* logging */

int
create_logfile()
{
  time_t currentTime;
  char logfile_name[256];

  if((currentTime=time(0))<0)
    {
      perror("get time in creating logfile");
      return(-1);
    }

  sprintf(logfile_name,"%s/etc/AG%08x.log",envofapgw.ozroot,currentTime);

  if((logfile = fopen(logfile_name,"w"))== (FILE *)NULL)
    {
      perror("Can't open log file :");
      return(-1);
    }
  else
    {
      printf("Log file is %s\n",logfile_name);
      return(0);
    }
}

void
close_logfile()
{
  fclose(logfile);
}


void
syslog(char *message)
{
  time_t currentTime;
  char time_str[26];

  currentTime = time(NULL);
  strcpy(time_str,ctime(&currentTime));
  time_str[24]='\0';
  fprintf(logfile,"[%s] %s\n",time_str,message);
  fflush(logfile);
}
