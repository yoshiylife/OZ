/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_CONFIG_REQ_H_
#define _EXEC_CONFIG_REQ_H_

#include "executor/executor.h"

typedef struct OZ_ConfigQueueEltStr *OZ_ConfigQueueElt;

typedef struct OZ_ConfigurationRequestRec {
  ClassID replied_cid;
  ClassID compiled_cid;
  OZ_ConfigQueueElt queue_elt;
} OZ_ConfigurationRequestRec, *OZ_ConfigurationRequest;

extern OZ_ConfigurationRequest OzOmConfiguration(void);
extern void OzOmConfigurationReply
  (OZ_ClassID cid, OZ_ConfigurationRequest request);

#endif _EXEC_CONFIG_REQ_H_
