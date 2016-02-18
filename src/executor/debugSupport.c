/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	OZ++ language level debug I/F module
 */
/* unix system include */
#include <sys/types.h>
#include <stropts.h>
#include <ctype.h>
/* multithread system include */
#include "thread/print.h"
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "channel.h"
#include "debugChannel.h"
#include "debugFunction.h"
#include "debugSupport.h"
#include "executor/alloc.h"
#include "oz++/debug.h"

#if	!defined(SVR4)
extern	int	tolower( int ) ;
extern	int	toupper( int ) ;
#endif	/* SVR4 */

#define	MSGSIZE	1024
#define	MSGHEAD	"%3s %3s %2d %02d:%02d:%02d %4d %c %016lx %016lx %016lx "

static	char	*Days[] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" } ;
static	char	*Months[] = { "Jan", "Feb", "Mar", "Apr", "May", "Jun",
				"Jul", "Aug", "Sep", "Oct", "Nov", "Dec" } ;

typedef	struct	ExceptionNameStr*	ExceptionName ;
static	struct	ExceptionNameStr {
	int	no ;
	char	*name ;
} ExceptionNameTable[] = {
	{ -2, "DoubleFault"		},
	{ -1, "Any"			},
	{  1, "Abort"			},
	{  2, "ChildAborted"		},
	{  3, "ObjectNotFound"		},
	{  4, "ClassNotFound"		},
	{  5, "CodeNotFound"		},
	{  6, "LayoutNotFound"		},
	{  7, "GlobalInvokeFailed"	},
	{  8, "NoMemory"		},
	{  9, "ForkFailed"		},
	{ 10, "KillSelf"		},
	{ 11, "ChildDoubleFault"	},
	{ 12, "IllegalInvoke"		},
	{ 13, "NarrowFailed"		},
	{ 14, "ArrayRangeOverflow"	},
	{  0, NULL }
} ;


typedef union	{
	struct	{
		unsigned	head    : 1 ;
		unsigned	reserve : 4 ;
		unsigned	except  : 1 ;
		unsigned	trace   : 1 ;
		unsigned	debug   : 1 ;

		unsigned	exceptFork : 1 ;
		unsigned	exceptCStop: 1 ;	/* Stop on Catch */
		unsigned	exceptLStop: 1 ;	/* Stop on ReRaise */
		unsigned	exceptFStop: 1 ;	/* Stop on D-Fault */
		unsigned	exceptUndef: 1 ;	/* Not caught, & Stop */
		unsigned	exceptCatch: 1 ;	/* Catch */
		unsigned	exceptLeave: 1 ;	/* ReRaise */
		unsigned	exceptFault: 1 ;	/* Double Fault */

		unsigned	traceFork  : 1 ;	/* Propagate at fork */
		unsigned	traceOnce  : 1 ;	/* Propagate at once */
		unsigned	trace_     : 1 ;
		unsigned	traceAC    : 5 ;

		unsigned	debugFork  : 1 ;	/* Propagate at fork */
		unsigned	debugOnce  : 1 ;	/* Propagate at once */
		unsigned	debugMsg   : 1 ;
		unsigned	debugAC    : 5 ;
	} f ;
	struct	{
		unsigned char	head ;
		unsigned char	except ;
		unsigned char	trace ;
		unsigned char	debug ;
	} v ;
	unsigned int	value ;
} DsDebugFlags ;

typedef	struct	{
	size_t		size ;
	OzDcData	data ;
} MsgBufRec, *MsgBuf ;

static	struct	{
	OZ_MonitorRec	lock ;
	OID		oid ;
	DC		dc ;
} dChannel ;

typedef	struct	{
	OZ_MonitorRec	lock ;
	int		file ;
} CapMsgRec, *CapMsg ;

static	CapMsgRec	cMsg ;
static	CapMsgRec	cExp ;

