/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include	<stdio.h>
#include	<sys/time.h>
/* multithread system include */
#include	"thread/thread.h"
#include	"thread/monitor.h"
#include	"oz++/ozlibc.h"

#include	"executor/debug.h"

#include	"switch.h"
#include	"queue.h"
#include	"fault-q.h"

#include	"debugChannel.h"
#include	"debugManager.h"

#define	NO_ABORT	0
#define	OK		0
#define	NG		(-1)
#define	LOOP		for(;;)
#define	DM_STACK_SIZE	(4096 * 4)
#define	DM_PRIORITY	(MAX_PRIORITY-2)	/* < DT_PRIORITY */
#define	DT_STACK_SIZE	(4096 * 8)
#define	DT_PRIORITY	MAX_PRIORITY
#define	AB_STACK_SIZE	(4096*4)

#undef	DEBUG
#undef	DEBUG_REQ
#undef	DEBUG_RES

#if	defined(CHECK)
#include "check.h"
#endif

extern	int	getitimer() ;

/* ���꡼��ʥå׽����ѥ��塼�ι�¤ */
typedef	struct	OnExitStr*	OnExit ;
typedef	struct	OnExitStr	OnExitRec ;
struct	OnExitStr	{
	OzDcBuff	buff ;
	OnExit		b_prev ;
	OnExit		b_next ;
} ;

/* ϫƯ�Ԥθ��Ҥι�¤ */
typedef	struct	LaborRec*	Labor ;
struct	LaborRec	{
	Labor		b_prev ;
	Labor		b_next ;
	OZ_MonitorRec	lock ;
	OZ_ConditionRec	cond ;
	DC		dc ;
	int		busy ;
	OzDcBuff	send ;
	OzDcBuff	recv ;
	OnExit		onExit ;
} ;

/* ���Ȱ���� */
static	struct	{
	OZ_MonitorRec	lock ;
	Labor		lose ;
	Labor		work ;
} LaborQ ;

static	FaultQueueRec	ClassRequestQ ;
static	int	InitFlag = 0 ;
static	int	Mode = 0 ;	/* �顧�ǥХå��ػߡ������׵�١����������ǥХå������� */


/* ϫƯ�Ԥθ��Ҥκ��� */
static	Labor
DmAlloc( DC aDC )
{
	Labor	labor ;

	if ( (labor=(Labor)OzMalloc( sizeof(struct LaborRec) )) == NULL ) goto error ;

	labor->b_prev = NULL ;
	labor->b_next = NULL ;
	OzInitializeMonitor( &labor->lock ) ;
	OzExecInitializeCondition( &labor->cond, NO_ABORT ) ;
	labor->dc = aDC ;
	labor->busy = 0 ;
	labor->send = NULL ;
	labor->recv = NULL ;
	InitQueueBinary( labor->onExit ) ;

	if ( (labor->send=OzDcSetBuff( NULL, BUFF_INIT )) == NULL ) goto error ;

	if ( (labor->recv=OzDcSetBuff( NULL, BUFF_INIT )) == NULL ) goto error ;

	return( labor ) ;

error:
	if ( labor != NULL ) {
		if ( labor->send != NULL ) OzDcSetBuff( labor->send, BUFF_FREE ) ;
		if ( labor->recv != NULL ) OzDcSetBuff( labor->recv, BUFF_FREE ) ;
		OzFree( labor ) ;
	}
	return( NULL ) ;
}

/* ϫƯ�Ԥθ��Ҥ��˴� */
static	void
DmFree( Labor aLabor )
{
	OzDcSetBuff( aLabor->recv, BUFF_FREE ) ;
	OzDcSetBuff( aLabor->send, BUFF_FREE ) ;
	OzFree( aLabor ) ;
}

