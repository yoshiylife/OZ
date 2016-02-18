/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Function for OZ++ World.
//
//	CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
inline "C" {
#include "../src/executor/debugFunction.h"
}
class	DebugFunction
{
constructor:
	New
;
public:
	Open,
	Close,
	PTable
;
protected:

	/* instance */
	DChan
;

	DebugChannel	DChan ;

void
New()
{
	DChan=>New() ;
}

void
Open( global Object aObject ) : locked
{
	DChan->Open( aObject ) ;
}

void
Close() : locked
{
	DChan->Close() ;
}

void
PTable( unsigned int aAddr, char aData[] ) : locked
{
	int		head[] ;
	char	data[] ;
	int		request ;
	int		addr ;

	length head = 4 ;
	inline "C" {
		request = DM_PTABLE
		addr = (unsigned int)aAddr ;
	}
	head[0] = request ;
	head[1] = 8 ;
	head[2] = addr ;
	head[3] = 
	dc->Send( head, data ) ;
	if ( 0 <= head[0] ) {
		length data = head[1] ;
		dc->Recv( head, data ) ;
	}
			(OZ_ArrayElement(data,int)) ) ;
}

// class DebugChannel.
}
