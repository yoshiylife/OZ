/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* CAUTION */
/* Ｃ言語標準（ＡＮＳＩ、または、システムが提供する）ヘッダ
 * のみのインクルードを許可する。ただし、本ファイル名と
 * 同じベース名を持つファイルのだた１つのインクルードは
 * 行ってよい。
 */
#include <stdio.h>
#include <ctype.h>
#include "id.h"

typedef	union	IdUni*	Id ;
typedef	union	IdUni	IdRec ;
typedef	unsigned char	uchar ;
union	IdUni	{
	uchar	bit[8] ;
	LONG	value ;
} ;

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	ＩＤ文字列（１６進）をダブルワード整数に変換

【形式】
	LONG	StrToID( int aSiteID, int aExecID, char *aStr, char **aPtr ) ;

【引数】
	aSiteID	：サイトＩＤ
	aExecID	：エグゼキュータＩＤ
	aStr	：１６進文字列
	aPtr	：解釈を終了した文字へのポインタ

【機能】
	１６進文字列をダブルワード整数に変換する。
	その変換の結果、サイトＩＤ、エグゼキュータＩＤのビットフィールドが
	ゼロとなる場合は、aSiteID, aExecID の値を各フィールドに設定し、
	ゼロでない場合は、aSiteID, aExecID と一致するかを検査する。
	ただし、aSiteID, aExecID がそれぞれゼロである場合は、各々の
	ビットフィールドの値は設定も検査もされない。
	aSiteID, aExecID の値にかかわらず、aPtr が NULL でない場合は、
	*aPtr に解釈を終了した文字のアドレス値を代入する。

【戻り値】
	ダブルワード整数（ＩＤ）

【エラー】
	戻り値が０の値になる。

【注意事項】
	１６進文字として認識するのは、0 〜 9, a 〜 f, A 〜 F のみである。
	上記の文字セット以外の先頭の文字（複数）は無視される。
	上記の文字セット以外の文字が現われるまでの文字が解釈される。
	解釈される文字列の長さは１６文字以下である。
	ただし、先頭に 0x または 0X が現われた場合、その直後から文字の解釈が
	行われる。つまり、その直後に上記文字セット以外の文字があると戻り値
	は０となる。
	ＳＰＡＲＣアーキテクチャ専用である。

【内部説明】
	この関数の実現のために、他の関数の呼出しを一切行わないこと。

