/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _CB_H_
#define _CB_H_

#include "lang/internal.h"

extern char *GetVID2 (char *, int);
extern int LoadSubSchool (char *);

extern void PrintRuntimeClassInfo ();
extern int LoadRuntimeClassInfo (char *);

extern void Emit (FILE *, char *, ...);
extern void Emit2 (FILE *, char *, ...);

extern void PrintClass (struct OO_ClassType_Rec *, int, int);
extern void PrintMember (struct OO_Symbol_Rec *, int, int);

extern struct OO_ClassType_Rec *LoadClassInfo (char *, int);
extern struct OO_ClassType_Rec *LoadClassFromZ (char *, int);
extern struct OO_Symbol_Rec *SearchMember (struct OO_ClassType_Rec *, char *);

extern void FatalError (char *, ...);

extern struct OO_ClassType_Rec *CreateClass (char *, int, int);
extern void DestroyClass (OO_ClassType);

extern OO_Symbol CreateSymbol (char *);
extern void DestroySymbol (OO_Symbol);

extern OO_List CreateList (OO_Object, OO_Object);
extern OO_List AppendList (OO_List *, OO_List);
extern void DestroyList (OO_List);

#endif _CB_H_