/* ��������Ԥ����塼�ؤ���Ͽ */
static	void
DmEnque( Labor aLabor )
{
	OzExecEnterMonitor( &LaborQ.lock ) ;
	RemoveQueueBinary( aLabor, LaborQ.work ) ;
	InsertQueueBinary( aLabor, LaborQ.lose ) ;
	OzExecExitMonitor( &LaborQ.lock ) ;
}

/* ��������Ԥ����塼����κ�� */
static	Labor
DmDeque()
{
	Labor	labor = NULL ;

	OzExecEnterMonitor( &LaborQ.lock ) ;
	if ( LaborQ.lose != NULL ) {
		labor = LaborQ.lose ;
		RemoveQueueBinary( labor, LaborQ.lose ) ;
		InsertQueueBinary( labor, LaborQ.work ) ;
	}
	OzExecExitMonitor( &LaborQ.lock ) ;
	return( labor ) ;
}

/* ��ʬ����դ��ڤκ��� */
inline	static	void
DmDownHeapFnEntry( int k, int r )
{
	int	j ;
	FnEntry	fe ;

	fe = DmWorkTable.entry[k] ;
	LOOP {
		j = k + k ;
		if ( j > r ) break ;
		if ( j != r && DmWorkTable.entry[j+1].No > DmWorkTable.entry[j].No ) j ++ ;
		if ( fe.No >= DmWorkTable.entry[j].No ) break ;
		DmWorkTable.entry[k] = DmWorkTable.entry[j] ;
		k = j ;
	}
	DmWorkTable.entry[k] = fe ;
}

/* ������ơ��֥�ν����ֹ�ˤ�륽���� */
static	void
DmSortFnEntry()
{
	int	i ;
	FnEntry	fe ;

	for ( i = DmWorkTable.max / 2 ; i >= 0 ; i -- ) DmDownHeapFnEntry( i, DmWorkTable.max - 1 ) ;

	for ( i = DmWorkTable.max - 1 ; i > 0 ; i -- ) {
		fe = DmWorkTable.entry[0] ;
		DmWorkTable.entry[0] = DmWorkTable.entry[i] ;
		DmWorkTable.entry[i] = fe ;
		DmDownHeapFnEntry( 0, i-1 ) ;
	}
}

/* �����ֹ椫��ؿ��ݥ��󥿤ؤ��Ѵ� */
static	FnEntry*
DmToFnEntry( int aRequest )
{
	FnEntry	*now, *max ;
	int	div ;

	max = DmWorkTable.entry + DmWorkTable.max ;
	now = DmWorkTable.entry ;
	if ( now->No <= aRequest && aRequest <= (max-1)->No ) {
		do {
			div = (max - now) / 2 ;
			if ( (now+div)->No <= aRequest ) now += div ;
			else max = now + div ;
		} while( div ) ;
		if ( now->No != aRequest ) now = NULL ;
	} else now = NULL ;

	return( now ) ;
}

/* ����Ǥ����� */
static	void
DmAbroad( Labor aLabor )
{
		struct	{
			int	status ;
			int	size ;
		} data ;
	struct	itimerval	ival ;
		long		interval ;
		int		wtime ;

	getitimer( ITIMER_REAL, &ival ) ;
	interval =  ival.it_interval.tv_usec ;
	getitimer( ITIMER_VIRTUAL, &ival ) ;
	if ( interval < ival.it_interval.tv_usec ) interval = ival.it_interval.tv_usec;

	wtime = ( 1000000 / interval ) * 1 ;	/* ���� */
	data.status = DC_BUSY ;
	data.size = 0 ;

	OzExecEnterMonitor( &aLabor->lock ) ;
	LOOP {
		OzExecWaitConditionWithTimeout( &aLabor->lock, &aLabor->cond, wtime ) ;
		if ( aLabor->busy ) {
			if ( OzDcSend( aLabor->dc, &data, sizeof(data) ) < 0 ) break ;
		} else break ;
	}
	aLabor->busy = 0 ;
	OzExecExitMonitor( &aLabor->lock ) ;

	ThrExit() ;
}

