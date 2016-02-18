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

/* ��Τ���Υ����åȡ��͡���ʥݡ��ȡ����ɥ쥹���ѥХåե��ι�¤ */
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

/* �ǥХå�������ͥ�Υ����ӥ��ʥ����Сˡ��ݡ���(�̿��Ϥ����ꤹ��� */
extern	int	DmUnixServPort ;
extern	int	DmInetServPort ;

/* �ǥХå�������ͥ�ι�¤ */
typedef	struct DChanRec*	DChan ;
struct	DChanRec	{
	DChan		b_prev ;
	DChan		b_next ;
	OZ_MonitorRec	lock ;
	OZ_MonitorRec	sndrcv_lock ;
	int		port ;
} ;

/* �ǥХå�������ͥ���� */
static	struct	{
	OZ_MonitorRec	lock ;
	OZ_ConditionRec	cond ;
	DChan		wait ;
	DChan		work ;
	DChan		free ;
} DChanManage ;

static	int	InitFlag = 0 ;


/* �ǥХå�������ͥ��ѥ���γ��� */
static	DChan
DcGet( int aPort )
{
	DChan	dchan = NULL ;

	if ( DChanManage.free != NULL ) {
		/* �����ꥹ�Ȥ���μ��Ф� */
		dchan = DChanManage.free ;
		RemoveQueueBinary( dchan, DChanManage.free ) ;
	} else {
		/* ������̵���Τǿ����˺��� */
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

/* �����ӥ����ݡ��Ȥδƻ� */
static	void
DcService( int aDomain, int aServPort )
{
		DChan	dchan ;
		int	port ;

	if ( ! InitFlag ) {
		OzDebugf( "�ǥХå�������ͥ�Υ⥸�塼�뤬���������Ƥ��ʤ�\n" ) ;
		return ;
	}

	/* �����н����ʥᥤ�󡦥롼�ס� */
	LOOP {
		if ( OzListen( aServPort, 5 ) ) {
			OzDebugf( "�����ӥ����ݡ��Ȥ� listen ���Ǥ��ʤ�[%m]\n" ) ;
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
			OzDebugf( "�����ӥ����ݡ��Ȥ� accept ���Ǥ��ʤ�[%m]\n" ) ;
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
			/* ��³�׵�μ������쥭�塼�ؤΥ���å���Ͽ */
			InsertQueueBinary( dchan, DChanManage.wait ) ;
			OzExecSignalCondition( &DChanManage.cond ) ;
		} else {
			OzDebugf( "����ʾ奯�饤����Ȥ���³�ϤǤ��ʤ�\n" ) ;
			OzShutdown( port, 2 ) ;
			OzClose( port ) ;
		}
		OzExecExitMonitor( &DChanManage.lock ) ;
	}
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�ǥХå�������ͥ�ν����

�ڷ�����
	int	DcInit( int aN ) ;

�ڰ�����
	aN	��ͽ��������Ƥ����ǥХå�������ͥ�θĿ�

�ڵ�ǽ��
	�ǥХå�������ͥ�Υ⥸�塼��������������ꤵ�줿�Ŀ���
	�ǥХå�������ͥ��ѤΥ������ݤ��롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ����ʳ����ͤˤʤ롣

����ջ����
	�ǥХå�������ͥ�ϻ��ꤵ�줿�Ŀ��ʾ�ΥǥХå�������ͥ�κ���
	�׵᤬����ȡ������ʥ������ݤ��ǥХå�������ͥ��������롣
	��ü���ݤ��줿�ǥХå�������ͥ��ѤΥ���ϳ������줺������
	�ǥХå�������ͥ�κ������˺����Ѥ���롣

������������
-----------------------------------------------------------------------------*/
int
DcInit( int aN )
{
	int	ret = NG ;
	int	i ;
	DChan	dchan ;

/* ������ϣ��٤Τ� */
	if ( InitFlag ) goto error ;
	InitFlag = 1 ;

/* �ǡ����ΰ�ν���� */
	OzInitializeMonitor( &DChanManage.lock ) ;
	OzExecInitializeCondition( &DChanManage.cond, NO_ABORT ) ;
	InitQueueBinary( DChanManage.wait ) ;
	InitQueueBinary( DChanManage.work ) ;
	InitQueueBinary( DChanManage.free ) ;

/* �ǥХå�������ͥ�γ��� */
	OzExecEnterMonitor( &DChanManage.lock ) ;
	for ( i = 0 ; i < aN ; i ++ ) {
		dchan = DcGet( -1 ) ;
		if ( dchan != NULL ) InsertQueueBinary( dchan, DChanManage.free ) ;
	}
	OzExecExitMonitor( &DChanManage.lock ) ;

#if	defined(TEST)
	OzDcSetupPort() ;
#endif

/* UNIX �ɥᥤ��Υ����ӥ��γ��� */
	if ( DmUnixServPort > 0 )
		ThrFork( DcService, STACK_SIZE, PRIORITY, 2, UNIX, DmUnixServPort ) ;

/* INET �ɥᥤ��Υ����ӥ��γ��� */
	if ( DmInetServPort > 0 )
		ThrFork( DcService, STACK_SIZE, PRIORITY, 2, INET, DmInetServPort ) ;

	ret = OK ;
	
error:
	if ( ret != OK ) InitFlag = 0 ;
	return( ret ) ;
}



/*
 *	�ǥХå�������ͥ�ɡ��ƴؿ�
 *
 */

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�ǥХå�������ͥ�Υ��饤�����¦����

�ڷ�����
	DC	OzDcOpen( long long aID ) ;

�ڰ�����
	aID	����³���륨�������塼������ꤹ�롣
		�����������塼���ɣ���ʬ�Τߤ����Ȥ���롣

�ڵ�ǽ��
	���饤�����¦�ΥǥХå�������ͥ�������Ƥ롣

������͡�
	�ǥХå�������ͥ롣

�ڥ��顼��
	����ͤ� NULL �Ȥʤ롣

����ջ����

������������
-----------------------------------------------------------------------------*/
DC
OzDcOpen( long long aID )
{
		int	port ;
		DChan	dchan = NULL ;

	if ( ! InitFlag ) goto error ;

	port = OzConnectDebugManager( aID ) ;
	if ( port < 0 ) {
		/* �����Ф���³�Ǥ��ʤ� */
		goto error ;
	}

	/* �ǥХå�������ͥ�γ��� */
	OzExecEnterMonitor( &DChanManage.lock ) ;
	dchan = DcGet( port ) ;
	if ( dchan != NULL ) InsertQueueBinary( dchan, DChanManage.work ) ;
	OzExecExitMonitor( &DChanManage.lock ) ;

	if ( dchan == NULL ) {
		/* DChan�Ѥλ񸻤�­��ʤ� */
		OzShutdown( port, 2 ) ;
		OzClose( port ) ;
		goto error ;
	}

error:
	return( (DC)dchan ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�ǥХå�������ͥ�Υ�����¦����

�ڷ�����
	DC	OzDcAccept() ;

�ڰ�����

�ڵ�ǽ��
	������¦�ΥǥХå�������ͥ�������Ƥ롣

������͡�
	�ǥХå�������ͥ롣

�ڥ��顼��
	����ͤ� NULL �Ȥʤ롣

����ջ����

������������
-----------------------------------------------------------------------------*/
DC
OzDcAccept()
{
	DChan	dchan = NULL ;

	if ( ! InitFlag ) goto error ;

	OzExecEnterMonitor( &DChanManage.lock ) ;
	while ( DChanManage.wait == NULL ) OzExecWaitCondition( &DChanManage.lock, &DChanManage.cond ) ;
	/* ��³�׵�μ������쥭�塼����Υ���åȼ��Ф� */
	dchan = DChanManage.wait ;
	RemoveQueueBinary( dchan, DChanManage.wait ) ;
	InsertQueueBinary( dchan, DChanManage.work ) ;
	OzExecExitMonitor( &DChanManage.lock ) ;

error:
	return( (DC)dchan ) ;
}

/*-----------------------------------------------------------------------------
�ڴؿ���
	����

��̾����
	�ǥХå�������ͥ���ĺ�

�ڷ�����
	void	OzDcClose( DC aDC ) ;

�ڰ�����
	aDC	���ĺ�����ǥХå�������ͥ����ꤹ�롣

�ڵ�ǽ��
	�ǥХå�������ͥ���ĺ����롣

������͡�
	�ʤ���

�ڥ��顼��

����ջ����
	���å������Ǥ��äƤ⡢�ǥХå�������ͥ���ĺ����롣

������������
-----------------------------------------------------------------------------*/
void
OzDcClose( DC aDC )
{
	DChan	dchan = (DChan)aDC ;
	int	port ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL ) goto error ;

	/* ������Ǥ��äƤ�ե����뵭�һҥե�����ɤ�̵���ˤ��� */
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
�ڴؿ���
	����

��̾����
	�ǡ���������

�ڷ�����
	int	OzDcSend( DC aDC, void *aData, int aNbyte )

�ڰ�����
	aDC	��������ΥǥХå�������ͥ����ꤹ�롣
	aData	����������ǡ�������Ǽ����Ƥ����ΰ�ؤΥݥ��󥿤���ꤹ�롣
	aNbyte	����������ǡ����ΥХ��ȿ�����ꤹ�롣

�ڵ�ǽ��
	�ǡ������������롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ�����ʳ����ͤˤʤ롣
	

����ջ����
	�����ǡ����ΥХåե���󥰤ϹԤ��ʤ���
	���δؿ�����¾�����ԤäƤ��ʤ��Τǡ��ؿ� OzDcBegin() ��
	�ؿ� OzDcEnd() ���Ȥ߹�碌�ƻȤ����ȡ�
	�ǥХå����ޥ͡����㤫��ƤӽФ���뤳�Ȥ����ꤷ�Ƥ��롣

������������
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
�ڴؿ���
	����

��̾����
	�ǡ����μ���

�ڷ�����
	int	OzDcRecv( DC aDC, void *aData, int aNbyte )

�ڰ�����
	aDC	��������ΥǥХå�������ͥ����ꤹ�롣
	aData	����������ǡ������Ǽ�����ΰ�ؤΥݥ��󥿤���ꤹ�롣
	aNbyte	����������ǡ����ΥХ��ȿ�����ꤹ�롣

�ڵ�ǽ��
	�ǡ�����������롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ�����ʳ����ͤˤʤ롣
	

����ջ����
	���δؿ�����¾�����ԤäƤ��ʤ��Τǡ��ؿ� OzDcBegin() ��
	�ؿ� OzDcEnd() ���Ȥ߹�碌�ƻȤ����ȡ�
	�ǥХå����ޥ͡����㤫��ƤӽФ���뤳�Ȥ����ꤷ�Ƥ��롣

������������
-----------------------------------------------------------------------------*/
int
OzDcRecv( DC aDC, void *aData, int aNbyte )
{
	DChan	dchan = (DChan)aDC ;
	char	*ptr = aData ;
	int	ret = NG ;

	if ( ! InitFlag ) goto error ;
	if ( aDC == NULL || aData == NULL || aNbyte <= 0 ) goto error ;

	/* �ǡ����μ��� */
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
�ڴؿ���
	����

��̾����
	�ǥХå�������ͥ�Υ��å���󳫻�

�ڷ�����
	int	OzDcBegin( DC aDC ) ;

�ڰ�����
	aDC	�����å����򳫻Ϥ���ǥХå�������ͥ����ꤹ�롣

�ڵ�ǽ��
	�ǥХå�������ͥ�򥻥å�������¾�Υץ���ब���ѤǤ��ʤ��褦��
	���롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ�����ʳ����ͤˤʤ롣

����ջ����
	���å����λ���ˤ˴ؿ� OzEndDC() ��ƤӽФ����ȡ�

������������
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
�ڴؿ���
	����

��̾����
	�ǥХå�������ͥ�Υ��å����λ

�ڷ�����
	int	OzDcEnd( DC aDC ) ;

�ڰ�����
	aDC	�����å�����λ����ǥХå�������ͥ����ꤹ�롣

�ڵ�ǽ��
	�ǥХå�������ͥ��¾�Υץ���ब���å����˻��ѤǤ���褦�ˤ��롣

������͡�
	���ơ�����

�ڥ��顼��
	����ͤ�����ʳ����ͤˤʤ롣

����ջ����
	���å���󳫻Ϥϴؿ� OzBeginDC() ��ƤӽФ����ȡ�

������������
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

/* �Хåե��κ����ȥǡ����ΰ���礭�����ѹ� */
void*
OzDcSetBuff( OzDcBuff aBuff, int aSize )
{
	OzDcBuff	buff = (OzDcBuff)aBuff ;
	void		*addr = NULL ;
	void		*data ;

/* �Хåե�������¤�ΤȥХåե��ΰ�κ��� */
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

/* �Хåե��ΰ����� */
	} else {

		/* �Хåե�������¤�ΤȥХåե��ΰ�γ��� */
		if ( aSize ==  BUFF_FREE ) {
			if ( buff->data != NULL ) OzFree( (void *)buff->data ) ;
			OzFree( (void *)buff ) ;

		} else {
			/* �Хåե��ΰ�κ��� */
			if ( buff->size == 0 ) {
				data = (void *)OzMalloc( DATA_SIZE(aSize) ) ;
				if ( data == NULL ) goto error ;
				buff->size = aSize ;
				buff->data = data ;
				addr = buff->data->addr ;

			/* �Хåե��ΰ�γ�ĥ */
			} else if ( buff->size < aSize ) {
				data = (void *)OzRealloc( (void *)buff->data, DATA_SIZE(aSize) ) ;
				if ( data == NULL ) goto error ;
				buff->size = aSize ;
				buff->data = data ;
				addr = buff->data->addr ;

			/* �Хåե��ΰ�κ����� */
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

	/* �����ӥ������ɥ쥹�ʥݡ��ȡˤκ��� */
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

	/* ���饤����ȡ��ݡ��Ȥγ��� */
	port = OzSocket( servAddr.domain, SOCK_STREAM, servAddr.protocol ) ;
	if ( port < 0 ) {
		/* �����åȤ������Ǥ��ʤ� */
		goto error ;
	}

	if ( OzConnect( port, (struct sockaddr *)&servAddr.addr, servAddr.size ) ) {
		/* �����Ф���³�Ǥ��ʤ� */
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

/* UNIX �ɥᥤ��Υ����ӥ������ɥ쥹�ʥݡ��ȡˤκ��� */
	memset( &servAddr.addr, 0, sizeof(servAddr.addr) ) ;
	servAddr.addr.un.sun_family = AF_UNIX ;
	OzSprintf( servAddr.addr.un.sun_path, UNIX_PATHFMT,(int)EXECID(OzExecutorID) ) ;
	if ( access( servAddr.addr.un.sun_path, F_OK ) == OK ) unlink( servAddr.addr.un.sun_path ) ;
	servAddr.size = sizeof(servAddr.addr.un.sun_family) + strlen(servAddr.addr.un.sun_path) ;

/* UNIX �ɥᥤ��Υ����ӥ����ݡ��Ȥγ��� */
	DmUnixServPort = OzSocket( AF_UNIX, SOCK_STREAM, PSEUDO ) ;
	if ( DmUnixServPort < 0 ) {
		/* �����ӥ����ݡ��Ȥ����ߤǤ��ʤ� */
		goto error ;
	}
	ret = OzBind( DmUnixServPort, (struct sockaddr *)&servAddr.addr.un, servAddr.size ) ;
	if ( ret ) {
		/* �����ӥ����ݡ��Ȥ�̾���������Ƥ뤳�Ȥ��Ǥ��ʤ� */
		goto error ;
	}
	OzDebugf( "DC Service UNIX Path: %s\n", servAddr.addr.un.sun_path ) ;

/* INET �ɥᥤ��Υ����ӥ������ɥ쥹�ʥݡ��ȡˤκ��� */
	memset( &servAddr.addr, 0, sizeof(servAddr.addr) ) ;
	servAddr.addr.in.sin_family = AF_INET ;
	servAddr.addr.in.sin_addr.s_addr = INADDR_ANY ;
	servAddr.addr.in.sin_port = 0 ;
	servAddr.size = sizeof(servAddr.addr.in) ;

/* INET �ɥᥤ��Υ����ӥ����ݡ��Ȥγ��� */
	DmInetServPort = OzSocket( AF_INET, SOCK_STREAM, IPPROTO_TCP ) ;
	if ( DmInetServPort < 0 ) {
		/* �����ӥ����ݡ��Ȥ����ߤǤ��ʤ� */
		goto error ;
	}
	ret = OzBind( DmInetServPort, (struct sockaddr *)&servAddr.addr.in, servAddr.size ) ;
	if ( ret ) {
		/* �����ӥ����ݡ��Ȥ�̾���������Ƥ뤳�Ȥ��Ǥ��ʤ� */
		goto error ;
	}

	ret = getsockname( DmInetServPort, &servAddr.addr.in, &servAddr.size ) ;
	if ( ret ) {
		/* �����å�̾�γ����˼��Ԥ��� */
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

