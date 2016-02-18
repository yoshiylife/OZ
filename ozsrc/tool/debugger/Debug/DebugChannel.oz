/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Channel
//
//	Depend on executor's implementation.
//	Refer to debugChannel.[ch]
//
//	inherits:
//		Object
//
//	uses:
//		class	Object
//		class	ObjectManager
//		shared	DebugException
//		class	Lib:Lock
//
//	CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
inline "C" {
#include "../src/executor/debugChannel.h"
}
//
class	DebugChannel
{
constructor:
	New
;
public:
	Open,
	Close,
	Send,
	Recv,
	Call
;
protected:	/* Method */
	send,
	recv
;
protected:	/* Instance */
	DChan,
	OM,
	L_Send,
	L_Recv
;



//
//	Protected instance
//
Lock	L_Send ;		// Lock for Send
Lock	L_Recv ;		// Lock for Recv

// Executor debug channel handle (pointer)
unsigned int	DChan ;

// Check to Migrate
global ObjectManager	OM ;


//
//	Private instance
//
char	Name[] ;		// Class Name ( Read only )
int		H_Send[] ;		// Packet header for Send
int		H_Recv[] ;		// Packet header for Recv

//
//	Constructor method
//
void
New()
{
	Name = "DebugChannel" ;
	OM = Where() ;
	DChan = 0 ;
	L_Send => New() ;
	L_Recv => New() ;
	length H_Send  = 2 ;
	length H_Recv  = 2 ;
}

//
//	Public method
//
void
Open( global Object aObject ) : locked
{
	unsigned int	dc ;
		int			size ;

	/* Check to migrate */
	if ( OM != Where() ) raise DebugException::Migrated( OM ) ;
	if ( DChan ) raise DebugException::AlreadyInUse( DChan ) ;

	/* Open debug channel */
	inline "C" {
		dc = (unsigned int)OzDcOpen( aObject ) ;
	}
	debug( 0, "OzDcOpen(%O) = %#08x\n", aObject, dc ) ;
	if ( ! dc ) raise DebugException::NotFound( aObject ) ;

	/* Setup */
	DChan = dc ;
}

void
Close() : locked
{
	unsigned int	dc ;
		int			size ;
	dc = DChan ;

	/* Check to migrate */
	if ( OM != Where() ) raise DebugException::Migrated( OM ) ;
	if ( ! DChan ) raise DebugException::NotReady ;

	/* Close debug channel */
	inline "C" {
		OzDcClose( (DC)dc ) ;
	}
	debug( 0, "OzDcClose(%#08x)\n", dc ) ;

	/* Clear */
	DChan = 0 ;
}

void
Send( int aRequest, char aData[] )
{
	L_Send -> Lock() ;

	try {
		send( aRequest, aData ) ;
	} except {
		default {
			L_Send -> UnLock() ;
			raise ;
		}
	}

	L_Send -> UnLock() ;

	return ;
}

char
Recv()[]
{
	char	data[] ;

	L_Recv -> Lock() ;

	try {
		data = recv() ;
	} except {
		default {
			L_Recv -> UnLock() ;
			raise ;
		}
	}

	L_Recv -> UnLock() ;

	return( data ) ;
}

char
Call( int aRequest, char aData[] )[]
{
	char	data[] ;

	L_Send -> Lock() ;
	L_Recv -> Lock() ;

	try {
		send( aRequest, aData ) ;
	} except {
		default {
			L_Send -> UnLock() ;
			L_Recv -> UnLock() ;
			raise ;
		}
	}

	try {
		data = recv() ;
	} except {
		default {
			L_Send -> UnLock() ;
			L_Recv -> UnLock() ;
			raise ;
		}
	}

	L_Send -> UnLock() ;
	L_Recv -> UnLock() ;

	return( data ) ;
}

//
//	Private method
//
void
send( int aRequest, char aData[] )
{
	unsigned int	dc ;
		int			hsize ;
		int			dsize ;
		int			ret ;
		int			head[] ;
	head = H_Send ;
	dc = DChan ;

	/* Check object state */
	if ( OM != Where() ) raise DebugException::Migrated( OM ) ;
	if ( ! DChan ) raise DebugException::NotReady ;

	/* Send head to debug channel */
	hsize = 4 * length head ;
	head[0] = aRequest ;
	head[1] = dsize = (aData == 0) ? 0 : length aData ;
	inline "C" {
		ret = OzDcSend( (DC)dc, OZ_ArrayElement(head,int), hsize ) ;
	}
	debug( 0, "OzDcSend(%#08x,head[size:%d]) = %d\n", dc, hsize, ret ) ;
	if ( ret < 0 ) raise DebugException::IO( OM ) ;

	/* Send data to debug channel */
	if ( dsize ) {
		inline "C" {
			ret = OzDcSend( (DC)dc, OZ_ArrayElement(aData,char), dsize ) ;
		}
		debug( 0, "OzDcSend(%#08x,aData[size:%d]) = %d\n", dc, dsize, ret ) ;
		if ( ret < 0 ) raise DebugException::IO( OM ) ;
	}
}

char
recv()[]
{
	unsigned int	dc ;
		int			hsize ;
		int			dsize ;
		int			ret ;
		char		data[] ;
		int			head[] ;
	head = H_Recv ;
	dc = DChan ;

	/* Check to migrate */
	if ( OM != Where() ) raise DebugException::Migrated( OM ) ;
	if ( ! DChan ) raise DebugException::NotReady ;

	/* Recv head from debug channel */
	hsize = 4 * length head ;
	inline "C" {
		ret = OzDcRecv( (DC)dc, OZ_ArrayElement(head,int), hsize ) ;
	}
	debug( 0, "OzDcRecv(%#08x,head[size:%d]) = %d\n", dc, hsize, ret ) ;
	if ( ret < 0 ) raise DebugException::IO( OM ) ;
	debug( 0, "head[0] = %d, head[1] = %d\n", head[0], head[1] ) ;
	if ( head[0] < 0 ) raise DebugException::Error( head[0] ) ;

	/* Recv data from debug channel */
	dsize = head[1] ;
	length data = dsize ;
	if ( dsize ) {
		inline "C" {
			ret = OzDcRecv( (DC)dc, OZ_ArrayElement(data,char), dsize ) ;
		}
		debug( 0, "OzDcRecv(%#08x,aData[size:%d]) = %d\n", dc, dsize, ret ) ;
		if ( ret < 0 ) raise DebugException::IO( OM ) ;
	}
	return( data ) ;
}

}
// End of file: DebugChannel.oz
