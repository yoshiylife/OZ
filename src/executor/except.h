/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_EXCEPT_H_
#define	_EXCEPT_H_

#include "executor/executor.h"
#include "executor/exception.h"

typedef struct Oz_ExceptionCatchTableStr *Oz_ExceptionCatchTable;
typedef struct Oz_ExceptionCatchTableStr Oz_ExceptionCatchTableRec;

struct Oz_ExceptionCatchTableStr {
  unsigned int number_of_entries;
  int cnt;
  OZ_ExceptionIDRec exceptions[1];
};

typedef struct OZ_ExceptionImplStr ExceptionImplRec;

struct OZ_ExceptionImplStr {
  OZ_Exception next;
  char fmt;
  char handling;
  char pad[2];
  void *imp;
  Oz_ExceptionCatchTableRec table;
};

extern void ExInitializeExceptionHandlerWith
  (OZ_Exception e_rec, Oz_ExceptionCatchTable exception_list);

extern Oz_ExceptionCatchTable ExMergeExceptionList(void);

#endif	_EXCEPT_H_
