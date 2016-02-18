/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _G_INVOKE_H_
#define _G_INVOKE_H_
/* unix system include */
#include <stdarg.h>

#include "global-trace.h"
#include "channel.h"

typedef OZ_ClassID OZ_ClassPartID;

extern void GiGlobalInvokeStub(OzRecvChannel chan);

#define TRACE(x, cr, ce)                                        \
  if ( OzGlobalObjectTraceCheck() ) {                           \
	OzGlobalObjectTraceInfo	info ;                          \
	info = (OzGlobalObjectTraceInfo)                        \
	  OzMalloc( sizeof(OzGlobalObjectTraceInfoRec) ) ;      \
	if ( info ) {                                           \
		info->phase = TRACE_CALLER|TRACE_ENTRY ;        \
		info->self = (x) ;                              \
		info->caller = (cr) ;                           \
		info->callee = (ce) ;                           \
		info->cvid = cvid ;                             \
		info->slot1 = slot1 ;                           \
		info->slot2 = slot2 ;                           \
		info->fmt = fmt ;                               \
		info->args = args ;                             \
		info->elist = exception_list ;                  \
		OzGlobalObjectTrace( info ) ;                   \
		OzFree( info ) ;                                \
	}                                                       \
  }

#endif _G_INVOKE_H_
