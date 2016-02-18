/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _LANG_SYSEXCEPT_H_
#define _LANG_SYSEXCEPT_H_

#define NO_SYS_EXCEPTION 15

static char sys_except[][20] = 
{ 
  "Abort", 
  "ChildAborted", 
  "ObjectNotFound", 
  "ClassNotFound",
  "CodeNotFound", 
  "LayoutNotFound", 
  "GlobalInvokeFailed", 
  "NoMemory", 
  "ForkFailed",
  "KillSelf",
  "ChildDoubleFault",
  "IllegalInvoke",
  "NarrowFailed",
  "ArrayRangeOverflow",
  "TypeCorrectionFailed",
};

#endif  _LANG_SYSEXCEPT_H_
