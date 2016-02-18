/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* mofified for inter-site communication on 24-mar-1996 */
#include "remotefile.h"

int
main(int argc,char *argv[])
{
  char filename[NAMESIZE], *cp;
  int fd;
  int size, i;
  char buffer[BUFFER_SIZE];
  struct stat st;
  int zero;
  int s;
  int readSize;
#ifdef INTERSITE
  long long dest_exid;
#endif

  zero=0;
  strcpy(filename,argv[1]);

#ifdef OFSDEBUG
  printf("OzFS start, arg1 : %s \n",filename);
#endif

  s = atoi(filename);
#ifdef INTERSITE
  /* read destination exid, but this value is not used in OzFS but in OzFGW */
  i = read(s,(char *)&dest_exid,sizeof(long long));

  
#endif
  
  /* read filename from socket */
  cp = filename;
  do {
    read(s,cp,1);
    cp++;
  } while( *(cp-1) != '\0' );

#ifdef OFSDEBUG
  printf("OzFS started: socket %d, filename %s\n",s,filename);
#endif

  /* send size of file to socket */
  if(stat(filename,&st)!=0)
    {
      perror("OzFS(stat)");
      write(s,(char *)&zero,4);
      close(s);
      return(-1);
    }
  else if((fd = open(filename,O_RDONLY)) <0)
    { 
      perror("OzFS(open)");
      write(s,(char *)&zero,4);
      close(s);
      return(-1);
    }
  else
    {
      size = st.st_size;
      write(s,(char *)&size,4);
    }

#ifdef OFSDEBUG
  printf("OzFS: file transfer started, size = %d bytes (fd %d)\n",size,fd);
#endif

  for(;size>0;)
    {
      readSize = (size>=BUFFER_SIZE)? BUFFER_SIZE : size;
      if((i = read(fd,buffer,readSize)) <=0)
	{ /* read file fail */
	  close(s);
	  close(fd);
	  return(-1);
	}
#ifdef OFSDEBUG
      printf("OzFS::read file %d bytes ",i);
#endif
      if(write(s,buffer,i)<=0)
	{ /* write to socket fail */
	  close(s);
	  close(fd);
	  return(-1);
	}
      size -= i;
#ifdef OFSDEBUG
      printf(" remains %d bytes \n",size);
#endif
    }
#ifdef OFSDEBUG
  printf("end of OzFS\n");
#endif
  close(fd);
  close(s);
  return(0);
}
