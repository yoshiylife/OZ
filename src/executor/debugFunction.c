/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include	<stdio.h>
/* multithread system include */
#include        "thread/signal.h"
#include	"thread/monitor.h"
#include        "oz++/ozlibc.h"

#include	"switch.h"
#include        "executor/alloc.h" /* OzExecGetObjectTop */
#include        "main.h"
#include	"queue.h"
#include	"debugManager.h"
#include	"debugFunction.h"
#include	"debugSupport.h"
#include	"cl.h"
#include        "dyload.h"

#define	OK		0
#define	NG		(-1)
#define	LOOP		for(;;)
#define	EXECID(xxx)	((xxx>>24)&0xffffff)

#define	DEUBG
#undef	TEST

extern	OzRecvChannel		OzSearchRemoteRecvChannel( long long aMsgID ) ;
extern	int			MyArchitectureType ;

#if	defined(TEST)
#define	OzSearchRemoteRecvChannel(xxx) 	((OzRecvChannel)(xxx))
#endif

typedef	struct	OtListStr*	OtList ;
typedef	struct	OtListStr	OtListRec ;
struct	OtListStr	{
	OtList		b_prev ;
	OtList		b_next ;
	DmOTableSlot	slot ;
} ;
	
int
OtEnque( ObjectTableEntry aEntry, OtList *aHead )
{
	OtList		list ;
	OZ_ObjectAll	top ;

	list = (OtList)OzMalloc( sizeof(OtListRec) ) ;
	if ( list == NULL ) return( NG ) ;

	if ( aEntry->object != 0 ) {
		top = OzExecGetObjectTop( aEntry->object ) ;
		list->slot.cid = top->head->a ;
	} else list->slot.cid = 0 ;
	list->slot.oid = aEntry->oid ;
	list->slot.status = aEntry->status ;
	list->slot.flags = aEntry->flags ;

	InsertQueueBinary( list, *aHead ) ;

	return( OK ) ;
}

DmOTableSlot
OtDeque( OtList *aHead )
{
	DmOTableSlot	slot = { 0, OT_STOP } ;
	OtList		list ;

	if ( *aHead == NULL ) return( slot ) ;

	list = *aHead ;
	slot = list->slot ;

	RemoveQueueBinary( list, *aHead ) ;

	OzFree( list ) ;

	return( slot ) ;
}



typedef	struct	PtListStr*	PtList ;
typedef	struct	PtListStr	PtListRec ;
struct	PtListStr	{
	PtList		b_prev ;
	PtList		b_next ;
	DmPTableSlot	slot ;
} ;

int
PtEnque( OzProcess aEntry, PtList *aHead )
{
	PtList	list ;

	list = (PtList)OzMalloc( sizeof(PtListRec) ) ;
	if ( list == NULL ) return( NG ) ;

	list->slot.entry = aEntry ;
	list->slot.pid = aEntry->pid ;
	list->slot.status = aEntry->status ;
	list->slot.callee = aEntry->chan.callee ;
	list->slot.caller = aEntry->chan.caller ;
	list->slot.t = aEntry->chan.t ;

	InsertQueueBinary( list, *aHead ) ;

	return( OK ) ;
}

DmPTableSlot
PtDeque( PtList *aHead )
{
	DmPTableSlot	slot ;
	PtList		list ;

	if ( *aHead == NULL ) return( slot ) ;

	list = *aHead ;
	slot = list->slot ;

	RemoveQueueBinary( list, *aHead ) ;

	OzFree( list ) ;

	return( slot ) ;
}

typedef	struct	TtListStr*	TtList ;
typedef	struct	TtListStr	TtListRec ;
struct	TtListStr	{
	TtList		b_prev ;
	TtList		b_next ;
	DmTTableSlot	slot ;
} ;

int
TtEnque( OZ_Thread aEntry, TtList *aHead )
{
	TtList	list ;

	list = (TtList)OzMalloc( sizeof(TtListRec) ) ;
	if ( list == NULL ) return( NG ) ;

	list->slot.entry = aEntry ;
	list->slot.id = aEntry->tid ;
	list->slot.status = aEntry->status ;
	list->slot.rchan = aEntry->channel ;

	InsertQueueBinary( list, *aHead ) ;

	return( OK ) ;
}

