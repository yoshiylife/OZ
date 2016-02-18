/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "switch.h"
#include "executor/config-req.h"
#include "conf.h"
#include "fault-q.h"

static FaultQueueRec config_queue;

typedef struct OZ_ConfigQueueEltStr ConfigQueueEltRec;

struct OZ_ConfigQueueEltStr {
  SimpleRequestRec simple_req;
  OZ_ConfigurationRequest request;
};

OZ_ClassID CnfGetConfigID(OZ_ClassID compiled_cid)
{
  OZ_ConfigurationRequestRec request;
  ConfigQueueEltRec queue_elt;

  FqInitializeSimpleRequest((SimpleRequest)&queue_elt);
  request.compiled_cid = compiled_cid;
  request.replied_cid = (OZ_ClassID)0;
  request.queue_elt = &queue_elt;
  queue_elt.request = &request;
  FqEnqueueRequestAndWait((SimpleRequest)&queue_elt, &config_queue);
  return(request.replied_cid);
}

OZ_ConfigurationRequest OzOmConfiguration()
{
  OZ_ConfigQueueElt queue_elt
    = (OZ_ConfigQueueElt)FqReceiveRequest(&config_queue);
  return queue_elt->request;
}

void OzOmConfigurationReply(OZ_ClassID cid, OZ_ConfigurationRequest request)
{
  OZ_ConfigQueueElt queue_elt = request->queue_elt;
  request->replied_cid = cid;
  FqWakeupFaultSender((SimpleRequest)queue_elt);
}

int CnfInit()
{
  FqInitializeFaultQueue((FaultQueue)&config_queue);
  return( 0 ) ;
}
