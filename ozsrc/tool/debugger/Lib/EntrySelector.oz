/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger: Select a name entry from name directory.
//
//	inherits:
//		GUI
//
//	uses:
//		class	CWDirectory<NameDirectory,global ResolvableObject>
//		class	ResolvableObject
//		class	String
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	EntrySelector.tcl
//
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	EntrySelector : GUI
{
constructor:
	New
;
public:
	GetPropertyPathName,
	ReadEvent,
	Chdir
;
protected:	// Instance
	CWD,	// Current work directory in name directory.
	CWG		// Current selected global object.
;
protected:	// Inherits from GUI
	Quit,
	ExecProc,
	ReadEvents
;
protected:	// Method
	Window,
	Event,
	Destroy,
	StartWish,
	CommandIs,
	RecvCommandArgs
;
protected:	// For Tcl/Tk script
	Property
;
//------------------------------------------------------------------------------
//
//	Protected instance
//
CWDirectory<NameDirectory,global ResolvableObject>
	CWD ;
global ResolvableObject
	CWG ;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Read only)
char	Property[] ;	// Tcl/Tk script file name
char	Toplevel[] ;
char	Title[] ;
char	IconName[] ;

// Event from Tcl/Tk
char	EventReady[] ;
char	EventChdir[] ;
char	EventLookup[] ;
char	EventUpdate[] ;
char	EventCommit[] ;
char	EventDismiss[] ;

// Tcl/Tk procedure
char	ProcWindow[] ;
char	ProcUpdate[] ;
char	ProcType[] ;
char	ProcEnable[] ;
char	ProcDisable[] ;
char	ProcPrint[] ;
char	ProcDestroy[] ;
char	ProcExit[] ;

// Etc...
char	ChrTrue[] ;
char	ChrFalse[] ;
char	ChrDone[] ;
char	ChrZero[] ;
char	ChrDotDot[] ;

// Error message
char	ChrNotFound[] ;
char	ChrNotSelected[] ;

