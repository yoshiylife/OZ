/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test of remote global access
//
//
//
class	TestRemote : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch,
	Loop
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
String	TargetName ;

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestRemote" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	//TargetName => NewFromArrayOfChar( ":object-managers:site-master" ) ;
	//TargetName => NewFromArrayOfChar( ":object-managers:002502" ) ;
	TargetName => NewFromArrayOfChar( ":object-managers:site-master" ) ;
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
	global	Object			O ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;

	OM = Where() ;
	ND = OM->GetNameDirectory() ;
	O = ND->Resolve( TargetName ) ;

	detach fork Loop( narrow( ObjectManager, O ) ) ;

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

void
test( global ObjectManager OM )
{
	global	Object	objs[] ;

	inline "C" {
		OzSleep( 1 ) ;
	}
	objs = OM->ListObjects() ;
    // OM->MyArchitecture() ;
	//	OzDebugf( "Abort.cid = %016lx\n", OzExceptionAbort.cid ) ;
}

void
Loop( global ObjectManager OM )
{
	global	Object	objs[] ;
		void		@p ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Loop Start[%P]\n", NAME, p ) ;
	try {
		for (;;) {
			objs = OM->ListObjects() ;
			inline "C" {
				OzSleep( 1 ) ;
			}
			abortable ;
		}
	} except {
		Abort {
			debug( 0, "%S::Loop [%P] Abort\n", NAME, p ) ;
		}
	}
	debug( 0, "%S::Loop Finish[%P]\n", NAME, p ) ;
}

} // End of file: TestRemote.oz
