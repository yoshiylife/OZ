/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_METHOD_INVOKE_H_
#define _EXEC_METHOD_INVOKE_H_

#include "executor/executor.h"
#include "executor/alloc.h"

typedef struct OZ_MethodImplementationRec {
  OZ_FunctionPtr function;   /* Compiler assumes this member */

  struct OZ_MethodImplementationRec *next;
  void *code;
} OZ_MethodImplementationRec, *OZ_MethodImplementation;

extern void *OzExecGetMethodImplementation(void);

extern void OzExecFindMethodImplementation
  (OZ_MethodImplementation imp, OZ_Object obj,
   int class_number_diff, unsigned int method_number);
extern void OzExecFreeMethodImplementation(OZ_MethodImplementation prev_imp);

#endif /* _EXEC_METHOD_INVOKE_H_ */
