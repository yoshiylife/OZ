/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_EXEC_MONITOR_H
#define	_EXEC_MONITOR_H

#ifndef	_OZ_MONITOR
typedef	struct	{
	char    pad[8];
} OZ_MonitorRec, *OZ_Monitor;
#define	_OZ_MONITOR
#endif	!_OZ_MONITOR

#ifndef	_OZ_CONDITION
typedef	struct	{
	char    pad[8];
} OZ_ConditionRec, *OZ_Condition;
#define	_OZ_CONDITION
#endif	!_OZ_CONDITION

/*
 * prototypes
 */

extern void OzExecInitializeCondition( OZ_Condition cv, int abortable );
extern void OzExecEnterMonitor(OZ_Monitor ml);
extern void OzExecExitMonitor(OZ_Monitor ml);
extern void OzExecWaitConditionWithTimeout
  (OZ_Monitor ml, OZ_Condition cv, int timeout);
extern void OzExecSignalCondition(OZ_Condition cv);
extern void OzExecSignalConditionAll(OZ_Condition cv);
extern int  OzExecThreadShouldBeAborted();

/*
 * inline functions
 */

inline	extern	void
OzExecWaitCondition( OZ_Monitor ml, OZ_Condition cv )
{
	OzExecWaitConditionWithTimeout(ml,cv,0) ;
}

#endif	!_EXEC_MONITOR_H
