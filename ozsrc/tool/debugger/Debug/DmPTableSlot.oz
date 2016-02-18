/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Function DM_PTABLE
//
//	Depend on executor's implimentation.
//
record	DmPTableSlot
{
	unsigned int	entry ;
	DmProcessID		pid ;
	DmProcessStatus	status ;
	DmObjectID		callee ;
	DmObjectID		caller ;
	unsigned int	t ;

}
// End of file: DmPTableSlot.oz
