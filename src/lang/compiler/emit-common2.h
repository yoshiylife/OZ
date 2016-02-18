/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EMIT_COMMON2_H
#define _EMIT_COMMON2_H

#include <varargs.h>

extern void Emit2 (FILE *, char *, va_list);
extern void EmitIndentReset ();
extern void EmitIndentUp ();
extern void EmitIndentDown ();
#if 0
extern void EmitSCQF (char *, int);
#endif

#endif _EMIT_COMMON_H