static	size_t
dsPrnExtend(
	char		*aBuffer,		/* output buffer */
	int		aWidth, int aPrec,	/* format infomation */
	PrnFlags	aFlags,			/* additional infomation */
	va_list		*aList			/* input buffer */
)
{
	OZ_Object	obj ;
	OID		id ;
	size_t		len ;
	OzRecvChannel	recv ;
	int		i ;
	u_int		u ;

	switch( aFlags.f.type ) {
	case 'S':
		obj = va_arg( (*aList), OZ_Object ) ;
		if ( obj ) {
			len = obj->head.h ;
			obj ++ ;
			if ( OzMemchr( obj, '\0', len ) == NULL ) aPrec = len ;
		}
		len = PrnString( aBuffer, aWidth, aPrec, (char *)obj ) ;
		break ;
	case 'P':
		id = (OID)va_arg( (*aList), u_int ) ;
		if ( id == 0 && ThrRunningThread->channel != NULL ) {
			recv = (OzRecvChannel)ThrRunningThread->channel ;
			id = recv->pid ;
		} else id |= OzExecutorID ;
		aFlags.f.sign = 0 ;
		aFlags.f.lower = 1 ;
		aFlags.v.size = 8 ;
		aFlags.v.base = 16 ;
		aFlags.v.pad = '0' ;
		len = PrnInteger( aBuffer, aWidth, 16, aFlags.value, id ) ;
		break ;
	case 'O':
		id = (OID)va_arg( (*aList), OID ) ;
		aFlags.f.sign = 0 ;
		aFlags.f.lower = 1 ;
		aFlags.v.size = 8 ;
		aFlags.v.base = 16 ;
		aFlags.v.pad = '0' ;
		len = PrnInteger( aBuffer, aWidth, 16, aFlags.value, id ) ;
		break ;
	case 'V':
		obj = va_arg( (*aList), OZ_Object ) ;
		if ( obj ) id = obj->head.a ;
		else id = 0 ;
		aFlags.f.sign = 0 ;
		aFlags.f.lower = 1 ;
		aFlags.v.size = 8 ;
		aFlags.v.base = 16 ;
		aFlags.v.pad = '0' ;
		len = PrnInteger( aBuffer, aWidth, 16, aFlags.value, id ) ;
		break ;
	case 'C':
		obj = va_arg( (*aList), OZ_Object ) ;
		if ( obj && obj->head.h == -2 ) {
			OZ_ObjectAll	top ;
			top = OzExecGetObjectTop( obj ) ;
			id = top->head->a ;
		} else id = 0 ;
		aFlags.f.sign = 0 ;
		aFlags.f.lower = 1 ;
		aFlags.v.size = 8 ;
		aFlags.v.base = 16 ;
		aFlags.v.pad = '0' ;
		len = PrnInteger( aBuffer, aWidth, 16, aFlags.value, id ) ;
		break ;
	case 'T':
		obj = va_arg( (*aList), OZ_Object ) ;
		if ( obj ) u = obj->head.e ;
		else u = 0 ;
		aFlags.f.sign = 0 ;
		aFlags.v.size = 4 ;
		aFlags.v.base = 10 ;
		len = PrnInteger( aBuffer, aWidth, aPrec, aFlags, u ) ;
		break ;
	case 'A':
		obj = va_arg( (*aList), OZ_Object ) ;
		if ( obj && obj->head.h == -2 ) {
			OZ_ObjectAll	top ;
			top = OzExecGetObjectTop( obj ) ;
			i = top->head->h ;
		} else i = 0 ;
		aFlags.f.sign = 1 ;
		aFlags.v.size = 4 ;
		aFlags.v.base = 10 ;
		len = PrnInteger( aBuffer, aWidth, aPrec, aFlags, i ) ;
		break ;
	default :
		len = 0 ;
	}
	return( len ) ;
}

char*
DsExceptionName( int aValue )
{
	ExceptionName	exception = ExceptionNameTable ;
	char		*name = NULL ;
	while ( exception->name ) {
		if ( exception->no == aValue ) {
			name = exception->name ;
			break ;
		}
		exception ++ ;
	}
	return( name ) ;
}

