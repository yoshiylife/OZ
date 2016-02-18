/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include	<stdio.h>
/* multithread system include */
#include	"thread/thread.h"
#include	"thread/monitor.h"
#include	"oz++/ozlibc.h"

#include	"switch.h"
#include	"queue.h"

#include	"debugChannel.h"

#undef	TEST
#undef	CHECK

/* #if	defined(TEST) */
#include	<unistd.h>
#include	<sys/un.h>
#include	<sys/socket.h>
#include	<sys/types.h>
#include	<netinet/in.h>
#include	<arpa/inet.h>
#include	<fcntl.h>

#if	defined(TEST)
#define	UNIX_PATHFMT	"/tmp/Dm%06xunix"
#define	INET_TESTFMT	"/tmp/Dm%06xinet"
#define	UNIX		AF_UNIX
#define	INET		AF_INET

/* 試験のためのソケット・ネーム（ポート・アドレス）用バッファの構造 */
struct	Address		{
	int	domain ;
	int	protocol ;
	int	size ;
	union	{
		struct	sockaddr_un	un ;
		struct	sockaddr_in	in ;
	} addr ;
} ;
#else	/* TEST */
#define	UNIX		0
#define	INET		1
#endif	/* TEST */


#define	MSG_NORMAL	0
#define PSEUDO 		0
#define	NO_ABORT	0
#define	OK		0
#define	NG		(-1)
#define	LOOP		for(;;)
#define	STACK_SIZE	(4096 * 4)
#define	PRIORITY	(MAX_PRIORITY-1)		/* < DM_PRIORITY */
#define	EXECID(xxx)	((xxx>>24)&0xffffff)
#define	DATA_SIZE(xxx)	(sizeof(struct OzDcHeadStr)+(xxx))


#if	defined(CHECK)
extern	void	OzExecEnterMonitor( OZ_Monitor ml ) ;
extern	void	OzExecExitMonitor( OZ_Monitor ml ) ;
extern	void	OzExecSignalCondition( OZ_Condition cv ) ;
extern	char*	OzMalloc( unsigned size ) ;
extern	char*	OzRealloc( char *ptr, unsigned size ) ;
extern	void	OzFree( char *ptr ) ;
extern	int	OzOpen( char *path, int flags, int mode ) ;
extern	int	OzClose( int fd ) ;
#if	defined(TEST)
extern	int	OzRead( int fd, char *buf, int nbyte ) ;
extern	int	OzWrite( int fd, char *buf, int nbyte ) ;
extern	int	OzSocket( int domain, int type, int protocol ) ;
extern	int	OzBind( int s, struct sockaddr *name, int namelen ) ;
extern	int	OzConnect( int s, struct sockaddr *name, int namelen ) ;
extern	int	OzAccept( int s, struct sockaddr *name, int *namelen ) ;
#else
extern	int	OzAccept( int s, void *name, int *namelen ) ;
#endif	/* TEST */
extern	int	OzListen( int s, int backlong ) ;
extern	int	OzSend( int s, char *ms, int len, int flags ) ;
extern	int	OzRecv( int s, char *ms, int len, int flags ) ;
extern	int	OzShutdown( int s, int how ) ;
#endif	/* CHECK */

#if	defined(TEST)
static int	OzConnectDebugManager( long long aExID ) ;
#else
extern	int	OzConnectDebugManager( long long aID ) ;
#endif

/* デバッグ・チャネルのサービス（サーバ）・ポート(通信系が設定する） */
extern	int	DmUnixServPort ;
extern	int	DmInetServPort ;

/* デバッグ・チャネルの構造 */
typedef	struct DChanRec*	DChan ;
struct	DChanRec	{
	DChan		b_prev ;
	DChan		b_next ;
	OZ_MonitorRec	lock ;
	OZ_MonitorRec	sndrcv_lock ;
	int		port ;
} ;

/* デバッグ・チャネル管理 */
static	struct	{
	OZ_MonitorRec	lock ;
	OZ_ConditionRec	cond ;
	DChan		wait ;
	DChan		work ;
	DChan		free ;
} DChanManage ;

static	int	InitFlag = 0 ;


