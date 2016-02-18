/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Class id
//
//	Depend on executor's implimentation.
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
record	DmClassID
{
	global	Object	Value ;

char
ToChars()[]
{
	char	result[] ;
	inline "C" {
		extern	OZ_Array	OzFormat() ;
		result = OzFormat( "%O", self->ozValue ) ;
	}
	return( result ) ;
}

}
// End of file: DmClassID.oz
