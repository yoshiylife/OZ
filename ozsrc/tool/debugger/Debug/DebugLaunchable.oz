/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger: Launch width debug flags and hold one instance of Launchable.
//
//	inherits:
//		Object
//		Launchable
//		PackageSelector
//
//	uses:
//		class	ObjectManager
//		class	NameDirectory
//		class	Package
//		class	String
//		class	School
//		class	ConfigurationTable
//		class	ConfiguredClassID
//		class	VersionID
//
//	indirect:
//		class	SubString
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	DebugLaunchable.tcl
//
inline "C" {
	extern	unsigned int	OzDebugFlags ;
	extern	OZ_Array		OzFormat() ;
}
//
class	DebugLaunchable : Launchable,
			PackageSelector (
				alias New NewPS ;
				alias Window WindowPS ;
				alias Destroy DestroyPS ;
				alias Event EventPS ;
				rename Property PropertyPS ;
				rename ReadEvent NewReadEvent ;
			)
{
public:	// To be managed by a Launcher
	Initialize,
	Launch
;
protected:	// Method
	Fork,
	Watch
;
//------------------------------------------------------------------------------
//
//	Private instance
//

// Performance & Comfortable programming
global	ObjectManager	OM ;
global	NameDirectory	ND ;

// Target Launchable
Launchable	WorkObject ;
Package		WorkPackage ;
String		WorkPackageName ;
String		WorkClassName ;
void		@Worker ;
void		@Watcher ;

Lock		StatusL ;
int			Status ;
unsigned int	DebugFlags ;

//------------------------------------------------------------------------------
//
//	Private instance for constant
//
char	NAME[] ;		// Class Name (Ready only)
char	Property[] ;	// Tcl/Tk script
char	Toplevel[] ;
char	Title[] ;
char	IconName[] ;

char	EventReady[] ;
char	EventFlag[] ;
char	EventInitialize[] ;
char	EventLaunch[] ;
char	EventKill[] ;
char	EventInspect[] ;
char	EventQuit[] ;
char	EventTest[] ;

char	ProcWindow[] ;
char	ProcEnable[] ;
char	ProcDisable[] ;
char	ProcUpdate[] ;
char	ProcPrint[] ;
char	ProcSource[] ;
char	ProcExit[] ;

char	ChrDone[] ;
char	ChrTrue[] ;
char	ChrNone[] ;
char	ChrDotDot[] ;

String	StrZero ;
String	StrFork ;
String	StrConstructor ;
String	StrPublic ;
String	StrProtected ;
String	StrPrivate ;
String	StrRecord ;

char	ChrInitialize[] ;
char	ChrLaunch[] ;
char	ChrKill[] ;
char	ChrInspect[] ;
char	ChrQuit[] ;

// Error message
char	ChrNotFoundCCID[] ;
char	ChrNarrowFailed[] ;
char	ChrExceptionRaised[] ;
char	ChrForkFailed[] ;
char	ChrNotImplement[] ;
char	ChrProcessAborted[] ;
char	ChrNoMemory[] ;

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "DebugLaunchable" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	Property = "DebugLaunchable.tcl" ;
	Toplevel = "." ;
	Title = "OZ++ Debug Launchable" ;
	IconName = "DLaunch" ;

	EventReady = "DL.Ready" ;
	EventFlag = "DL.Flag" ;
	EventInitialize = "DL.Initialize" ;
	EventLaunch = "DL.Launch" ;
	EventKill = "DL.Kill" ;
	EventInspect = "DL.Inspect" ;
	EventQuit = "DL.Quit" ;
	EventTest = "DL.Test" ;

	ProcWindow = "DL.Window" ;
	ProcEnable = "DL.Enable" ;
	ProcDisable = "DL.Disable" ;
	ProcUpdate = "DL.Update" ;
	ProcPrint = "Print" ;
	ProcSource = "Source" ;
	ProcExit = "Exit" ;
	
	ChrDone = "Done" ;
	ChrTrue = "true" ;
	ChrNone = "None" ;
	ChrDotDot = ".." ;

	StrZero => NewFromArrayOfChar( "0" ) ;
	StrFork => NewFromArrayOfChar( "Fork" ) ;
	StrConstructor => NewFromArrayOfChar( "Constructor" ) ;
	StrPublic => NewFromArrayOfChar( "Public" ) ;
	StrProtected => NewFromArrayOfChar( "Protected" ) ;
	StrPrivate => NewFromArrayOfChar( "Private" ) ;
	StrRecord => NewFromArrayOfChar( "Record" ) ;

	ChrInitialize = "Initialize" ;
	ChrLaunch = "Launch" ;
	ChrKill = "Kill" ;
	ChrInspect = "Inspect" ;
	ChrQuit = "Quit" ;

	ChrNotFoundCCID = "Not found configured class id." ;
	ChrNarrowFailed = "Narrow failed." ;
	ChrExceptionRaised = "Exception raised." ;
	ChrForkFailed = "Fork failed" ;
	ChrNotImplement = "Not yet implement." ;
	ChrProcessAborted = "Process aborted." ;

	WorkObject = 0 ;
	WorkPackage = 0 ;
	WorkPackageName = 0 ;
	WorkClassName = 0 ;
	Worker = 0 ;
	Watcher = 0 ;
	DebugFlags = 0 ;

	NewPS( ".ps" ) ;

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
		length args = 4 ;
		args[0] = Toplevel ;									// Window path
		args[1] = Title ;										// Window title
		args[2] = IconName ;									// Icon name
		args[3] = (WorkClassName == 0) ? ChrNone : WorkClassName->Content() ;
																// class name
		ExecProc( ProcWindow, args ) ;
	}

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Override method of GUI
//
int
NewReadEvent()
{
	int		result = 0 ;								// Return value
	String	rArgs[] ;									// Received arguments
	char	sArgs[][] ;									// Sending arguments
	char	cwin[] ;									// Current window path
	int		i, n ;

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
		char	script[] ;
		PackageSelector	PS ;
		PS = self ;
		script = PS->GetPropertyPathName( PropertyPS ) ;
		length sArgs = 1 ;
		sArgs[0] = script ;
		ExecProc( ProcSource, sArgs ) ;
		StatusL => New() ;
		Status = 0 ;
		if ( WorkObject ) {
			length sArgs = 5 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrInitialize ;
			sArgs[2] = ChrLaunch ;
			sArgs[3] = ChrInspect ;
			sArgs[4] = ChrQuit ;
			ExecProc( ProcEnable, sArgs ) ;
		} else {
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrInitialize ;
			sArgs[2] = ChrQuit ;
			ExecProc( ProcEnable, sArgs ) ;
		}

	} else if ( CommandIs( EventFlag ) ) {					// 1:part, 2:flag
		unsigned int	flag ;

		if ( rArgs[1]->IsEqual( StrFork ) ) {
			inline "C" { flag = 0x80 ; }
		} else if ( rArgs[1]->IsEqual( StrConstructor ) ) {
			inline "C" { flag = OZ_AC_CONSTRUCTOR ; }
		} else if ( rArgs[1]->IsEqual( StrPublic ) ) {
			inline "C" { flag = OZ_AC_PUBLIC ; }
		} else if ( rArgs[1]->IsEqual( StrProtected ) ) {
			inline "C" { flag = OZ_AC_PROTECTED ; }
		} else if ( rArgs[1]->IsEqual( StrPrivate ) ) {
			inline "C" { flag = OZ_AC_PRIVATE ; }
		} else if ( rArgs[1]->IsEqual( StrRecord ) ) {
			inline "C" { flag = OZ_AC_RECORD ; }
		}
		if ( rArgs[2]->IsEqual( StrZero ) ) DebugFlags &= ~flag ;
		else DebugFlags |= flag ;

	} else if ( CommandIs( EventInitialize ) ) {			// 1:class name
		char	msg[] ;

		WorkObject = 0 ;
		try {
			WorkObject = Create( cwin, WorkPackage, rArgs[1] ) ;
			msg = ChrDotDot ;
		} except {
			default {
				msg = ChrExceptionRaised ;
			}
		}
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = ChrTrue ;
		sArgs[2] = msg ;
		ExecProc( ProcPrint, sArgs ) ;

		if ( WorkObject ) {
			Worker = Watcher = 0 ;
			try {
				void	@p ;

				StatusL->Lock() ;
				Status = 1 ;
				StatusL->UnLock() ;
				Worker = Fork( WorkObject,1,DebugFlags ) ;
				Watcher = fork Watch( cwin, Worker ) ;
				detach Watcher ;
				p = Worker ;
				inline "C" {
					msg = OzFormat( "%P ", p ) ;
				}
			} except {
				default {
					WorkObject = 0 ;
					StatusL->Lock() ;
					Status = 0 ;
					StatusL->UnLock() ;
					try {
						if ( Worker ) kill Worker ;
					} except {
						default {
							/* Nothing */
						}
					}
					msg = ChrForkFailed ;
				}
			}
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrTrue ;
			sArgs[2] = msg ;
			ExecProc( ProcPrint, sArgs ) ;
		}

		if ( WorkObject ) {
			length sArgs = 2 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrKill ;
			ExecProc( ProcEnable, sArgs ) ;
		} else {
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrInitialize ;
			sArgs[2] = ChrQuit ;
			ExecProc( ProcEnable, sArgs ) ;
		}

	} else if ( CommandIs( EventLaunch ) ) {

		Worker = Watcher = 0 ;
		try {
			void	@p ;
			char	buf[] ;

			Worker = Fork( WorkObject, 0, DebugFlags ) ;
			Watcher = fork Watch( cwin, Worker ) ;
			detach Watcher ;
			p = Worker ;
			inline "C" {
				buf = OzFormat( "%P ", p ) ;
			}
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrTrue ;
			sArgs[2] = buf ;
			ExecProc( ProcPrint, sArgs ) ;
			length sArgs = 2 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrKill ;
			ExecProc( ProcEnable, sArgs ) ;
		} except {
			default {
				try {
					if ( Worker ) kill Worker ;
				} except {
					default {
						/* Nothing */
					}
				}
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = ChrTrue ;
				sArgs[2] = ChrForkFailed ;
				ExecProc( ProcPrint, sArgs ) ;
				length sArgs = 4 ;
				sArgs[0] = cwin ;
				sArgs[1] = ChrInitialize ;
				sArgs[2] = ChrInspect ;
				sArgs[3] = ChrQuit ;
				ExecProc( ProcEnable, sArgs ) ;
			}
		}

	} else if ( CommandIs( EventKill ) ) {

		try {
			if ( Worker ) kill Worker ;
		} except {
			default {
				/* Nothing */
			}
		}
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = ChrTrue ;
		sArgs[2] = ChrDotDot ;
		ExecProc( ProcPrint, sArgs ) ;
		StatusL->Lock() ;
		if ( Status ) {
			length sArgs = 4 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrInitialize ;
			sArgs[2] = ChrInspect ;
			sArgs[3] = ChrQuit ;
			ExecProc( ProcEnable, sArgs ) ;
		} else {
			length sArgs = 5 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrInitialize ;
			sArgs[2] = ChrLaunch ;
			sArgs[3] = ChrInspect ;
			sArgs[4] = ChrQuit ;
			ExecProc( ProcEnable, sArgs ) ;
		}
		StatusL->UnLock() ;

	} else if ( CommandIs( EventInspect ) ) {
		length sArgs = 3 ;
		sArgs[0] = cwin ;
		sArgs[1] = ChrTrue ;
		sArgs[2] = ChrNotImplement ;
		ExecProc( ProcPrint, sArgs ) ;
		length sArgs = 5 ;
		sArgs[0] = cwin ;
		sArgs[1] = ChrInitialize ;
		sArgs[2] = ChrLaunch ;
		sArgs[3] = ChrInspect ;
		sArgs[4] = ChrQuit ;
		ExecProc( ProcEnable, sArgs ) ;
	} else if ( CommandIs( EventQuit ) ) result = 1 ;
	else if ( CommandIs( EventTest ) ) {
		CWP = 0 ;
		WindowPS() ;
	} else {
		int		ret ;
		ret = EventPS( rArgs ) ;
		if ( ret ) {
			if ( CWP ) {
				WorkPackage = CWP ;
				WorkPackageName = CWN ;
				if ( CCN ) {
					WorkClassName = CCN ;
					length sArgs = 2 ;
					sArgs[0] = Toplevel ;
					sArgs[1] = WorkClassName->Content() ;
					ExecProc( ProcUpdate, sArgs ) ;
				}
			}
			length sArgs = 1 ;
			sArgs[0] = Toplevel ;
			ExecProc( ProcEnable, sArgs ) ;
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
		sArgs[0] = StrZero->Content() ;
		ExecProc( ProcExit, sArgs ) ;
		Quit() ;
	}

	debug( 0, "%S::ReadEvent() = %d\n", NAME, result ) ;
	return( result ) ;
}

