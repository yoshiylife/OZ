/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Function DM_...ENTRY
//
//	Depend on executor's implimentation.
//
record	DmOEntry
{
	unsigned int	entry ;
	DmObjectStatus	status ;
	unsigned int	object ;
	unsigned int	head ;
		int			parts ;
	unsigned int	size ;
	DmClassID		cid ;
}
// End of file: DmOEntry.oz
