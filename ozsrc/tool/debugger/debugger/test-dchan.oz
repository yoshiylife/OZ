/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
// CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
class TestDebugChannel : Launchable
{
constructor:
	New
;
public:
	Initialize,
	Launch
;

void
Initialize()
{
	debug( 0, "TestDebugChannel: Initialize()\n" ) ;
}

void
New()
{
	Initialize() ;
	debug( 0, "TestDebugChannel: New()\n" ) ;
}

void
Launch()
{
 global ObjectManager	om ;
	DebugChannel		dc ;
		int				head[] ;
		char			data[] ;

	om = Where() ;
	dc=>New() ;
	dc->Open( om ) ;
	length head = 2 ;
	data = "test data\n" ;
	head[0] = 0 ;
	head[1] = length data ;
	dc->Send( head, data ) ;
	if ( head[0] >= 0 ) {
		data = dc->Recv( head ) ;
		inline "C" {
			OzDebugf( "TestDebugChannel: %s", OZ_ArrayElement(data,char) ) ;
		}
	}
	dc->Close() ;
	return ;
}

/* class: TestDebugChannel ****************************************************/
}
