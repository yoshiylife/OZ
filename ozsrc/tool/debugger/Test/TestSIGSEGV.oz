/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test SIGSEGV
//
//
class	TestSIGSEGV : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch
;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)

//------------------------------------------------------------------------------
//
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestSIGSEGV" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Launch()
{
	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;
	inline "C" {
		char	*segv ;
		segv = (char *)0x2000 ;
		*segv = 0 ;
	}
	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestSIGSEGV.oz