DmTTableSlot
TtDeque( TtList *aHead )
{
	DmTTableSlot	slot ;
	TtList		list ;

	if ( *aHead == NULL ) return( slot ) ;

	list = *aHead ;
	slot = list->slot ;

	RemoveQueueBinary( list, *aHead ) ;

	OzFree( list ) ;

	return( slot ) ;
}

static	int
DmREAD( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;
	struct	{
		void	*addr ;
		int	size ;
	} *args = aData ;
	void	*data ;

	if ( (data=DmWork( aSelf, args->size )) == NULL ) goto error ;

	if ( OzMemcpy( data, args->addr, args->size ) != data ) goto error ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmWRITE( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;
	struct	{
		void	*addr ;
		int	size ;
		char	data[1] ;
	} *args = aData ;

	if ( OzMemcpy( args->addr, args->data, args->size ) != args->addr ) goto error ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmECHO( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;
	struct	{
		char	data[1] ;
	} *args = aData ;
	void	*data ;

	if ( (data=DmWork( aSelf, aSize )) == NULL ) goto error ;

	if ( OzMemcpy( data, args->data, aSize ) != data ) goto error ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmTTABLE( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	TtList		list ;
	int		i, count ;
	DmTTable	*table ;

	InitQueueBinary( list ) ;

	count = ThrMapTable( TtEnque, &list ) ;
	if ( (table=DmWork( aSelf, SIZEOF_DmTTable(count) )) == NULL ) {
		for ( i = 0 ; i < count ; i ++ ) TtDeque( &list ) ;
		goto error ;
	}
	table->count = count ;
	for ( i = 0 ; i < count ; i ++ ) table->slot[i] = TtDeque( &list ) ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmPTABLE( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	PtList		list ;
	int		i, count ;
	DmPTable	*table ;

	InitQueueBinary( list ) ;

	count = PrMapProcessTable( PtEnque, &list ) ;
	if ( (table=DmWork( aSelf, SIZEOF_DmPTable(count) )) == NULL ) {
		for ( i = 0 ; i < count ; i ++ ) PtDeque( &list ) ;
		goto error ;
	}
	table->count = count ;
	for ( i = 0 ; i < count ; i ++ ) table->slot[i] = PtDeque( &list ) ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmOTABLE( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	OtList		list ;
	int		i, count ;
	DmOTable	*table ;

	InitQueueBinary( list ) ;

	count = OtMapObjectTable( OtEnque, &list ) ;
	if ( (table=DmWork( aSelf, SIZEOF_DmOTable(count) )) == NULL ) {
		for ( i = 0 ; i < count ; i ++ ) OtDeque( &list ) ;
		goto error ;
	}
	table->count = count ;
	for ( i = 0 ; i < count ; i ++ ) table->slot[i] = OtDeque( &list ) ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmOGETENTRY( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		OID	oid ;
	} *args = aData ;
	DmOEntry	*data ;
	OZ_ObjectAll	all ;

	if ( (data=DmWork( aSelf, sizeof(DmOEntry) )) == NULL ) goto error ;

	data->entry = OtGetEntryRaw( args->oid ) ;
	if ( data->entry == NULL ) goto error ;

	if ( DmOnExitAdd( aSelf, DM_ORELENTRY, &data->entry, sizeof(data->entry) ) ) {
		OtReleaseEntry( data->entry ) ;
		goto error ;
	}

	data->status = data->entry->status ;
	data->object = data->entry->object ;
	if ( data->entry->object ) {
		all = OzExecGetObjectTop( data->entry->object ) ;
		data->head = (OZ_Header)all ;
		data->parts = all->head[0].h ;
		data->size = all->head[0].e ;
		data->cid = all->head[0].a ;
	} else {
		data->head = 0 ;
		data->parts = 0 ;
		data->size = 0 ;
		data->cid = 0 ;
	}

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmORELENTRY( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		ObjectTableEntry	entry ;
	} *args = aData ;

	if ( DmOnExitDel( aSelf, DM_ORELENTRY, &args->entry, sizeof(args->entry) ) ) goto error ;

	OtReleaseEntry( args->entry ) ;

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmTSUSPEND( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		OZ_Thread	t ;
	} *args = aData ;

	if ( ThrSuspend( args->t ) < 0 ) goto error ;

	if ( DmOnExitAdd( aSelf, DM_TRESUME, &args->t, sizeof(args->t) ) ) {
		ThrResume( args->t ) ;
		goto error ;
	}

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmTRESUME( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		OZ_Thread	t ;
	} *args = aData ;

	if ( DmOnExitDel( aSelf, DM_TRESUME, &args->t, sizeof(args->t) ) ) goto error ;

	if ( ThrResume( args->t ) < 0 ) goto error ;

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	return( ret ) ;
}

typedef	struct	{
	PID		pid ;
	OzProcess	proc ;
} RootChan ;
	
static	int
DmLGETROOT_FindAndSuspend( OzProcess aProc, RootChan *aKey )
{
	int	ret = NG ;
	if ( aProc->pid == aKey->pid ) {
		aKey->proc = aProc ;
		if ( aProc->status != PROC_EXITED ) {
			if ( ThrSuspend( aProc->chan.t ) >= 0 ) ret = OK ;
		}
	}
	return( ret ) ;
}

static	int
DmLGETROOT( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	int		mask ;
	struct	{
		OID	pid ;
	} *args = aData ;
	RootChan	root ;
	DmLink		*data ;

	mask = SigBlock() ;

	if ( EXECID(args->pid) != EXECID(OzExecutorID) ) goto error ;

	if ( (data=DmWork( aSelf, sizeof(DmLink) )) == NULL ) goto error ;

	root.pid = args->pid ;

	if ( PrMapProcessTable( DmLGETROOT_FindAndSuspend, &root ) == 0 ) goto error ;

	if ( DmOnExitAdd( aSelf, DM_TRESUME, &root.proc->chan.t, sizeof(root.proc->chan.t) ) ) {
		ThrResume( root.proc->chan.t ) ;
		goto error ;
	}

	data->callee = root.proc->chan.callee ;
	data->caller = root.proc->chan.caller ;
	data->chan.rchan = &root.proc->chan ;
	data->t = root.proc->chan.t ;

	ret = OK ;

error:
	SigUnBlock( mask ) ;
	return( ret ) ;
}

static	int
DmLGETNEXT( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	int		mask ;
	struct	{
		OzRecvChannel	rchan ;
	} *args = aData ;
	DmLink		*data ;
	OzSendChannel	schan ;
	OzRecvChannel	rchan ;

	mask = SigBlock() ;

	if ( (data=DmWork( aSelf, sizeof(DmLink) )) == NULL ) goto error ;

	OzExecEnterMonitor( &args->rchan->vars.lock ) ;
	if ( (schan=args->rchan->vars.next) == NULL ) {
		OzExecExitMonitor( &args->rchan->vars.lock ) ;
		goto error ;
	}

	if ( EXECID(args->rchan->callee) == EXECID(schan->callee) ) {
		rchan = schan->peer.rchan ;
		if ( ThrSuspend( rchan->t ) < 0 ) {
			OzExecExitMonitor( &args->rchan->vars.lock ) ;
			goto error ;
		}
		if ( DmOnExitAdd( aSelf, DM_TRESUME, &rchan->t, sizeof(rchan->t) ) ) {
			ThrResume( rchan->t ) ;
			OzExecExitMonitor( &args->rchan->vars.lock ) ;
			goto error ;
		}
	} else rchan = NULL ;

	data->caller = args->rchan->callee ;
	data->callee = schan->callee ;
	data->chan = schan->peer ;
	data->t = (rchan != NULL) ? rchan->t : NULL ;

	OzExecExitMonitor( &args->rchan->vars.lock ) ;

	ret = OK ;

error:
	SigUnBlock( mask ) ;
	return( ret ) ;
}

static	int
DmLGETFIND( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	int		mask ;
	struct	{
		long long	msgID ;
	} *args = aData ;
	DmLink		*data ;
	OzRecvChannel	rchan ;
	OZ_Thread	t ;

	mask = SigBlock() ;

	if ( (data=DmWork( aSelf, sizeof(DmLink) )) == NULL ) goto error ;

	rchan = OzSearchRemoteRecvChannel( args->msgID ) ;
	if ( rchan == NULL ) goto error ;

	OzExecEnterMonitor( &rchan->vars.lock ) ;

	t = rchan->t ;
	if ( ThrSuspend( t ) < 0 ) {
		OzExecExitMonitor( &rchan->vars.lock ) ;
		goto error ;
	}
	if ( DmOnExitAdd( aSelf, DM_TRESUME, &t, sizeof(t) ) ) {
		ThrResume( t ) ;
		OzExecExitMonitor( &rchan->vars.lock ) ;
		goto error ;
	}

	data->callee = rchan->callee ;
	data->caller = rchan->caller ;
	data->chan.rchan = rchan ;
	data->t = rchan->t ;

	OzExecExitMonitor( &rchan->vars.lock ) ;

	ret = OK ;

error:
	SigUnBlock( mask ) ;
	return( ret ) ;
}

static	int
DmOSUSPEND( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		ObjectTableEntry	entry ;
	} *args = aData ;

	/* DmBusy() ; */

	if ( OtGlobalObjectSuspend( args->entry ) < 0 ) goto error ;

	if ( DmOnExitAdd( aSelf, DM_ORESUME, &args->entry, sizeof(args->entry) ) ) {
		OtGlobalObjectResume( args->entry ) ;
		goto error ;
	}

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	/* DmReady() ; */
	return( ret ) ;
}

static	int
DmORESUME( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		ObjectTableEntry	entry ;
	} *args = aData ;

	if ( DmOnExitDel( aSelf, DM_ORESUME, &args->entry, sizeof(args->entry) ) ) goto error ;

	OtGlobalObjectResume( args->entry ) ;

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	return( ret ) ;
}

#define	CASE(xXvAlUe,xXnAmE)	case xXvAlUe: xXnAmE = #xXvAlUe ; break

static	const	char*
DmTraceModeToName( int aMode )
{
	const char	*name ;
	switch( aMode & TRACE_MODE ) {
	CASE( TRACE_LOG,	name ) ;
	CASE( TRACE_STEP,	name ) ;
	CASE( TRACE_TIME,	name ) ;
	CASE( TRACE_RECORD,	name ) ;
	default:	name = "UNKNOWN MODE" ;
	}
	return( name ) ;
}

static	const	char*
DmTraceTypeToName( int aType )
{
	const char	*name ;
	switch( aType & TRACE_TYPE ) {
	CASE( TRACE_CALLER,	name ) ;
	CASE( TRACE_CALLEE,	name ) ;
	default:	name = "UNKNOWN TYPE" ;
	}
	return( name ) ;
}

static	const	char*
DmTracePhaseToName( int aPhase )
{
	const char	*name ;
	switch( aPhase & TRACE_PHASE ) {
	CASE( TRACE_ENTRY, 	name ) ;
	CASE( TRACE_RETURN, 	name ) ;
	CASE( TRACE_EXCEPTION,	name ) ;
	CASE( TRACE_ERROR,	name ) ;
	default:	name = "UNKNOWN PHASE" ;
	}
	return( name ) ;
}

typedef	struct	TrSlotStr*	TrSlot ;
typedef	struct	TrSlotStr	TrSlotRec ;
struct	TrSlotStr	{
	TrSlot		b_prev ;
	TrSlot		b_next ;
	DmGTrace	info ;
} ;
typedef	struct	TrTableStr*	TrTable ;
typedef	struct	TrTableStr	TrTableRec ;
struct	TrTableStr {
	ObjectTableEntry	entry ;
	OZ_MonitorRec		lock ;
	OZ_ConditionRec		cond ;
	int		flag ;
	int		over ;
	int		max ;
	int		count ;
	TrSlot		free ;
	TrSlot		used ;
	TrSlotRec	slot[1] ;
} ;

static	void
DmGTRACE_Tracer( TrTable aTable, OzRecvChannel aChan, OzGlobalObjectTraceInfo aInfo )
{
	TrSlot	slot ;
	OzExecEnterMonitor( &aTable->lock ) ;
	if ( aTable->over == 0 ) {
		if ( aTable->count < aTable->max ) {
			aTable->count ++ ;
			slot = aTable->free ;
			RemoveQueueBinary( slot, aTable->free ) ;
			InsertQueueBinary( slot, aTable->used ) ;
			slot->info.phase = aInfo->phase ;
			slot->info.pid = aChan->pid ;
			slot->info.caller = aChan->caller ;
			slot->info.callee = aChan->callee ;
			slot->info.cvid = aInfo->cvid ;
			slot->info.slot1 = aInfo->slot1 ;
			slot->info.slot2 = aInfo->slot2 ;
			slot->info.self = aInfo->self ;
			slot->info.rchan = aChan ;
			OzGettimeofday( &slot->info.tp, &slot->info.tzp ) ;
			if ( aInfo->phase & TRACE_STEP ) {
				aTable->flag = 1 ;
				OzExecWaitCondition( &aTable->lock, &aTable->cond ) ;
				aTable->flag = 0 ;
				if ( aTable->over ) OzExecSignalCondition( &aTable->cond ) ;
			}
		} else aTable->over = 1 ;
	}
	OzExecExitMonitor( &aTable->lock ) ;
}

static	int
DmGTRACE( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	int		i ;
	int		size ;
	struct	{
		ObjectTableEntry	entry ;
		int			mode ;
		int			max ;
	} *args = aData ;
	TrTable	table ;
	TrTable	*data ;

	if ( (data=DmWork( aSelf, sizeof(TrTable) )) == NULL ) goto error ;
	size = sizeof(TrTableRec) + sizeof(TrSlotRec) * (args->max - 1) ;
	if ( (table=(TrTable)OzMalloc( size )) == NULL ) goto error ;
	OzInitializeMonitor( &table->lock ) ;
	OzExecInitializeCondition( &table->cond, 0 ) ;
	table->entry = args->entry ;
	table->flag = 0 ;
	table->over = 0 ;
	table->max = args->max ;
	table->count = 0 ;
	table->free = NULL ;
	table->used = NULL ;
	for ( i = 0 ; i < args->max ; i ++ ) InsertQueueBinary( table->slot+i, table->free ) ;

	if ( OzGlobalObjectTraceSet( args->entry, args->mode, DmGTRACE_Tracer, table ) ) {
		OzFree( table ) ;
		goto error ;
	}

	if ( DmOnExitAdd( aSelf, DM_GCONT, &table, sizeof(table) ) ) {
		OzGlobalObjectTraceReset( args->entry ) ;
		OzFree( table ) ;
		goto error ;
	}
	*data = table ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmGSTEP( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		TrTable	table ;
	} *args = aData ;
	DmGTrace	*data ;
	TrSlot		slot ;

	if ( (data=DmWork( aSelf, sizeof(DmGTrace) )) == NULL ) goto error ;

	OzExecEnterMonitor( &args->table->lock ) ;
	if ( args->table->count ) {
		slot = args->table->used ;
		RemoveQueueBinary( slot, args->table->used ) ;
		InsertQueueBinary( slot, args->table->free ) ;
		args->table->count -- ;
		*data = slot->info ;
		if ( args->table->over ) ret = args->table->count + 1 ;
		else ret = args->table->count ;
		if ( args->table->flag ) OzExecSignalCondition( &args->table->cond ) ;
	} else if ( args->table->over ) {
		args->table->over = 0 ;
		ret = -2 ;
	}
	OzExecExitMonitor( &args->table->lock ) ;

error:
	return( ret ) ;
}

static	int
DmGCONT( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		TrTable		table ;
	} *args = aData ;

	if ( DmOnExitDel( aSelf, DM_GCONT, &args->table, sizeof(args->table) ) ) goto error ;
	OzExecEnterMonitor( &args->table->lock ) ;
	args->table->over = 1 ;
	if ( args->table->flag ) {
		OzExecSignalCondition( &args->table->cond ) ;
		OzExecWaitCondition( &args->table->lock, &args->table->cond ) ;
	}
	OzExecExitMonitor( &args->table->lock ) ;

	if ( OzGlobalObjectTraceReset( args->table->entry ) == NULL ) goto error ;
	OzFree( args->table ) ;

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:

	return( ret ) ;
}


static	void
DmGLOG_Printer( int aTty, OzRecvChannel aRchan, OzGlobalObjectTraceInfo aInfo )
{
static	char	buf[512] ;
	OzSprintf( buf, "%12s %15s Callee:0x%08x%08x Caller:0x%08x%08x Slot1:%d Slot2:%d\n",
		DmTraceTypeToName( aInfo->phase) , DmTracePhaseToName( aInfo->phase ),
		(int)(aInfo->callee>>32), (int)(aInfo->callee&0xffffffff),
		(int)(aInfo->caller>>32), (int)(aInfo->caller&0xffffffff),
		aInfo->slot1, aInfo->slot2 ) ;
	OzWrite( aTty, buf, strlen(buf) ) ;
}

static	int
DmGLOGON( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	int		mode ;
	int		tty ;
	char		buf[64] ;
	struct	{
		ObjectTableEntry	entry ;
	} *args = aData ;

	mode = TRACE_CALLER|TRACE_CALLEE | TRACE_ENTRY|TRACE_RETURN|TRACE_EXCEPTION|TRACE_ERROR ;

	OzSprintf( buf, "Method Trace [0x%08x]", args->entry ) ;
#if	1
	tty = OzCreateKterm( buf, 0 ) ; /* 0 means non-iconic */
#else
	tty = OzCreateKterm() ;
#endif
	if ( OzGlobalObjectTraceSet( args->entry, mode, DmGLOG_Printer, (void *)tty ) ) goto error ;

	if ( DmOnExitAdd( aSelf, DM_GLOGOFF, &args->entry, sizeof(args->entry) ) ) {
		OzGlobalObjectTraceReset( args->entry ) ;
		goto error ;
	}

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	/* DmReady() ; */
	return( ret ) ;
}

static	int
DmGLOGOFF( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	int		tty ;
	struct	{
		ObjectTableEntry	entry ;
	} *args = aData ;

	if ( DmOnExitDel( aSelf, DM_GLOGOFF, &args->entry, sizeof(args->entry) ) ) goto error ;

	tty = (int)OzGlobalObjectTraceReset( args->entry ) ;
	OzClose( tty ) ;

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	/* DmReady() ; */
	return( ret ) ;
}

static	int
DmPKILL( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	int		mask ;
	struct	{
		OID	pid ;
	} *args = aData ;

	mask = SigBlock() ;

	if ( EXECID(args->pid) != EXECID(OzExecutorID) ) goto error ;

	OzExecAbortProcess( (int)(args->pid&0x0ffffffLL) ) ;

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	SigUnBlock( mask ) ;
	return( ret ) ;
}

static	int
DmSSEARCH( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;
	struct	{
		caddr_t	addr ;
	} *args = aData ;
	struct	{
		caddr_t	addr ;
		char	name[1] ;
	} *data ;
	void		*handle = NULL ;
	DlInfoRec	dli ;

	if ( (handle = DlOpen( DlIsClass( args->addr ) )) == NULL ) goto error ;
	if ( DlAddr( handle, args->addr, &dli ) < 0 ) goto error ;

	if ( (data=DmWork(aSelf,strlen(dli.sname)+1+4)) == NULL ) goto error ;
	data->addr = dli.saddr ;
	OzStrcpy( data->name, dli.sname ) ;

	ret = OK ;

error:
	if ( handle != NULL ) DlClose( handle ) ;
	return( ret ) ;
}

/* for IPA '94 Oct. Demo */
static	int
DmSERVPORT( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;
	struct	{
		OID	oid ;
	} *args = aData ;

	ret = DmGetServAddr( aSelf, args->oid ) ;

	return( ret ) ;
}

static	int
DmOGETTOP( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		OZ_Object	obj ;
	} *args = aData ;
	OZ_ObjectAll	*all ;

	if ( (all=DmWork( aSelf, sizeof(OZ_ObjectAll) )) == NULL ) goto error ;

	*all = OzExecGetObjectTop( args->obj ) ;

	ret = OK ;

error:
	return( ret ) ;
}

/* for IPA '94 Oct. Demo */
static	int
DmINETPORT( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;

	ret = DmGetInetPort( aSelf ) ;

	return( ret ) ;
}

static	int
DmTLIST( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		ObjectTableEntry	entry ;
	} *args = aData ;
	DmTList	*list ;
	OZ_Thread	t ;
	int	count ;

	/* DmBusy() ; */

	OzExecEnterMonitor( &args->entry->lock ) ;
	count = 0 ;
	if ( (t=args->entry->threads ) != 0 ) {
		do {
			count ++ ;
		} while ( (t=t->b_next) != args->entry->threads ) ;
	}
	if ( (list=DmWork( aSelf, SIZEOF_DmTList(count) )) == NULL ) goto error ;
	list->count = count ;
	if ( count ) {
		count = 0 ;
		do {
			if ( t->channel ) {
				list->slot[count].pid = ((OzRecvChannel)t->channel)->pid ;
				list->slot[count].caller = ((OzRecvChannel)t->channel)->caller ;
			} else {
				list->slot[count].pid = 0LL ;
				list->slot[count].caller = 0LL ;
			}
			list->slot[count].t = t ;
			list->slot[count].status = t->status ;
			list->slot[count].suspend_count = t->suspend_count ;
			count ++ ;
		} while ( (t=t->b_next) != args->entry->threads ) ;
	}
	ret = OK ;

error:
	OzExecExitMonitor( &args->entry->lock ) ;
	/* DmReady() ; */
	return( ret ) ;
}

