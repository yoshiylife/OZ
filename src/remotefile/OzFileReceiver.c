/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* mofified for inter-site communication on 24-mar-1996 */
#include "remotefile.h"

#define REQUEST_TABLE_SIZE 32

#define NOBODY   65534
#define FILEMODE 0755

typedef struct _requestTable {
  int pid;
  int fd;
  char filename[NAMESIZE];
  struct timeval tvStart;
  int rsn; /* request sequence number */
} RequestTableRec, *RequestTable;


RequestTableRec request_table[REQUEST_TABLE_SIZE];
int NumberOfRequest;
int RequestSequenceNumber;

extern errno;

int AcceptPort;
char fromFilename[NAMESIZE], toFilename[NAMESIZE];

union {
  int i;
  struct {
    unsigned char s0;
    unsigned char s1;
    unsigned char s2;
    unsigned char s3;
  }bytes;
}fromIp;

/* initialize request table */
void
init_request_table()
{
  int i;
  for(i=0;i<REQUEST_TABLE_SIZE;i++)
    {
      request_table[i].pid=0;
      request_table[i].fd=0;
      request_table[i].filename[0]='\0';
    }
  NumberOfRequest = 0;
  RequestSequenceNumber = 0;
  return;
}

int
search_table_by_pid(int pid, int from)
{
  int i;

  for(i=from;i<REQUEST_TABLE_SIZE;i++)
    {
      if(request_table[i].pid == pid)
	break;
    }
  return(i);
}

int
search_table_by_fname(char *filename, int from)
{
  int i;

  for(i=from;i<REQUEST_TABLE_SIZE;i++)
    {
      if( (request_table[i].pid!=0) &&
	 (strcmp(filename,request_table[i].filename)==0) )
	break;
    }
  return(i);
}

int
search_empty_entry()
{
  int i;

  for(i=0;i<REQUEST_TABLE_SIZE;i++)
    {
      if(request_table[i].pid==0)
	break;
    }
  return(i);
}

int
check_accessor(struct sockaddr_in *hisaddress)
{

  if(hisaddress->sin_addr.s_addr != INADDR_LOOPBACK)
    {
#ifdef OFRdDEBUG
      printf("Not loopback! (Illegal remote access occured) : his address is %08lx:%0x4\n",hisaddress->sin_addr.s_addr,hisaddress->sin_port);
#endif
      return(-1);
    }
  else
    return(0);
}

/* initialize port */
/* returns minus number if error occured, otherwise returns zero */
int
init_port()
{
  struct sockaddr_in AcceptPortAddress; 

  AcceptPortAddress.sin_family = AF_INET;
  AcceptPortAddress.sin_port = OzFileReceiverPort;
  AcceptPortAddress.sin_addr.s_addr = INADDR_ANY;
  
  if(( AcceptPort = socket(PF_INET,SOCK_STREAM,0) )<0)
    {
      return(-1); /* socket create failure */
    }
  if(bind(AcceptPort,(struct sockaddr *)(&AcceptPortAddress),sizeof(struct sockaddr_in)))
    {
      close(AcceptPort);
      return(-2); /* bind failure */
    }
  if(listen(AcceptPort,2)<0)
    { close(AcceptPort);
      return(-3); /* listen failure */
    }
  return(0);
}

void
delete_port()
{
  shutdown(AcceptPort,2);
  close(AcceptPort);
  return;
}

void
reportToExec(int pid,char *report)
{
  int i;
  struct tm tm;
  struct timeval tv;

  gettime(&tm,&tv);

  for(i=search_table_by_pid(pid,0);
      i<REQUEST_TABLE_SIZE; 

      i=search_table_by_pid(pid,i+1))
    {
      write(request_table[i].fd,report,strlen(report));
      printf("Job %d Finished with exit code:%s: time ",request_table[i].rsn,report);
      printtimeinterval(&(request_table[i].tvStart),&tv);
      printf("(sec)\n");
      close(request_table[i].fd);
      request_table[i].pid = 0;
    }
}

