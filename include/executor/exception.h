/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_EXEC_EXCEPTION_H_
#define	_EXEC_EXCEPTION_H_

#include <setjmp.h>
#include "oz++/object-type.h"

#if	#system(svr4)
#define	SETJMP( env )		setjmp( (env) )
#define	LONGJMP( env, val )	longjmp( (env), (val) )
#endif
#if	#system(bsd)
#define	SETJMP( env )		_setjmp( (env) )
#define	LONGJMP( env, val )	_longjmp( (env), (val) )
#endif

typedef	struct OZ_ExceptionIDRec {
  OID cid;
  unsigned int val;
  int pad;
} OZ_ExceptionIDRec, *OZ_ExceptionID;

typedef struct OZ_ExceptionImplStr *OZ_ExceptionImpl;

typedef struct OZ_ExceptionRec {
  OZ_ExceptionIDRec eid;
  long long param;
  jmp_buf jmp;
  OZ_ExceptionImpl eimpl;
} OZ_ExceptionRec, *OZ_Exception;

extern int OzExecEidcmp(OZ_ExceptionIDRec x, OZ_ExceptionIDRec y);
extern void OzExecInitializeExceptionHandler(OZ_Exception e_rec, int n);
extern void OzExecRegisterExceptionHandlerFor(OZ_Exception e_rec);
extern void OzExecUnregisterExceptionHandler(void);
extern void OzExecRaise(OZ_ExceptionIDRec eid, long long param, char fmt);
extern void OzExecReRaise(void);
extern void OzExecHandlingException(OZ_Exception e_rec);
extern void OzExecPutEidIntoCatchTable
  (OZ_Exception e_rec, OZ_ExceptionIDRec eid);

#endif	_EXEC_EXCEPTION_H_
