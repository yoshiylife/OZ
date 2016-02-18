/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Function DM_TLIST
//
//	Depend on executor's implimentation.
//
record	DmTListSlot
{
	DmProcessID		pid ;
	DmObjectID		caller ;
	unsigned int	t ;
	//DmThreadStatus	status ;
		int			status ;
		int			suspend_count ;

}
// End of file: DmTListSlot.oz
