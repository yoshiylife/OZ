/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	struct	OZ_AllocateInfoRec
//
//	Depend on executor's implimentation.
//
record	DmAllocateInfo
{
	unsigned short	data_size_protected ;
	unsigned short	data_size_private ;
	unsigned short	number_of_pointer_protected ;
	unsigned short	number_of_pointer_private ;
	unsigned short	zero_protected ;
	unsigned short	zero_private ;
			char	pad0 ;
			char	pad1 ;
			char	pad2 ;
			char	pad3 ;
}
// End of file: DmAllocateInfo
