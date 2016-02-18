/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* CAUTION */
/* �ø���ɸ��ʣ��Σӣɡ��ޤ��ϡ������ƥब�󶡤���˥إå�
 * �ΤߤΥ��󥯥롼�ɤ���Ĥ��롣���������ܥե�����̾��
 * Ʊ���١���̾����ĥե�����Τ������ĤΥ��󥯥롼�ɤ�
 * �ԤäƤ褤��
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
�ڴؿ���
	�ǥХå�����

��̾����
	�ɣ�ʸ����ʣ����ʡˤ���֥����������Ѵ�

�ڷ�����
	LONG	StrToID( int aSiteID, int aExecID, char *aStr, char **aPtr ) ;

�ڰ�����
	aSiteID	�������ȣɣ�
	aExecID	�����������塼���ɣ�
	aStr	��������ʸ����
	aPtr	������λ����ʸ���ؤΥݥ���

�ڵ�ǽ��
	������ʸ�������֥����������Ѵ����롣
	�����Ѵ��η�̡������ȣɣġ����������塼���ɣĤΥӥåȥե�����ɤ�
	����Ȥʤ���ϡ�aSiteID, aExecID ���ͤ�ƥե�����ɤ����ꤷ��
	����Ǥʤ����ϡ�aSiteID, aExecID �Ȱ��פ��뤫�򸡺����롣
	��������aSiteID, aExecID �����줾�쥼��Ǥ�����ϡ��ơ���
	�ӥåȥե�����ɤ��ͤ�����⸡���⤵��ʤ���
	aSiteID, aExecID ���ͤˤ�����餺��aPtr �� NULL �Ǥʤ����ϡ�
	*aPtr �˲���λ����ʸ���Υ��ɥ쥹�ͤ��������롣

������͡�
	���֥��������ʣɣġ�

�ڥ��顼��
	����ͤ������ͤˤʤ롣

����ջ����
	������ʸ���Ȥ���ǧ������Τϡ�0 �� 9, a �� f, A �� F �ΤߤǤ��롣
	�嵭��ʸ�����åȰʳ�����Ƭ��ʸ����ʣ���ˤ�̵�뤵��롣
	�嵭��ʸ�����åȰʳ���ʸ����������ޤǤ�ʸ������ᤵ��롣
	��ᤵ���ʸ�����Ĺ���ϣ���ʸ���ʲ��Ǥ��롣
	����������Ƭ�� 0x �ޤ��� 0X ������줿��硢����ľ�夫��ʸ���β�᤬
	�Ԥ��롣�Ĥޤꡢ����ľ��˾嵭ʸ�����åȰʳ���ʸ��������������
	�ϣ��Ȥʤ롣
	�ӣУ��ңå������ƥ��������ѤǤ��롣

������������
	���δؿ��μ¸��Τ���ˡ�¾�δؿ��θƽФ�����ڹԤ�ʤ����ȡ�

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

	/* ʸ�����åȰʳ���ʸ���Υ����å� */
	if ( aStr[0] == '0' && (aStr[1] == 'x' || aStr[1] == 'X') ) aStr += 2 ;
	else while( *aStr != '\0' && ! isxdigit(*aStr) ) aStr ++ ;
	if ( aPtr != NULL ) *aPtr = aStr ;

	/* ������ʸ������ڤ�Ф� */
	for ( i = 0 ; *aStr && isxdigit(*aStr) && i < 16 ; i ++, aStr ++ ) buf[i] = *aStr ;
	if ( aPtr != NULL ) *aPtr = aStr ;

	/* ������ʸ�������ͤ��Ѵ� */
	for ( j = 15, i -- ; j >= 0 && i >= 0 ; j --, i -- ) {
		c = isdigit(buf[i]) ? buf[i]&0x0f : (buf[i]&0x0f) + 0x09 ;
		id.bit[j/2] |= (j%2 ? c : c<<4) ;
	}

	/* �����ȡʣɣġˤΥӥåȥե�����ɤν��� */
	if ( aSiteID ) {
		if ( SITEID(id.value) == 0 ) id.value |= (aSiteID&0x0ffffll) << 48 ;
		else if ( SITEID(id.value) != aSiteID ) id.value = 0 ;
	}

	/* ���������塼���ʣɣġˤΥӥåȥե�����ɤν��� */
	if ( aExecID ) {
		if ( EXECID(id.value) == 0 ) id.value |= (aExecID&0x0ffffffll) << 24 ;
		else if ( EXECID(id.value) != aExecID ) id.value = 0 ;
	}

	return( id.value ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	�ǥХå�����

��̾����
	���֥���������ʸ����ʣ����ʡˤ��Ѵ�

�ڷ�����
	const	char*	IDtoStr( long long aID, char *aStr ) ;

�ڰ�����
	aStr	��������ʸ������Ǽ�����ΰ�ؤΥݥ���
	aID	�����֥�������

�ڵ�ǽ��
	aID �򣱣���ʸ������Ѵ�����aStr �� NULL �Ǥʤ�С�
	�����Ѵ���̤� aStr �������ΰ�˳�Ǽ���롣
	aStr �� NULL �ξ��ϡ������Ѵ���̤������Хåե���
	��Ǽ���롣

������͡�
	������ʸ����ؤΥݥ���

�ڥ��顼��
	�ʤ�

����ջ����
	�Ѵ���̤��Ǽ�����ΰ���礭���� 17 �Х��Ȱʾ�ɬ�פǤ��롣
	�Ѵ��˻��Ѥ���룱����ʸ�����åȤϡ�0 �� 9, a �� f �Ǥ��롣

������������
	���δؿ��μ¸��Τ���ˡ�¾�δؿ��θƽФ�����ڹԤ�ʤ����ȡ�

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
�ڴؿ���
	�ǥХå�����

��̾����
	���֥���������ʸ����ʣ����ʡˤ��Ѵ�

�ڷ�����
	const	char*	Ltoa( long long aLong, char *aStr ) ;

�ڰ�����
	aStr	�����Ͽ�ʸ������Ǽ�����ΰ�ؤΥݥ���
	aLong	�����֥�������

�ڵ�ǽ��
	aLong �򣱣���ʸ������Ѵ�����aStr �� NULL �Ǥʤ�С�
	�����Ѵ���̤� aStr �������ΰ�˳�Ǽ���롣
	aStr �� NULL �ξ��ϡ������Ѵ���̤������Хåե���
	��Ǽ���롣

������͡�
	������ʸ����ؤΥݥ���

�ڥ��顼��
	�ʤ�

����ջ����
	�Ѵ���̤��Ǽ�����ΰ���礭���� 22 �Х��Ȱʾ�ɬ�פǤ��롣

������������
	���δؿ��μ¸��Τ���ˡ�¾�δؿ��θƽФ�����ڹԤ�ʤ����ȡ�

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
