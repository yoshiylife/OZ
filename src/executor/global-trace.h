/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_GLOBAL_TRACE_H)
#define	_OZ_GLOBAL_TRACE_H

#include "ot.h"
#include "except.h"
#include "channel.h"

#define	TRACE_NONE		0x0000

/* Trace Mode */
#define	TRACE_MODE		0x0f00
#define	TRACE_LOG		0x0100
#define	TRACE_STEP		0x0200
#define	TRACE_TIME		0x0400
#define	TRACE_RECORD		0x0800

/* Trace Type */
#define	TRACE_TYPE		0x00f0
#define	TRACE_CALLER		0x0010
#define	TRACE_CALLEE		0x0020

/* Trace Phase */
#define	TRACE_PHASE		0x000f
#define	TRACE_ENTRY		0x0001
#define	TRACE_RETURN		0x0002
#define	TRACE_EXCEPTION		0x0004
#define	TRACE_ERROR		0x0008

typedef	struct	OzGlobalObjectTraceInfoStr*	OzGlobalObjectTraceInfo ;
typedef	struct	OzGlobalObjectTraceInfoStr	OzGlobalObjectTraceInfoRec ;
struct	OzGlobalObjectTraceInfoStr	{
	int			phase ;
	OZ_Object		self ;
	OID			caller ;
	OID			callee ;
	OID			cvid ;
	int			slot1 ;
	int			slot2 ;
	char			*fmt ;
	va_list			args ;
	int			size ;
	Oz_ExceptionCatchTable	elist ;
	union	{
		long long	value ;
		OZ_ExceptionIDRec exception;
	} ret ;
} ;

extern	void	OzGlobalObjectTrace( OzGlobalObjectTraceInfo aInfo ) ;
extern	int	OzGlobalObjectTraceSet( ObjectTableEntry aEntry, int aMode , void (*aFunction)(), void *aArguments ) ;
extern	void	*OzGlobalObjectTraceReset( ObjectTableEntry aEntry ) ;

inline	extern	int
OzGlobalObjectTraceCheck()
{
	return ((OzRecvChannel)ThrRunningThread->channel)->o->trace_flag ;
}

#endif	/* _OZ_GLOBAL_TRACE_H */
