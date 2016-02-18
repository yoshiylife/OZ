/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test of class GUI
//
//	Tcl/Tk:	7.3jp/3.4jp(Pixmap)
//	Uses:
//		class	ObjectManaer
//		class	NameDirectory
//		class	String
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
//class	TestGUI : Launchable, GUI
class	TestGUI : GUI, Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch
;
//------------------------------------------------------------------------------
//
//	Protected instance
//
char	Property[] ;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)
int		Counter ;

// Window info
char	Toplevel[] ;
char	Title[] ;
char	IconName[] ;

// Event from Tcl/Tk
char	EventReady[] ;	// [0]: path
char	EventTest[] ;	// [1]: path
char	EventQuit[] ;	// [2]: path

// Procdure of Tcl/Tk
char	ProcWindow[] ;	// [0]: path, [1]: toplevel, [2]: title, [3]: icon name
char	ProcEnable[] ;	// [0]: path
char	ProcDisable[] ;	// [0]: path
char	ProcPrint[] ;	// [0]: path, [1]: append flag, [2]...: messages
char	ProcExit[] ;	// [0]: exit status

// Etc...
char	ChrTrue[] ;
char	ChrFalse[] ;
char	ChrDone[] ;
char	ChrZero[] ;

global	ObjectManager	OM ;
global	NameDirectory	ND ;

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestGUI" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	Property = "TestGUI.tcl" ;

	Counter = 0 ;

	Toplevel = "." ;
	Title = "Test of class GUI" ;
	IconName = "TestGUI" ;

	EventReady = "TEST.Ready" ;
	EventTest = "TEST.Test" ;
	EventQuit = "TEST.Quit" ;

	ProcWindow = "TEST.Window" ;
	ProcEnable = "TEST.Enable" ;
	ProcDisable = "TEST.Disable" ;
	ProcPrint = "Print" ;
	ProcExit = "Exit" ;

	ChrTrue = "true" ;
	ChrFalse = "false" ;
	ChrDone = "Done" ;

	ChrZero = "0" ;

	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Launch()
{
	char	args[][] ;
	char	script[] ;

	debug( 0, "%S::Launch()\n", NAME ) ;

	OM = Where() ;
	ND = OM->GetNameDirectory() ;

	script = GetPropertyPathName( Property ) ;
	debug( 0, "%S::Launch script = %S\n", NAME, script ) ;

	length args = 1 ;
	args[0] = script ;
	if ( ! StartWish( args, ':', '|' ) ) {
		length args = 3 ;
		args[0] = Toplevel ;									// Window path
		args[1] = Title ;										// Window title
		args[2] = IconName ;									// Icon name
		ExecProc( ProcWindow, args ) ;
	}

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	class GUI method
//
int
ReadEvent()
{
	int		result = 0 ;								// Return value
	String	rArgs[] ;									// Received arguments
	char	sArgs[][] ;									// Sending arguments
	char	cwin[] ;									// Current window path
	int		i, n ;

	//inline "C" {
	//	_oz_debug_flag = 1 ;
	//}

	debug( 0, "%S::ReadEvent()\n", NAME ) ;

	try {
		rArgs = RecvCommandArgs () ;
	} except {
		default {
			rArgs = 0 ;
		}
	}
	if ( rArgs == 0 ) {
		Quit() ;
		return( 1 ) ;
	}
	debug {
		n = length rArgs ;
		for ( i = 0 ; i < n ; i ++ ) {
			debug( 0, "%S::ReadEvent [%d]='%S'\n",NAME,i,rArgs[i]->Content() );
		}
	}
	if ( rArgs ) cwin = rArgs[0]->Content() ;
	else cwin = 0 ;

	if ( CommandIs( EventReady ) ) {
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = ChrTrue ;
		sArgs[2] = ChrDone ;
		ExecProc( ProcPrint, sArgs ) ;
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( ProcEnable, sArgs ) ;

	} else if ( CommandIs( EventTest ) ) {
		Counter ++ ;
		length sArgs = 4 ;
		sArgs[0] = cwin ;
		sArgs[1] = ChrTrue ;
		sArgs[2] = ToChars( Counter ) ; ;
		sArgs[3] = ChrDone ;
		ExecProc( ProcPrint, sArgs ) ;
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( ProcEnable, sArgs ) ;

	} else if ( CommandIs( EventQuit ) ) {
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( ProcDisable, sArgs ) ;
		result = 1 ;
	}

	try {
		abortable ;
	} except {
		default {
			result =1 ;
		}
	}

	if ( result ) {
		length sArgs = 1 ;
		sArgs[0] = ChrZero ;
		ExecProc( ProcExit, sArgs ) ;
		Quit() ;
	}

	debug( 0, "%S::ReadEvent() = %d\n", NAME, result ) ;
	return( result ) ;
}

//------------------------------------------------------------------------------
//	Private method
//
char
ToChars( int aInt )[]
{
	char	result[] ;
	inline "C" {
		result = OzFormat( "%d", aInt ) ;
	}
	return( result ) ;
}

} // End of file: TestGUI.oz
