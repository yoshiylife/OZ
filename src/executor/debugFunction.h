/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_DEBUG_FUNCTION_H_
#define	_DEBUG_FUNCTION_H_

/* unix system include */
#include	<sys/time.h>
/* multithread system include */
#include	"thread/thread.h"

#include	"executor/executor.h"
#include	"channel.h"
#include	"proc.h"
#include	"ot.h"
#include	"cl.h"
#include	"global-trace.h"

#define	DM_ECHO		0
#define	DM_READ		1
#define	DM_WRITE	2
#define	DM_TTABLE	3
#define	DM_PTABLE	4
#define	DM_OTABLE	5
#define	DM_OGETENTRY	6
#define	DM_ORELENTRY	7
#define	DM_TSUSPEND	8
#define	DM_TRESUME	9
#define	DM_LGETROOT	10
#define	DM_LGETNEXT	11
#define	DM_LGETFIND	12
#define	DM_OSUSPEND	13
#define	DM_ORESUME	14
#define	DM_GTRACE	15
#define	DM_GSTEP	16
#define	DM_GCONT	17
#define	DM_GLOGON	18
#define	DM_GLOGOFF	19
#define	DM_PKILL	20
#define	DM_SSEARCH	21
#define	DM_SERVPORT	22		/* for IPA '94 Oct. Demo */
#define	DM_OGETTOP	23
#define	DM_INETPORT	24	/* Don't Change this number, for IPA '94 Oct. Demo */
#define	DM_TLIST	30
#define	DM_CCODE	40
#define	DM_EXECID	50
#define	DM_ARCHID	51
#define	DM_DBGMSG	52
#define	DM_TCONT	53
#define	DM_NOTIFY	54
#define	DM_CGET		55
#define	DM_IDLETIME	56
#define	DM_CGETID	57

/* DM_TTABLE */
typedef	struct	{
	OZ_Thread	entry ;
	int		id ;
	int		status ;
	OzRecvChannel	rchan ;
} DmTTableSlot ;
typedef	struct	{
	int		count ;
	int		pad ;
	DmTTableSlot	slot[1] ;
} DmTTable ;
#define	SIZEOF_DmTTable(xxx)	(sizeof(DmTTable)+(xxx-1)*sizeof(DmTTableSlot))

/* DM_PTABLE */
typedef	struct	{
	OzProcess	entry ;
	PID		pid ;
	int		status ;
	OID		callee ;
	OID		caller ;
	OZ_Thread	t ;
} DmPTableSlot ;
typedef	struct	{
	int		count ;
	int		pad ;
	DmPTableSlot	slot[1] ;
} DmPTable ;
#define	SIZEOF_DmPTable(xxx)	(sizeof(DmPTable)+(xxx-1)*sizeof(DmPTableSlot))

/* DM_OTABLE */
typedef	struct	{
	OID			cid ;
	OID			oid ;
	OZ_ObjectStatus		status ;
	int			flags ;
} DmOTableSlot ;
typedef	struct	{
	int		count ;
	int		pad ;
	DmOTableSlot	slot[1] ;
} DmOTable ;
#define	SIZEOF_DmOTable(xxx)	(sizeof(DmOTable)+(xxx-1)*sizeof(DmOTableSlot))

/* DM_LGETROOT & DM_LGETNEXT */
typedef	struct	{
	OID		caller ;
	OID		callee ;
	OzChannel	chan ;
	OZ_Thread	t ;
} DmLink ;

/* DM_OGETENTRY */
typedef	struct	{
	ObjectTableEntry	entry ;
	OZ_ObjectStatus		status ;
	OZ_Object		object ;
	OZ_Header		head ;
	int			parts ;
	unsigned int		size ;
	OZ_ClassID		cid ;
} DmOEntry ;

/* DM_TLIST */
typedef	struct	{
	PID		pid ;
	OID		caller ;
	OZ_Thread	t ;
	TStat		status ;
	int		suspend_count ;
} DmTListSlot ;
typedef	struct	{
	int		count ;
	int		pad ;
	DmTListSlot	slot[1] ;
} DmTList ;
#define	SIZEOF_DmTList(xxx)	(sizeof(DmTList)+(xxx-1)*sizeof(DmTListSlot))
	
/* DM_CGETCODE */
typedef	struct	{
	ClassCode	code ;
	unsigned long	base ;
	unsigned long	size ;
} DmCCode ;

/* DM_GSTEP */
typedef	struct	{
	int		phase ;
	PID		pid ;
	OID		caller ;
	OID		callee ;
	OZ_ClassID	cvid ;
	int		slot1 ;
	int		slot2 ;
	OZ_Object	self ;
	OzRecvChannel	rchan ;
	struct timeval	tp ;
	struct timezone	tzp ;
} DmGTrace ;

#endif	!_DEBUG_FUNCTION_H_
