/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OT_H_
#define _OT_H_
/* multithread system include */
#include "thread/monitor.h"

#include "mem.h"
#include "fault-q.h"
#include "oh-header.h"
#include "executor/object-table.h"
#include "executor/executor.h"
#include "oz++/object-type.h"

typedef struct ObjectTableEntryStr *ObjectTableEntry;
typedef struct ObjectTableEntryStr ObjectTableEntryRec;

#define OBJECT_TABLE_SIZE 1024

struct ObjectTableEntryStr {
  HashHeaderRec hash_header;
  OID oid;
  OZ_ObjectStatus status ;
  int flags;
  Heap heap;
  OZ_Object object;
  OZ_MonitorRec lock;
  OZ_ConditionRec object_ready;
  OZ_ConditionRec all_messages_processed;
  int call_count;  /* to determine when all messages have processed */
  int op_count;    /* someone is operating on the entry */

  OZ_ConditionRec object_suspend ;
  OZ_Thread threads ;

  OZ_MonitorRec	trace_lock ;
  int		trace_mode ;
  void		(*trace_func)() ;
  void		*trace_args ;

  char		trace_flag ;	/* Not need Monitor Lock */
  char accessed;
};

/* flags */
#define OT_ACCESSED 0x1   /* indicates that the methods have been invoked */
#define OT_LOADED   0x2   /* indicates that the object has been loaded into the
			     virtual memory */
#define OT_LOADING  0x4   /* to avoid duplicated 'cell_in's and 'loadings'. */
#define	OT_SUSPEND  0x10  /* indicates that the object has been suspended. */

/* return values of `OzSchedulerWaitThread' */
#define TIME_OUT   0
#define SUCCEEDED  1

/* !!! Assumed return values of Encoder/Decoder !!! */
#define DECODE_FAILED  -1
#define ENCODE_FAILED  -1

extern void OtReleaseEntry(ObjectTableEntry entry);
extern int OtInit(void);
extern int OtMapObjectTable(int (func)(),void *args);
extern int OtMapObjectTableWithoutLock(int (func)(),void *args);
extern int OtLoadObjectCounter(char *file);
extern ObjectTableEntry OtGetEntry(OID oid);
extern ObjectTableEntry OtGetEntryRaw(OID oid);
extern int OtGlobalObjectSuspend(ObjectTableEntry aEntry);
extern int OtGlobalObjectResume(ObjectTableEntry aEntry);
extern int OtInvokePre(ObjectTableEntry entry,int slot1,int slot2);
extern void OtInvokePost(ObjectTableEntry entry);
extern Heap OtGetHeap(void);

#endif /* _OT_H_ */
