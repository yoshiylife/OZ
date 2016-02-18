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

/* クリーンナップ処理用キューの構造 */
typedef	struct	OnExitStr*	OnExit ;
typedef	struct	OnExitStr	OnExitRec ;
struct	OnExitStr	{
	OzDcBuff	buff ;
	OnExit		b_prev ;
	OnExit		b_next ;
} ;

/* 労働者の戸籍の構造 */
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

/* 職業安定所 */
static	struct	{
	OZ_MonitorRec	lock ;
	Labor		lose ;
	Labor		work ;
} LaborQ ;

static	FaultQueueRec	ClassRequestQ ;
static	int	InitFlag = 0 ;
static	int	Mode = 0 ;	/* 負：デバッグ禁止、０：要求ベース、正：デバッグ数固定 */


/* 労働者の戸籍の作成 */
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

/* 労働者の戸籍の破棄 */
static	void
DmFree( Labor aLabor )
{
	OzDcSetBuff( aLabor->recv, BUFF_FREE ) ;
	OzDcSetBuff( aLabor->send, BUFF_FREE ) ;
	OzFree( aLabor ) ;
}

/* 割り当て待ちキューへの登録 */
static	void
DmEnque( Labor aLabor )
{
	OzExecEnterMonitor( &LaborQ.lock ) ;
	RemoveQueueBinary( aLabor, LaborQ.work ) ;
	InsertQueueBinary( aLabor, LaborQ.lose ) ;
	OzExecExitMonitor( &LaborQ.lock ) ;
}

/* 割り当て待ちキューからの削除 */
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

/* 部分順序付き木の作成 */
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

/* ワーク・テーブルの処理番号によるソート */
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

/* 処理番号から関数ポインタへの変換 */
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

/* 外国での生活 */
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

	wtime = ( 1000000 / interval ) * 1 ;	/* １秒 */
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

/* 労働者の人生 */
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
		OzDebugf( "デバッグ・マネージャのモジュールが初期化されていない\n" ) ;
		return ;
	}

	LOOP {
		/* 仕事の割り当て待ち */
		OzExecEnterMonitor( &aLabor->lock ) ;
		while ( (dc=aLabor->dc) == NULL ) OzExecWaitCondition( &aLabor->lock, &aLabor->cond ) ;
		OzExecExitMonitor( &aLabor->lock ) ;

		/* 仕事開始 */
		OzDcBegin( dc ) ;

#if	defined(DEBUG)
OzDebugf( "DM Labor Begin: 0x%08x\n", aLabor ) ;
#endif

		/* 仕事ループ */
		LOOP {

			/* どの仕事？ */
			ret = OzDcRecv( dc, &recv->data->head, sizeof(recv->data->head) ) ; 
			if ( ret != OK ) break ;

			request = recv->data->head.type.request ;
			size = recv->data->head.size ;

			/* 使うものは？ */
			if ( 0 < size ) {

				/* 資材置き場の確保 */
				if ( (data=OzDcSetBuff( recv, size )) == NULL ) break ;

				/* 資材を受け取る */
				ret = OzDcRecv( dc, data, size ) ;
				if ( ret != OK ) break ;

			} else data = NULL ;
#if	defined(DEBUG_REQ)
OzDebugf( "DM Labor      Req = %d, Size = %d\n", request, size ) ;
#endif
			/* 働く */
			entry = DmToFnEntry( request ) ;
			if ( entry == NULL ) status = -1 ;
			else status = entry->ptr( aLabor, data, size ) ;
			if ( status < 0 ) DmWork( aLabor, 0 ) ;

			send->data->head.type.status = status ;
			size = sizeof(send->data->head) + send->data->head.size ;

			/* 結果の報告 */
			ret = OzDcSend( dc, (char *)send->data, size ) ;
			if ( ret != OK ) break ;

#if	defined(DEBUG_RES)
OzDebugf( "DM Labor      Res = %d, Size = %d\n", status, send->data->head.size ) ;
#endif

		} ;

		/* 終了処理 */
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
		/* 出国中であれば帰国させる */
		DmReady( aLabor ) ;

		/* 仕事終了 */
		OzDcEnd( dc ) ;

		/* Multiplexしないので、ここで終了 */
		OzDcClose( dc ) ;

		OzExecEnterMonitor( &aLabor->lock ) ;
		aLabor->dc = NULL ;
		OzExecExitMonitor( &aLabor->lock ) ;

		if ( Mode != 0 ) {
			/* 失業したので職業安定所に行く */
			DmEnque( aLabor ) ;
		} else {
			/* 要求ベースなので自殺する */
			OzExecEnterMonitor( &LaborQ.lock ) ;
			RemoveQueueBinary( aLabor, LaborQ.work ) ;
			OzExecExitMonitor( &LaborQ.lock ) ;
			DmFree( aLabor ) ;
			break ;
		}
	}
}

