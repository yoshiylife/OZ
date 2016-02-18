/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* mofified for inter-site communication on 24-mar-1996 */
#include "remotefile.h"

int
main(int argc, char *argv[]) 
{
  int ip;
  char fromFilename[NAMESIZE];
  int pid;
  char tmpfile[NAMESIZE];
  char hostname[256];
  char buffer[BUFFER_SIZE];

  struct sockaddr_in destination;
  int s, sockopt,fd,size,i;
  int receiveSize;
#ifdef INTERSITE
  unsigned int exid_h,exid_l;
  long long dest_exid;
#endif

  chdir("/");


#ifdef INTERSITE

  printf("OzFR testprint 1 start \n");

  sscanf(argv[2],"%08x%08x",&exid_h,&exid_l);

  printf("OzFR exid in halvs(copy) %08x : %08x \n",
	 exid_h,exid_l);

  dest_exid = ((long long)(exid_h) << 32 ) +
    (long long)(exid_l);

  printf("OzFR testprint 2 exid = %08x%08x \n",
       (int)((dest_exid>>32)&0xffffffffLL),
       (int)(dest_exid & 0xffffffffLL));

  strcpy(fromFilename,argv[3]);

  printf("OzFR testprint 3 filename %s (length=%d)\n",
	 fromFilename,strlen(fromFilename));
#else
  strcpy(fromFilename,argv[2]);
#endif

  
  sscanf(argv[1],"%08x",&ip);

  printf("OzFR testprint 4 ip %08x \n",ip);

  printf("OzFR started : IP %08x , Exid %08x%08x , filename (%s)\n",
	 ip,
	 (int)((dest_exid >>32) & 0xffffffffLL),
	 (int)(dest_exid & 0xffffffffLL),
	 fromFilename);



  destination.sin_port = OzRemoteFileTransferPort;
  destination.sin_addr.s_addr= ip;
  destination.sin_family = AF_INET;

  if((s = socket(PF_INET,SOCK_STREAM,0)) <0)
    {
#ifdef OFRDEBUG
      printf("Connection error(socket creation failure) end of OzFR\n");
#endif
      exit(REM_CONN_ER); /* -3 */
    }
  sockopt=1;
  setsockopt(s, 6, TCP_NODELAY,(char *)&sockopt,4);
  setsockopt(s, SOL_SOCKET,SO_KEEPALIVE,(char *)&sockopt,4);
  if(connect(s,(struct sockaddr *)&destination,sizeof(struct sockaddr_in)) <0)
    {
      close(s);
#ifdef OFRDEBUG
      printf("Connection error end of OzFR\n");
#endif
      exit(REM_CONN_ER); /* -3 */
    }
  
  /* create temporaty file */
  pid = getpid();
  bzero(tmpfile,NAMESIZE); /* clear char array */
  
  /* change of directory structure on may-1995 */
  
  if(gethostname(hostname,256) <0)
    hostname[0] = '\0';
  
  sprintf(tmpfile,"/%s/%s%08x",TEMPORARYPATH,hostname,pid);
  
  if((fd = open(tmpfile,O_WRONLY|O_CREAT|O_EXCL , 0755)) <0)
    {
/* #ifdef OFRDEBUG */
      perror("OzFR:(create file):");
      printf("OzFR file create fail(errno %d), filename is %s\n",errno,tmpfile);
/* #endif */
      close(s);
#ifdef OFRDEBUG
      printf("File creation error end of OzFR\n");
#endif
      exit(FILE_CREA_FAIL); /* -4 */
    }

#ifdef INTERSITE /* must be sent in network order */
  i = write(s,(char *)&dest_exid,sizeof(long long));
  printf("OzFR: write %d bytes as executor ID\n",i);
#endif
  
  i = write(s,fromFilename,strlen(fromFilename)+1);
  printf("OzFR: write %d bytes as filename \n",i);

  if(i = read(s,(char *)&size,4) <4)
    goto ERROR;
  
  if(size==0)
    {
      close(s);
#ifdef OFRDEBUG
      printf("No such file end of OzFR\n");
#endif
      exit(NO_REM_FILE); /* -2 */
    }
#ifdef OFRDEBUG
  printf("OzFR:: start to receive, size %d bytes\n",size);
#endif
  
  for(;size>0;)
    {
      receiveSize = (size>=BUFFER_SIZE)? BUFFER_SIZE : size;
      if((i = read(s,(char *)buffer,receiveSize)) <= 0)
	goto ERROR;
      else
	{
	  if(write(fd,(char *)buffer,i)<=0)
	    {
	      close(fd);
	      close(s);
	      unlink(tmpfile);
#ifdef OFRDEBUG
	      printf("File write error end of OzFR\n");
#endif
	      exit(FILE_WRITE_ER);
	    }
	  size -= i;
#ifdef OFRDEBUG
	  printf("OzFR:: received and write to file %d bytes, remains %d bytes\n",
		 i,size);
#endif
	}
    }
  close(fd);
  close(s);
#ifdef OFRDEBUG
  printf("Successful end of OzFR\n");
#endif
  exit(SUCCESS);
  
 ERROR:
  close(s);
  close(fd);
  unlink(tmpfile);
#ifdef OFRDEBUG
  printf("Communication error end of OzFR\n");
#endif
  exit(COMM_ERROR); /* -5 */  
}