/* ϫƯ�Ԥο��� */
static	void
DmLaborLife( Labor aLabor )
{
	DC	dc ;
	int	ret ;
	int	request ;
	int	status ;
	int	size ;
	FnEntry	*entry ;
	void	*data ;
	OzDcBuff	send = aLabor->send ;
	OzDcBuff	recv = aLabor->recv ;

	if ( !InitFlag ) {
		OzDebugf( "�ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ�\n" ) ;
		return ;
	}

	LOOP {
		/* �Ż��γ�������Ԥ� */
		OzExecEnterMonitor( &aLabor->lock ) ;
		while ( (dc=aLabor->dc) == NULL ) OzExecWaitCondition( &aLabor->lock, &aLabor->cond ) ;
		OzExecExitMonitor( &aLabor->lock ) ;

		/* �Ż����� */
		OzDcBegin( dc ) ;

#if	defined(DEBUG)
OzDebugf( "DM Labor Begin: 0x%08x\n", aLabor ) ;
#endif

		/* �Ż��롼�� */
		LOOP {

			/* �ɤλŻ��� */
			ret = OzDcRecv( dc, &recv->data->head, sizeof(recv->data->head) ) ; 
			if ( ret != OK ) break ;

			request = recv->data->head.type.request ;
			size = recv->data->head.size ;

			/* �Ȥ���Τϡ� */
			if ( 0 < size ) {

				/* ����֤���γ��� */
				if ( (data=OzDcSetBuff( recv, size )) == NULL ) break ;

				/* ���������� */
				ret = OzDcRecv( dc, data, size ) ;
				if ( ret != OK ) break ;

			} else data = NULL ;
#if	defined(DEBUG_REQ)
OzDebugf( "DM Labor      Req = %d, Size = %d\n", request, size ) ;
#endif
			/* Ư�� */
			entry = DmToFnEntry( request ) ;
			if ( entry == NULL ) status = -1 ;
			else status = entry->ptr( aLabor, data, size ) ;
			if ( status < 0 ) DmWork( aLabor, 0 ) ;

			send->data->head.type.status = status ;
			size = sizeof(send->data->head) + send->data->head.size ;

			/* ��̤���� */
			ret = OzDcSend( dc, (char *)send->data, size ) ;
			if ( ret != OK ) break ;

#if	defined(DEBUG_RES)
OzDebugf( "DM Labor      Res = %d, Size = %d\n", status, send->data->head.size ) ;
#endif

		} ;

		/* ��λ���� */
		while( aLabor->onExit != NULL ) {
			request = aLabor->onExit->buff->data->head.type.request ;
			data = aLabor->onExit->buff->data->addr ;
			size = aLabor->onExit->buff->data->head.size ;
#if	defined(DEBUG)
OzDebugf( "DM Labor Clean: Request = %d\n", request ) ;
#endif
			entry = DmToFnEntry( request ) ;
			if ( entry == NULL ) status = -1 ;
			else status = entry->ptr( aLabor, data, size ) ;
#if	defined(DEBUG)
OzDebugf( "DM Labor Clean: Status = %d\n", status ) ;
#endif
		}


#if	defined(DEBUG)
OzDebugf( "DM Labor End  : 0x%08x\n", aLabor ) ;
#endif
		/* �й���Ǥ���е��񤵤��� */
		DmReady( aLabor ) ;

		/* �Ż���λ */
		OzDcEnd( dc ) ;

		/* Multiplex���ʤ��Τǡ������ǽ�λ */
		OzDcClose( dc ) ;

		OzExecEnterMonitor( &aLabor->lock ) ;
		aLabor->dc = NULL ;
		OzExecExitMonitor( &aLabor->lock ) ;

		if ( Mode != 0 ) {
			/* ���Ȥ����Τǿ��Ȱ����˹Ԥ� */
			DmEnque( aLabor ) ;
		} else {
			/* �׵�١����ʤΤǼ������� */
			OzExecEnterMonitor( &LaborQ.lock ) ;
			RemoveQueueBinary( aLabor, LaborQ.work ) ;
			OzExecExitMonitor( &LaborQ.lock ) ;
			DmFree( aLabor ) ;
			break ;
		}
	}
}

