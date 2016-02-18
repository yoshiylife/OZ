/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EMIT_HEADER_H_
#define _EMIT_HEADER_H_

#include "lang/internal.h"

extern FILE *PublicOutputFileH;
extern FILE *ProtectedOutputFileH;
extern FILE *PrivateOutputFileH;

extern void EmitHeader (OO_ClassType);
extern void EmitRecordHeader (OO_ClassType);
extern void EmitRecordMemberDefinition (OO_ClassType);

extern void EmitUsedHeader (FILE *fp);

#endif _EMIT_HEADER_H_