static	int
outputMsgBuf( void *aKey, const char *aData, size_t aSize )
{
	MsgBuf	mbuf = (MsgBuf)aKey ;
	char	*ptr = mbuf->data->addr ;

	if ( mbuf->data->head.size + aSize > mbuf->size ) {
		mbuf->size += MSGSIZE ;
		ptr = OzRealloc( ptr, sizeof(OzDcHeadRec) + mbuf->size ) ;
		if ( ptr == NULL ) {
			OzError( "outputMsgBuf: OzRealloc error[%m]\n" ) ;
			return( -1 ) ;
		}
		mbuf->data = (OzDcData)ptr ;
	}

	ptr += mbuf->data->head.size ;
	if ( aSize < 16 ) {
		size_t	s = aSize ;
		while ( s -- ) *(ptr ++) = *aData ++ ;
	} else OzMemcpy( ptr, aData, aSize ) ;
	mbuf->data->head.size += aSize ;

	return( (int)aSize ) ;
}

static	int
printMsgBuf( MsgBuf aMsgBuf, const char *aFormat, ... )
{
	va_list	args ;
	int	ret ;

	va_start( args, aFormat ) ;
	ret = PrnFormat( outputMsgBuf, (void *)aMsgBuf, aFormat, args ) ;
	va_end( args ) ;

	return( ret ) ;
}


static	int
sendMsgBuf( int aRequest, OID aTarget, MsgBuf mbuf )
{
	OzDcHeadRec	head ;
	int		s = -1 ;

	OzExecEnterMonitor( &dChannel.lock ) ;
	if ( aTarget != dChannel.oid ) {
		if ( dChannel.dc ) OzDcClose( dChannel.dc ) ;
		dChannel.dc = OzDcOpen( aTarget ) ;
		if ( dChannel.dc == NULL ) dChannel.oid = 0LL ;
		else dChannel.oid = aTarget ;
	}
	if ( dChannel.dc ) {
		mbuf->data->head.type.request = aRequest ;
		s = sizeof(OzDcHeadRec) + mbuf->data->head.size ;
		s = OzDcSend( dChannel.dc, mbuf->data, s ) ;
		if ( s == 0 ) {
		    s = OzDcRecv( dChannel.dc, &head, sizeof(head) ) ;
		} else {
		    OzDcClose( dChannel.dc ) ;
		    dChannel.oid = 0LL ;
		    dChannel.dc = NULL ;
		}
	} ;
	OzExecExitMonitor( &dChannel.lock ) ;

	return( s ) ;
}

int
OzExecDebugCheck( OZ_Object this, long long vid, int part, void *info )
{
	DsDebugFlags	dflags ;

	dflags.value = OzDebugFlags ;
	if ( dflags.f.head && dflags.f.debug ) {
		if ( dflags.v.debug & part ) {
			if ( dflags.f.debugMsg ) return( -1 ) ;
			else return( 1 ) ;
		}
	}

	dflags.value = this->head.g ;
	if ( dflags.f.head && dflags.f.debug ) {
		if ( dflags.v.debug & part ) {
			if ( dflags.f.debugMsg ) return( -1 ) ;
			else return( 1 ) ;
		}
	}

	return( 0 ) ;
}

int
OzExecDebugMessage( OID aTarget, char *aFormat, ... )
{
	OzRecvChannel	recv ;
	va_list		args ;
	MsgBufRec	mbuf ;
	int		ret ;
	OID		oid ;
	OID		pid ;
	char		cf ;
	struct tm	tm ;

	mbuf.size = MSGSIZE ;
	mbuf.data = (OzDcData)OzMalloc( sizeof(OzDcHeadRec) + mbuf.size ) ;
	if ( mbuf.data == NULL ) {
		/* error */
		ret = -1 ;
		goto error ;
	}
	mbuf.data->head.size = 0 ;

	recv = (OzRecvChannel)ThrRunningThread->channel ;
	if ( recv ) {
		pid = recv->pid ;
		oid = recv->callee ;
	} else {
		pid = 0LL ;
		oid = 0LL ;
	}

	if ( aTarget == 0LL ) {
		if ( pid == 0LL ) {
			aTarget = OzExecutorID ;
			cf = 'D' ;			/* to debugger */
		} else {
			aTarget = pid ;
			cf = 'P' ;			/* to process */
		}
	} else if ( aTarget == OzExecutorID ) {
		cf = 'D' ;			/* to debugger */
	} else {
		cf = 'O' ;				/* to object */
	}

	OzDate( NULL, &tm ) ;
	printMsgBuf( &mbuf, MSGHEAD,
			Days[tm.tm_wday], Months[tm.tm_mon], tm.tm_mday,
			tm.tm_hour, tm.tm_min, tm.tm_sec, tm.tm_year+1900,
			cf, aTarget, pid, oid ) ;

	va_start( args, aFormat ) ;
	ret = PrnFormat( outputMsgBuf, (void *)&mbuf, aFormat, args ) ;
	va_end( args ) ;
	if ( ret < 0 ) goto error ;

	sendMsgBuf( DM_DBGMSG, aTarget, &mbuf ) ;

error:
	if ( mbuf.data ) OzFree( mbuf.data ) ;

	return( ret ) ;
}