/* �ǥХå����ޥ͡�����ʻŻ��γ�����ơ� */
static	void
DmManager()
{
	DC	dc ;
	Labor	labor = NULL ;
	OZ_Thread	t ;

	if ( !InitFlag ) {
		OzDebugf( "�ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ�\n" ) ;
		return ;
	}

	LOOP {
		/* �Ż��ΰ�����Ԥ� */
		dc = OzDcAccept() ;

		/* �Ż��������Ƥ� */
		if ( 0 <= Mode && (labor=DmDeque()) != NULL ) {
			/* ���ȼԤ˻Ż��������Ƥ� */
			OzExecEnterMonitor( &labor->lock ) ;
			labor->dc = dc ;
			OzExecSignalCondition( &labor->cond ) ;
			OzExecExitMonitor( &labor->lock ) ;
		}

		/* �׵�١����Υ⡼�ɤʤ�� */
		if ( Mode == 0 && labor == NULL ) {
			/* ������ϫƯ�Ԥ���������Ż��������Ƥ� */
			labor = DmAlloc( dc ) ;
			if ( labor != NULL ) {
				OzExecEnterMonitor( &LaborQ.lock ) ;
				InsertQueueBinary( labor, LaborQ.work ) ;
				OzExecExitMonitor( &LaborQ.lock ) ;
				t = ThrFork( DmLaborLife, DT_STACK_SIZE, DT_PRIORITY, 1, labor ) ;
				if ( t == NULL ) {
					OzExecEnterMonitor( &LaborQ.lock ) ;
					RemoveQueueBinary( labor, LaborQ.work ) ;
					OzExecExitMonitor( &LaborQ.lock ) ;
					DmFree( labor ) ;
					labor = NULL ;
				}
			}
		}

		/* �Ż��γ�����Ƥ˼��Ԥ��� */
		if ( labor == NULL ) OzDcClose( dc ) ;
	}
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�ǥХå����ޥ͡�����ν����

�ڷ�����
	int	DmInit( int aMax ) ;

�ڰ�����
	aMax	�������դ��뤳�Ȥ��Ǥ���ǥХå������å����κ����
		��â�������ξ��ϡ��׵�١����ǥǥХå������å���󤬺�������롣
		���ޤ�����ξ��ϡ��ǥХå������å����Ϻ�������ʤ���

�ڵ�ǽ��
	�ǥХå����ޥ͡�����Υ⥸�塼�����������ɬ�פʥ���åɺ������롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ����ʳ����ͤˤʤ롣

����ջ����

������������
-----------------------------------------------------------------------------*/
int
DmInit( int aMax )
{
	int	ret = NG ;
	int	i ;
	Labor	labor ;
	OZ_Thread	t ;

/* ������ϣ��٤Τ� */
	if ( InitFlag ) goto error ;
	InitFlag = 1 ;
	Mode = aMax ;

/* �ǡ����ΰ�ν������������� */
	OzInitializeMonitor( &LaborQ.lock ) ;
	InitQueueBinary( LaborQ.lose ) ;
	InitQueueBinary( LaborQ.work ) ;
	FqInitializeFaultQueue( (FaultQueue)&ClassRequestQ ) ;

	DmSortFnEntry() ;

	/* ϫƯ�Ԥ�����������Ȱ�������Ͽ����ʼ��ȼԤȤ��ƽ�������� */
	OzExecEnterMonitor( &LaborQ.lock ) ;
	for ( i = 0, labor = NULL ; i < aMax ; i ++ ) {
		if ( labor == NULL ) labor = DmAlloc( NULL ) ;
		if ( labor != NULL ) {
			t = ThrFork( DmLaborLife, DT_STACK_SIZE, DT_PRIORITY, 1, labor ) ;
			if ( t != NULL ) {
				InsertQueueBinary( labor, LaborQ.lose ) ;
				labor = NULL ;
			}
		}
	}
	if ( labor != NULL ) DmFree( labor ) ;
	OzExecExitMonitor( &LaborQ.lock ) ;

	/* �ǥХå����ޥͥ��㡼��ư */
	ThrFork( DmManager, DM_STACK_SIZE, DM_PRIORITY, 0 ) ;

	ret = OK ;

error:
	if ( ret != OK ) InitFlag = 0 ;
	return( ret ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�ǥХå����ޥ͡�����Υ⡼���ѹ�

�ڷ�����
	int	OzDmChangeMode( int aMode ) ;

�ڰ�����
	aMode	�����ξ��ϡ��������ǥХå������å����κ�����ػߤ��롣
		�����ʳ��ξ��ϡ��������ǥХå������å����κ�������Ĥ��롣

�ڵ�ǽ��
	�ǥХå����ޥ͡�����Υ⡼�ɤ��ѹ����롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ����ʳ����ͤˤʤ롣

����ջ����
	ͽ��ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ���Фʤ�ʤ���

������������
-----------------------------------------------------------------------------*/
int
OzDmChangeMode( int aMode )
{
	int	ret = NG ;

	if ( !InitFlag ) {
		OzDebugf( "�ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ�\n" ) ;
		goto error ;
	}

	if ( aMode ) Mode *= ( (Mode>0) ? -1 : 1 ) ;
	else Mode *= ( (Mode>0) ? 1 : -1 ) ;
	ret = OK ;

error:
	return( ret ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	���꡼�󡦥��å׽�������Ͽ

�ڷ�����
	int	DmOnExitAdd( DmLabor aSelf, int aRequest, void *aData, int aSize ) ;

�ڰ�����
	aSelf	��ϫƯ�ԤΥ����ǥ�ƥ��ƥ�
	aRequest���Ż��μ���
	aData	���Ż��˻Ȥ�����֤���ؤΥݥ���
	aSize	�����λ���֤���ι���

�ڵ�ǽ��
	��Ϣ�λŻ��ν�λ�ˡ�¾�ͤ����Ǥ򤫤��ʤ��ʤ��褦�ˡ�
	��������뤿��λŻ�����Ͽ���롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ����ʳ����ͤˤʤ롣

����ջ����
	ͽ��ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ���Фʤ�ʤ���

������������
-----------------------------------------------------------------------------*/
int
DmOnExitAdd( DmLabor aSelf, int aRequest, void *aData, int aSize )
{
	Labor	labor = (Labor)aSelf ;
	OnExit	slot ;
	void	*data ;

	if ( (slot=(OnExitRec *)OzMalloc( sizeof(OnExitRec) )) == NULL ) goto error ;

	if ( (slot->buff=OzDcSetBuff( NULL, BUFF_INIT )) == NULL ) goto error ;

	if ( (data=OzDcSetBuff( slot->buff, aSize )) == NULL ) goto error ;

	slot->buff->data->head.type.request = aRequest ;
	memcpy( data, aData, aSize ) ;

	InsertQueueBinary( slot, labor->onExit ) ;

	return( OK ) ;

error:
	if ( slot != NULL ) {
		if ( slot->buff != NULL ) OzDcSetBuff( slot->buff, BUFF_FREE ) ;
		OzFree( slot ) ;
	}
	return( NG ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	���꡼�󡦥��å׽����κ��

�ڷ�����
	int	DmOnExitDel( DmLabor aSelf, int aRequest, void *aData, int aSize )

�ڰ�����
	aSelf	��ϫƯ�ԤΥ����ǥ�ƥ��ƥ�
	aRequest���Ż��μ���
	aData	���Ż��˻Ȥ�����֤���ؤΥݥ���
	aSize	�����λ���֤���ι���

�ڵ�ǽ��
	¾�ͤ����Ǥ򤫤���Ż�����λ�����Τǡ� ���������ɬ�פ��ʤ��ʤä��Τ�
	��Ͽ�����Ż��������롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ����ʳ����ͤˤʤ롣

����ջ����
	ͽ��ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ���Фʤ�ʤ���

������������
-----------------------------------------------------------------------------*/
int
DmOnExitDel( DmLabor aSelf, int aRequest, void *aData, int aSize )
{
	Labor	labor = (Labor)aSelf ;
	OnExit	slot ;

	if ( (slot=labor->onExit) != NULL ) {
		do {
			if ( slot->buff->data->head.type.request == aRequest
				&& slot->buff->data->head.size == aSize
				&& memcmp( aData, slot->buff->data->addr, aSize ) == OK ) {
				RemoveQueueBinary( slot, labor->onExit ) ;
				OzDcSetBuff( slot->buff, BUFF_FREE ) ;
				OzFree( slot ) ;
				return( OK ) ;
			}
		} while ( (slot=slot->b_next) != labor->onExit ) ;
	}
	return( NG ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�Ż���η���

�ڷ�����
	void*	DmWork( DmLabor aSelf, int aSize ) ;

�ڰ�����
	aSelf	��ϫƯ�ԤΥ����ǥ�ƥ��ƥ�
	aSize	���Хåե��Ȥ��ƻ��Ѥ���Х��ȿ�����ꤹ�롣

�ڵ�ǽ��
	�Ż���ι�����Ĵ������ȤȤ�ˡ����ξ����֤���

������͡�
	�Ż���ؤΥݥ��󥿡�

�ڥ��顼��
	����ͤ� NULL �ˤʤ롣

����ջ����
	ͽ��ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ���Фʤ�ʤ���

������������
-----------------------------------------------------------------------------*/
void*
DmWork( DmLabor aSelf, int aSize )
{
	Labor	labor = (Labor)aSelf ;
	return( OzDcSetBuff( labor->send, aSize ) ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�Ժ����Τ�����

�ڷ�����
	int	DmBusy( DmLabor aSelf ) ;

�ڰ�����
	aSelf	��ϫƯ�ԤΥ����ǥ�ƥ��ƥ�

�ڵ�ǽ��
	���������˥ǥХå�������ͥ�˥��ơ������Ȥ��� (int)DC_BUSY ���������롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ� ����� �ˤʤ롣

����ջ����
	ͽ��ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ���Фʤ�ʤ���
	�ؿ� DmReady() �ȥڥ��ǻ��Ѥ��롣

������������
-----------------------------------------------------------------------------*/
int
DmBusy( DmLabor aSelf )
{
	Labor	labor = (Labor)aSelf ;
	OZ_Thread	t = NULL ;

	/* �й񤹤� */
	OzExecEnterMonitor( &labor->lock ) ;
	if ( labor->busy == 0 ) {
		labor->busy = 1 ;
		t = ThrFork( DmAbroad, AB_STACK_SIZE, DT_PRIORITY, 1, labor ) ;
	}
	OzExecExitMonitor( &labor->lock ) ;
	if ( t == NULL ) goto error ;

	return( OK ) ;

error:
	return( NG ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�Ժ����Τκ��

�ڷ�����
	void	DmReady( DmLabor aSelf ) ;

�ڰ�����
	aSelf	��ϫƯ�ԤΥ����ǥ�ƥ��ƥ�

�ڵ�ǽ��
	�ؿ� DmBusy() �ν����������롣

������͡�
	�ʤ���

�ڥ��顼��

����ջ����
	ͽ��ǥХå����ޥ͡�����Υ⥸�塼�뤬���������Ƥ��ʤ���Фʤ�ʤ���
	�ؿ� DmBusy() �ȥڥ��ǻ��Ѥ��롣

������������
-----------------------------------------------------------------------------*/
void
DmReady( DmLabor aSelf )
{
	Labor	labor = (Labor)aSelf ;

	/* ���񤹤� */
	OzExecEnterMonitor( &labor->lock ) ;
	if ( labor->busy ) {
		labor->busy = 0 ;
		OzExecSignalCondition( &labor->cond ) ;
	}
	OzExecExitMonitor( &labor->lock ) ;
}

/* for IPA '94 Oct. Demo */
int
DmGetServAddr( DmLabor aSelf, long long aOid )
{
	Labor		labor = (Labor)aSelf ;
	int		ret = NG ;
	DC		dc = NULL ;
	char		*data ;
	int		size = DC_SIZE ;
	char		buff[DC_SIZE] ;

	dc = OzDcOpen( aOid ) ;
	if ( dc == NULL ) goto error ;
	if ( OzDcType( labor->dc, buff, NULL ) == DC_UNIX && OzDcType( dc, buff, &size ) == DC_UNIX ) {
		if ( (data=DmWork( aSelf, size )) == NULL ) goto error ;
		memcpy( data, buff, size ) ;
	} else {
		int	i ;
		OzDcHeadRec	head ;
		head.type.request = 24 /* DM_INETPORT */ ;
		head.size = 0 ;
		if ( OzDcSend( dc, &head, sizeof(head) ) ) goto error ;
		if ( OzDcRecv( dc, &head, sizeof(head) ) || head.type.status < 0 ) goto error ;
		if ( (data=DmWork( aSelf, head.size )) == NULL ) goto error ;
		if ( OzDcRecv( dc, data, head.size ) ) goto error ;
		OzDcType( dc, buff, &size ) ;
		for ( i = 4 ; i < size ; i ++ ) *(data+i) = *(buff+i) ;
	}
	ret = OK ;

error:
	if ( dc != NULL ) OzDcClose( dc ) ;
	return( ret ) ;
}

/* for IPA '94 Oct. Demo */
int
DmGetInetPort( DmLabor aSelf )
{
	int	ret = NG ;
	char	*data ;
	int	size = DC_SIZE ;
	char	buff[DC_SIZE] ;

	if ( OzDcInet( buff, &size ) < 0 ) goto error ;
	if ( (data=DmWork( aSelf, size )) == NULL ) goto error ;
	memcpy( data, buff, size ) ;
	ret = OK ;

error:
	return( ret ) ;
}



/*
 *	�գΣɣإץ����ΥǥХå�����Υ��饹ž���׵�μ���
 */
typedef	struct	OZ_DmClassQueueEltStr	DmClassQueueEltRec ;
struct	OZ_DmClassQueueEltStr {
	SimpleRequestRec	simple_req ;
	OZ_DmClassRequest	request ;
} ;

int
DmGetClass( OID aCid )
{
	OZ_DmClassRequestRec	request ;
	DmClassQueueEltRec	queue_elt ;

	FqInitializeSimpleRequest( (SimpleRequest)&queue_elt ) ;
	request.cid = aCid ;
	request.status = 0 ;
	request.queue_elt = &queue_elt ;
	queue_elt.request = &request ;
	FqEnqueueRequestAndWait( (SimpleRequest)&queue_elt, &ClassRequestQ ) ;
	return( request.status ) ;
}

OZ_DmClassRequest
OzDmClassRequest()
{
	OZ_DmClassQueueElt	queue_elt ;
	queue_elt = (OZ_DmClassQueueElt)FqReceiveRequest( &ClassRequestQ ) ;
	return( queue_elt->request ) ;
}

void
OzDmClassRequestReply( int aStatus, OZ_DmClassRequest aRequest )
{
	OZ_DmClassQueueElt	queue_elt = aRequest->queue_elt ;
	aRequest->status = aStatus ;
	FqWakeupFaultSender( (SimpleRequest)queue_elt ) ;
}
