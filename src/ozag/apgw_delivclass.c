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
#include "apgw_ethash.h"

extern  HashTableRec ex_tbl;
extern ApgwEnvRec envofapgw;

extern  ExecTable ApgwSearchEtHash(HashTable hp, long long eid);
#define OzRemoteFileTransferPort 3774

/* signal handler for SIGCHLD */
void
getSIGCHLD()
{
  int pid,status,rval;
  int mask;
  char s[256];

  mask = sigblock( ~0 );

  for(;;)
    {
      pid = wait3(&status,WNOHANG,(struct rusage *)0);

      if(pid <= 0) 
	break;
      if(WIFEXITED(status))
	{
	  rval=WEXITSTATUS(status);
#if 0
	  printf("OzFGW exited with value %d\n",rval);
#endif
	  sprintf(s,"OzFGW: file_transfer process %d finished(%d)\n",pid,rval);
	  syslog(s);
	}
      else
	{
	  printf("OzFGW exited abnormally\n");
	  sprintf(s,"OzFGW: file_transfer process %d finished abnormally\n",pid);
	  syslog(s);
      }
    }

  sigsetmask(mask);
  signal(SIGCHLD,getSIGCHLD); /* set signal again */
  return;
}


int      delivery_class(ReceivePort np)
{
  int pid,zero,i,fd;
  long long destination;
  ExecTable et;
  struct sockaddr_in dest;
  char s[256];


  zero=0;

#if 0
  printf("Deliver class\n");
#endif

  i = read(np->fd,(char *)(&destination),sizeof(long long));
  if(i<sizeof(long long))
    { /* connection disconnected */
      printf("Deliver class: read returns %d\n",i);
      syslog("deliver_class:connection disconnected before getting destination");
      close(np->fd);
      np->fd=0;
      return(0);
    }

#if 0
  printf("DeliverClass: destination %08x%08x\n",
	 (int)((destination>>32)&INTEGER_MASK),
	 (int)(destination&INTEGER_MASK));
#endif

  et = ApgwSearchEtHash(&ex_tbl,destination);
  if(et == (ExecTable)0)
    { /* can't find in executor table */
      write(np->fd,&zero,sizeof(int));
      close(np->fd);
      np->fd=0;
      sprintf(s,"DeliverClass:Can't locate destination %08x%08x\n",
	     (int)((destination>>32)&INTEGER_MASK),
	     (int)(destination&INTEGER_MASK));
      syslog(s);
      printf("%s\n",s);
      return(-2);
    }

  if( (pid = fork()) == 0)
    { /* Child process */
      dup2(np->fd,3);
      for(i=4; i<NOFILE; i++)
	close(i);

      bcopy((char *)(&(et->addr)),(char *)(&dest),sizeof(struct sockaddr_in));
      dest.sin_port = OzRemoteFileTransferPort;

      fd=socket(PF_INET,SOCK_STREAM,0);
      i=connect(fd, &dest,sizeof(struct sockaddr_in));

      if(i<0)
	{ /* can't connect */
	  write(3,&zero,sizeof(int));
	  close(3);
	  close(fd);
	  printf("DeliverClass:Can't connect. OZAG or executor may be out-of-service\n");
	  return(-3);
	}

      if(fd != 4)
	{ dup2(fd,4);
	  close(fd);
	}

      write(4,&destination,sizeof(long long));

      sprintf(s,"%s/bin/OzFGW",envofapgw.ozroot);


      execl(s,"OzFGW",(char *)0);
      /* exec failure */
      perror("OzFGW(execl)");
      write(3,&zero,sizeof(int));
      close(3);
      close(4);
      return(-1);
    }
  else
    {
      sprintf(s,"DeliverClass: source of file %08x%08x (process:%d)\n",
	      (int)((destination>>32)&INTEGER_MASK),
	      (int)(destination&INTEGER_MASK),
	      pid);
      syslog(s);
      close(np->fd);
      np->fd=0;
    }
}
