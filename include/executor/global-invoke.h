/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_GLOBAL_INVOKE_H_
#define _EXEC_GLOBAL_INVOKE_H_

#include <stdarg.h>
#include "oz++/object-type.h"

extern long long OzExecGlobalInvoke
  (OID caller, OID callee, OID cvid, int slot1, int slot2, char *fmt,
#if 1
   int dummy1, int dummy2, ...);
#else
   int dummy1, int dummy2, OZ_Object o, ...);
#endif

#endif /* _EXEC_GLOBAL_INVOKE_H_ */
