/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Global object id
//
//	Depend on executor's implimentation.
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
record	DmObjectID
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

global	Object
ToOID ( char id[] )
{
	global	Object	o ;
	inline "C" {
		o = OzStrtoull( OZ_ArrayElement(id,char), 0, 16 ) ;
	}
	Value = o ;
	return( o ) ;
}

} // End of file: DmObjectID.oz
