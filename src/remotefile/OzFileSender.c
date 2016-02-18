/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "remotefile.h"

int acceptPort;
struct sockaddr dummy_addr;
int dummy_len;
int s;
char socketDescriptor[10];

int
init_port()
{
  struct sockaddr_in AcceptPortAddress;
  int fd,sockopt;

  AcceptPortAddress.sin_port = OzRemoteFileTransferPort;
  AcceptPortAddress.sin_family = AF_INET;
  AcceptPortAddress.sin_addr.s_addr = INADDR_ANY;

  if( (fd = socket(PF_INET,SOCK_STREAM,0)) < 0)
    {
      perror("OzFileSender(create socket)");
      printf("socket create failure\n");
      return(-1);
    }
  sockopt=1;
  setsockopt(fd,6,TCP_NODELAY,(char *)&sockopt,4);
  setsockopt(fd,SOL_SOCKET,SO_KEEPALIVE,(char *)&sockopt,4);

  if( bind(fd,(struct sockaddr *)&AcceptPortAddress,sizeof(struct sockaddr_in)) <0)
    { 
      perror("OzFileSender(bind)");
      printf("socket bind failure\n");
      close(fd);
      return(-1);
    }
  else if(listen(fd,5)<0)
    {
      perror("OzFileSender(listen)");
      printf("socket listen failure\n");
      close(fd);
      return(-1);
    }
  else
    return(fd);
}

void
finish()
{
  close(acceptPort);
  printf("Interrupted. Terminate OzFileSender\n");
  exit(1);
}


void 
  getSIGCHLD()
{
  int pid,status;
  int returnedValue;
  int mask;

  mask = sigblock( ~0 );
#ifdef OFRdDEBUG
	      printf("getSIGCHLD started: (previous mask is %d)\n",mask);
#endif

  for(;;)
    {
      /* check conditions of terminated child process without blocking */
      pid=wait3(&status,WNOHANG,(struct rusage *)0); 
      
      /* if no terminated child exist, break */
      if(pid <= 0)
	break;

      if(WIFEXITED(status))
	{
	  if( (returnedValue = (signed char)WEXITSTATUS(status)) != 0)
	    { /* child terminated unsuccessfully */
#ifdef OFSdDEBUG
		printf("error (OzFS exited unsuccessfully.\n");
#endif
	    }
	}
      else
	{/* exceptional termination of child process */
#ifdef OFSdDEBUG
	  if(WIFSIGNALED(status))
	    {
	      printf("OzFS is terminated by signal %d\n",WTERMSIG(status));
	    }
	  else
	    {
	      printf("OzFS is not terminated nor signaled.\n");
	    }
	  printf("Unexpected termination of OzFS.\n");
#endif
      }
  }

  sigsetmask(mask);
#ifdef OFSdDEBUG
  printf("end of getSIGCHLD (sigsetmask(%d))\n",mask);
#endif
  return;
  /* end of getSIGCHLD, signal handler for SIGCHLD */
}


int
main()
{

  int zero, i, pid;
  char *cp;
  struct tm tm;
  struct timeval tv;
  struct sigvec sigvec1,sigvec2;

  /* signal for SIGCHLD */
  signal(SIGCHLD,getSIGCHLD);
  /* reset SV_RESETHAND bit of sv_flags */
  /* SIGCHLD is treated at getSIGCHLD as many as SIGCHLD occured */
  sigvec(SIGCHLD,(struct sigvec *)0,&sigvec1);
  sigvec1.sv_flags &= (~(SV_RESETHAND));
  sigvec(SIGCHLD,&sigvec1,&sigvec2);


  zero = 0;

  if( (cp = (char *)getenv("OZROOT")) == (char *)NULL)
    {
      printf("OzFileSender: Please set environment value OZROOT\n");
      return(-2);
    }
  else
    {
      if(chroot(cp)<0)
	{
	  perror("OzFileSender");
	  return(-2);
	}
      chdir("/");
    }

  if( (acceptPort = init_port() )<0)
    {
      printf("Can't create listen port\n");
      return(-1);
    }

  signal(SIGHUP,finish);
  signal(SIGINT,finish);
  signal(SIGTERM,finish);
  signal(SIGQUIT,finish);

  gettime(&tm,&tv);
  printtime(&tm,&tv);
  printf("(UST) :: OzFileSender started!\n");

  for(;;)
    {

#ifdef OFSdDEBUG
      printf("acceptPort %d: \n",acceptPort);
#endif

      s = accept(acceptPort,&dummy_addr,&dummy_len);
      if(s<0)
	{
	  if(errno != EINTR)
	    {
	      perror("OzFileSender(accept)");
	      printf("Accept error : errno = %d \n",errno);
	      break;
	    }
	  else
	    continue;
	}
      
      if( (pid = fork()) == 0)
	{
	  for(i=3;i<NOFILE;i++)
	    if(i!=s)
	      close(i);
#ifdef OFSdDEBUG
	  printf("OzFileSender ( execl : %d)\n",s);
#endif
	  sprintf(socketDescriptor,"%d",s);
	  execl("/bin/OzFS","OzFS",&socketDescriptor,(char *)0);
	  /* exec failure */
	  perror("OzFileSender(execl)");
	  printf("OzFileSender:: fork&exec failure of OzFS\n");
	  write(s,(char *)&zero,4);
	  close(s);
	  exit(EXECLP_ERROR); /* -1 */
	}
      else
	{
	  close (s);
	}
    }
  return(0); /* never reached */
}


