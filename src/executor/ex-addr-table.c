/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "nif.h"
#include "ncl/exec_table.h"
#include "ncl/ex_ncl_event.h"

#include "ex-addr-table.h"

/* MAX_ADDR_REQ is maximum number of address resolution request waiter,
* which does not include waiting threads of same executor id resolution.
* MAX_ADDR_REQ_RETRY is maximum number of retry.
* ADDR_REQ_TIMEOUT is retry period of address resolution, unit is
* tick of system, so this value may need to adjust system by system */ 

#define MAX_ADDR_REQ 1024
#define MAX_ADDR_REQ_RETRY 5
#define ADDR_REQ_TIMEOUT 500
#define AIQ_MAX 5

extern	int	bzero( char *, int ) ;
extern	char	*alloc_shmmem(int size) ;

ExecTable extbl;
ETHashTable ethash;
AddressReq addressqueue;

int AIQcount;
AddressReq AIQtable;

OZ_MonitorRec AddressReqLock;
OZ_ConditionRec AddressReqFree;
OZ_ConditionRec AddressReqResp;
int AddressRequested;

void
init_exectable() {
  int i;
  extbl = (ExecTable)alloc_shmmem(sizeof(ExecTableRec)*EXEC_TABLE_SIZE);
  ethash = (ETHashTable)alloc_shmmem(sizeof(ETHashTable));
  addressqueue = (AddressReq)OzMalloc(sizeof(AddressReqRec)*MAX_ADDR_REQ);
  AddressRequested=0;
  for(i=0;i<MAX_ADDR_REQ;i++)
    { addressqueue[i].ed.head.event_num = EN_UNKNOWN_EXID;
      addressqueue[i].ed.data.so_addr.unknown_exid = 0LL; 
    }
  AIQtable = (AddressReq)OzMalloc(sizeof(AddressReqRec)*AIQ_MAX);
  AIQcount=0;
  for(i=0; i<AIQ_MAX; i++)
    { AIQtable[i].ed.head.event_num = EN_UNKNOWN_EXID;
      AIQtable[i].ed.data.so_addr.unknown_exid = 0LL; 
    }

  OzInitializeMonitor(&AddressReqLock);
  OzExecInitializeCondition(&AddressReqFree,1);
  OzExecInitializeCondition(&AddressReqResp,1);

  return;
}

static void   DumpAddress(struct sockaddr_in *a)
{ unsigned char *b; int i;

  b=(unsigned char *)a;

  for(i=0;i<8;i++) OzDebugf("%02x ",*b++); 
  OzDebugf("\n");
}

int
NotChanged(struct sockaddr_in *a, ExecTable b)
{
  char *pa,*pb;
  int i;
#if 1
OzDebugf("NotChanged: compare two addresses below\n");
DumpAddress(a);
DumpAddress(&(b->addr));
#endif

  pa = (char *)a;
  pb = (char *)(&(b->addr));
  for(i=0;i<8;i++,pa++,pb++)
    {
      if(*pa != *pb)
	return(0);
    }
  return(1);
}

void
AddressInQuestion(long long exid, struct sockaddr_in *old_addr)
{
  int i,found,count=0;

  OzDebugf("AddressInQuestion enter: exid is %08x%08x \n",(int)(exid>>32), (int)(exid&0xffffffffLL));
  if ( OzStandAlone ) {
    OzDebugf("AddressInQuestion: exit without work (standalone)\n");
    return ;
  }
  OzExecEnterMonitor(&AddressReqLock);

  for(found=0,i=0;i<AIQ_MAX && !found;i++)
    if(AIQtable[i].ed.data.so_addr.unknown_exid == exid)
      {
	OzExecExitMonitor(&AddressReqLock);
OzDebugf("AddressInQuestion: exit without work\n");
	return;
      }


  for(i=0;i<AIQ_MAX;i++)
    if(AIQtable[i].ed.data.so_addr.unknown_exid == 0LL)
      { found = i;
	AIQcount++;
	AIQtable[i].ed.data.so_addr.unknown_exid = exid;

	AIQtable[i].ref_count=1;
	OzExecInitializeCondition(&(AIQtable[i].ready),0);

	count=MAX_ADDR_REQ_RETRY;
	while(NotChanged(old_addr,&(extbl[OzSearchETHash(ethash,exid)]))
	      && (count--) )
	  { 
	    OzDebugf("Broadcast request for refresh address information\n");
	    NifWriteToNcl((char *)(&(AIQtable[i].ed)), sizeof(EventDataRec));
	    OzExecWaitConditionWithTimeout(&AddressReqLock
					   ,&(AIQtable[i].ready)
					   ,ADDR_REQ_TIMEOUT*3);
	  }
	break;
      }

  AIQtable[found].ref_count--;
  if(AIQtable[found].ref_count ==0)
    {
      AIQtable[found].ed.data.so_addr.unknown_exid = 0LL;
      AIQcount--;
    }
  OzExecExitMonitor(&AddressReqLock);
  if(count >0)
    {
      OzDebugf("AddressInQuestion: exit after work\n");
    }
  else
    {
      OzDebugf("AddressInQuestion: exit with no effort \n");
    }

  return;
}

