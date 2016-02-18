/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include "oz++/type.h"
#include "executor/object-table.h"
#include "channel.h"
#include "proc.h"
#include "global-trace.h"
#include "id.h"

#define	BUFSIZE		64
#define	OT_UNKNOWN	"?%d"
#define	PT_UNKNOWN	"?%d"
#define	TT_UNKNOWN	"?%d"
#define	CASE(xXvAlUe,xXnAmE)	case xXvAlUe: xXnAmE = #xXvAlUe ; break

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	OZ_ObjectStatus を文字列に変換

【形式】
	const	char*	ObjectStatusToName( OZ_ObjectStatus aStatus ) ;

【引数】
	aStatus	：ＯＴのステータス

【機能】
	aStatus の値を文字列化する。

【戻り値】
	定数文字列へのポインタ

【エラー】
	なし

【注意事項】
	aStatus が意図しない値の場合は、OT_UNKNOWN で変換した結果の
	文字列へのポインタ（内部バッファ）を返す。

【内部説明】
-----------------------------------------------------------------------------*/
const	char*
ObjectStatusToName( OZ_ObjectStatus aStatus )
{
static	char	buf[BUFSIZE] ;
const	char	*name ;
	switch( aStatus ) {
	case OT_READY	: name = "READY" ; break ;
	case OT_QUEUE	: name = "QUEUE" ; break ;
	case OT_STOP	: name = "STOP" ; break ;
	default		: sprintf( buf, OT_UNKNOWN, aStatus ) ; name = buf ;
	}
	return( name ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	配列要素の型を文字列に変換

【形式】
	const	char*	ArrayTypeToName( int aType ) ;

【引数】
	aType	：配列要素の型

【機能】
	aType の値を文字列化する。

【戻り値】
	定数文字列へのポインタ

【エラー】
	なし

【注意事項】

【内部説明】
-----------------------------------------------------------------------------*/
const	char*
ArrayTypeToName( long long aType )
{
static	char	buf[BUFSIZE] ;
const	char	*name ;
	switch( aType ) {
	case OZ_CHAR		: name = "CHAR" ; break ;
	case OZ_SHORT		: name = "SHORT" ; break ;
	case OZ_INT		: name = "INT" ; break ;
	case OZ_LONG_LONG	: name = "LONG" ; break ;
	case OZ_FLOAT		: name = "FLOAT" ; break ;
	case OZ_DOUBLE		: name = "DOUBLE" ; break ;
	case OZ_CONDITION	: name = "CONDITION" ; break ;
	case OZ_LOCAL_OBJECT	: name = "LOCAL" ; break ;
	case OZ_RECORD		: name = "RECORD" ; break ;
	case OZ_STATIC_OBJECT	: name = "STATIC" ; break ;
	case OZ_GLOBAL_OBJECT	: name = "GLOBAL" ; break ;
	case OZ_ARRAY		: name = "ARRAY" ; break ;
	case OZ_PROCESS		: name = "PROCESS" ; break ;
	case OZ_PADDING		: name = "PADDING" ; break ;
	default			: name = IDtoStr( aType, buf ) ;
	}
	return( name ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	ProcStatus を文字列に変換

【形式】
	const	char*	ProcStatusToName( ProcStatus aStatus ) ;

【引数】
	aStatus	：プロセスのステータス

【機能】
	aStatus の値を文字列化する。

【戻り値】
	定数文字列へのポインタ

【エラー】
	なし

【注意事項】
	aStatus が意図しない値の場合は、PT_UNKNOWN で変換した結果の
	文字列へのポインタ（内部バッファ）を返す。

【内部説明】
-----------------------------------------------------------------------------*/
const	char*
ProcStatusToName( ProcStatus aStatus )
{
static	char	buf[BUFSIZE] ;
const	char	*name ;
	switch( aStatus ) {
	case PROC_FREE		: name = "FREE" ; break ;
	case PROC_RUNNING	: name = "RUNNING" ; break ;
	case PROC_EXITED	: name = "EXITED" ; break ;
	case PROC_DETACHED	: name = "DETACHED" ; break ;
	case PROC_JOINED	: name = "JOINED" ; break ;
	default			: sprintf( buf, PT_UNKNOWN, aStatus ) ; name = buf ;
	}
	return( name ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	TStat を文字列に変換

【形式】
	const	char*	TStatToName( TStatus aStatus ) ;

【引数】
	aStatus	：スレッドのステータス

【機能】
	aStatus の値を文字列化する。

【戻り値】
	定数文字列へのポインタ

【エラー】
	なし

【注意事項】
	aStatus が意図しない値の場合は、TT_UNKNOWN で変換した結果の
	文字列へのポインタ（内部バッファ）を返す。

【内部説明】
-----------------------------------------------------------------------------*/
const	char*
TStatToName( TStat aStatus )
{
static	char	buf[BUFSIZE] ;
const	char	*name ;
	switch( aStatus ) {
	CASE(	FREE,		name ) ;
	CASE(	CREATE,		name ) ;
	CASE(	READY,		name ) ;
	CASE(	RUNNING,	name ) ;
	CASE(	SUSPEND,	name ) ;
	CASE(	WAIT_IO,	name ) ;
	CASE(	WAIT_LOCK,	name ) ;
	CASE(	WAIT_COND,	name ) ;
	CASE(	WAIT_SUSPEND,	name ) ;
	CASE(	WAIT_TIMER,	name ) ;
	CASE(	DEFUNCT,	name ) ;
	default	: sprintf( buf, TT_UNKNOWN, aStatus ) ; name = buf ;
	}
	return( name ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	トレース状態を文字列に変換する

【形式】
	const	char*	TraceModeToName( int aMode ) ;

	const	char*	TraceTypeToName( int aType ) ;

	const	char*	TracePhaseToName( int aPhase ) ;

【引数】
	aMode	：トレース・モード
	aType	：トレース・タイプ
	aPhase	：トレース・フェーズ

【機能】
	引数の値を文字列化する。

【戻り値】
	定数文字列へのポインタ

【エラー】
	なし

【注意事項】
	引数の値が意図しない値の場合は、UNKNOWN で始まる
	文字列へのポインタを返す。

【内部説明】
-----------------------------------------------------------------------------*/
const	char*
TraceModeToName( int aMode )
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

const	char*
TraceTypeToName( int aType )
{
	const char	*name ;
	switch( aType & TRACE_TYPE ) {
	CASE( TRACE_CALLER,	name ) ;
	CASE( TRACE_CALLEE,	name ) ;
	default:	name = "UNKNOWN TYPE" ;
	}
	return( name ) ;
}

const	char*
TracePhaseToName( int aPhase )
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