int
move_file(int pid,char *filepath)
{
  char tmpfile[NAMESIZE],filename[NAMESIZE];
  int len,i;
  char *cp0,*cp1,*cp2,*cp3;
  char hostname[256];

  bzero(filename,NAMESIZE); /* clear char array */

  /* change according to directory stracture change on May 1995 */

  if(gethostname(hostname,256) <0)
    hostname[0] = '\0';

  sprintf(tmpfile,"/%s/%s%08x",TEMPORARYPATH,hostname,pid);
  
#ifdef OFRdDEBUG
  printf("OzFileReceiver:move_file:: %s -> %s\n",tmpfile,filepath);
#endif

  len = strlen(filepath);
  cp0 = filename;

  for(cp1 = filepath, cp2 = cp1, cp3 = index(cp2+1,'/');
      cp2 && cp3;
      cp2 = cp3, cp3 = index(cp2+1,'/')  )
    {
      for(;cp2!=cp3;cp2++,cp0++)
	*cp0 = *cp2;
#ifdef OFRdDEBUG
      printf("OzFileReceiver:: (create directory) \"%s\"\n",filename);
#endif
      if( ( i = mkdir(filename,0755)) != 0) 
	{
	  if(errno != EEXIST)
	    {
	      printf("OzFileReceiver::can't create directory \"%s\"\n",filename);
	      return(-1);
	    }
	}
    }
  
  if(link(tmpfile,filepath) <0)
    if(errno == EEXIST)
      { /* successful exit , because file exist already */
	unlink(tmpfile);
	return(0);
      }
    else
      {
	printf("OzFileReceiver: move failure (%s -> %s)\n",tmpfile,filepath);
	unlink(tmpfile);
	return(-1);
      }
  else
    {
      chown(filepath,NOBODY,NOBODY);
      chmod(filepath,FILEMODE);
      unlink(tmpfile);
      return(0);  
    }
}

void 
  getSIGCHLD()
{
  int pid,status;
  int returnedValue;
  int mask, i;

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
	  if( (returnedValue = (signed char)WEXITSTATUS(status)) == 0)
	    { /* child terminated successfully */
	      i = search_table_by_pid(pid,0);
	      /* ( debug print )
		 printf("move_file, table position is %d, filename %s\n",
		 i,request_table[i].filename); */
	      if(move_file(pid,request_table[i].filename)==0)
		{ 
		  reportToExec(pid,"OK!!");
#ifdef OFRdDEBUG
		  printf("Success!!\n");
#endif
		}
	      else
		{
		  reportToExec(pid,"FMFL");
#ifdef OFRdDEBUG
		  printf("File move fail\n");
#endif
		}
	    }
	  else
	    {
	      if(returnedValue == NO_REM_FILE)
		{
		  reportToExec(pid,"RNFL");
#ifdef OFRdDEBUG
		  printf("Remote File not exist\n");
#endif
		}
	      else if(returnedValue == REM_CONN_ER)
		{
		  reportToExec(pid,"RCON");
#ifdef OFRdDEBUG
		  printf("Can't connect server OzFileSender\n");
#endif
		}
	      else if(returnedValue == FILE_CREA_FAIL)
		{
		  reportToExec(pid,"FCFL");
#ifdef OFRdDEBUG
		  printf("Can't create file\n");
#endif
		}
	      else if(returnedValue == FILE_WRITE_ER)
		{
		  reportToExec(pid,"FWFL");
#ifdef OFRdDEBUG
		  printf("Can't write file!!\n");
#endif
		}
	      else if(returnedValue == COMM_ERROR)
		{
		  reportToExec(pid,"COMM");
#ifdef OFRdDEBUG
		  printf("Communication error!!\n");
#endif
		}
	      else if(returnedValue == EXECLP_ERROR)
		{
		  reportToExec(pid,"EXER");
#ifdef OFRdDEBUG
		  printf("Execution of OzFR failed\n");
#endif
		}
	      else
		{
		  reportToExec(pid,"RUNK");
#ifdef OFRdDEBUG
		  printf("Unknown error!! (OzFR exited with unknow parameter(%d)\n",
returnedValue);
#endif
		}
	    }
	}
      else
	{/* exceptional termination of child process */
	  reportToExec(pid,"REXC");
#ifdef OFRdDEBUG
	  if(WIFSIGNALED(status))
	    {
	      printf("OzFR is terminated by signal %d\n",WTERMSIG(status));
	    }
	  else
	    {
	      printf("OzFR is not terminated nor signaled\n");
	    }
	  printf("Unexpected termination of OzFR!!\n");
#endif
	}
    }

  sigsetmask(mask);