u_int
DsMaskProcess( u_int aDebugFlags, OZ_Object aSelf )
{
	DsDebugFlags	pdflags ;
	DsDebugFlags	odflags ;

	pdflags.value = aDebugFlags ;
	if ( pdflags.f.head ) {
		if ( pdflags.f.except ) {
			if ( ! pdflags.f.exceptFork ) pdflags.v.except = 0 ;
		}
		if ( pdflags.f.trace ) {
			if ( pdflags.f.traceOnce ) pdflags.f.traceOnce = 0 ;
			else if ( ! pdflags.f.traceFork ) pdflags.v.trace = 0 ;
		}
		if ( pdflags.f.debug ) {
			if ( pdflags.f.debugOnce ) pdflags.f.debugOnce = 0 ;
			else if ( ! pdflags.f.debugFork ) pdflags.v.debug = 0 ;
		}
	}
	if ( aSelf == 0 ) return( pdflags.value ) ;

	odflags.value = aSelf->head.g ;
	if ( odflags.f.head ) {
		if ( odflags.f.except ) {
			if ( odflags.f.exceptFork ) {
				pdflags.v.except = odflags.v.except ;
				pdflags.f.exceptFork = 0 ;
			}
		}
		if ( odflags.f.trace ) {
			if ( odflags.f.traceFork ) {
				pdflags.v.trace = odflags.v.trace ;
				pdflags.f.traceFork = 0 ;
			}
		}
		if ( odflags.f.debug ) {
			if ( odflags.f.debugFork ) {
				pdflags.v.debug = odflags.v.debug ;
				pdflags.f.debugFork = 0 ;
			}
		}
	}

	return( pdflags.value ) ;
}

int
DsCheckException( int type )
{
	int		ret = 1 ;
#if	0	/* Not yet implement */
	DsDebugFlags	dflags ;

	if ( OzDebugging ) return( ret ) ;

	dflags.value = OzDebugFlags ;
	
	if ( ! dflags.f.head ) return( 0 ) ;
	if ( ! dflags.f.except ) return( 0 ) ;
	
	switch ( type ) {
	case	'N':	/* Not caught */
		if ( dflags.f.exceptUndef ) ret = 1 ;
		break ;
	case	'C':	/* Caught */
		if ( dflags.f.exceptCatch ) ret = 1 ;
		break ;
	case	'R':	/* ReRaise */
		if ( dflags.f.exceptLeave ) ret = 1 ;
		break ;
	case	 'F':	/* Double Fault */
		if ( dflags.f.exceptFault ) ret = 1 ;
		break ;
	default:
		ret = 0 ;
	}
#endif

	return( ret ) ;
}

/*
 * Argumensts:
 *	type	=  N : Not caught
 *		=  C : Caught
 *		=  R : Reraise
 *		=  F : Double Fault
 *
 * Return values:
 *	== 0 : Capture exception infomation
 *	!= 0 : Suspend and wait to continnue from debugger
 */
