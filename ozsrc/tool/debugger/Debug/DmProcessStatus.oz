/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Process status
//
//	Depend on executor's implimentation.
//
inline "C" {
#include "../src/executor/proc.h"
}
//
record	DmProcessStatus
{
	int		Value ;

int
IsFree()
{
	inline "C"	{
		return( self->ozValue == PROC_FREE ) ;
	}
}

int
IsRunning()
{
	inline "C"	{
		return( self->ozValue == PROC_RUNNING ) ;
	}
}

int
IsExited()
{
	inline "C"	{
		return( self->ozValue == PROC_EXITED ) ;
	}
}

int
IsDetached()
{
	inline "C"	{
		return( self->ozValue == PROC_DETACHED ) ;
	}
}

int
IsJoined()
{
	inline "C"	{
		return( self->ozValue == PROC_JOINED ) ;
	}
}

char
ToChars()[]
{
	char	name[] ;

	inline "C" {
		switch( self->ozValue ) {
		case PROC_FREE:
			name = OzLangString( "Free" ) ;
			break ;
		case PROC_RUNNING:
			name = OzLangString( "Running" ) ;
			break ;
		case PROC_EXITED:
			name = OzLangString( "Exited" ) ;
			break ;
		case PROC_DETACHED:
			name = OzLangString( "Detached" ) ;
			break ;
		case PROC_JOINED:
			name = OzLangString( "Joined" ) ;
			break ;
		default:
			name = OzLangString( "Unknown" ) ;
		}
	}
	return( name ) ;
}

}
// End of file: DmProcessStatus.oz
