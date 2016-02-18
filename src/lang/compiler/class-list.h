/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _CLASS_LIST_H
#define _CLASS_LIST_H

#include "lang/internal.h"

typedef struct ClassList_Rec {
  struct ClassList_Rec *next;
  OO_ClassType class;
  int count;
  char name[1];
} ClassList_Rec, *ClassList;

extern OO_ClassType SearchClass (char *);
extern void EmitUsedHeader (FILE *fp);
extern OO_ClassType GetClassFromUsedList (long long);
extern void RemoveFromClassList (char *);
extern ClassList AddClassList (char *);
extern void PrintClassList ();

extern FILE *PrivateOutputFileH;

extern void EmitImported ();
extern void EmitImportedForRecord ();

extern struct OO_ClassType_Rec *SetClassStatus (long long, int);
extern void AddClassType (OO_ClassType);

extern void EmitUsedClasses (FILE *);

#endif _CLASS_LIST_H
