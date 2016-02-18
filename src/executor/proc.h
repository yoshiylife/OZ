/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_PROC_H_)
#define	_PROC_H_

#include "executor/process.h"
#include "common.h"
#include "channel.h"

#define	N_OZ_PROCESS	1024

typedef	enum	{
	PROC_FREE,
	PROC_RUNNING,
	PROC_EXITED,
	PROC_DETACHED,
	PROC_JOINED,
} ProcStatus ;

typedef	struct	OzProcessStr*	OzProcess ;
typedef	struct	OzProcessStr	OzProcessRec ;
struct	OzProcessStr {
	OzRecvChannelRec	chan ;
	ProcStatus		status ;
	PID			pid ;
	int                     aborted;
	long long		rval ;
	OZ_ConditionRec		wait_join ;
	OzProcess		next ;
	void			*args ;		/* for GC */
	int			size ;		/* for GC */
} ;

#define PROC_EXCEPT_ABORTED         1
#define PROC_EXCEPT_DOUBLE_FAULT    2

extern int PrInit(void);
extern int PrMapProcessTable( int (func)(), void *arg ) ;

#endif	_PROC_H_
