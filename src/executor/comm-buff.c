/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* multithread system include */
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "comm-buff.h"

#define MAX_COMM_BUFF_RESERVE 128

extern	int	bzero( char *, int ) ;

/* variables for free communication buffer management */
static commBuff         commBuffFreeList;
static int              commBuffFreeCount;
static OZ_MonitorRec    commBuffLock;
static OZ_ConditionRec  commBuffFreeAvail;

void 
InitCommBuff()
{
  commBuff p,pp;
  int i;

  OzInitializeMonitor(&commBuffLock);
  OzExecInitializeCondition(&commBuffFreeAvail,0);
  commBuffFreeList = (commBuff)OzMalloc(sizeof(commBuffRec));
  /* create communication buffers and keep them as reserve */
  for(i=1,pp=commBuffFreeList;i<MAX_COMM_BUFF_RESERVE;i++)
    {
      p=(commBuff)OzMalloc(sizeof(commBuffRec));
      p->next=(commBuff)0;
      pp->next=p;
      pp=p;
    }
  commBuffFreeCount = MAX_COMM_BUFF_RESERVE;
  return;
}


void
FreeCommBuff(commBuff b)
{
  commBuff p,pp,tail;
  int count,dealloc_count,reserve_count,i;

  for(p=b->next,pp=b,count=1; p!=(commBuff)0; pp=p,p=p->next,count++)
    ;
  tail=pp;

  OzExecEnterMonitor(&commBuffLock);
  reserve_count = (count+commBuffFreeCount <= MAX_COMM_BUFF_RESERVE)?
    count : MAX_COMM_BUFF_RESERVE - commBuffFreeCount;
  dealloc_count = count - reserve_count;

/*  OzDebugf("OzFreeCommBuff: count(%d),reserve(%d),dealloc(%d)\n",
	   count,reserve_count,dealloc_count);
*/
  for(i=0,p=b,pp=p->next;i<dealloc_count;i++)
    {
      OzFree(p);
      p=pp;
      if(pp!=(commBuff)0)
	pp=pp->next;
    }
  if(reserve_count>0)
    {
      pp=commBuffFreeList;
      commBuffFreeList=p;
      tail->next=pp;
      commBuffFreeCount += reserve_count;
      OzExecSignalCondition(&commBuffFreeAvail);
    }
    OzExecExitMonitor(&commBuffLock);
  return;
}


commBuff
GetCommBuff()
{
  commBuff p;

/*  OzDebugf("OzGetCommBuff:\n"); */
  OzExecEnterMonitor(&commBuffLock);
  if(commBuffFreeList==(commBuff)0)
      p=(commBuff)OzMalloc(sizeof(commBuffRec));
  else
    {
      p=commBuffFreeList;
      commBuffFreeList=commBuffFreeList->next;
      commBuffFreeCount--;
    }
  OzExecExitMonitor(&commBuffLock);

  /* initialize */
  p->next = (commBuff)0;
  p->bufsize = 0;
  p->bp = p->buf;
  bzero((char *)p->buf,COMM_BUFF_SIZE);  
  bzero((char *)&(p->networkAddr),sizeof(struct sockaddr_in));
  p->channel=0;
  p->channeltype=RCHAN;
  return(p);
}
