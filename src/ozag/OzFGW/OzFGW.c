/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <ctype.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/file.h>

#define BUFFER_SIZE 8192
/* This program is executed as child process of OZAG. */
/* Two connected socket which file descriptor are 3 and 4 respectively */
/* are passed from OZAG. */
/* fd:3 is connected to requester side, and fd:4 is connected to  */
/* responder side. */

/* #define OzFGWDebug */

main()
{
  char c,buffer[BUFFER_SIZE],fname[256],*p;
  int i,zero,size;
  
  zero=0;

  p=fname;
  do { /* path file name from 3 to 4 */
    read(3,&c,1);
    write(4,&c,1);
    *p = c;
    p++;
  } while(c != '\0');

#ifdef OzFGWDebug
  printf("OzFGW: filename is %s\n",fname);
#endif

  if(i=read(4,(char *)(&size),sizeof(int))<sizeof(int))
    {
      printf("OzFGW: fail to accept size\n");
      write(3,(char *)(&zero),sizeof(int));
      close(3);
      close(4);
      exit(1);
    }
  else if(size <= 0)
    {
      write(3,(char *)(&size),sizeof(int));
      printf("OzFGW: accept illegal size(%d)\n",size);
      close(3);
      close(4);
      exit(2);
    }
  else
    write(3,(char *)(&size),sizeof(int));

#ifdef OzFGWDebug
  printf("OzFGW: start transfer data... size(%d)\n",size);
#endif

  do {
    if((i = read(4,buffer,BUFFER_SIZE))<=0)
      { /* fail to read in the middle */
	printf("OzFGW: fail to read in the middle(read returns %d)\n",i);
	close(3);
	close(4);
	exit(3);
      }
    size -= i;
    write(3,buffer,i);
  }while(size>0);

  /* finish successfully */
  close(3);
  close(4);
  exit(0);
}
