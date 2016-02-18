/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdio.h>
#include <stdarg.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/testandset.h"

#include "switch.h"
#include "channel.h"
#include "except.h"
#include "global-trace.h"

int
OzGlobalObjectTraceSet( ObjectTableEntry aEntry, int aMode , void (*aFunction)(), void *aArguments )
{
	int	ret = -1 ;

	OzExecEnterMonitor( &aEntry->trace_lock ) ;
	if ( ! TestAndSet( &aEntry->trace_flag ) ) {
		aEntry->trace_mode = aMode ;
		aEntry->trace_func = aFunction ;
		aEntry->trace_args = aArguments ;
		ret = 0 ;
	}
	OzExecExitMonitor( &aEntry->trace_lock ) ;

	return( ret ) ;
}

void*
OzGlobalObjectTraceReset( ObjectTableEntry aEntry )
{
	void	*args ;

	OzExecEnterMonitor( &aEntry->trace_lock ) ;
	aEntry->trace_flag = 0 ;
	aEntry->trace_mode = TRACE_NONE ;
	aEntry->trace_func =  NULL ;
	args = aEntry->trace_args ;
	OzExecExitMonitor( &aEntry->trace_lock ) ;

	return( args ) ;
}

void
OzGlobalObjectTrace( OzGlobalObjectTraceInfo aInfo )
{
	ObjectTableEntry	entry ;
	OzRecvChannel		rchan ;

	rchan = (OzRecvChannel)ThrRunningThread->channel ;
	entry = rchan->o ;

	OzExecEnterMonitor( &entry->trace_lock ) ;
	if ( entry->trace_flag ) {
		if ( (aInfo->phase & TRACE_TYPE ) & entry->trace_mode ) {
			if ( (aInfo->phase & TRACE_PHASE ) & entry->trace_mode ) {
				aInfo->phase |= (TRACE_MODE&entry->trace_mode) ;
				entry->trace_func( entry->trace_args, rchan, aInfo ) ;
			}
		}
	}
	OzExecExitMonitor( &entry->trace_lock ) ;

	return ;
}