static	int
checkStop( type )
{
	int		ret = 0 ;
#if	0	/* Not yet implement */
	DsDebugFlags	dflags ;

	dflags.value = OzDebugFlags ;
	
	switch ( type ) {
	case	'N':	/* Not caught */
		if ( dflags.f.exceptUndef ) ret = 1 ;
		break ;
	case	'C':	/* Caught */
		if ( dflags.f.exceptCatch ) ret = dflags.f.exceptCStop ? 1 : 0 ;
		else ret = 0 ;
		break ;
	case	'R':	/* ReRaise */
		if ( dflags.f.exceptLeave ) ret = dflags.f.exceptLStop ? 1 : 0 ;
		else ret = 0 ;
		break ;
	case	'F':	/* Double Fault */
		if ( dflags.f.exceptFault ) ret = dflags.f.exceptFStop ? 1 : 0 ;
		else ret = 0 ;
		break ;
	default:
		ret = 0 ;
	}
#endif

	return( ret ) ;
}

void
DsTrapException( int type, OZ_ExceptionID eid, long long param, char fmt )
{
	OzRecvChannel	recv ;
	MsgBufRec	mbuf ;
	int		ret ;
	OID		oid ;
	OID		pid ;
	OID		target ;
	int		stop ;
	struct	tm	tm ;
	char		*ename ;

	stop = checkStop( type ) ;

	mbuf.size = MSGSIZE ;
	mbuf.data = (OzDcData)OzMalloc( sizeof(OzDcHeadRec) + mbuf.size ) ;
	if ( mbuf.data == NULL ) {
		/* error */
		ret = -1 ;
		goto error ;
	}
	mbuf.data->head.size = 0 ;

	recv = (OzRecvChannel)ThrRunningThread->channel ;
	if ( recv ) {
		pid = recv->pid ;
		oid = recv->callee ;
		target = pid ;
	} else {
		pid = OzExecutorID ; ;
		oid = 0LL ;
		target = pid ;
	}

	OzDate( NULL, &tm ) ;
	printMsgBuf( &mbuf, MSGHEAD,
		Days[tm.tm_wday], Months[tm.tm_mon], tm.tm_mday,
		tm.tm_hour, tm.tm_min, tm.tm_sec, tm.tm_year+1900,
		stop ? tolower(type) : toupper(type), target, pid, oid ) ;

 	printMsgBuf( &mbuf, "%016lx:%08x %016lx:%c ",
		eid->cid, eid->val, param, (fmt==0) ? 'v' : fmt ) ;
	if ( eid->cid == 0 && (ename=DsExceptionName( eid->val )) != NULL ) {
		printMsgBuf( &mbuf, ename ) ;
	} else printMsgBuf( &mbuf, "User" ) ;
	switch( type ) {
	case	'N':
		printMsgBuf( &mbuf, " Exception not caught\n" ) ; break ;
	case	'C':
		printMsgBuf( &mbuf, " Exception caught\n" ) ; break ;
	case	'R':
		printMsgBuf( &mbuf, " Exception reraise\n" ) ; break ;
	case	'F':
		printMsgBuf( &mbuf, " Exception double fault\n" ) ; break ;
	default	:
		printMsgBuf( &mbuf, " Exception system error\n" ) ;
	}

	sendMsgBuf( DM_DBGMSG, pid, &mbuf ) ;
	sendMsgBuf( DM_NOTIFY, pid, &mbuf ) ;

error:
	if ( mbuf.data ) OzFree( mbuf.data ) ;
	if ( stop ) {
		ThrSuspend( NULL /* RunningThread */ ) ;
	}
}

static	int
capture( CapMsg cap , const char *aData, int aSize )
{
	int	ret ;
	char	buf[32] ;

	MsgBufRec	mbuf ;

	mbuf.size = MSGSIZE ;
	mbuf.data = (OzDcData)OzMalloc(sizeof(OzDcHeadRec)+mbuf.size) ;
	if ( mbuf.data == NULL ) {
		/* error */
		ret = -1 ;
		goto error ;
	}
	mbuf.data->head.size = 0 ;
	printMsgBuf( &mbuf, "%.*s", aSize, aData ) ;
	OzSprintf( buf, "%d\n", mbuf.data->head.size ) ;
	ret = OzWrite( cap->file, buf, strlen(buf) ) ;
	if ( ret <= 0 ) {
		OzClose( cap->file ) ;
		cap->file = -1 ;
		goto error ;
	}
	ret = OzWrite( cap->file, mbuf.data->addr, mbuf.data->head.size ) ;
	if ( ret <= 0 ) {
		OzClose( cap->file ) ;
		cap->file = -1 ;
	} else {
		ret = OzRead( cap->file,mbuf.data->addr,mbuf.data->head.size ) ;
		if ( ret <= 0 ) {
			OzClose( cap->file ) ;
			cap->file = -1 ;
		} else ret = 0 ;
	} ;

error:
	if ( mbuf.data ) OzFree( mbuf.data ) ;

	return( ret ) ;
}