/* デバッグ・マネージャ（仕事の割り当て） */
static	void
DmManager()
{
	DC	dc ;
	Labor	labor = NULL ;
	OZ_Thread	t ;

	if ( !InitFlag ) {
		OzDebugf( "デバッグ・マネージャのモジュールが初期化されていない\n" ) ;
		return ;
	}

	LOOP {
		/* 仕事の依頼を待つ */
		dc = OzDcAccept() ;

		/* 仕事を割り当てる */
		if ( 0 <= Mode && (labor=DmDeque()) != NULL ) {
			/* 失業者に仕事を割り当てる */
			OzExecEnterMonitor( &labor->lock ) ;
			labor->dc = dc ;
			OzExecSignalCondition( &labor->cond ) ;
			OzExecExitMonitor( &labor->lock ) ;
		}

		/* 要求ベースのモードならば */
		if ( Mode == 0 && labor == NULL ) {
			/* 新しい労働者を作成し、仕事を割り当てる */
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

		/* 仕事の割り当てに失敗した */
		if ( labor == NULL ) OzDcClose( dc ) ;
	}
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・マネージャの初期化

【形式】
	int	DmInit( int aMax ) ;

【引数】
	aMax	：受け付けることができるデバッグ・セッションの最大数
		　但し、０の場合は、要求ベースでデバッグ・セッションが作成される。
		　また、負の場合は、デバッグ・セッションは作成されない。

【機能】
	デバッグ・マネージャのモジュールを初期化し、必要なスレッド作成する。

【戻り値】
	ステータス

【エラー】
	戻り値が０以外の値になる。

【注意事項】

【内部説明】
-----------------------------------------------------------------------------*/
int
DmInit( int aMax )
{
	int	ret = NG ;
	int	i ;
	Labor	labor ;
	OZ_Thread	t ;

/* 初期化は１度のみ */
	if ( InitFlag ) goto error ;
	InitFlag = 1 ;
	Mode = aMax ;

/* データ領域の初期化＆初期設定 */
	OzInitializeMonitor( &LaborQ.lock ) ;
	InitQueueBinary( LaborQ.lose ) ;
	InitQueueBinary( LaborQ.work ) ;
	FqInitializeFaultQueue( (FaultQueue)&ClassRequestQ ) ;

	DmSortFnEntry() ;

	/* 労働者を作成し、職業安定所に登録する（失業者として出世する） */
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

	/* デバッグ・マネジャーを起動 */
	ThrFork( DmManager, DM_STACK_SIZE, DM_PRIORITY, 0 ) ;

	ret = OK ;

error:
	if ( ret != OK ) InitFlag = 0 ;
	return( ret ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・マネージャのモード変更

【形式】
	int	OzDmChangeMode( int aMode ) ;

【引数】
	aMode	：０の場合は、新しいデバッグ・セッションの作成を禁止する。
		　０以外の場合は、新しいデバッグ・セッションの作成を許可する。

【機能】
	デバッグ・マネージャのモードを変更する。

【戻り値】
	ステータス

【エラー】
	戻り値が０以外の値になる。

【注意事項】
	予めデバッグ・マネージャのモジュールが初期化されていなければならない。

【内部説明】
-----------------------------------------------------------------------------*/
int
OzDmChangeMode( int aMode )
{
	int	ret = NG ;

	if ( !InitFlag ) {
		OzDebugf( "デバッグ・マネージャのモジュールが初期化されていない\n" ) ;
		goto error ;
	}

	if ( aMode ) Mode *= ( (Mode>0) ? -1 : 1 ) ;
	else Mode *= ( (Mode>0) ? 1 : -1 ) ;
	ret = OK ;

error:
	return( ret ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	クリーン・アップ処理の登録

【形式】
	int	DmOnExitAdd( DmLabor aSelf, int aRequest, void *aData, int aSize ) ;

【引数】
	aSelf	：労働者のアイデンティティ
	aRequest：仕事の種類
	aData	：仕事に使う資材置き場へのポインタ
	aSize	：その資材置き場の広さ

【機能】
	一連の仕事の終了に、他人に迷惑をかけないないように、
	後始末するための仕事を登録する。

【戻り値】
	ステータス

【エラー】
	戻り値が０以外の値になる。

【注意事項】
	予めデバッグ・マネージャのモジュールが初期化されていなければならない。

【内部説明】
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
【関数】
	公開

【名前】
	クリーン・アップ処理の削除

【形式】
	int	DmOnExitDel( DmLabor aSelf, int aRequest, void *aData, int aSize )

【引数】
	aSelf	：労働者のアイデンティティ
	aRequest：仕事の種類
	aData	：仕事に使う資材置き場へのポインタ
	aSize	：その資材置き場の広さ

【機能】
	他人に迷惑をかける仕事が終了したので、 後始末する必要がなくなったので
	登録した仕事を削除する。

【戻り値】
	ステータス

【エラー】
	戻り値が０以外の値になる。

【注意事項】
	予めデバッグ・マネージャのモジュールが初期化されていなければならない。

【内部説明】
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
【関数】
	公開

【名前】
	仕事場の決定

【形式】
	void*	DmWork( DmLabor aSelf, int aSize ) ;

【引数】
	aSelf	：労働者のアイデンティティ
	aSize	：バッファとして使用するバイト数を指定する。

【機能】
	仕事場の広さを調整するとともに、その場所を返す。

【戻り値】
	仕事場へのポインタ。

【エラー】
	戻り値が NULL になる。

【注意事項】
	予めデバッグ・マネージャのモジュールが初期化されていなければならない。

【内部説明】
-----------------------------------------------------------------------------*/
void*
DmWork( DmLabor aSelf, int aSize )
{
	Labor	labor = (Labor)aSelf ;
	return( OzDcSetBuff( labor->send, aSize ) ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	不在通知の設定

【形式】
	int	DmBusy( DmLabor aSelf ) ;

【引数】
	aSelf	：労働者のアイデンティティ

【機能】
	一定時間毎にデバッグ・チャネルにステータスとして (int)DC_BUSY を送信する。

【戻り値】
	ステータス

【エラー】
	戻り値が 負の値 になる。

【注意事項】
	予めデバッグ・マネージャのモジュールが初期化されていなければならない。
	関数 DmReady() とペアで使用する。

【内部説明】
-----------------------------------------------------------------------------*/
int
DmBusy( DmLabor aSelf )
{
	Labor	labor = (Labor)aSelf ;
	OZ_Thread	t = NULL ;

	/* 出国する */
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
【関数】
	公開

【名前】
	不在通知の削除

【形式】
	void	DmReady( DmLabor aSelf ) ;

【引数】
	aSelf	：労働者のアイデンティティ

【機能】
	関数 DmBusy() の処理を解除する。

【戻り値】
	なし。

【エラー】

【注意事項】
	予めデバッグ・マネージャのモジュールが初期化されていなければならない。
	関数 DmBusy() とペアで使用する。

【内部説明】
-----------------------------------------------------------------------------*/
void
DmReady( DmLabor aSelf )
{
	Labor	labor = (Labor)aSelf ;

	/* 帰国する */
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
 *	ＵＮＩＸプロセスのデバッガからのクラス転送要求の受付
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
