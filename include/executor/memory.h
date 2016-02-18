/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_MEMORY_H_
#define _EXEC_MEMORY_H_

/* I/F w/ OM */

extern void OzOmEnterGC(void);
extern void OzOmExitGC(void);
extern unsigned int OzOmFreeMemory(void);

#endif _EXEC_MEMORY_H_
