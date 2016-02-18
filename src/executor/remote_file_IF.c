/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* Interface program to remote file transfer */
/* this program will be included in executor of OZ++ */
#include "oz++/ozlibc.h"

#include "switch.h"
#include "circuits.h"
#include "comm.h"
#include <netinet/tcp.h>
#include <sys/param.h>
#include <netdb.h>
#include "executor/remote-file-if.h"

#include "ncl/exec_table.h"

#if 1
#define OzFileReceiverPort 3002
#else
#define UNIX_PORT_NAME "/tmp/OzRFT"
#endif
extern ExecTable AddressRequest(long long exid);

int
OzOmFileTransfer(OID class,char *fromFile, char *toFile)
{
  ExecTable dest;
  int ip,s,i;
  char result[6];
  struct sockaddr_in ozFileReceiverAddr;
#ifdef INTERSITE
  long long dest_exid;

  dest_exid = class & 0xffffffffff000000LL;
#endif


  if( (dest = AddressRequest(class & 0xffffffffff000000LL)) == (ExecTable)0)
    {
      OzDebugf("OzOmFileTransfer:: fail to resolve address\n");
      return(-1); /* address resolution failure */
    }
  else if(dest->location == ET_LOCAL)
    {
      OzDebugf("OzOmFileTransfer:: fail to connect OzFileReceiver\n");
      return(-2); /* destination is local (on the same station ) */
    }

  ip = dest->addr.sin_addr.s_addr;

  if((s = OzSocket(PF_INET,SOCK_STREAM,0))<0)
    return(-3); /* socket creation error */

  ozFileReceiverAddr.sin_family = AF_INET;
  ozFileReceiverAddr.sin_port = OzFileReceiverPort;
  ozFileReceiverAddr.sin_addr.s_addr = INADDR_ANY;
  
  if(OzConnect(s,(struct sockaddr *)&ozFileReceiverAddr, sizeof(struct sockaddr_in)) <0)
    {
      OzClose(s);
      OzDebugf("OzOmFileTransfer:: fail to connect OzFileReceiver\n");
      return(-4); /* connection failure */
    }
  
  OzDebugf("OzOmFileTransfer:: from %08x , filename %s -> %s\n",
	   ip,fromFile,toFile);



  OzWrite(s,&ip,4);

#ifdef INTERSITE
  OzWrite(s,&dest_exid,sizeof(long long));
#endif

  OzWrite(s,fromFile,strlen(fromFile)+1);
  OzWrite(s,toFile,strlen(toFile)+1);

  i = OzRead(s,&result,4);
  OzClose(s);

  if(i<4)
    return(-5); /* unexpected response */
  
  result[i]='\0';
  
  if(strcmp(result,"OK!!")==0)
    return(0); /* success */
  else if(strcmp(result,"TBF0")==0)
    return(10); /* Request table full (OzFileReceiver) */ 
  else if(strcmp(result,"TBF1")==0)
    return(11); /* Request table full (OzFileReceiver) */
  else if(strcmp(result,"FCFL")==0)
    return(12); /* Fail to create file (OzFileReceiver) */
  else if(strcmp(result,"FWFL")==0)
    return(13); /* Fail to write file (OzFileReceiver) */
  else if(strcmp(result,"FMFL")==0)
    return(14); /* Fail to move file (OzFileReceiver) */
  else if(strcmp(result,"REXC")==0)
    return(15); /* Child process terminated unexpectedly (OzFR) */
  else if(strcmp(result,"RNFL")==0)
    return(20); /* No such file (OzFS) */
  else if(strcmp(result,"RCON")==0)
    return(21); /* Connection fail to OzFS (OzFR/OzFS) */
  else if(strcmp(result,"COMM2")==0)
    return(22); /* Communication fail (OzFR/OzFS) */
  else if(strcmp(result,"RUNK")==0)
    return(30); /* Unknown error occured at remote (OzFS) */
  else 
    return(30); /* Unknown error at local */
}
