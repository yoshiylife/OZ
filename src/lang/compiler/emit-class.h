/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EMIT_CLASS_H
#define _EMIT_CLASS_H

#include "lang/internal.h"

extern void EmitClassFileZ (OO_ClassType, int);
extern void EmitClassFileI (OO_ClassType);

extern FILE *ProtectedOutputFileZ;
extern FILE *PublicOutputFileZ;
extern FILE *PrivateOutputFileI;

#endif _EMIT_CLASS_H
