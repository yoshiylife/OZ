/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Process id
//
//	Depend on executor's implimentation.
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
record	DmProcessID
{
	unsigned long	Value ;

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

unsigned long
ToValue ( char id[] )
{
	unsigned long	pid ;
	inline "C" {
		pid = OzStrtoull( OZ_ArrayElement(id,char), 0, 16 ) ;
	}
	Value = pid ;
	return( pid ) ;
}

}
// End of file: DmProcessID.oz
