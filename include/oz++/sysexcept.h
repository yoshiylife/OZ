/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OZ_SYSEXCEPT_H_
#define _OZ_SYSEXCEPT_H_
#include "executor/exception.h"

#define INTERSITE

#ifdef INTERSITE
#define NO_SYS_EXCEPTION 16
#else
#define NO_SYS_EXCEPTION 15
#endif

extern OZ_ExceptionIDRec OzExceptionDoubleFault;
extern OZ_ExceptionIDRec OzExceptionAny;
extern OZ_ExceptionIDRec OzExceptionAbort;
extern OZ_ExceptionIDRec OzExceptionChildAborted;
extern OZ_ExceptionIDRec OzExceptionObjectNotFound;
extern OZ_ExceptionIDRec OzExceptionClassNotFound;
extern OZ_ExceptionIDRec OzExceptionCodeNotFound;
extern OZ_ExceptionIDRec OzExceptionLayoutNotFound;
extern OZ_ExceptionIDRec OzExceptionGlobalInvokeFailed;
extern OZ_ExceptionIDRec OzExceptionNoMemory;
extern OZ_ExceptionIDRec OzExceptionForkFailed;
extern OZ_ExceptionIDRec OzExceptionKillSelf;
extern OZ_ExceptionIDRec OzExceptionChildDoubleFault;
extern OZ_ExceptionIDRec OzExceptionIllegalInvoke;
extern OZ_ExceptionIDRec OzExceptionNarrowFailed;
extern OZ_ExceptionIDRec OzExceptionArrayRangeOverflow;
extern OZ_ExceptionIDRec OzExceptionTypeCorrectionFailed;

#ifdef INTERSITE
extern OZ_ExceptionIDRec OzExceptionForeignAccessViolation;
#endif
#endif  _OZ_SYSEXCEPT_H_
