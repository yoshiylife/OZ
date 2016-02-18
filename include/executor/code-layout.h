/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_CODE_LAYOUT_H_
#define _EXEC_CODE_LAYOUT_H_

#include "executor/executor.h"

extern int OzOmRemoveCode(OZ_ClassID cid);
extern void OzOmDisableCodeGC(OZ_ClassID cid);
extern void OzOmEnableCodeGC(OZ_ClassID cid);
extern int OzOmRemoveLayout(OZ_ClassID cid);
extern void OzOmLoadCode(OZ_ClassID cid, char *file);
extern void OzOmPreloadCode(OID cid, char *file);
extern void OzOmLoadLayout(OZ_ClassID cid, char *filename);
extern void OzOmPreloadLayout(OZ_ClassID cid, char *filename);
extern OZ_ClassID OzOmCodeFault(void);
extern OZ_ClassID OzOmLayoutFault(void);
void OzOmGCollectCodes(void);
void OzOmGCollectLayoutInfo(void);

#endif /* _EXEC_CODE_LAYOUT_H_ */
