/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_NCL_IF_H_
#define _EXEC_NCL_IF_H_

#include "executor/executor.h"

typedef struct OZ_BroadcastParameterRec {
  OID sender;
  int id;
  OID param1;
  int param2;
} OZ_BroadcastParameterRec, *OZ_BroadcastParameter;

extern void OzOmBroadcast(OZ_BroadcastParameterRec param);
extern OZ_BroadcastParameterRec OzOmReceiveBroadcast(void);
extern OID OzOmCreatExecutor(long nclid, OID exid);
extern void OzOmBroadcastReady(void);
extern int OzOmWaitShutdownRequest(void);
extern int OzOmShutdownRequest(void);

#endif  _EXEC_NCL_IF_H_
