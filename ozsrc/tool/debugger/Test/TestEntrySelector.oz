/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test of class EntrySelector
//
//	inherits:
//		class	Launchable
//		class	EntrySelector
//
//	uses:
//		class	ObjectManager
//		class	NameDirectory
//
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	TestEntrySelector : Launchable,
			EntrySelector (
				alias New SuperNew ;
			)
{
public:	// To be managed by a Launcher
	Initialize,
	Launch
;
//------------------------------------------------------------------------------
//
//	Protected instance
//

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestEntrySelector" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	SuperNew( "." ) ;

	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Launch()
{
	global	ObjectManager	OM ;
	global	NameDirectory	ND ;
			EntrySelector	ES ;
	char	args[][] ;
	char	script[] ;

	debug( 0, "%S::Launch()\n", NAME ) ;

	OM = Where() ;
	ND = OM->GetNameDirectory() ;

	ES = self ;
	script = ES->GetPropertyPathName( Property ) ;
	debug( 0, "%S::Launch script = %S\n", NAME, script ) ;

	length args = 1 ;
	args[0] = script ;
	if ( ! StartWish( args, ':', '|' ) ) Window() ;

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

} // End of file: TestEntrySelector.oz
