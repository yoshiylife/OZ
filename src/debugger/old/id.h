/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_DEBUGGER_ID_H)
#define	_OZ_DEBUGGER_ID_H
/* CAUTION */
/* Ｃ言語標準（ＡＮＳＩ、または、システムが提供する）ヘッダ
 * のみのインクルードを許可する。
 */

#define	EXECID(eXeCiD)	((int)((eXeCiD>>24)&0x0ffffffll))
#define	SITEID(sItEiD)	((int)((sItEiD>>48)&0x0ffffll))
#define	LONG	long long

extern	LONG
StrToID( int aSiteID, int aExecID, char *aStr, char **aPtr ) ;

extern	const	char*
IDtoStr( long long aID, char *aStr ) ;

extern	const	char*
Ltoa( long long aLong, char *aStr ) ;

#endif	_OZ_DEBUGGER_ID_H
