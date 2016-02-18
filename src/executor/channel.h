/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_CHANNEL_H_
#define	_CHANNEL_H_
/* unix system include */
#include <stdarg.h>

/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"

/* executor include */
#include "except.h"
#include "ot.h"

#define	NORMAL		0
#define	EXCEPTION	1
#define	ERROR		2

typedef	struct	OzSendChannelStr*	OzSendChannel ;
typedef	struct	OzSendChannelStr	OzSendChannelRec ;
typedef	struct	OzRecvChannelStr*	OzRecvChannel ;
typedef	struct	OzRecvChannelStr	OzRecvChannelRec ;
typedef	struct	OzRecvChannelOpsStr	OzRecvChannelOpsRec, *OzRecvChannelOps ;

/* oz++ process id */
typedef	long long	PID ;

/* channel */
typedef	union	{
	OzSendChannel	schan ;
	OzRecvChannel	rchan ;
	long long	msgID ;
} OzChannel ;

/* send channel */
typedef	struct	OzSendChannelOpsRec	{
	/* send to receive channel */
	void	(*send_cvid)( OzSendChannel aSelf, OID aCompVerID ) ;
	void	(*send_slot)( OzSendChannel aSelf, int aSlot1, int aSlot2 ) ;
	void	(*send_args)( OzSendChannel aSelf, char *aForm, va_list aArgs );
	void	(*send_exception_list)( OzSendChannel aSelf,
					Oz_ExceptionCatchTable aExcepList ) ;
	/* receive from receive channel */
	int			(*recv_return)( OzSendChannel aSelf ) ;
	long long		(*recv_value)( OzSendChannel aSelf ) ;
	OZ_ExceptionIDRec	(*recv_exception)( OzSendChannel aSelf ) ;
	char            	(*recv_exception_fmt)(OzSendChannel sc);
	long long       	(*recv_exception_param)(OzSendChannel sc) ;
	void			(*send_abort)( OzSendChannel aSelf ) ;
	/* free channel */
	void			(*free)( OzSendChannel aSelf ) ;
} OzSendChannelOpsRec, *OzSendChannelOps ;

struct	OzSendChannelStr	{
	OzSendChannelOps	ops ;
	OID			callee ;
	OzRecvChannel		prev ;
	OzChannel		peer ;
	struct	{
			long long	rval ;
			long long	eparam ;
	} vars ;
} ;

/* recv channel */
struct	OzRecvChannelOpsStr	{
	/* receive from send channel */
	OID	(*recv_cvid)( OzRecvChannel aSelf ) ;
	int	(*recv_slot)( OzRecvChannel aSelf ) ;
	char	*(*recv_fmt)( OzRecvChannel aSelf ) ;
	void	*(*recv_args)( OzRecvChannel aSelf ) ;
	Oz_ExceptionCatchTable
		(*recv_exception_list)( OzRecvChannel aSelf ) ;
	/* send to send channel */
	void	(*send_return)( OzRecvChannel aSelf, int aReturn ) ;
	void	(*send_value)( OzRecvChannel aSelf, long long aReturn ) ;
	void	(*send_exception)(OzRecvChannel aSelf, OZ_ExceptionIDRec eid,
						long long param, char fmt ) ;
	void	(*free)( OzRecvChannel aSelf ) ;
} ;

struct	OzRecvChannelStr	{
	OzRecvChannelOps	ops ;
	OID			callee ;
	OID			caller ;
	PID			pid ;
	ObjectTableEntry	o ;
	OZ_Thread		t ;
	struct	{
		OZ_MonitorRec		lock ;
		OzChannel		peer ;
		OzSendChannel		next ;
		int			readyToInvoke ;
		OID			cvid ;
		int			slot1 ;
		int			slot2 ;
		va_list			args ;
		char			*fmt ;
		Oz_ExceptionCatchTable	elist ;
	} vars ;
} ;

#endif	!_CHANNEL_H_