ExecTable
AddressRequest(long long exid)
{
  int i,j,found,count;

  if ( OzStandAlone ) {
    static ExecTableRec execTable={0LL,{AF_INET},0,ET_LOCAL};
    return(&execTable);
  }

  OzExecEnterMonitor(&AddressReqLock);
  if(AIQcount)
    { for(i=0;i<AIQ_MAX;i++)
	if(AIQtable[i].ed.data.so_addr.unknown_exid == exid)
	  { /* AddressInQuestion request is already made */
	    /* debug on 17-oct-95 */ 
# if 1
	    AIQtable[i].ref_count++;
#endif
	    OzExecWaitCondition(&AddressReqLock, &(AIQtable[i].ready));
	    AIQtable[i].ref_count--;
	    OzDebugf("Address in question reference count %d\n",AIQtable[i].ref_count);
	    if(AIQtable[i].ref_count==0)
	      {
		AIQtable[i].ed.data.so_addr.unknown_exid = 0LL;
		AIQcount--;
	      }
	    break;
	  }
    }
  OzExecExitMonitor(&AddressReqLock);

  if((i=OzSearchETHash(ethash,exid))<0)
    {
      OzExecEnterMonitor(&AddressReqLock);
      for(j=0,found=0;!found && j<MAX_ADDR_REQ;j++)
	{ if(addressqueue[j].ed.data.so_addr.unknown_exid == exid)
	    { /* Address resolution request was issued already */
	      found=j;
	      addressqueue[j].ref_count++;
	      OzExecWaitCondition(&AddressReqLock,&(addressqueue[j].ready));
 	      if( (--addressqueue[j].ref_count) ==0)
		{ addressqueue[j].ed.data.so_addr.unknown_exid=(long long)0;
		  OzExecSignalCondition(&AddressReqFree);
		}
	      OzExecExitMonitor(&AddressReqLock);
	      if((i=OzSearchETHash(ethash,exid))<0)
		{ /* Timed out */
		  return((ExecTable)0);
		}
	      else
		{
		  return(&(extbl[i]));
		}
	    }
	}
      /* if address resolution has not requested */
      for(j=0;j<MAX_ADDR_REQ;j++)
	{ if(addressqueue[j].ed.data.so_addr.unknown_exid == (long long)0)
	    {
 	      addressqueue[j].ed.data.so_addr.unknown_exid = exid;
	      addressqueue[j].ref_count=1;
	      bzero((char *)&(addressqueue[j].ed.data.so_addr.address),sizeof(struct sockaddr_in));
	      OzExecInitializeCondition(&(addressqueue[j].ready),0);

	      count=MAX_ADDR_REQ_RETRY;
	      while( ( (i=OzSearchETHash(ethash,exid)) <0) && (count--))
		{ NifWriteToNcl((char *)(&(addressqueue[j].ed)), sizeof(EventDataRec));

		  OzExecWaitConditionWithTimeout(&AddressReqLock
						 ,&(addressqueue[j].ready)
						 ,ADDR_REQ_TIMEOUT);
		}
OzDebugf("AddressRequest: index %d (error if minus)from OzSearchETHash(exid;%08x%08x)\n"
,i,(int)(exid>>32),(int)(exid & 0xffffffffLL));

	      if( (i=OzSearchETHash(ethash,exid)) <0)
		{ /* address resolution failure after retry */
		  if(--addressqueue[j].ref_count ==0)
		    { addressqueue[j].ed.data.so_addr.unknown_exid=(long long)0;
		      OzExecSignalCondition(&AddressReqFree);
		    }
		  OzExecSignalConditionAll(&(addressqueue[j].ready));
		  OzExecExitMonitor(&AddressReqLock);
		  return((ExecTable)0);
		}
	      else
		{ 
		  if(--addressqueue[j].ref_count ==0)
		    { addressqueue[j].ed.data.so_addr.unknown_exid=(long long)0;
		      OzExecSignalCondition(&AddressReqFree);
		    }
		  OzExecExitMonitor(&AddressReqLock);
		  OzExecSignalConditionAll(&(addressqueue[j].ready));
		  OzDebugf("AddressRequest: success may (ExTbl %x)\n",&(extbl[i]));
		  return(&(extbl[i]));
		}
	    }
	}
      /* address solution request queue is full */
      OzExecWaitCondition(&AddressReqLock,&AddressReqFree);
      OzExecExitMonitor(&AddressReqLock);
      return(AddressRequest(exid));
    }
  else
    { 
#if 0 /* ONIDEBUG */
      ExecTable ent = ((ExecTable)(&extbl[i]));
      OzDebugf("ex-addr-table.c: index = %d\n", i);
      OzDebugf("ex-addr-table.c: exid = %08x%08x\n",
	       (int)(ent->exid >> 32), (int)(ent->exid & 0xffffffffLL));
      OzDebugf("ex-addr-table.c: location = %d\n", ((ExecTable)(&extbl[i]))->location);
#endif
      return(&(extbl[i]));
    }
}

void
AddressReply(SolutAddressRec data)
{
  int i,found;

  OzExecEnterMonitor(&AddressReqLock);
  for(i=0,found=0;!found && i<MAX_ADDR_REQ;i++)
    if(addressqueue[i].ed.data.so_addr.unknown_exid == data.unknown_exid)
      {
	OzExecSignalConditionAll(&(addressqueue[i].ready));
	found=1;
      }
  for(i=0,found=0;!found && i<AIQ_MAX;i++)
    if(AIQtable[i].ed.data.so_addr.unknown_exid == data.unknown_exid)
      {
	OzExecSignalConditionAll(&(AIQtable[i].ready));
	found=1;
      }
  OzExecSignalConditionAll(&AddressReqResp);
  OzExecExitMonitor(&AddressReqLock);
}

