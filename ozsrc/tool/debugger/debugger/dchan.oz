/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Channel for OZ++ World.
//
//	CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
inline "C" {
#include "../src/executor/debugChannel.h"
}
class	DebugChannel
{
constructor:
	New
;
public:
	Open,
	Close,
	Send,
	Recv
;
protected:
	/* instance */
	DChan,
	OM
;

	unsigned int			DChan ;
	global ObjectManager	OM ;

void
New()
{
	OM = Where() ;
	DChan = 0 ;
}

void
Open( global Object aObject ) : locked
{
	unsigned int	dc ;
		int			size ;

	/* Check object state */
	if ( OM != Where() ) raise DebugChannelException::Migrated( OM ) ;
	if ( DChan ) raise DebugChannelException::AlreadyInUse( DChan ) ;

	/* Open debug channel */
	inline "C" {
		dc = (unsigned int)OzDcOpen( aObject ) ;
	}
	debug( 0, "OzDcOpen(%O) = %#08x\n", aObject, dc ) ;
	if ( ! dc ) raise DebugChannelException::NotFound( aObject ) ;

	/* Setup */
	DChan = dc ;
}

void
Close() : locked
{
	unsigned int	dc ;
		int			size ;
	dc = DChan ;

	/* Check object state */
	if ( OM != Where() ) raise DebugChannelException::Migrated( OM ) ;
	if ( ! DChan ) raise DebugChannelException::NotReady ;

	/* Close debug channel */
	inline "C" {
		OzDcClose( (DC)dc ) ;
	}
	debug( 0, "OzDcClose(%#08x)\n", dc ) ;

	/* Clear */
	DChan = 0 ;
}

void
Send( int aHead[], char aData[] ) : locked
{
	unsigned int	dc ;
		int			size ;
		int			ret ;
	dc = DChan ;

	/* Check object state */
	if ( OM != Where() ) raise DebugChannelException::Migrated( OM ) ;
	if ( ! DChan ) raise DebugChannelException::NotReady ;

	/* Send head to debug channel */
	size = (aHead == 0) ? 0 : length aHead ;
	size *= 4 ;
	if ( size ) {
		inline "C" {
			ret = OzDcSend( (DC)dc, OZ_ArrayElement(aHead,int), size ) ;
		}
		debug( 0, "OzDcSend(%#08x,aHead[size:%d]) = %d\n", dc, size, ret ) ;
		if ( ret < 0 ) raise DebugChannelException::IO( OM ) ;
	}

	/* Send data to debug channel */
	size = (aData == 0) ? 0 : length aData ;
	if ( size ) {
		inline "C" {
			ret = OzDcSend( (DC)dc, OZ_ArrayElement(aData,char), size ) ;
		}
		debug( 0, "OzDcSend(%#08x,aData[size:%d]) = %d\n", dc, size, ret ) ;
		if ( ret < 0 ) raise DebugChannelException::IO( OM ) ;
	}
}

char
Recv( int aHead[] )[] : locked
{
	unsigned int	dc ;
		int			size ;
		int			ret ;
		char		data[] ;
	dc = DChan ;

	/* Check object state */
	if ( OM != Where() ) raise DebugChannelException::Migrated( OM ) ;
	if ( ! DChan ) raise DebugChannelException::NotReady ;

	/* Recv head from debug channel */
	size = (aHead == 0) ? 0 : length aHead ;
	size *= 4 ;
	if ( size ) {
		inline "C" {
			ret = OzDcRecv( (DC)dc, OZ_ArrayElement(aHead,int), size ) ;
		}
		debug( 0, "OzDcRecv(%#08x,aHead[size:%d]) = %d\n", dc, size, ret ) ;
		if ( ret < 0 ) raise DebugChannelException::IO( OM ) ;
	}
	debug( 0, "aHead[0] = %d, aHead[1] = %d\n", aHead[0], aHead[1] ) ;
	if ( aHead[0] < 0 || aHead[1] == 0 ) return 0 ;

	/* Recv data from debug channel */
	size = aHead[1] ;
	length data = size ;
	if ( size ) {
		inline "C" {
			ret = OzDcRecv( (DC)dc, OZ_ArrayElement(data,char), size ) ;
		}
		debug( 0, "OzDcRecv(%#08x,aData[size:%d]) = %d\n", dc, size, ret ) ;
		if ( ret < 0 ) raise DebugChannelException::IO( OM ) ;
	}
	return( data ) ;
}

} // class DebugChannel [dchan.oz]
