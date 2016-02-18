/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Object status on OT
//
//	Depend on executor's implimentation.
//
inline "C" {
#include	"executor/object-table.h"
}
//
record	DmObjectStatus
{
	int		Value ;

int
IsReady()
{
	inline "C"	{
		return( self->ozValue == OT_READY ) ;
	}
}

int
IsQueue()
{
	inline "C"	{
		return( self->ozValue == OT_QUEUE ) ;
	}
}

int
IsStop()
{
	inline "C"	{
		return( self->ozValue == OT_STOP ) ;
	}
}

char
ToChars()[]
{
	char	name[] ;

	inline "C" {
		switch( self->ozValue ) {
		case OT_READY:
			name = OzLangString( "Ready" ) ;
			break ;
		case OT_QUEUE:
			name = OzLangString( "Queue" ) ;
			break ;
		case OT_STOP:
			name = OzLangString( "Stop" ) ;
			break ;
		default:
			name = OzLangString( "Unknown" ) ;
		}
	}

	return( name ) ;
}

}
// End of file: DmObjectStatus.oz