//------------------------------------------------------------------------------
//	Private method
//
Launchable
Create( char cwin[], Package aPackage, String aName )
{
			Launchable			result = 0 ;					// Return value
			School				school ;
			ConfigurationTable	config ;
	global	ConfiguredClassID	ccid ;
	global	VersionID			vid ;
			char				msg[] ;

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}
	debug( 0, "%S::Create(, %C, %S )\n", NAME, aPackage, aName->Content() ) ;

	school = aPackage->GetSchool() ;
	config = aPackage->GetConfigurationTable() ;
	vid = school->VersionIDOf( aName ) ;
	ccid = (config != 0 ) ? config->Lookup( vid ) : 0 ;
	if ( ccid == 0 ) ccid = OM->GetConfiguredClassID( vid, 0 ) ;

	if ( ccid ) {
		try {
			Object		o ;
			inline "C" {
				OZ_Object	_obj = OzExecAllocateLocalObject( ccid ) ;
				o = _obj - (_obj->head.e-1) ;
			}
			result = narrow( Launchable, o ) ;
		} except {
			NarrowFailed {
				msg = ChrNarrowFailed ;
			}
			NoMemory {
				msg = ChrNoMemory ;
			}
		}
	} else msg = ChrNotFoundCCID ;

	if ( result == 0 ) {
		char	args[][] ;
		length args = 3 ;
		args[0] = cwin ;
		args[1] = ChrTrue ;
		args[2] = msg ;
		ExecProc( ProcPrint, args ) ;
	}

	debug( 0, "%S::Create()=%C\n", NAME, result ) ;
	return( result ) ;
}

