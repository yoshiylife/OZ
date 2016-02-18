/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test GC Compaction
//
//
class	TestCompaction : Launchable
{
constructor:
	New
;
public:	// To be managed by a Launcher
	Initialize,
	Launch
;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)
int		DATA[] ;
int		ADDR ;

//------------------------------------------------------------------------------
//
//	Constructor
//
void
New()
{
	Initialize() ;
}

//------------------------------------------------------------------------------
//
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	int		i ;
	int		data[] ;
	int		addr ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	NAME = "TestCompaction" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	for ( i = 0 ; i < 1000 ; i ++ ) length data = 32 ;
	DATA = data ;
	inline "C" {
		addr = (int)data ;
	}
	ADDR = addr ;
	debug( 0, "%S: DATA = 0x%x\n", NAME, addr ) ;

	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Launch()
{
	int		i ;
	int		data[] ;
	int		addr ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;

	for ( i = 0 ; i < 1000 ; i ++ ) length data = 32 ;
	data = DATA ;
	inline "C" {
		addr = (int)data ;
	}
	debug( 0, "%S:: DATA = 0x%x\n", NAME, addr ) ;
	if ( ADDR == addr ) {
		debug( 0, "%S:: --- Not compaction !!\n", NAME ) ;
	} else {
		debug( 0, "%S:: --- Compaction !!\n", NAME ) ;
		ADDR = addr ;
	}

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestCompaction.oz