-----------------------------------------------------------------------------*/
LONG
StrToID( int aSiteID, int aExecID, char *aStr, char **aPtr )
{
	int	i ;
	int	j ;
	IdRec	id ;
	uchar	buf[16] ;
	uchar	c ;

	id.value = 0 ; /* default: Error */
	if ( aPtr != NULL ) *aPtr = aStr ;

	/* 文字セット以外の文字のスキップ */
	if ( aStr[0] == '0' && (aStr[1] == 'x' || aStr[1] == 'X') ) aStr += 2 ;
	else while( *aStr != '\0' && ! isxdigit(*aStr) ) aStr ++ ;
	if ( aPtr != NULL ) *aPtr = aStr ;

	/* １６進文字列の切り出し */
	for ( i = 0 ; *aStr && isxdigit(*aStr) && i < 16 ; i ++, aStr ++ ) buf[i] = *aStr ;
	if ( aPtr != NULL ) *aPtr = aStr ;

	/* １６進文字列を数値に変換 */
	for ( j = 15, i -- ; j >= 0 && i >= 0 ; j --, i -- ) {
		c = isdigit(buf[i]) ? buf[i]&0x0f : (buf[i]&0x0f) + 0x09 ;
		id.bit[j/2] |= (j%2 ? c : c<<4) ;
	}

	/* サイト（ＩＤ）のビットフィールドの処理 */
	if ( aSiteID ) {
		if ( SITEID(id.value) == 0 ) id.value |= (aSiteID&0x0ffffll) << 48 ;
		else if ( SITEID(id.value) != aSiteID ) id.value = 0 ;
	}

	/* エグゼキュータ（ＩＤ）のビットフィールドの処理 */
	if ( aExecID ) {
		if ( EXECID(id.value) == 0 ) id.value |= (aExecID&0x0ffffffll) << 24 ;
		else if ( EXECID(id.value) != aExecID ) id.value = 0 ;
	}

	return( id.value ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	ダブルワード整数を文字列（１６進）に変換

【形式】
	const	char*	IDtoStr( long long aID, char *aStr ) ;

【引数】
	aStr	：１６進文字列を格納する領域へのポインタ
	aID	：ダブルワード整数

【機能】
	aID を１６進文字列に変換し、aStr が NULL でなれば、
	その変換結果を aStr が示す領域に格納する。
	aStr が NULL の場合は、その変換結果を内部バッファに
	格納する。

【戻り値】
	１６進文字列へのポインタ

【エラー】
	なし

【注意事項】
	変換結果を格納する領域の大きさは 17 バイト以上必要である。
	変換に使用される１６進文字セットは、0 〜 9, a 〜 f である。

【内部説明】
	この関数の実現のために、他の関数の呼出しを一切行わないこと。

-----------------------------------------------------------------------------*/
const	char*
IDtoStr( long long aID, char *aStr )
{
static	uchar	buf[17] ;
static	uchar	cset[] = "0123456789abcdef" ;
	Id	id = (Id)&aID ;
	int	i ;
	uchar	*cp ;
	uchar	c ;

	cp = ( aStr == NULL ) ? buf : (uchar *)aStr ;
	for ( i = 0 ; i < 16 ; i ++ ) {
		c = i%2 ? id->bit[i/2]&0x0f : id->bit[i/2]>>4 ;
		*cp ++ = cset[c] ;
	}
	*cp = '\0' ;
	return( ( aStr == NULL ) ? buf : (uchar *)aStr ) ;
}

/*-----------------------------------------------------------------------------
【関数】
	デバッガ汎用

【名前】
	ダブルワード整数を文字列（１０進）に変換

【形式】
	const	char*	Ltoa( long long aLong, char *aStr ) ;

【引数】
	aStr	：１Ｏ進文字列を格納する領域へのポインタ
	aLong	：ダブルワード整数

【機能】
	aLong を１０進文字列に変換し、aStr が NULL でなれば、
	その変換結果を aStr が示す領域に格納する。
	aStr が NULL の場合は、その変換結果を内部バッファに
	格納する。

【戻り値】
	１０進文字列へのポインタ

【エラー】
	なし

【注意事項】
	変換結果を格納する領域の大きさは 22 バイト以上必要である。

【内部説明】
	この関数の実現のために、他の関数の呼出しを一切行わないこと。

-----------------------------------------------------------------------------*/
const	char*
Ltoa( long long aLong, char *aStr )
{
static	uchar	buf[22] ;
	uchar	work[22] ;
	int	i ;
	uchar	*cp ;
	uchar	*dst ;

	dst = (aStr == NULL) ? buf : (uchar *)aStr ;
	if ( aLong < 0 ) {
		*dst ++ = '-' ;
		aLong *= -1 ;
	}

	cp = work ;
	do {
		*cp ++ = aLong % 10 + '0' ;
		aLong /= 10 ;
	} while( aLong ) ;

	while( cp -- != work ) *dst ++ = *cp ;
	*dst = '\0' ;

	return( (aStr == NULL) ? buf : (uchar *)aStr ) ;
}

#if	defined(TEST_STRTOID)||defined(TEST_IDTOSTR)||defined(TEST_LTOA)
int
main()
{
	long long	id ;
	char		*str ;

	str = "1234567890abcdef" ;
	id = StrToID( 0, 0, str, NULL ) ;
	fprintf( stderr, "StrToID(0,0,%s,NULL) = %08x%08x\n",
			str, (int)(id>>32), (int)(id&0x0ffffffffll) ) ;
	fprintf( stderr, "IDtoStr(%08x%08x,NULL) = %s\n",
			(int)(id>>32), (int)(id&0x0ffffffffll), IDtoStr(id,NULL) ) ;

	str = "0x1234567890ABCDEF" ;
	id = StrToID( 0, 0, str, NULL ) ;
	fprintf( stderr, "StrToID(0,0,%s,NULL) = %08x%08x\n",
			str, (int)(id>>32), (int)(id&0x0ffffffffll) ) ;
	fprintf( stderr, "IDtoStr(%08x%08x,NULL) = %s\n",
			(int)(id>>32), (int)(id&0x0ffffffffll), IDtoStr(id,NULL) ) ;

	str = "<<123456abcdef>>" ;
	id = StrToID( 0, 0, str, NULL ) ;
	fprintf( stderr, "StrToID(0,0,%s,NULL) = %08x%08x\n",
			str, (int)(id>>32), (int)(id&0x0ffffffffll) ) ;
	fprintf( stderr, "IDtoStr(%08x%08x,NULL) = %s\n",
			(int)(id>>32), (int)(id&0x0ffffffffll), IDtoStr(id,NULL) ) ;

	str = "0001000002000003" ;
	id = StrToID( 1, 2, str, NULL ) ;
	fprintf( stderr, "StrToID(1,2,%s,NULL) = %08x%08x\n",
			str, (int)(id>>32), (int)(id&0x0ffffffffll) ) ;
	fprintf( stderr, "IDtoStr(%08x%08x,NULL) = %s\n",
			(int)(id>>32), (int)(id&0x0ffffffffll), IDtoStr(id,NULL) ) ;

	str = "0001000002000003" ;
	id = StrToID( 0x17, 0x27, str, NULL ) ;
	fprintf( stderr, "StrToID(0x17,0x27,%s,NULL) = %08x%08x\n",
			str, (int)(id>>32), (int)(id&0x0ffffffffll) ) ;
	fprintf( stderr, "IDtoStr(%08x%08x,NULL) = %s\n",
			(int)(id>>32), (int)(id&0x0ffffffffll), IDtoStr(id,NULL) ) ;

	str = "0000000000000003" ;
	id = StrToID( 1, 2, str, NULL ) ;
	fprintf( stderr, "StrToID(1,2,%s,NULL) = %08x%08x\n",
			str, (int)(id>>32), (int)(id&0x0ffffffffll) ) ;
	fprintf( stderr, "IDtoStr(%08x%08x,NULL) = %s\n",
			(int)(id>>32), (int)(id&0x0ffffffffll), IDtoStr(id,NULL) ) ;

	fprintf( stderr, "Ltoa(1234567890123456) = %s\n", Ltoa(1234567890123456ll,NULL) ) ;
	fprintf( stderr, "Ltoa(-1234567890123456) = %s\n", Ltoa(-1234567890123456ll,NULL) ) ;
	fprintf( stderr, "Ltoa(9876543210) = %s\n", Ltoa(9876543210ll,NULL) ) ;
	fprintf( stderr, "Ltoa(-9876543210) = %s\n", Ltoa(-9876543210ll,NULL) ) ;

	return( 0 ) ;
}
#endif
