/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Thread status
//
//	Depend on executor's implimentation.
//
inline "C" {
#include "thread/thread.h"
}
//
record	DmThreadStatus
{
	int		Value ;

int
IsFree()
{
	inline "C"	{
		return( self->ozValue == FREE ) ;
	}
}

int
IsCreate()
{
	inline "C"	{
		return( self->ozValue == CREATE ) ;
	}
}

int
IsReady()
{
	inline "C"	{
		return( self->ozValue == READY ) ;
	}
}

int
IsRunning()
{
	inline "C"	{
		return( self->ozValue == RUNNING ) ;
	}
}

int
IsSuspend()
{
	inline "C"	{
		return( self->ozValue == SUSPEND ) ;
	}
}

int
IsWaitIO()
{
	inline "C"	{
		return( self->ozValue == WAIT_IO ) ;
	}
}

int
IsWaitLock()
{
	inline "C"	{
		return( self->ozValue == WAIT_LOCK ) ;
	}
}

int
IsWaitCondition()
{
	inline "C"	{
		return( self->ozValue == WAIT_COND ) ;
	}
}

int
IsWaitSuspend()
{
	inline "C"	{
		return( self->ozValue == WAIT_SUSPEND ) ;
	}
}

int
IsWaitTimer()
{
	inline "C"	{
		return( self->ozValue == WAIT_TIMER ) ;
	}
}

int
IsZombi()
{
	inline "C"	{
		return( self->ozValue == DEFUNCT ) ;
	}
}

char
ToChars()[]
{
	char	name[] ;

	inline "C" {
		switch( self->ozValue ) {
		case FREE:
			name = OzLangString( "Free" ) ;
			break ;
		case CREATE:
			name = OzLangString( "Create" ) ;
			break ;
		case READY:
			name = OzLangString( "Ready" ) ;
			break ;
		case RUNNING:
			name = OzLangString( "Running" ) ;
			break ;
		case SUSPEND:
			name = OzLangString( "Suspend" ) ;
			break ;
		case WAIT_IO:
			name = OzLangString( "WaitIO" ) ;
			break ;
		case WAIT_LOCK:
			name = OzLangString( "WaitLock" ) ;
			break ;
		case WAIT_COND:
			name = OzLangString( "WaitCondition" ) ;
			break ;
		case WAIT_SUSPEND:
			name = OzLangString( "WaitSuspend" ) ;
			break ;
		case WAIT_TIMER:
			name = OzLangString( "WaitTimer" ) ;
			break ;
		case DEFUNCT:
			name = OzLangString( "Defunct" ) ;
			break ;
		default:
			name = OzLangString( "Unknown" ) ;
		}
	}
	return( name ) ;
}

}
// End of file: DmThreadStatus.oz
