/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXCEPT_H_
#define _EXCEPT_H_

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
};

static int sys_except_num = 9;

#endif _EXCEPT_H_
