/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EMIT_METHOD_H_
#define _EMIT_METHOD_H_

#include "lang/internal.h"

typedef struct EmitMethodsRec {
  struct EmitMethodsRec *next;
  OO_Symbol sym;
} EmitMethodsRec, *EmitMethods;

extern void EmitMethodsBefore (FILE *);
extern void EmitMethodsAfter ();
extern void EmitMethodsAfterInStatic ();
extern void EmitMethodsHeader (FILE *);

extern void EmitFirst (FILE *);

extern void EmitMethod (FILE *, OO_Symbol);
extern void EmitMethodAfter (FILE *);

extern void EmitVars (FILE *, OO_Block);

extern void EmitBlockBefore (FILE *);
extern void EmitBlockAfter (FILE *);

extern FILE *PrivateOutputFileC;

#endif _EMIT_METHOD_H_
