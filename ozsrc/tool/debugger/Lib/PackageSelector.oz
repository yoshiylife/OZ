/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger: Select a package from catalog(direcotry).
//
//	inherits:
//		GUI
//
//	uses:
//		class	CWDirectory<Catalog,Package>
//		class	Package
//		class	School
//		class	String
//		class	Set <String>
//		class	Iterator <String>
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	PackageSelector.tcl
//
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	PackageSelector : GUI
{
constructor:
	New
;
public:
	GetPropertyPathName,
	ReadEvent
;
protected:	// Instance
	CWD,	// Current work directory in catalog
	CWP,	// Selected package
	CWN,	// Name of selected package name
	CCN		// Choiced class name
;
protected:	// Method
	Window,
	Event,
	Destroy,
	StartWish,
	ExecProc,
	CommandIs,
	RecvCommandArgs,
	Quit
;
protected:	// For Tcl/Tk script
	Property
;
//------------------------------------------------------------------------------
//
//	Protected instance
//
CWDirectory<Catalog,Package>
			CWD ;
Package		CWP ;
String		CWN ;
String		CCN ;

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
char	EventSelect[] ;
char	EventChoice[] ;
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
	NAME = "PackageSelector" ;
	debug( 0, "%S::New( %S )\n", NAME, aToplevel ) ;

	Property = "PackageSelector.tcl" ;
	Toplevel = aToplevel ;
	Title = "OZ++ Package Selector" ;
	IconName = "PkSel" ;

	EventReady = "PKS.Ready" ;
	EventChdir = "PKS.Chdir" ;
	EventSelect = "PKS.Select" ;
	EventChoice = "PKS.Choice" ;
	EventUpdate = "PKS.Update" ;
	EventCommit = "PKS.Commit" ;
	EventDismiss = "PKS.Dismiss" ;

	ProcWindow = "PKS.Window" ;
	ProcUpdate = "PKS.Update" ;
	ProcType = "PKS.Type" ;
	ProcEnable = "PKS.Enable" ;
	ProcDisable = "PKS.Disable" ;
	ProcPrint = "Print" ;
	ProcDestroy = "Destroy" ;
	ProcExit = "Exit" ;

	ChrTrue = "true" ;
	ChrFalse = "false" ;
	ChrDone = "Done." ;
	ChrZero = "0" ;
	ChrDotDot = ".." ;

	ChrNotFound = "Not found." ;
	ChrNotSelected = "Not selected." ;

	CWD => New( ":catalog" ) ;
	CWP = 0 ;
	CWN = 0 ;

	debug( 0, "%S::New() return\n", NAME ) ;
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
		if ( Update( cwin ) ) {
			if ( CWN ) {
				try {
					CWP = CWD->Retrieve( CWN ) ;
					args = Type( CWP->GetSchool() ) ;
					args[0] = cwin ;
					args[1] = CWN->Content() ;
					ExecProc( ProcType, args ) ;
				} except {
					default {
						length args = 4 ;
						args[0] = cwin ;
						args[1] = ChrFalse ;
						args[2] = CWN->Content() ;
						args[3] = ChrNotFound ;
						ExecProc( ProcPrint, args ) ;
					}
				}
			}
		} else {
			CWP = 0 ;
			CWN = 0 ;
		}
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;

	} else if ( CommandIs( EventChdir ) ) {
		CWP = 0 ;
		CWN = 0 ;
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

	} else if ( CommandIs( EventSelect ) ) {
		try {
			CWP = CWD->Retrieve( aArgs[1] ) ;
			CWN = aArgs[1]->Duplicate() ;
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrTrue ;
			args[2] = ChrDotDot ;
			ExecProc( ProcPrint, args ) ;
			args = Type( CWP->GetSchool() ) ;
			args[0] = cwin ;
			args[1] = CWN->Content() ;
			ExecProc( ProcType, args ) ;
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrTrue ;
			args[2] = ChrDone ;
			ExecProc( ProcPrint, args ) ;
		} except {
			default {
				length args = 3 ;
				args[0] = cwin ;
				args[1] = ChrTrue ;
				args[2] = ChrNotFound ;
				ExecProc( ProcPrint, args ) ;
			}
		}
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;

	} else if ( CommandIs( EventChoice ) ) {
		CCN = aArgs[1]->Duplicate() ;
		length args =3 ;
		args[0] = cwin ;
		args[1] = ChrTrue ;
		args[2] = CCN->Content() ;
		ExecProc( ProcPrint, args ) ;
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;

	} else if ( CommandIs( EventUpdate ) ) {
		if ( Update( cwin ) ) {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrTrue ;
			args[2] = ChrDotDot ;
			ExecProc( ProcPrint, args ) ;
			if ( CWN ) {
				try {
					CWP = CWD->Retrieve( CWN ) ;
					length args = 3 ;
					args[0] = cwin ;
					args[1] = ChrTrue ;
					args[2] = ChrDotDot ;
					ExecProc( ProcPrint, args ) ;
					args = Type( CWP->GetSchool() ) ;
					args[0] = cwin ;
					args[1] = CWN->Content() ;
					ExecProc( ProcType, args ) ;
					length args = 3 ;
					args[0] = cwin ;
					args[1] = ChrTrue ;
					args[2] = ChrDone ;
					ExecProc( ProcPrint, args ) ;
				} except {
					default {
						length args = 3 ;
						args[0] = cwin ;
						args[1] = ChrTrue ;
						args[2] = ChrNotFound ;
						ExecProc( ProcPrint, args ) ;
					}
				}
			} else {
				length args = 3 ;
				args[0] = cwin ;
				args[1] = ChrTrue ;
				args[2] = ChrDone ;
				ExecProc( ProcPrint, args ) ;
			}
		}
		length args = 1 ;
		args[0] = cwin ;
		ExecProc( ProcEnable, args ) ;

	} else if ( CommandIs( EventCommit ) ) {
		if ( length aArgs > 1 ) {
			try {
				CWP = CWD->Retrieve( aArgs[1] ) ;
				CWN = aArgs[1]->Duplicate() ;
				length args = 3 ;
				args[0] = cwin ;
				args[1] = ChrTrue ;
				args[2] = ChrDone ;
				ExecProc( ProcPrint, args ) ;
				Destroy() ;
				result = 1 ;
			} except {
				default {
					length args = 3 ;
					args[0] = cwin ;
					args[1] = ChrTrue ;
					args[2] = ChrNotFound ;
					ExecProc( ProcPrint, args ) ;
					length args = 1 ;
					args[0] = cwin ;
					ExecProc( ProcEnable, args ) ;
				}
			}
		} else {
			if ( CWP ) {
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
		CWP = 0 ;
		CWN = 0 ;
		Destroy() ;
		result = 1 ;
	} else result = -1 ;

	return( result ) ;
}

//------------------------------------------------------------------------------
//	Private method:	Update list of directory and package
//
int
Update( char cwin[] )
{
	char	args[][] ;
	String	delimiter ;
	String	tmp ;
	String	dirs[] ;
	String	pkgs[] ;
	int		index ;
	int		lenDirs ;
	int		lenPkgs ;
	int		i ;
	char	buf[] ;

	buf = CWD->Getcwd()->Content() ;
	debug( 0, "%S::List CWD=%S\n", NAME, buf ) ;

	delimiter => NewFromArrayOfChar( ":" ) ;
	try {
		dirs = CWD->ListDirectory()->AsArray() ;
		pkgs = CWD->ListEntry()->AsArray() ;
		lenDirs = ( dirs == 0 ) ? 0 : length dirs ;
		lenPkgs = ( pkgs == 0 ) ? 0 : length pkgs ;
		debug ( 0, "%S::List lenDirs:%d, lenPkgs:%d\n", NAME,lenDirs,lenPkgs ) ;
		length args = 2 + lenDirs + lenPkgs ;
		index = 0 ;
		index ++ ; /* for cwin */ ;
		tmp = CWD->Getcwd() ;
		args[index++] = tmp->Content() ;
		for ( i = 0 ; i < lenDirs ; i ++ ) {
			tmp = delimiter->Concatenate(dirs[i]) ;
			args[index++] = tmp->Content() ;
			debug ( 0, "%S::List dirs[%d]:%S\n",NAME,i,args[index-1] ) ;
		}
		for ( i = 0 ; i < lenPkgs ; i ++ ) {
			args[index++] = pkgs[i]->Content() ;
			debug ( 0, "%S::List pkgs[%d]:%S\n",NAME,i,args[index-1] ) ;
		}
	} except {
		default {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrTrue ;
			args[2] = ChrNotFound ;
			ExecProc( ProcPrint, args ) ;
			CWN = 0 ;
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

//------------------------------------------------------------------------------
//	Private method:	List of class
//
char
Type( School aSchool )[][]
{
	String					name ;
	Set	<String>			names ;
	Iterator <String>		handle ;
	//SortableSet <String>	sortedNames ;
	Set <String>			sortedNames ;
	char					ret[][] ;
	int						index ;
	int						part ;

	names = aSchool->ListNames() ;

	/* Select name of ordinary class */
	handle => New( names ) ;
	sortedNames => New() ;
	while ( (name=names->DoNext( handle )) != 0 ) {
		debug( 0, "DFE::Type name=%S\n", name->Content() ) ;
		part = aSchool->KindOf( name ) ;
		if ( part == 0 ) {									/* ordinary class */
			if ( name->StrChr( '<' ) < 0 ) {
				sortedNames->Add( name ) ;
			}
		}
	}
	// sortedNames->DoReset( handle ) ;

	length ret = sortedNames->Size() + 2 ;
	index = 0 ;
	index ++ ; /* for cwin */
	index ++ ; /* for path */
	handle => New( sortedNames ) ;
	while ( (name=sortedNames->DoNext( handle )) != 0 ) {
		ret[index++] = name->Content() ;
	}
	return( ret ) ;
}

}
// End of file: PackageSelector.oz