//------------------------------------------------------------------------------
//	Private method
//
void
@Fork( Launchable aObj, int aMode, unsigned int aDflags )
{
		void		@result ;							// Return value
	unsigned int	dflags ;
	unsigned int	dfsave ;

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}

	debug( 0, "%S::Fork( %C, %d, 0x%08x )\n", NAME, aObj, aMode, aDflags ) ;

	dflags = aDflags ;
	inline "C" {
		dfsave = OzDebugFlags ;
		OzDebugFlags = dflags|0x81000040u ;
	}
	result = ( aMode ? fork aObj->Initialize() : fork aObj->Launch() ) ;
	inline "C" {
		OzDebugFlags = dfsave ;
	}

	debug( 0, "%S::Fork()=%P\n", NAME, result ) ;
	return( result ) ;
}

//------------------------------------------------------------------------------
//	Private method
//
void
Watch( char cwin[], void @aProc )
{
	int		flag ;
	char	args[][] ;
	char	msg[] ;

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}

	debug( 0, "%S::Watch( %S, %P )\n", NAME, cwin, aProc ) ;

	try {
		join aProc ;
		msg = ChrDone ;
		flag = 1 ;
	} except {
		default {
			msg = ChrProcessAborted ;
			flag = 0 ;
		}
	}

	try {
		abortable ;
	} except {
		default {
			msg = 0 ;
			flag = 0 ;
		}
	}

	if ( msg ) {
		char	buf[] ;
		inline "C" {
			buf = OzFormat( "%P", aProc ) ;
		}
		length args = 4 ;
		args[0] = cwin ;
		args[1] = ChrTrue ;
		args[2] = buf ;
		args[3] = msg ;
		ExecProc( ProcPrint, args ) ;
	}

	if ( flag ) {
		length args = 5 ;
		args[0] = cwin ;
		args[1] = ChrInitialize ;
		args[2] = ChrLaunch ;
		args[3] = ChrInspect ;
		args[4] = ChrQuit ;
		ExecProc( ProcEnable, args ) ;
	}

	StatusL->Lock() ;
	Status = 0 ;
	StatusL->UnLock() ;

	debug( 0, "%S::Watch() return\n", NAME ) ;
}

}
// End of file: DebugLaunchable.oz