//------------------------------------------------------------------------------
//	Constructor method
//
void
New( char aToplevel[] )
{
	NAME = "EntrySelector" ;
	debug( 0, "%S::New( %S )\n", NAME, aToplevel ) ;

	Property = "EntrySelector.tcl" ;
	Toplevel = aToplevel ;
	Title = "OZ++ Name Entry Selector" ;
	IconName = "EntSel" ;

	EventReady = "ETS.Ready" ;
	EventChdir = "ETS.Chdir" ;
	EventLookup = "ETS.Lookup" ;
	EventUpdate = "ETS.Update" ;
	EventCommit = "ETS.Commit" ;
	EventDismiss = "ETS.Dismiss" ;

	ProcWindow = "ETS.Window" ;
	ProcUpdate = "ETS.Update" ;
	ProcType = "ETS.Type" ;
	ProcEnable = "ETS.Enable" ;
	ProcDisable = "ETS.Disable" ;
	ProcPrint = "Print" ;
	ProcDestroy = "Destroy" ;
	ProcExit = "Exit" ;

	ChrTrue = "true" ;
	ChrFalse = "false" ;
	ChrDone = "Done." ;
	ChrZero = "0" ;
	ChrDotDot = ".." ;

	ChrNotFound = "Not found." ;
	ChrNotSelected = "Not Selected." ;

	CWD => New( ":name" ) ;
	CWG = 0 ;

	debug( 0, "%S::New() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method
//
String
Chdir( String aPath )
{
	return CWD->Chdir( aPath ) ;
}

//------------------------------------------------------------------------------
//	Protected method
//
void
Window()
{
	char	args[][] ;

	length args = 3 ;
	args[0] = Toplevel ;
	args[1] = Title ;
	args[2] = IconName ;
	ExecProc( ProcWindow, args ) ;
}

//------------------------------------------------------------------------------
//	Protected method
//
void
Destroy()
{
	char	args[][] ;

	length args = 1 ;
	args[0] = Toplevel ;
	ExecProc( ProcDestroy, args ) ;
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

	result = Event( rArgs ) ;

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
//	Protected method
//
int
Event( String aArgs[] )
{
	int		result = 0 ;
	char	args[][] ;
	char	cwin[] ;

	cwin = aArgs[0]->Content() ;

	if ( CommandIs( EventReady ) ) {
		Update( cwin ) ;
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;
		CWG = 0 ;

	} else if ( CommandIs( EventChdir ) ) {
		CWG = 0 ;
		length args = 3 ;
		args[0] = cwin ;
		args[1] = ChrTrue ;
		try {
			if ( CWD->Chdir( (length aArgs == 1) ? 0 : aArgs[1] ) ) {
				Update( cwin ) ;
				args[2] = ChrDone ;
			} else args[2] = ChrNotFound ;
		} except {
			default {
				args[2] = ChrNotFound ;
			}
		}
		ExecProc( ProcPrint, args ) ;
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;

	} else if ( CommandIs( EventLookup ) ) {
		length args = 3 ;
		args[0] = cwin ;
		args[1] = ChrTrue ;
		try {
			CWG = CWD->Retrieve( aArgs[1] ) ;
			args[2] = ToChars( CWG ) ;
		} except {
			default {
				args[2] = ChrNotFound ;
			}
		}
		ExecProc( ProcPrint, args ) ;
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;

	} else if ( CommandIs( EventUpdate ) ) {
		if ( Update( cwin ) ) {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrTrue ;
			args[2] = ChrDone ;
			ExecProc( ProcPrint, args ) ;
		}
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;

	} else if ( CommandIs( EventCommit ) ) {
		if ( length aArgs > 1 ) {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrTrue ;
			try {
				CWG = CWD->Retrieve( aArgs[1] ) ;
				args[2] = ChrDone ;
				ExecProc( ProcPrint, args ) ;
				Destroy() ;
				result = 1 ;
			} except {
				default {
					args[2] = ChrNotFound ;
					ExecProc( ProcPrint, args ) ;
					length args = 1 ;
					args[0] = cwin ;
					ExecProc( ProcEnable, args ) ;
				}
			}
		} else {
			if ( CWG ) {
				Destroy() ;
				result = 1 ;
			} else {
				length args = 3 ;
				args[0] = cwin ;
				args[1] = ChrTrue ;
				args[2] = ChrNotSelected ;
				ExecProc( ProcPrint, args ) ;
				length args = 1 ;
				args[0] = cwin ;
				ExecProc( ProcEnable, args ) ;
			}
		}

	} else if ( CommandIs( EventDismiss ) ) {
		CWG = 0 ;
		Destroy() ;
		result = 1 ;
	} else result = -1 ;

	return( result ) ;
}

//------------------------------------------------------------------------------
//	Private method:	Update list of directory and entry
//
int
Update( char cwin[] )
{
	char	args[][] ;
	String	delimiter ;
	String	tmp ;
	String	dirs[] ;
	String	ents[] ;
	int		index ;
	int		lenDirs ;
	int		lenEnts ;
	int		i ;
	char	buf[] ;

	buf = CWD->Getcwd()->Content() ;
	debug( 0, "%S::List CWD=%S\n", NAME, buf ) ;

	delimiter => NewFromArrayOfChar( ":" ) ;
	try {
		dirs = CWD->ListDirectory()->AsArray() ;
		ents = CWD->ListEntry()->AsArray() ;
		lenDirs = ( dirs == 0 ) ? 0 : length dirs ;
		lenEnts = ( ents == 0 ) ? 0 : length ents ;
		debug ( 0, "%S::List lenDirs:%d, lenEnts:%d\n", NAME,lenDirs,lenEnts ) ;
		length args = 2 + lenDirs + lenEnts ;
		index = 0 ;
		index ++ ; /* for cwin */ ;
		tmp = CWD->Getcwd() ;
		args[index++] = tmp->Content() ;
		for ( i = 0 ; i < lenDirs ; i ++ ) {
			tmp = delimiter->Concatenate(dirs[i]) ;
			args[index++] = tmp->Content() ;
			debug ( 0, "%S::List dirs[%d]:%S\n",NAME,i,args[index-1] ) ;
		}
		for ( i = 0 ; i < lenEnts ; i ++ ) {
			args[index++] = ents[i]->Content() ;
			debug ( 0, "%S::List ents[%d]:%S\n",NAME,i,args[index-1] ) ;
		}
	} except {
		default {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrTrue ;
			args[2] = ChrNotFound ;
			ExecProc( ProcPrint, args ) ;
			CWG= 0 ;
			args = 0 ;
		}
	}

	if ( args ) {
		args[0] = cwin ;
		ExecProc( ProcUpdate, args ) ;
		debug( 0, "%S::Update() length args = %d\n", NAME, length args ) ;
		return( 1 ) ;
	} else {
		debug( 0, "%S::Update() Not found\n", NAME ) ;
		return( 0 ) ;
	}
}

char
ToChars( global Object aObject )[]
{
	char	id[] ;
	inline "C" {
		extern	OZ_Array	OzFormat() ;
		id = OzFormat( "%O", aObject ) ;
	}
	return( id ) ;
}

}
// End of file: EntrySelector.oz
