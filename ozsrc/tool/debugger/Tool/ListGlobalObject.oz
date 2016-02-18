/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	List of global object
//
//	inherits:
//		Launcahble
//		GUI
//		EntrySelector
//
//	uses:
//		class	String
//		record	Lib:ObjectStatusName
//		record	Lib:OTObjectStatusName
//		class	ObjectManager
//		class	Object
//
//	indirect:
//		class	SubString
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	ListGlobalObject.tcl
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	ListGlobalObject :
			Launchable,
			EntrySelector (
				alias	New			SuperNew ;
				alias	Window		SuperWindow ;
				alias	Event		SuperEvent ;
				alias	Quit		SuperQuit ;
				alias	ExecProc	SuperExecProc ;
				rename	Property	NewProperty ;
				rename	Quit		NewQuit ;
				rename	ExecProc	NewExecProc ;
				rename	ReadEvents	NewReadEvents ;
			)
{
constructor:
	New
;
public:	// To be managed by a Launcher
	Initialize,
	Launch
;
protected:	// Instance
	Property
;
//------------------------------------------------------------------------------
//
//	Protected instance
//
char	Property[] ;	// Tcl/Tk script
String	NameDir ;
String	NameKey ;
int			QuitFlag ;
condition	QuitCond ;

//------------------------------------------------------------------------------
//
//	Private instance for constant
//
char	NAME[] ;		// Class Name (Ready only)
char	Toplevel[] ;
char	Title[] ;
char	IconName[] ;

// Event from Tcl/Tk
char		EventList[] ;
char		EventReady[] ;
char		EventSelect[] ;
char		EventOperate[] ;
char		EventServer[] ;
char		EventQuit[] ;

// Tck/Tk procedure
char		ProcWindow[] ;
char		ProcList[] ;
char		ProcClear[] ;
char		ProcPrint[] ;
char		ProcSet[] ;
char		ProcUpdate[] ;
char		ProcDisable[] ;
char		ProcEnable[] ;
char		ProcExit[] ;
char		ProcSource[] ;

// Mode
String		M_All ;
String		M_Loaded ;
String		M_Ready ;
String		M_Suspended ;
String		M_SwappedOut ;
String		M_Preloading ;

// OTM Operation
String		O_Suspend ;
String		O_Resume ;
String		O_Flush ;
String		O_Load ;
String		O_Remove ;
String		O_Restore ;
String		O_Stop ;
String		O_Queued ;
String		O_Permanentize ;
String		O_Transientize ;
String		O_Lookup ;
String		O_AddPreloading ;
String		O_RemovePreloading ;
String		O_ExecutorID ;
String		O_Architecture ;
String		O_Domain ;

// Etc...
char		Yes[] ;
char		No[] ;
char		None[] ;
char		Nothing[] ;
char		Done[] ;
char		Error[] ;
char		ExceptionRaised[] ;
char		True[] ;
char		NoSupport[] ;
char		Zero[] ;
char		NotFound[] ;

// Work
		ObjectStatusName	ObjSN ;
global	ObjectManager		OM ;

//------------------------------------------------------------------------------
//	Constructor
//
void
New()
{
	Initialize() ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "ListGlobalObject" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	QuitFlag = 0 ;
	SuperNew( ".ets" ) ;

	Property = "ListGlobalObject.tcl" ;
	Toplevel = "." ;
	Title = "OZ++ List of Global Object" ;
	IconName = "GList" ;

	EventList = "LGO.List" ;
	EventReady = "LGO.Ready" ;
	EventSelect = "LGO.Select" ;
	EventOperate = "LGO.Operate" ;
	EventServer = "LGO.Server" ;
	EventQuit = "LGO.Quit" ;

	ProcWindow = "LGO.Window" ;
	ProcList = "LGO.List" ;
	ProcClear = "LGO.Clear" ;
	ProcPrint = "Print" ;
	ProcSet = "LGO.Set" ;
	ProcUpdate = "LGO.Update" ;
	ProcDisable = "LGO.Disable" ;
	ProcEnable = "LGO.Enable" ;
	ProcExit = "Exit" ;
	ProcSource = "Source" ;

	M_All => NewFromArrayOfChar( "All" ) ;
	M_Loaded => NewFromArrayOfChar( "Loaded" ) ;
	M_Ready => NewFromArrayOfChar( "Ready" ) ;
	M_Suspended => NewFromArrayOfChar( "Suspended" ) ;
	M_SwappedOut => NewFromArrayOfChar( "SwappedOut" ) ;
	M_Preloading => NewFromArrayOfChar( "Preloading" ) ;

	O_Suspend => NewFromArrayOfChar( "Suspend" ) ;
	O_Resume => NewFromArrayOfChar( "Resume" ) ;
	O_Flush => NewFromArrayOfChar( "Flush" ) ;
	O_Load => NewFromArrayOfChar( "Load" ) ;
	O_Remove => NewFromArrayOfChar( "Remove" ) ;
	O_Restore => NewFromArrayOfChar( "Restore" ) ;
	O_Stop => NewFromArrayOfChar( "Stop" ) ;
	O_Queued => NewFromArrayOfChar( "Queued" ) ;
	O_Permanentize => NewFromArrayOfChar( "Permanentize" ) ;
	O_Transientize => NewFromArrayOfChar( "Transientize" ) ;
	O_Lookup => NewFromArrayOfChar( "Lookup" ) ;
	O_AddPreloading => NewFromArrayOfChar( "AddPreloading" ) ;
	O_RemovePreloading => NewFromArrayOfChar( "RemovePreloading" ) ;
	O_ExecutorID => NewFromArrayOfChar( "ExecutorID" ) ;
	O_Architecture => NewFromArrayOfChar( "Architecture" ) ;
	O_Domain => NewFromArrayOfChar( "Domain" ) ;

	Yes = "Yes" ;
	No = "No" ;
	None = "-" ;
	Nothing = "Nothing." ;
	Done = "Done." ;
	Error = "Error." ;
	ExceptionRaised = "Exception raised." ;
	True = "true" ;
	NoSupport = "No Support." ;
	Zero = "0" ;
	NotFound = "Not found." ;

	NameDir => NewFromArrayOfChar( ":object-managers" ) ;
	debug( 0, "%S::Initialze NameDir = %S\n", NAME, NameDir->Content() ) ;
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

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}

	debug( 0, "%S::Launch()\n", NAME ) ;

	script = GetPropertyPathName( Property ) ;
	debug( 0, "%S::Launch script = %S\n", NAME, script ) ;

	length args = 1 ;
	args[0] = script ;
	QuitFlag = 0 ;
	if ( ! StartWish( args, ':', '|' ) ) {
		length args = 3 ;
		args[0] = Toplevel ;
		args[1] = Title ;
		args[2] = IconName ;
		NewExecProc( ProcWindow, args ) ;
	}

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Private method
//
void
NewExecProc( char aProcName[], char aRecvArgs[][] ) : locked
{
	if ( ! QuitFlag ) SuperExecProc( aProcName, aRecvArgs ) ;
	else {
		signal QuitCond ;
		abort ;
	}
}

//------------------------------------------------------------------------------
//	Private method
//
void
NewQuit() : locked
{
	if ( QuitFlag ) signal QuitCond ;
	else SuperQuit() ;
}

//------------------------------------------------------------------------------
//	Private method
//
void
NewReadEvents()
{
	try {
		while( 1 ) {
			if ( ReadEvent() ) break ;
			if ( QuitFlag ) abort ;
		}
	} except {
		default {
			NewQuit() ;
		}
	}
}

//------------------------------------------------------------------------------
//	Override method of GUI
//
int
ReadEvent()
{
	int		result = 0 ;								// Return value
	String	rArgs[] ;									// Received arguments
	char	sArgs[][] ;									// Send arguments
	char	cwin[] ;									// A current window path
	int		i, n ;

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}

	debug( 0, "%S::ReadEvent()\n", NAME ) ;

	try {
		rArgs = RecvCommandArgs () ;
		abortable ;
	} except {
		default {
			rArgs = 0 ;
		}
	}
	if ( rArgs == 0 ) {
		result =1 ;
		debug( 0, "%S::ReadEvent rArgs is 0.\n", NAME ) ;
	} else if ( rArgs[0]->Length() == 0 ) {
		result =1 ;
		debug( 0, "%S::ReadEvent length rArgs[0] is 0.\n", NAME ) ;
	}
	if ( result ) {
		NewQuit() ;
		debug( 0, "%S::ReadEvent()=%d\n", NAME, result ) ;
		return( result ) ;
	}
	debug {
		n = length rArgs ;
		for ( i = 0 ; i < n ; i ++ ) {
			debug( 0, "%S::ReadEvent [%d]='%S'\n",NAME,i,rArgs[i]->Content() ) ;
		}
	}
	if ( rArgs ) cwin = rArgs[0]->Content() ;
	else cwin = 0 ;

	if ( CommandIs( EventReady ) ) {
		EntrySelector	ES ;
		char			buf[] ;
		OM = Where() ;
		ES = self ;
		buf = ES->GetPropertyPathName( NewProperty ) ;
		debug( 0, "%S::ReadEvent() NewProperty = %S\n", NAME, NewProperty ) ;
		length sArgs = 1 ;
		sArgs[0] = buf ;
		NewExecProc( ProcSource, sArgs ) ;
		length sArgs = 2 ;
		sArgs[0] = cwin ;
		sArgs[1] = M_All->Content() ;
		NewExecProc( ProcList, sArgs ) ;
	} else if ( CommandIs( EventList ) ) {
		global Object	objs[] ;
				char	sArgs[][] ;
				int		i, n ;
		try {
			objs = List( rArgs[1] ) ;
			n = (objs == 0) ? 0 : length objs ;
			length sArgs = (n + 1) ;
			sArgs[0] = cwin ;
			for ( i = 0 ; i < n ; i ++ ) {
				try {
					sArgs[i+1] = Set( cwin, objs[i] ) ;
				} except {
					default {
						/* nothing */
					}
				}
			}
			NewExecProc( ProcUpdate, sArgs ) ;
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = True ;
			sArgs[2] = (n == 0) ? Nothing : Done ;
			NewExecProc( ProcPrint, sArgs ) ;
		} except {
			default {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = True ;
				sArgs[2] = ExceptionRaised ;
				NewExecProc( ProcPrint, sArgs ) ;
			}
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		NewExecProc( ProcEnable, sArgs ) ;
	} else if ( CommandIs( EventOperate ) ) {
		try {
			Operate( cwin, rArgs[1], rArgs[2] ) ;
		} except {
			default {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = True ;
				sArgs[2] = ExceptionRaised ;
				NewExecProc( ProcPrint, sArgs ) ;
			}
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		NewExecProc( ProcEnable, sArgs ) ;
	} else if ( CommandIs( EventSelect ) ) {
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = True ;
		sArgs[2] = NoSupport ;
		NewExecProc( ProcPrint, sArgs ) ;
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		NewExecProc( ProcEnable, sArgs ) ;
	} else if ( CommandIs( EventQuit ) ) result = 1 ;
	else if ( CommandIs( EventServer ) ) {
		try {
			EntrySelector	ES ;
			ES = self ;
			if ( ES->Chdir( NameDir ) ) {
				CWG = 0 ;
				SuperWindow() ;
			} else {
				length sArgs = 4 ;
				sArgs[0] = cwin ;
				sArgs[1] = True ;
				sArgs[2] = NameDir->Content() ;
				sArgs[3] = NotFound ;
				NewExecProc( ProcPrint, sArgs ) ;
			}
		} except {
			default {
				/* Nothing */
			}
		}
	} else {
		int		ret ;
		ret = SuperEvent( rArgs ) ;
		if ( ret ) {
			if ( CWG ) {
				try {
					OM = narrow( ObjectManager, CWG ) ;
					//length sArgs = 2 ;
					//sArgs[0] = Toplevel ;
					//sArgs[1] = ToChars( OM ) ;
					//NewExecProc( ProcChange, sArgs ) ;
					length sArgs = 2 ;
					sArgs[0] = Toplevel ;
					sArgs[1] = M_All->Content() ;
					NewExecProc( ProcList, sArgs ) ;
				} except {
					default {
						/* Nothing */
					}
				}
			} else {
				length sArgs = 1 ;
				sArgs[0] = Toplevel ;
				NewExecProc( ProcEnable, sArgs ) ;
			}
		}
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
		sArgs[0] = Zero ;
		NewExecProc( ProcExit, sArgs ) ;
		NewQuit() ;
	}

	debug( 0, "%S::ReadEvent() = %d\n", NAME, result ) ;
	return( result ) ;
}

//
//	Private method
//
char
Set( char cwin[], global Object aObj )[]
{
	char	sArgs[][] ;

	length sArgs = 7 ;
	sArgs[0] = cwin ;
	sArgs[1] = ToChars( aObj ) ;
	sArgs[2] = ObjSN.Name( OM->WhichStatus( aObj ) ) ;
	sArgs[3] = OM->IsPermanentObject( aObj ) ? Yes : No ;
	sArgs[4] = OM->IsSuspendedObject( aObj ) ? Yes : No ;
	sArgs[5] = OM->WasSafelyShutdown( aObj ) ? Yes : No ;
	sArgs[6] = OM->IsaPreloadingObject( aObj ) ? Yes : No ;
	NewExecProc( ProcSet, sArgs ) ;
	return( sArgs[1] ) ;
}

global Object
List( String mode )[]
{
	global	Object	objs[] ;

	if ( mode == 0 ) objs = OM->ListObjects() ;
	else if (mode->IsEqual( M_All )) objs = OM->ListObjects() ;
	else if (mode->IsEqual( M_Loaded )) objs = OM->ListLoadedObjects() ;
	else if (mode->IsEqual( M_Ready )) objs = OM->ListReadyObjects() ;
	else if (mode->IsEqual( M_Suspended )) objs = OM->ListSuspendedObjects() ;
	else if (mode->IsEqual( M_SwappedOut )) objs = OM->ListSwappedOutObjects() ;
	else if (mode->IsEqual( M_Preloading )) objs = OM->ListPreloadingObjects() ;
	else return( 0 ) ;

	return( objs ) ;
}

void
Operate( char cwin[], String op, String id )
{
	global	Object	go ;
			char	sArgs[][] ;						// Send arguments

	go = ToOID( id->Content() ) ;

	if ( op->IsEqual( O_Suspend ) ) OM->SuspendObject( go ) ;
	else if ( op->IsEqual( O_Resume ) ) OM->ResumeObject( go ) ;
	else if ( op->IsEqual( O_Flush ) ) OM->FlushObject( go ) ;
	else if ( op->IsEqual( O_Load ) ) OM->LoadObject( go ) ;
	else if ( op->IsEqual( O_Remove ) ) {
		OM->RemoveObject( go ) ;
		//
		// Testing for OzOmObjectTableRemove()
		//
		// inline "C" {
		// 	int	ret ;
		// 	extern	int OzOmObjectTableRemove( OID ) ;
		// 	ret = OzOmObjectTableRemove( go ) ;
		// 	OzDebugf( "OzOmObjectTableRemove(%O) = %d\n", go, ret ) ;
		// }
	} else if ( op->IsEqual( O_Restore ) ) OM->RestoreObject( go ) ;
	else if ( op->IsEqual( O_Stop ) ) OM->StopObject( go ) ;
	else if ( op->IsEqual( O_Queued ) ) OM->QueuedInvocation( go ) ;
	else if ( op->IsEqual( O_Permanentize ) ) OM->PermanentizeObject( go ) ;
	else if ( op->IsEqual( O_Transientize ) ) OM->TransientizeObject( go ) ;
	else if ( op->IsEqual( O_Lookup ) ) {
		global Object	o ;
		o = OM->LookupObject( go ) ;
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = True ;
		sArgs[2] = ( go == o ) ? Yes : No ;
		NewExecProc( ProcPrint, sArgs ) ;
		return ;
	} else if ( op->IsEqual( O_AddPreloading ) ) {
		OM->AddPreloadingObject( go ) ;
	} else if ( op->IsEqual( O_RemovePreloading ) ) {
		OM->RemovePreloadingObject( go ) ;
	} else if ( op->IsEqual( O_ExecutorID ) ) {
		long	exid ;
		char	buf[] ;
		exid = OM->ExecutorID() ;
		inline "C" {
			buf = OzFormat( "%016lx", exid ) ;
		}
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = True ;
		sArgs[2] = buf ;
		NewExecProc( ProcPrint, sArgs ) ;
		return ;
	} else if ( op->IsEqual( O_Architecture ) ) {
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = True ;
		sArgs[2] = OM->MyArchitecture()->Type() ;
		NewExecProc( ProcPrint, sArgs ) ;
		return ;
	} else if ( op->IsEqual( O_Domain ) ) {
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = True ;
		sArgs[2] = OM->WhichDomain() ;
		NewExecProc( ProcPrint, sArgs ) ;
		return ;
	} else {
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = True ;
		sArgs[2] = Error ;
		NewExecProc( ProcPrint, sArgs ) ;
		return ;
	}
	length sArgs = 3 ;
	sArgs[0] = cwin ;
	sArgs[1] = True ;
	sArgs[2] = Done ;
	NewExecProc( ProcPrint, sArgs ) ;
}

char
ToChars( global Object aObject )[]
{
	char	id[] ;
	inline "C" {
		id = OzFormat( "%O", aObject ) ;
	}
	return( id ) ;
}

global	Object
ToOID ( char id[] )
{
	global	Object	o ;
	inline "C" {
		o = OzStrtoull( OZ_ArrayElement(id,char), 0, 16 ) ;
	}
	return( o ) ;
}

}
// End of file: ListGlobalObject.oz
