/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _FAULT_Q_H_
#define _FAULT_Q_H_
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"

typedef struct FaultQueueElementRec {
  struct FaultQueueElementRec *next;
} FaultQueueElementRec, *FaultQueueElement;

typedef struct FaultQueueRec {
  OZ_MonitorRec lock;
  OZ_ConditionRec not_empty;
  int count;
  FaultQueueElement first;
  FaultQueueElement last;
} FaultQueueRec, *FaultQueue;

inline	static void
insert_into_fault_queue(FaultQueueElement x, FaultQueue q)
{
  if (q->first)
    q->last->next = x;
  else
    q->first = x;
  q->last = x;
}

inline	static int
queue_has_only_one_element(FaultQueue q)
{
  return(q->first == q->last);
}

inline	static int
queue_is_empty(FaultQueue q)
{
  return(!q->first);
}

inline	static int
queue_is_not_empty(FaultQueue q)
{
  return(q->first ? 1 : 0);
}

inline	static FaultQueueElement
remove_from_fault_queue(FaultQueue q)
{
  FaultQueueElement element;

  if (!queue_is_empty(q)) {
    element = q->first;
    if (queue_has_only_one_element(q)) {
      q->first = 0;
      q->last = 0;
    } else {
      q->first = q->first->next;
    }
    return(element);
  } else
    return(0);
}

inline	extern void
FqInitializeFaultQueue(FaultQueue queue)
{
  OzInitializeMonitor(&queue->lock);
  OzExecInitializeCondition(&queue->not_empty, 0);
  queue->first = 0;
  queue->last = 0;
  queue->count = 0;
}

inline	extern void
FqEnqueueRequest
  (FaultQueueElement element, FaultQueue queue)
{
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&queue->lock);
  insert_into_fault_queue(element, queue);
#ifndef ALWAYS_SIGNAL
  if (queue_has_only_one_element(queue))
#endif /* ALWAYS_SIGNAL */
    OzExecSignalCondition(&queue->not_empty);
  OzExecExitMonitor(&queue->lock);
  ThrUnBlockSuspend( block ) ;
}

inline	extern int
FqEnqueueRequestOnce  /* for GC */
  (FaultQueueElement element, FaultQueue queue)
{
  int block, result = 0;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&queue->lock);
  if (! queue->first) {
    result = 1;
    insert_into_fault_queue(element, queue);
    OzExecSignalCondition(&queue->not_empty);
  }
  OzExecExitMonitor(&queue->lock);
  ThrUnBlockSuspend( block ) ;
  return result;
}

inline	extern FaultQueueElement
FqReceiveRequest(FaultQueue queue)
{
  FaultQueueElement element;
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&queue->lock);
  while (queue_is_empty(queue))
    OzExecWaitCondition(&queue->lock, &queue->not_empty);
  element = remove_from_fault_queue(queue);
#ifndef ALWAYS_SIGNAL /* Signal to remainder */
  if (queue_is_not_empty(queue)) OzExecSignalCondition(&queue->not_empty);
#endif
  OzExecExitMonitor(&queue->lock);
  ThrUnBlockSuspend( block ) ;
  return(element);
}

typedef struct SimpleRequestStr *SimpleRequest;
typedef struct SimpleRequestStr SimpleRequestRec;

struct SimpleRequestStr {
  FaultQueueElementRec fault_elt;
  OZ_ConditionRec done;
  char replied;
};

inline	extern void
FqEnqueueRequestAndWait
  (SimpleRequest element, FaultQueue queue)
{
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&queue->lock);
  insert_into_fault_queue((FaultQueueElement)element, queue);
#ifndef ALWAYS_SIGNAL
  if (queue_has_only_one_element(queue))
#endif /* ALWAYS_SIGNAL */
    OzExecSignalCondition(&queue->not_empty);
  while (!element->replied)
    OzExecWaitCondition(&(queue->lock), &element->done);
  OzExecExitMonitor(&(queue->lock));
  ThrUnBlockSuspend( block ) ;
}

inline	extern void
FqWakeupFaultSender(SimpleRequest element)
{
  element->replied = (char)1;
  OzExecSignalConditionAll(&element->done);
}

inline	extern void
FqInitializeSimpleRequest(SimpleRequest element)
{
  OzExecInitializeCondition(&element->done, 0);
  element->replied = (char)0;
}

inline	extern void
FqEnqueueIntoFreeQueue(FaultQueueElement x, FaultQueue q)
{
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&q->lock);
  insert_into_fault_queue(x, q);
  q->count++;
  OzExecExitMonitor(&q->lock);
  ThrUnBlockSuspend( block ) ;
}

inline	extern FaultQueueElement
FqDequeueFromFreeQueue(FaultQueue q)
{
  FaultQueueElement elt;
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&q->lock);
  elt = remove_from_fault_queue(q);
  q->count--;
  OzExecExitMonitor(&q->lock);
  ThrUnBlockSuspend( block ) ;
  return(elt);
}

#endif !_FAULT_Q_H_