typedef	struct	{
	OZ_ClassID	cid ;
	ClassCode	code ;
} ClassCodeFind ;

#if 0
static	int
DmCCODE_Find( CodeLayoutTableEntry aEntry, ClassCodeFind *key )
{
	if ( aEntry->code.cid == key->cid && aEntry->code.state == CL_LOADED ) {
		key->code = &aEntry->code ;
		return( OK ) ;
	}
	return( NG ) ; 
}
#else
static	int
DmCCODE_Find( ClassCode code, ClassCodeFind *key )
{
	if ( code->cid == key->cid && code->state == CL_LOADED ) {
		key->code = code ;
		return( OK ) ;
	}
	return( NG ) ; 
}
#endif /* 0 */

static	int
DmCCODE( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		OZ_ClassID	cid ;
	} *args = aData ;
	ClassCodeFind	key ;
	DmCCode		*data ;

	if ( (data=DmWork( aSelf, sizeof(DmCCode) )) == NULL ) goto error ;

	key.cid = args->cid ;
#if 0
	if ( ClMapCodeLayoutTable( DmCCODE_Find, &key ) <= 0 ) goto error ;
#else
	if ( ClMapCode( DmCCODE_Find, &key ) <= 0 ) goto error ;
#endif /* 0 */

	data->base = (unsigned long)key.code->addr ;
	data->size = (unsigned long)key.code->size ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmEXECID( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	long long	*data ;

	if ( (data=DmWork( aSelf, sizeof(OzExecutorID) )) == NULL ) goto error ;
	*data = OzExecutorID ;
	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmARCHID( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;
	int	*data ;

	if ( (data=DmWork( aSelf, sizeof(MyArchitectureType) )) == NULL ) goto error ;
	*data = MyArchitectureType ;
	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmDBGMSG( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;

	if ( DmWork( aSelf, 0 ) == NULL ) goto error ;
	ret = DsCaptureDebugMessage( aData, aSize ) ;

error:
	return( ret ) ;
}

static	int
DmTCONT( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		OZ_Thread	t ;
	} *args = aData ;

	if ( ThrResume( args->t ) < 0 ) goto error ;

	DmWork( aSelf, 0 ) ;

	ret = OK ;

error:
	return( ret ) ;
}

static	int
DmNOTIFY( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;

	if ( DmWork( aSelf, 0 ) == NULL ) goto error ;
	ret = DsCaptureException( aData, aSize ) ;

error:
	return( ret ) ;
}

static	int
DmCGET( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		OID	id ;
	} *args = aData ;

	if ( DmWork( aSelf, 0 ) == NULL ) goto error ;
	ret = DmGetClass( args->id ) ;

error:
	return( ret ) ;
}

