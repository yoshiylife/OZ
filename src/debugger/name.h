/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_DEBUGGER_NAME_H)
#define	_OZ_DEBUGGER_NAME_H

#include "executor/object-table.h"
#include "channel.h"
#include "proc.h"

extern	const	char*
ObjectStatusToName( OZ_ObjectStatus aStatus ) ;

extern	const	char*
ArrayTypeToName( long long aType ) ;

extern	const	char*
ProcStatusToName( ProcStatus aStatus ) ;

extern	const	char*
TStatToName( TStat aStatus ) ;

extern	const	char*
TraceModeToName( int aMode ) ;

extern	const	char*
TraceTypeToName( int aType ) ;

extern	const	char*
TracePhaseToName( int aPhase ) ;

#endif	_OZ_DEBUGGER_NAME_H
