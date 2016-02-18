/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_CLASS_TABLE_H_
#define _EXEC_CLASS_TABLE_H_

#include "executor/executor.h"

extern void OzOmPreloadRuntimeClassInfo(OZ_ClassID cid, char *filename);
extern int OzOmRemoveClass(OZ_ClassID cid);
extern void OzOmLoadClass(OZ_ClassID cid, char *filename);
extern ClassID OzOmClassRequest(void);
void OzOmGCollectClassInfo(void);

#endif /* _EXEC_CLASS_TABLE_H_ */

