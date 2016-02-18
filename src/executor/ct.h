/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _CT_H_
#define _CT_H_
/* multithread system include */
#include "thread/monitor.h"

#include "fault-q.h"
#include "oh-header.h"
#include "oz++/class-type.h"

typedef struct OZ_ClassRec {
  FaultQueueElementRec fault_elt;
  OZ_ClassID cid;
  enum {CT_ABSENT, CT_CREATING, CT_CREATED} state;
  OZ_MonitorRec lock;
  OZ_ConditionRec class_created;
  int ref_count;
  int size;
  OZ_ClassInfo class_info;
} OZ_ClassRec, *OZ_Class;

extern int CtInit(void);
extern void CtReleaseClass(OZ_Class class);
extern OZ_Class CtGetClass(OZ_ClassID cid);

#endif !_CT_H_

