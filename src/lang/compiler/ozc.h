/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _OZTEST_H_
#define _OZTEST_H_

#include <stdio.h>
#include <stdlib.h>

#include "lang/internal.h"

typedef struct Member_Rec {
  int process;
  char *name;
  int array;
  struct Member_Rec *member;
} Member_Rec, *Member;

extern FILE *PrivateOutputFileL;
extern FILE *PrivateOutputFileI;
extern FILE *PrivateOutputFileD;
extern FILE *PrivateOutputFileG;

extern FILE *yyin;
extern char *yyfile;
extern int yylineno;

extern int BlockDepth;

extern int Debug, Generic;
extern int Pass;
extern int Mode;

enum ExecuteMode {
  NORMAL,
  THIS_CLASS,
  USED_CLASSES,
  INHERITED_CLASSES,
  ALL_CLASSES,
  GENERIC_PARAMS,
};

extern OO_ClassType ThisClass, PrivClass;
extern int Part;

extern char *ClassPath;
extern OO_Symbol Self;

extern int SlotNo;
extern int Object;

#ifndef OID
#include <oz++/object-type.h>
extern OID OzExecutorID;
#endif

extern int DataPad[];
extern OO_ClassType ObjectClass;
extern OO_Symbol CurrentMethod;

extern int Error;

#define THREAD_STACK 4096
#define THREAD_PRIORITY 3

FILE *EucToOctalEscape (FILE *in, char *oz_root);

#if 0
#define free(a) OzLangPrintf (a)
#endif

#endif _OZTEST_H_