/* デバッグ・チャネル用メモリの獲得 */
static	DChan
DcGet( int aPort )
{
	DChan	dchan = NULL ;

	if ( DChanManage.free != NULL ) {
		/* 空きリストからの取り出し */
		dchan = DChanManage.free ;
		RemoveQueueBinary( dchan, DChanManage.free ) ;
	} else {
		/* 空きが無いので新規に作成 */
		dchan = (DChan)OzMalloc( sizeof(struct DChanRec) ) ;
		if ( dchan != NULL ) {
			OzInitializeMonitor( &dchan->lock ) ;
			OzInitializeMonitor( &dchan->sndrcv_lock ) ;
		}
	}

	if ( dchan != NULL ) {
		OzExecEnterMonitor( &dchan->lock ) ;
		dchan->port = aPort ;
		OzExecExitMonitor( &dchan->lock ) ;
	}

	return( dchan ) ;
}

/* サービス・ポートの監視 */
static	void
DcService( int aDomain, int aServPort )
{
		DChan	dchan ;
		int	port ;

	if ( ! InitFlag ) {
		OzDebugf( "デバッグ・チャネルのモジュールが初期化されていない\n" ) ;
		return ;
	}

	/* サーバ処理（メイン・ループ） */
	LOOP {
		if ( OzListen( aServPort, 5 ) ) {
			OzDebugf( "サービス・ポートの listen ができない[%m]\n" ) ;
			return ;
		}
#if	defined(TEST)
{
		struct	Address	servAddr ;
		memset( &servAddr.addr, 0, sizeof(servAddr.addr) ) ;
		servAddr.size = sizeof(servAddr) ;
		port = OzAccept( aServPort, (struct sockaddr *)&servAddr.addr, &servAddr.size ) ;
#else	/* TEST */
		port = OzAccept( aServPort, NULL, 0 ) ;
#endif	/* TEST */
		if ( port < 0 ) {
#if	0
			OzDebugf( "サービス・ポートの accept ができない[%m]\n" ) ;
#endif
			return ;
		}

#if	defined(TEST)
		if ( aDomain == AF_UNIX ) OzDebugf( "DC Accept UNIX.\n" ) ;
		else OzDebugf( "DC Accept INET Port: %d\n", servAddr.addr.in.sin_port ) ;
}
#endif	/* TEST */

		OzExecEnterMonitor( &DChanManage.lock ) ;
		if ( (dchan=DcGet( port )) ) {
			/* 接続要求の受け入れキューへのスロット登録 */
			InsertQueueBinary( dchan, DChanManage.wait ) ;
			OzExecSignalCondition( &DChanManage.cond ) ;
		} else {
			OzDebugf( "これ以上クライアントの接続はできない\n" ) ;
			OzShutdown( port, 2 ) ;
			OzClose( port ) ;
		}
		OzExecExitMonitor( &DChanManage.lock ) ;
	}
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・チャネルの初期化

【形式】
	int	DcInit( int aN ) ;

【引数】
	aN	：予め準備しておくデバッグ・チャネルの個数

【機能】
	デバッグ・チャネルのモジュールを初期化し、指定された個数の
	デバッグ・チャネル用のメモリを確保する。

【戻り値】
	ステータス

【エラー】
	戻り値が０以外の値になる。

【注意事項】
	デバッグ・チャネルは指定された個数以上のデバッグ・チャネルの作成
	要求があると、新たなメモリを確保しデバッグ・チャネルを作成する。
	一端確保されたデバッグ・チャネル用のメモリは開放されず、次の
	デバッグ・チャネルの作成時に再利用される。

【内部説明】
-----------------------------------------------------------------------------*/
int
DcInit( int aN )
{
	int	ret = NG ;
	int	i ;
	DChan	dchan ;

/* 初期化は１度のみ */
	if ( InitFlag ) goto error ;
	InitFlag = 1 ;

/* データ領域の初期化 */
	OzInitializeMonitor( &DChanManage.lock ) ;
	OzExecInitializeCondition( &DChanManage.cond, NO_ABORT ) ;
	InitQueueBinary( DChanManage.wait ) ;
	InitQueueBinary( DChanManage.work ) ;
	InitQueueBinary( DChanManage.free ) ;

/* デバッグ・チャネルの確保 */
	OzExecEnterMonitor( &DChanManage.lock ) ;
	for ( i = 0 ; i < aN ; i ++ ) {
		dchan = DcGet( -1 ) ;
		if ( dchan != NULL ) InsertQueueBinary( dchan, DChanManage.free ) ;
	}
	OzExecExitMonitor( &DChanManage.lock ) ;

#if	defined(TEST)
	OzDcSetupPort() ;
#endif

/* UNIX ドメインのサービスの開始 */
	if ( DmUnixServPort > 0 )
		ThrFork( DcService, STACK_SIZE, PRIORITY, 2, UNIX, DmUnixServPort ) ;

/* INET ドメインのサービスの開始 */
	if ( DmInetServPort > 0 )
		ThrFork( DcService, STACK_SIZE, PRIORITY, 2, INET, DmInetServPort ) ;

	ret = OK ;
	
error:
	if ( ret != OK ) InitFlag = 0 ;
	return( ret ) ;
}



/*
 *	デバッグ・チャネルＩ／Ｆ関数
 *
 */

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・チャネルのクライアント側開設

【形式】
	DC	OzDcOpen( long long aID ) ;

【引数】
	aID	：接続するエグゼキュータを指定する。
		　エグゼキュータＩＤ部分のみが参照される。

【機能】
	クライアント側のデバッグ・チャネルを割り当てる。

【戻り値】
	デバッグ・チャネル。

【エラー】
	戻り値が NULL となる。

【注意事項】

【内部説明】
-----------------------------------------------------------------------------*/
DC
OzDcOpen( long long aID )
{
		int	port ;
		DChan	dchan = NULL ;

	if ( ! InitFlag ) goto error ;

	port = OzConnectDebugManager( aID ) ;
	if ( port < 0 ) {
		/* サーバに接続できない */
		goto error ;
	}

	/* デバッグ・チャネルの割当 */
	OzExecEnterMonitor( &DChanManage.lock ) ;
	dchan = DcGet( port ) ;
	if ( dchan != NULL ) InsertQueueBinary( dchan, DChanManage.work ) ;
	OzExecExitMonitor( &DChanManage.lock ) ;

	if ( dchan == NULL ) {
		/* DChan用の資源が足りない */
		OzShutdown( port, 2 ) ;
		OzClose( port ) ;
		goto error ;
	}

error:
	return( (DC)dchan ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・チャネルのサーバ側開設

【形式】
	DC	OzDcAccept() ;

【引数】

【機能】
	サーバ側のデバッグ・チャネルを割り当てる。

【戻り値】
	デバッグ・チャネル。

【エラー】
	戻り値が NULL となる。

【注意事項】

【内部説明】
-----------------------------------------------------------------------------*/
DC
OzDcAccept()
{
	DChan	dchan = NULL ;

	if ( ! InitFlag ) goto error ;

	OzExecEnterMonitor( &DChanManage.lock ) ;
	while ( DChanManage.wait == NULL ) OzExecWaitCondition( &DChanManage.lock, &DChanManage.cond ) ;
	/* 接続要求の受け入れキューからのスロット取り出し */
	dchan = DChanManage.wait ;
	RemoveQueueBinary( dchan, DChanManage.wait ) ;
	InsertQueueBinary( dchan, DChanManage.work ) ;
	OzExecExitMonitor( &DChanManage.lock ) ;

error:
	return( (DC)dchan ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・チャネルの閉鎖

【形式】
	void	OzDcClose( DC aDC ) ;

【引数】
	aDC	：閉鎖するデバッグ・チャネルを指定する。

【機能】
	デバッグ・チャネルを閉鎖する。

【戻り値】
	なし。

【エラー】

【注意事項】
	セッション中であっても、デバッグ・チャネルを閉鎖する。

【内部説明】
-----------------------------------------------------------------------------*/
void
OzDcClose( DC aDC )
{
	DChan	dchan = (DChan)aDC ;
	int	port ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL ) goto error ;

	/* 使用中であってもファイル記述子フィールドを無効にする */
	OzExecEnterMonitor( &dchan->lock ) ;
	port = dchan->port ;
	dchan->port = -1 ;
	OzExecExitMonitor( &dchan->lock ) ;

	OzExecEnterMonitor( &DChanManage.lock ) ;
	RemoveQueueBinary( dchan, DChanManage.work ) ;
	InsertQueueBinary( dchan, DChanManage.free ) ;
	OzExecExitMonitor( &DChanManage.lock ) ;

	OzShutdown( port, 2 ) ;
	OzClose( port ) ;

error:
	return ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	データの送信

【形式】
	int	OzDcSend( DC aDC, void *aData, int aNbyte )

【引数】
	aDC	：送信先のデバッグ・チャネルを指定する。
	aData	：送信するデータが格納されている領域へのポインタを指定する。
	aNbyte	：送信するデータのバイト数を指定する。

【機能】
	データを送信する。

【戻り値】
	ステータス

【エラー】
	戻り値がゼロ以外の値になる。
	

【注意事項】
	送信データのバッファリングは行われない。
	この関数は排他制御を行っていないので、関数 OzDcBegin() と
	関数 OzDcEnd() と組み合わせて使うこと。
	デバッグ・マネージャから呼び出されることを想定している。

【内部説明】
-----------------------------------------------------------------------------*/
int
OzDcSend( DC aDC, void *aData, int aNbyte )
{
	DChan	dchan = (DChan)aDC ;
	char	*ptr = aData ;
	int	ret = NG ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL || aData == NULL || aNbyte <= 0 ) goto error ;

	do {
		ret = OzSend( dchan->port, ptr, aNbyte, MSG_NORMAL ) ;
		if ( ret <= 0 ) break ;
		aNbyte -= ret ;
		ptr += ret ;
	} while( 0 < aNbyte ) ;
	if ( aNbyte != 0 ) {
		OzDebugf( "OzDcSend: %m" ) ;
		ret = NG ;
		goto error ;
	}

	ret = OK ;

error:
	return( ret ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	データの受信

【形式】
	int	OzDcRecv( DC aDC, void *aData, int aNbyte )

【引数】
	aDC	：受信先のデバッグ・チャネルを指定する。
	aData	：受信するデータを格納する領域へのポインタを指定する。
	aNbyte	：受信するデータのバイト数を指定する。

【機能】
	データを受信する。

【戻り値】
	ステータス

【エラー】
	戻り値がゼロ以外の値になる。
	

【注意事項】
	この関数は排他制御を行っていないので、関数 OzDcBegin() と
	関数 OzDcEnd() と組み合わせて使うこと。
	デバッグ・マネージャから呼び出されることを想定している。

【内部説明】
-----------------------------------------------------------------------------*/
int
OzDcRecv( DC aDC, void *aData, int aNbyte )
{
	DChan	dchan = (DChan)aDC ;
	char	*ptr = aData ;
	int	ret = NG ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL || aData == NULL || aNbyte <= 0 ) goto error ;

	/* データの受信 */
	do {
		ret = OzRecv( dchan->port, ptr, aNbyte, MSG_NORMAL ) ;
		if ( ret <= 0 ) break ;
		aNbyte -= ret ;
		ptr += ret ;
	} while( 0 < aNbyte ) ;
	if ( aNbyte != 0 ) {
		ret = NG ;
		goto error ;
	}

	ret = OK ;

error:
	return( ret ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・チャネルのセッション開始

【形式】
	int	OzDcBegin( DC aDC ) ;

【引数】
	aDC	：セッションを開始するデバッグ・チャネルを指定する。

【機能】
	デバッグ・チャネルをセッション中に他のプログラムが使用できないように
	する。

【戻り値】
	ステータス

【エラー】
	戻り値がゼロ以外の値になる。

【注意事項】
	セッション終了時にに関数 OzEndDC() を呼び出すこと。

【内部説明】
-----------------------------------------------------------------------------*/
int
OzDcBegin( DC aDC )
{
	DChan	dchan = (DChan)aDC ;
	int	ret = NG ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL ) goto error ;

	OzExecEnterMonitor( &dchan->sndrcv_lock ) ;

	ret = OK ;

error:
	return( ret ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	公開

【名前】
	デバッグ・チャネルのセッション終了

【形式】
	int	OzDcEnd( DC aDC ) ;

【引数】
	aDC	：セッションを終了するデバッグ・チャネルを指定する。

【機能】
	デバッグ・チャネルを他のプログラムがセッションに使用できるようにする。

【戻り値】
	ステータス

【エラー】
	戻り値がゼロ以外の値になる。

【注意事項】
	セッション開始は関数 OzBeginDC() を呼び出すこと。

【内部説明】
-----------------------------------------------------------------------------*/
int
OzDcEnd( DC aDC )
{
	DChan	dchan = (DChan)aDC ;
	int	ret = NG ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL ) goto error ;

	OzExecExitMonitor( &dchan->sndrcv_lock ) ;

	ret = OK ;

error:
	return( ret ) ;
}

/* バッファの作成とデータ領域の大きさの変更 */
void*
OzDcSetBuff( OzDcBuff aBuff, int aSize )
{
	OzDcBuff	buff = (OzDcBuff)aBuff ;
	void		*addr = NULL ;
	void		*data ;

/* バッファ管理構造体とバッファ領域の作成 */
	if ( buff == NULL ) {

		buff = (OzDcBuff)OzMalloc( sizeof(OzDcBuff) ) ;
		if ( buff == NULL ) goto error ;
		if ( aSize < 0 ) aSize *= (-1) ;
		buff->data = (OzDcData)OzMalloc( DATA_SIZE(aSize) ) ;
		if ( buff->data == NULL ) {
			OzFree( (void *)buff ) ;
			goto error ;
		}
		buff->size = aSize ;
		buff->data->head.size = 0 ;
		addr = (void *)buff ;

/* バッファ領域の操作 */
	} else {

		/* バッファ管理構造体とバッファ領域の開放 */
		if ( aSize ==  BUFF_FREE ) {
			if ( buff->data != NULL ) OzFree( (void *)buff->data ) ;
			OzFree( (void *)buff ) ;

		} else {
			/* バッファ領域の作成 */
			if ( buff->size == 0 ) {
				data = (void *)OzMalloc( DATA_SIZE(aSize) ) ;
				if ( data == NULL ) goto error ;
				buff->size = aSize ;
				buff->data = data ;
				addr = buff->data->addr ;

			/* バッファ領域の拡張 */
			} else if ( buff->size < aSize ) {
				data = (void *)OzRealloc( (void *)buff->data, DATA_SIZE(aSize) ) ;
				if ( data == NULL ) goto error ;
				buff->size = aSize ;
				buff->data = data ;
				addr = buff->data->addr ;

			/* バッファ領域の再利用 */
			} else addr = buff->data->addr ;

			buff->data->head.size = aSize ;
		}
	}

error:
	return( addr ) ;
}

/* for IPA Oct. '94 Demo */
int
OzDcType( DC aDC, void *aBuff, int *aSize )
{
	DChan		dchan = (DChan)aDC ;
	int		ret = NG ;
	int		size ;
	struct sockaddr	addr ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL ) goto error ;

	if ( aSize == NULL ) size = sizeof(struct sockaddr) ;
	else size = *aSize ;
	if ( OzGetpeername( dchan->port, aBuff, &size ) ) goto error ;
	if ( aSize != NULL ) *aSize = size ;

	size = sizeof(addr) ;
	if ( OzGetsockname( dchan->port, &addr, &size ) ) goto error ;
	if ( addr.sa_family == AF_UNIX ) ret = DC_UNIX ;
	else if ( addr.sa_family == AF_INET ) ret = DC_INET ;

error:
	return( ret ) ;
}

/* for IPA Oct. '94 Demo */
int
OzDcInet( void *aBuff, int *aSize )
{
	int		ret = NG ;
		
	if ( ! InitFlag ) goto error ;

	if ( OzGetsockname( DmInetServPort, aBuff, aSize ) ) goto error ;
	ret = OK ;

error:
	return( ret ) ;
}

#if	defined(TEST)
static int
OzConnectDebugManager( long long aExID )
{
		int	port ;
		int	fd ;
	struct Address	servAddr ;
		char	buf[64] ;

	/* サービス・アドレス（ポート）の作成 */
	servAddr.size = 0 ;
	memset( &servAddr.addr, 0, sizeof(servAddr.addr) ) ;

	if ( EXECID(aExID) != EXECID(OzExecutorID) ) {
		OzSprintf( buf, INET_TESTFMT, (int)EXECID(aExID) ) ;
		fd = open( buf, O_RDONLY|O_SYNC ) ;
		if ( fd > 0 ) {
			read( fd, &servAddr.addr.in, sizeof(servAddr.addr.in) ) ;
			close( fd ) ;
		} else goto error ;
		servAddr.domain = AF_INET ;
		servAddr.protocol = IPPROTO_TCP ;
		servAddr.size = sizeof(servAddr.addr.in) ;
	} else {
		servAddr.domain = AF_UNIX ;
		servAddr.protocol = PSEUDO  ;
		servAddr.addr.un.sun_family = AF_UNIX ;
		OzSprintf( servAddr.addr.un.sun_path, UNIX_PATHFMT,(int)EXECID(aExID) ) ;
		servAddr.size = sizeof(servAddr.addr.un.sun_family) ;
		servAddr.size += strlen(servAddr.addr.un.sun_path) ;
	}

	/* クライアント・ポートの開設 */
	port = OzSocket( servAddr.domain, SOCK_STREAM, servAddr.protocol ) ;
	if ( port < 0 ) {
		/* ソケットが作成できない */
		goto error ;
	}

	if ( OzConnect( port, (struct sockaddr *)&servAddr.addr, servAddr.size ) ) {
		/* サーバに接続できない */
		OzClose( port ) ;
		port = NG ;
		goto error ;
	}

error:
	return( port ) ;
}

int
OzDcSetupPort()
{
		int	ret = NG ;
		int	fd ;
		char	buf[64] ;
	struct	Address	servAddr ;

/* UNIX ドメインのサービス・アドレス（ポート）の作成 */
	memset( &servAddr.addr, 0, sizeof(servAddr.addr) ) ;
	servAddr.addr.un.sun_family = AF_UNIX ;
	OzSprintf( servAddr.addr.un.sun_path, UNIX_PATHFMT,(int)EXECID(OzExecutorID) ) ;
	if ( access( servAddr.addr.un.sun_path, F_OK ) == OK ) unlink( servAddr.addr.un.sun_path ) ;
	servAddr.size = sizeof(servAddr.addr.un.sun_family) + strlen(servAddr.addr.un.sun_path) ;

/* UNIX ドメインのサービス・ポートの開設 */
	DmUnixServPort = OzSocket( AF_UNIX, SOCK_STREAM, PSEUDO ) ;
	if ( DmUnixServPort < 0 ) {
		/* サービス・ポートが開設できない */
		goto error ;
	}
	ret = OzBind( DmUnixServPort, (struct sockaddr *)&servAddr.addr.un, servAddr.size ) ;
	if ( ret ) {
		/* サービス・ポートに名前を割り当てることができない */
		goto error ;
	}
	OzDebugf( "DC Service UNIX Path: %s\n", servAddr.addr.un.sun_path ) ;

/* INET ドメインのサービス・アドレス（ポート）の作成 */
	memset( &servAddr.addr, 0, sizeof(servAddr.addr) ) ;
	servAddr.addr.in.sin_family = AF_INET ;
	servAddr.addr.in.sin_addr.s_addr = INADDR_ANY ;
	servAddr.addr.in.sin_port = 0 ;
	servAddr.size = sizeof(servAddr.addr.in) ;

/* INET ドメインのサービス・ポートの開設 */
	DmInetServPort = OzSocket( AF_INET, SOCK_STREAM, IPPROTO_TCP ) ;
	if ( DmInetServPort < 0 ) {
		/* サービス・ポートが開設できない */
		goto error ;
	}
	ret = OzBind( DmInetServPort, (struct sockaddr *)&servAddr.addr.in, servAddr.size ) ;
	if ( ret ) {
		/* サービス・ポートに名前を割り当てることができない */
		goto error ;
	}

	ret = getsockname( DmInetServPort, &servAddr.addr.in, &servAddr.size ) ;
	if ( ret ) {
		/* ソケット名の獲得に失敗した */
		goto error ;
	}

	OzSprintf( buf, INET_TESTFMT, (int)EXECID(OzExecutorID) ) ;
	fd = open( buf, O_RDWR|O_TRUNC|O_CREAT|O_SYNC, 0666 ) ;
	if ( fd > 0 ) {
		write( fd, &servAddr.addr.in, sizeof(servAddr.addr.in) ) ;
		close( fd ) ;
	} else goto error ;

	OzDebugf( "DC Service INET Port: %d\n", servAddr.addr.in.sin_port ) ;

error:
	return( ret ) ;
}
#endif	/* TEST */