static	int
DmIDLETIME( DmLabor aSelf, void *aData, int aSize )
{
	int	ret = NG ;
	int	*data ;
	struct	{
		int	interval ;
	} *args = aData ;

	if ( (data=DmWork( aSelf, sizeof(int))) == NULL ) goto error ;

	*data = OzIdleTime( args->interval ) ;

error:
	return( ret ) ;
}

typedef	struct	{
	caddr_t		addr ;
	OZ_ClassID	cid ;
} ClassAddrFind ;

static	int
DmCGETID_Find( ClassCode code, ClassAddrFind *key )
{
	if ( code->addr <= key->addr
		&& key->addr <= code->addr + code->size ) {
		key->cid = code->cid ;
		return( OK ) ;
	} else return( NG ) ; 
}

static	int
DmCGETID( DmLabor aSelf, void *aData, int aSize )
{
	int		ret = NG ;
	struct	{
		caddr_t		addr ;
	} *args = aData ;
	ClassAddrFind	key ;
	OZ_ClassID	*data ;

	if ( (data=DmWork( aSelf, sizeof(OZ_ClassID) )) == NULL ) goto error ;

	key.addr = args->addr ;
	if ( ClMapCode( DmCGETID_Find, &key ) != 1 ) goto error ;

	*data = key.cid ;

	ret = OK ;

error:
	return( ret ) ;
}

