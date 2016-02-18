/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_CL_H_
#define	_CL_H_
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"

#include "executor/executor.h"
#include "oz++/layout-info.h"
#include "oz++/debug.h"
#include "oh-header.h"
#include "fault-q.h"

typedef struct ClassCodeStr *ClassCode;
typedef struct ClassCodeStr ClassCodeRec;

typedef	enum	{
  CL_ABSENT,
  CL_LOADING,
  CL_LOADED
} CodeLayoutStatus ;

struct ClassCodeStr {
  FaultQueueElementRec fault_elt;
  OZ_ClassID cid;
  OZ_MonitorRec lock;
  OZ_FunctionPtrTableRec *fp_table;
  OZ_ImportedCodesRec *imported_codes;
  OZ_DebugInfo	debugInfo;
  int is_static;
  CodeLayoutStatus state;
  OZ_ConditionRec loaded;
  int ref_count;
  ClassCode b_prev; /* to implement relocation wait queue */
  ClassCode b_next; /* to implement relocation wait queue */
  char		*addr;
  int		size;
  char		*sym_fname; /* debug symbol file name for debugger */
  struct nlist	*sym_nlist;/* debug symbol table for debugger */
  struct nlist	*sym_break;/* debug symbol table brak for debugger */
  char		*sym_strs; /* debug symbol strings for debugger */
  OZ_ExportedFunctions exported_funcs;
  struct link_dynamic *DYNAMIC;
};

typedef struct ClassLayoutRec *ClassLayout;
typedef struct ClassLayoutRec ClassLayoutRec;

struct ClassLayoutRec {
  FaultQueueElementRec fault_elt;
  OZ_ClassID cid;
  OZ_MonitorRec lock;
  CodeLayoutStatus state;
  int size;
  OZ_Layout layout_info;
  OZ_ConditionRec loaded;
  int ref_count;
};

extern int ClInit(void);
extern ClassCode ClGetCode(OZ_ClassID cid);
extern void ClReleaseCode(ClassCode code);
extern ClassLayout ClGetLayout(OZ_ClassID cid);
extern void ClReleaseLayout(ClassLayout layout);
extern int ClMapCode(int (func)(), void *args);
extern int ClMapLayout(int (func)(), void *args);

#endif	! _CL_H_