#ifdef OFRdDEBUG
  printf("end of getSIGCHLD (sigsetmask(%d))\n",mask);
#endif
  return;
  /* end of getSIGCHLD, signal handler for SIGCHLD */
}

void
readFilename(int fd,char *fn)
{
  do {
    read(fd,fn,1);
    fn++;
  } while( *(fn-1) != '\0');
  return;
}

void
finish()
{
  int i;

  for(i=0; i<REQUEST_TABLE_SIZE; i++)
    {
      if(request_table[i].pid)
	{
	  kill(request_table[i].pid,SIGKILL);
	  close(request_table[i].fd);
	}
    }
  
  printf("Interrupt!! Exit OzFileReceiver\n");
  delete_port();
  exit(-1);
}

int main()
{
  int s, pid;
  int dummy_int;
  struct sockaddr_in client_address;
  char *cp;
  int mask;
  int tableIndex, i, ii;
  char id_str[10];

#ifdef INTERSITE
  long long dest_exid;
  char exid_str[20];
#endif



  struct sigvec sigvec1,sigvec2;
  struct tm tm;
  struct timeval tv;

  init_request_table();

  /* signals for stop */
  signal(SIGHUP,finish);
  signal(SIGINT,finish);
  signal(SIGTERM,finish);
  signal(SIGQUIT,finish);

  /* signal for SIGCHLD */
  signal(SIGCHLD,getSIGCHLD);

  /* reset SV_RESETHAND bit of sv_flags */
  /* SIGCHLD is treated at getSIGCHLD as many as SIGCHLD occured */
  sigvec(SIGCHLD,(struct sigvec *)0,&sigvec1);
  sigvec1.sv_flags &= (~(SV_RESETHAND));
  sigvec(SIGCHLD,&sigvec1,&sigvec2);

  /* Change root to $OZROOT */
  if( (cp = (char *)getenv("OZROOT")) == (char *)NULL )
    {
      printf("OzFileReceiver: Please set environment value OZROOT\n");
      exit(-2);
    }
  else
    {
      if(chroot(cp)<0)
	{
	  perror("OzFileReceiver");
	  exit(-3);
	}
      chdir("/");
    }

  if(( ii = init_port()) <0)
    {
      printf("OzFileReceiver: Can't create port! (error number %d)\n",ii);
      delete_port();
      exit(-1);
    }

  gettime(&tm,&tv);
  printtime(&tm,&tv);
  printf("(UST) :: OzFileReceiver started\n");

  for(;;)
    {
      bzero((char *)&client_address,sizeof(struct sockaddr_in));
      dummy_int = sizeof(struct sockaddr_in);
      errno=0;
      s = accept(AcceptPort,(struct sockaddr *)&client_address,&dummy_int);
      
      if(s<0)
	{ /* accept error */
	  if(errno != EINTR)
	    {
	      perror("OzFileReceiver(accept)");
	      printf("accept error(errno : %d)\n",errno);
	      break;
	    }
	  else
	    continue;
	}
      
#ifdef OFRdDEBUG
      printf("accepted(%d)! addr_len is %d\n",s,dummy_int);
      for(i=0,cp=(char *)(&client_address); i<dummy_int; i++,cp++)
	printf("%02x ",((int)(*cp) & 0xff) );
      printf("\n");
#endif
      if(check_accessor(&client_address))
	{ /* access from outside of this executor */
	  printf("Illegl remote access!! His port is %08lx:%04x\n",
		 client_address.sin_addr.s_addr,
		 client_address.sin_port);
	  close(s);
	  continue;
	}
      
      read(s,(char *)&fromIp,4);
#ifdef INTERSITE
      read(s,(char *)&dest_exid,sizeof(long long));
#endif
      readFilename(s,fromFilename);
      readFilename(s,toFilename);
      
#ifdef OFRdDEBUG
      printf("Accepted Request is take a file %s from %08x and name it as %s\n",
	     fromFilename,fromIp.i,toFilename);

#endif
      mask = sigblock(~0);

#ifdef OFRdDEBUG
      printf("sigblock, previous mask is %08x\n",mask);
#endif
      RequestSequenceNumber++;
      printf("Job %d started:",RequestSequenceNumber);
      gettime(&tm,&tv);
      printtime(&tm,&tv);
      printf("(UST) \n  (%d.%d.%d.%d:%s -> %s)\n",
	     fromIp.bytes.s0,fromIp.bytes.s1,fromIp.bytes.s2,fromIp.bytes.s3,
	     fromFilename,toFilename);

      tableIndex = search_table_by_fname(toFilename,0);
      if(tableIndex < REQUEST_TABLE_SIZE)
	{ /* found same request processed already */
	  if((i = search_empty_entry()) >= REQUEST_TABLE_SIZE)
	    { /* no empty entry in the request table : Error */
	      write(s,"TBF1",4);
#ifdef OFRdDEBUG
	      printf("Request table full (case 1)\n");
#endif
	    }
	  else
	    {
#ifdef OFRdDEBUG
	      printf("Found identical request, wait result of earlier request\n");
#endif
	      request_table[i].pid = request_table[tableIndex].pid;
	      request_table[i].fd = s;
	      strcpy(request_table[i].filename,request_table[tableIndex].filename);
	      bcopy((char *)&tv,(char *)&(request_table[i].tvStart),sizeof(struct timeval));
	      request_table[i].rsn = RequestSequenceNumber;
	    }
	}
      else
	{
	  if((i = search_empty_entry()) >= REQUEST_TABLE_SIZE)
	    { /* no empty entry in the request table : Error */
	      write(s,"TBF0",4);
#ifdef OFRdDEBUG
	      printf("Request table full (case 0)\n");
#endif
	    }
	  else
	    {
	      request_table[i].fd = s;
	      strcpy(request_table[i].filename,toFilename);
	      bcopy((char *)&tv,(char *)&(request_table[i].tvStart),
		    sizeof(struct timeval));
	      request_table[i].rsn = RequestSequenceNumber;
	      if((pid= fork()) ==0)
		{
		  sigsetmask(mask);
		  for(i=3;i<NOFILE;i++)
		    close(i);

		  errno=0;

		  sprintf(id_str,"%08x",fromIp.i);
#ifdef INTERSITE
		  sprintf(exid_str,"%08x%08x",
			   (int)((dest_exid >> 32) & 0xffffffffLL),
			   (int)(dest_exid & 0xffffffffLL));

		  printf("OzFileReceiver: ip %08x exid %08x%08x fname %s\n",
			 fromIp.i,
			 (int)((dest_exid >> 32) & 0xffffffffLL),
			 (int)(dest_exid & 0xffffffffLL),
			 fromFilename);

		  if(execl("/bin/OzFR","OzFR",id_str,exid_str,fromFilename,(char *)0)<0)
#else
		  if(execl("/bin/OzFR","OzFR",id_str,fromFilename,(char *)0)<0)
#endif
		    {
		      /* exec failure */
		      perror("OzFileReceiver(OzFR invocation):");
#ifdef OFRdDEBUG
		      printf("Execution failure (child process OzFR : errno %d)\n",errno);
#endif
		      exit(EXECLP_ERROR); /* -1 */
		    }
		}
	      else
		{
#ifdef OFRdDEBUG
		  printf("child process (OzFR) %d created\n",pid);
#endif
		  request_table[i].pid = pid;
		}
	    }
	}
      sigsetmask(mask);
#ifdef OFRdDEBUG
      printf("sigsetmask, previous mask is %08x\n",mask);
#endif

    }

  printf("OzFileReceiver :: accept error! Can't work any more!!\n");
  exit(COMM_ERROR);
}