#define	FNENTRY( fn )	{ DM_ ## fn, Dm ## fn }
static	FnEntry	Table[] =
		{
			FNENTRY( ECHO ),
			FNENTRY( READ ),
			FNENTRY( WRITE ),
			FNENTRY( TTABLE ),
			FNENTRY( PTABLE ),
			FNENTRY( OTABLE ),
			FNENTRY( OGETENTRY ),
			FNENTRY( ORELENTRY ),
			FNENTRY( TSUSPEND ),
			FNENTRY( TRESUME ),
			FNENTRY( LGETROOT ),
			FNENTRY( LGETNEXT ),
			FNENTRY( LGETFIND ),
			FNENTRY( OSUSPEND ),
			FNENTRY( ORESUME ),
			FNENTRY( GTRACE ),
			FNENTRY( GSTEP ),
			FNENTRY( GCONT ),
			FNENTRY( GLOGON ),
			FNENTRY( GLOGOFF ),
			FNENTRY( PKILL ),
			FNENTRY( SSEARCH ),
			FNENTRY( SERVPORT ),
			FNENTRY( OGETTOP ),
			FNENTRY( TLIST ),
			FNENTRY( CCODE ),
			FNENTRY( INETPORT ),
			FNENTRY( EXECID ),
			FNENTRY( ARCHID ),
			FNENTRY( DBGMSG ),
			FNENTRY( TCONT ),
			FNENTRY( NOTIFY ),
			FNENTRY( CGET ),
			FNENTRY( IDLETIME ),
			FNENTRY( CGETID ),
		} ;
FnTable	DmWorkTable = { sizeof(Table)/sizeof(FnEntry), Table } ;
