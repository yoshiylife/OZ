/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _BLOCK_H_
#define _BLOCK_H_

#include "exp.h"
#include "type.h"

extern OO_Block CurrentBlock;

extern OO_Block CreateBlock ();
extern OO_Symbol CurrentMethod;
extern void DestroyBlock ();

extern void UpBlock ();
extern void DownBlock ();

extern OO_Symbol AddVar (int, char *, int, TypedSymbol, OO_Expr, int);
extern OO_Symbol AddMethod (int, char *, int, MethodSymbol, int);
extern OO_Symbol GetMethod (char *, OO_ClassType, int, int);
extern OO_Symbol GetConstructor (OO_Expr, char *);
extern OO_ClassType GetDefinedClass (OO_Symbol, OO_ClassType);

#endif