int
DsCaptureDebugMessage( const char *aData, int aSize )
{
	int	ret ;
	OzExecEnterMonitor( &cMsg.lock ) ;
	if ( cMsg.file >= 0 ) {
		ret = capture( &cMsg, aData, aSize ) ;
	} else {
		/* OzPrintf( "0x%08x %.64s\n", OzTime(NULL), aData ) ; */
		ThrPrintf( "%.*s", aSize-78, aData+78 ) ;
		ret = 0 ;
	}
	OzExecExitMonitor( &cMsg.lock ) ;
	return( ret ) ;
}

int
OzSetCaptureMessage( int fd )
{
	int	ret ;
	OzExecEnterMonitor( &cMsg.lock ) ;
	if ( 0 <= cMsg.file && 0 <= fd ) ret = -1 ;
	else ret = cMsg.file = fd ;
	OzExecExitMonitor( &cMsg.lock ) ;
	return( ret ) ;
}

int
DsCaptureException( const char *aData, int aSize )
{
	int	ret ;
	OzExecEnterMonitor( &cExp.lock ) ;
	if ( cExp.file >= 0 ) {
		ret = capture( &cExp, aData, aSize ) ;
	} else ret = 0 ;
	OzExecExitMonitor( &cExp.lock ) ;
	return( ret ) ;
}

int
OzSetCaptureException( int fd )
{
	int	ret ;
	OzExecEnterMonitor( &cExp.lock ) ;
	if ( 0 <= cExp.file && 0 <= fd ) ret = -1 ;
	else ret = cExp.file = fd ;
	OzExecExitMonitor( &cExp.lock ) ;
	return( ret ) ;
}

int
DsInit( int dummy )
{
	OzInitializeMonitor( &dChannel.lock ) ;
	dChannel.oid = 0LL ;
	dChannel.dc = NULL ;
	OzInitializeMonitor( &cMsg.lock ) ;
	cMsg.file = -1 ;
	OzInitializeMonitor( &cExp.lock ) ;
	cExp.file = -1 ;
	PrnExtend = dsPrnExtend ;
	return( 0 ) ;
}

OID
OzGetConfiguredClassIDof( OZ_Object aObj )
{
	OID	id ;
	if ( aObj && aObj->head.h == -2 ) {
		OZ_ObjectAll	top ;
		top = OzExecGetObjectTop( aObj ) ;
		id = top->head->a ;
	} else id = 0 ;
	return( id ) ;
}

OZ_Array
OzFormat( const char *aFormat, ... )
{
	OZ_Array	ret ;
	va_list		args ;
	MsgBufRec	mbuf ;

	mbuf.size = MSGSIZE ;
	mbuf.data = (OzDcData)OzMalloc( sizeof(OzDcHeadRec) + mbuf.size ) ;
	if ( mbuf.data == NULL ) {
		/* error */
		ret = 0 ;
		goto error ;
	}
	mbuf.data->head.size = 0 ;

	va_start( args, aFormat ) ;
	PrnFormat( outputMsgBuf, (void *)&mbuf, aFormat, args ) ;
	va_end( args ) ;

	outputMsgBuf( &mbuf, "", 1 ) ;
	ret = OzExecReAllocateArray( OZ_CHAR, 1, mbuf.data->head.size, 0 ) ;
	OzMemcpy( ret->mem, mbuf.data->addr, mbuf.data->head.size ) ;
	OzFree( mbuf.data ) ;

error:
	return( ret ) ;
}
