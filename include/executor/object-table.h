/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_OBJECT_TABLE_H_
#define _EXEC_OBJECT_TABLE_H_

#include "executor/executor.h"

typedef	enum	{
  OT_READY,
  OT_QUEUE,
  OT_STOP
} OZ_ObjectStatus ;

extern OID OzOmAllocateCell(OZ_ClassID cid);
OID OzOmObjectTableDownLoad(OID oid, int status);
extern OID OzOmObjectTableChangeStatus(OID oid, int status);
extern int OzOmObjectTableStatus(OID oid);
#ifdef 0
extern int OzOmSchedulerWaitThread(OID oid, int time);
#else
extern int OzOmSchedulerWaitThread(OID oid);
#endif
extern OID OzOmObjectTableCellIn(OID oid);
extern OID OzOmObjectTableCellOut(OID oid);
extern OID OzOmObjectTableLoad(OID oid);
extern OID OzOmObjectTableFlush(OID oid);
extern int OzOmObjectTableIsLoaded(OID oid);
extern void OzOmObjectTableResetAccessFlag(OID oid);
extern int OzOmObjectTableIsAccessed(OID oid);
extern OID OzOmQueuedInvocation(void);
extern void OzOmGCollectObject(OID oid, int compact);
extern OID OzOmCallerOfThisMethod(void);
extern int OzOmMyArchitecture(void);
extern void OzOmShutdownExecutor(void);
extern int OzOmObjectTableSuspend(OID aTarget) ;
extern int OzOmObjectTableResume(OID aTarget) ;

#endif /* _EXEC_OBJECT_TABLE_H_ */
