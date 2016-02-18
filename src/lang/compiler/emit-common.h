/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EMIT_COMMON_H
#define _EMIT_COMMON_H

#include "executor/executor.h"

extern void Emit (FILE *fp, char *, ...);
extern void EmitIndent (FILE *);
extern void EmitIndentReset ();
extern void EmitIndentUp ();
extern void EmitIndentDown ();
extern void EmitType (FILE *, OO_Type);
extern void EmitExp (FILE *, OO_Expr);
extern void EmitSemiColon (FILE *);
extern void EmitInline (FILE *, char *);
extern void EmitVID (FILE *, long long, int);
extern void EmitClassName (FILE *, char *);
extern void EmitAsClassOf (FILE *, ClassID, int, ClassID, OO_Expr);
extern void EmitRecordZeroInit (FILE *fp, OO_ClassType cl);

#define METHOD_PREFIX "_oz_"

#endif _EMIT_COMMON_H
