/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Object flags on OT
//
//	Depend on executor's implimentation.
//
inline "C" {
#include "../src/executor/ot.h"
}
//
record	DmObjectFlags
{
	int		Value ;

int
IsAccessed()
{
	inline "C" {
		return( self->ozValue & OT_ACCESSED ) ;
	}
}

int
IsLoaded()
{
	inline "C" {
		return( self->ozValue & OT_LOADED ) ;
	}
}

int
IsLoading()
{
	inline "C" {
		return( self->ozValue & OT_LOADING ) ;
	}
}

int
IsSuspend()
{
	inline "C" {
		return( self->ozValue & OT_SUSPEND ) ;
	}
}

}
// End of file: DmObjectFlags.oz
