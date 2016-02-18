/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Function DM_OTABLE
//
//	Depend on executor's implimentation.
//
record	DmOTableSlot
{
	DmClassID			c ;
	DmObjectID			o ;
	/* DmOTObjectStatus	status ; */
	int		status ;
	/* DmOTObjectFlags		flags ; */
	int		flags ;

}
// End of file: DmOTableSlot.oz
