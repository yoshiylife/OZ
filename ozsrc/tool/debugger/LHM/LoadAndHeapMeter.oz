/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Meter for scheduler load and memory heap.
//
//	Local object only.
//
//	inherits:
//		Launchable
//		GUI
//		EntrySelector
//
//	uses:
//		class	Object
//		class	ObjectManager
//		class	String
//		class	LoadAndHeapMonitor
//		class	LoadAndHeap
//
//	indirect:
//		class	SubString
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	LoadAndHeapMeter.tcl
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	LoadAndHeapMeter :
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
	Launch,
	Finish
;
public:	// To be called by LoadAndHeapMonitor
	GetCell
;
protected:	// Instance
	Property,
	Interval,
	Monitor,
	Cell,
	NameDir,
	NameKey,
	QuitCond
;
//------------------------------------------------------------------------------
//
//	Protected instance
//
			char			Property[] ;	// Tcl/Tk script
		unsigned int		Interval ;
global	LoadAndHeapMonitor	Monitor ;
global	Object				Cell ;
		String				NameDir ;
		String				NameKey ;
			int				QuitFlag ;
		condition			QuitCond ;

//------------------------------------------------------------------------------
//
//	Private instance for constant
//
char	NAME[] ;		// Class Name (Ready only)
char	Toplevel[] ;
char	Title[] ;
char	IconName[] ;

// Event from Tcl/Tk
char	EventReady[] ;
char	EventInstall[] ;
char	EventUpdate[] ;
char	EventSelect[] ;
char	EventRemove[] ;
char	EventQuit[] ;

// Tcl/Tk procedure
char	ProcWindow[] ;
char	ProcSet[] ;
char	ProcUpdate[] ;
char	ProcChange[] ;
char	ProcPrint[] ;
char	ProcExit[] ;
char	ProcSource[] ;

// Etc...
char	ChrNull[] ;
char	ChrTrue[] ;
char	ChrFalse[] ;
char	ChrDone[] ;
char	ChrZero[] ;
char	ChrNone[] ;
char	ChrError[] ;
char	ChrRaised[] ;
char	ChrNoCurrent[] ;
char	ChrResolveFailed[] ;
char	ChrNarrowFailed[] ;
char	ChrIllegalInvoked[] ;
char	ChrAlreadyInstalled[] ;
char	ChrAlreadyExisted[] ;
char	ChrNotFound[] ;
char	ChrNotInstalled[] ;

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
	String	tmp ;
	char	buf[] ;
	long	exid ;

	NAME = "LoadAndHeapMeter" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	Interval = 2 ;
	Monitor = 0 ;
	Cell = cell ;
	QuitFlag = 0 ;
	SuperNew( ".ets" ) ;

	Property = "LoadAndHeapMeter.tcl" ;
	Toplevel = "." ;
	Title = "OZ++ Load & Heap Meter" ;
	IconName = "Meter" ;

	EventReady = "LHM.Ready" ;
	EventInstall = "LHM.Install" ;
	EventUpdate = "LHM.Update" ;
	EventSelect = "LHM.Select" ;
	EventRemove = "LHM.Remove" ;
	EventQuit = "LHM.Quit" ;

	ProcWindow = "LHM.Window" ;
	ProcSet = "LHM.Set" ;
	ProcUpdate = "LHM.Update" ;
	ProcChange = "LHM.Change" ;
	ProcPrint = "Print" ;
	ProcExit = "Exit" ;
	ProcSource = "Source" ;

	ChrNull = "" ;
	ChrTrue = "true" ;
	ChrFalse = "false" ;
	ChrDone = " Done." ;
	ChrZero = "0" ;
	ChrNone = "-" ;
	ChrError = " Error." ;
	ChrRaised = " Raised." ;
	ChrNoCurrent = " No current." ;
	ChrResolveFailed = " Resolve failed." ;
	ChrNarrowFailed = " Narrow failed." ;
	ChrIllegalInvoked = " Illegal invoked." ;
	ChrAlreadyInstalled = " Already installed." ;
	ChrAlreadyExisted = " Already existed." ;
	ChrNotFound = " Not found." ;
	ChrNotFound = " Not Installed." ;

	NameDir => NewFromArrayOfChar( ":Load & Heap Monitors" ) ;

	exid = Where()->ExecutorID() ;
	inline "C" {
		buf = OzFormat( ":%06x", (int)(exid>>24) & 0x0ffffff ) ;
	}
	tmp => NewFromArrayOfChar( buf ) ;
	NameKey = NameDir->Duplicate()->Concatenate( tmp ) ;
	debug( 0, "%S::Initialze NameDir = %S\n", NAME, NameDir->Content() ) ;
	debug( 0, "%S::Initialze NameKey = %S\n", NAME, NameKey->Content() ) ;
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
//	Public method: Get global object which create this object(self).
//		To be called LoadAndHeapMonitor.
//
global	Object
GetCell()
{
	return( Cell ) ;
}

//------------------------------------------------------------------------------
//	Public method: To be called LoadAndHeapMonitor.
//
void
Finish() : locked
{
	QuitFlag = 1 ;
	SuperQuit() ;
	wait QuitCond ;
	QuitFlag = 0 ;
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
			debug( 0, "%S::ReadEvent [%d]='%S'\n",NAME,i,rArgs[i]->Content() );
		}
	}
	if ( rArgs ) cwin = rArgs[0]->Content() ;
	else cwin = 0 ;

	if ( CommandIs( EventReady ) ) {
		EntrySelector	ES ;
		unsigned int	ival ;
		char			buf[] ;
		ES = self ;
		buf = ES->GetPropertyPathName( NewProperty ) ;
		debug( 0, "%S::ReadEvent() NewProperty = %S\n", NAME, NewProperty ) ;
		length sArgs = 1 ;
		sArgs[0] = buf ;
		NewExecProc( ProcSource, sArgs ) ;
		ival = Interval ;
		inline "C" {
			buf = OzFormat( "%u",  ival ) ;
		}
		length sArgs = 2 ;
		sArgs[0] = cwin ;
		sArgs[1] = buf ;
		NewExecProc( ProcSet, sArgs ) ;
		Check( cwin ) ;
		length sArgs = 2 ;
		sArgs[0] = cwin ;
		sArgs[1] = ToChars( Monitor ) ;
		NewExecProc( ProcUpdate, sArgs ) ;

	} else if ( CommandIs( EventUpdate ) ) {
		unsigned int	load ;
		unsigned int	heap ;
				char	buf[] ;
				int		val ;
				char	loads[] ;
				char	heaps[] ;
		buf = rArgs[1]->Content() ;
		inline "C" {
			char	*cp ;
			cp = (char *)OZ_ArrayElement( buf, char ) ;
			val = OzStrtol( cp, NULL, 0 ) ;
		}
		if ( val != Interval ) Interval = val ;
		if ( Monitor ) {
			try {
				LoadAndHeap	data ;
				data = Monitor->Monitor( val ) ;
				load = data->Load() ;
				heap = data->Heap() ;
				//load = Monitor->LoadAverage( val ) ;
				//heap = Monitor->HeapConsume() ;
				inline "C" {
					loads = OzFormat( "%u", load ) ;
					heaps = OzFormat( "%u", heap ) ;
				}
				length sArgs = 4 ;
				sArgs[0] = cwin ;
				sArgs[1] = ToChars( Monitor ) ;
				sArgs[2] = loads ;
				sArgs[3] = heaps ;
				NewExecProc( ProcUpdate, sArgs ) ;
			} except {
				default {
					//length sArgs = 1 ;
					//sArgs[0] = cwin ;
					//NewExecProc( ProcUpdate, sArgs ) ;
					length sArgs = 3 ;
					sArgs[0] = cwin ;
					sArgs[1] = ChrFalse ;
					sArgs[2] = ChrIllegalInvoked ;
					NewExecProc( ProcPrint, sArgs ) ;
					Monitor = 0 ;
				}
			}
		} else {
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = ChrFalse ;
			sArgs[2] = ChrNotInstalled ;
			NewExecProc( ProcPrint, sArgs ) ;
		}

	} else if ( CommandIs( EventInstall ) ) {
		if ( rArgs[1]->CompareToArrayOfChar( ChrZero ) == 0 ) {
			Monitor => New( NameKey ) ;
			Install( cwin ) ;
		} else {
			Monitor => New( 0 ) ;
		}
		length sArgs = 2 ;
		sArgs[0] = cwin ;
		sArgs[1] = ToChars( Monitor ) ;
		NewExecProc( ProcUpdate, sArgs ) ;
	} else if ( CommandIs( EventRemove ) ) Remove( cwin ) ;
	else if ( CommandIs( EventQuit ) ) result = 1 ;
	else if ( CommandIs( EventSelect ) ) {
		try {
			EntrySelector	ES ;
			ES = self ;
			if ( ES->Chdir( NameDir ) ) {
				CWG = 0 ;
				SuperWindow() ;
			} else {
				length sArgs = 4 ;
				sArgs[0] = cwin ;
				sArgs[1] = ChrFalse ;
				sArgs[2] = NameDir->Content() ;
				sArgs[3] = ChrNotFound ;
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
					char	buf[] ;
					Monitor = narrow( LoadAndHeapMonitor, CWG ) ;
					length sArgs = 2 ;
					sArgs[0] = Toplevel ;
					sArgs[1] = ToChars( Monitor ) ;
					NewExecProc( ProcChange, sArgs ) ;
				} except {
					default {
						/* Nothing */
					}
				}
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
		sArgs[0] = ChrZero ;
		NewExecProc( ProcExit, sArgs ) ;
		NewQuit() ;
	}

	debug( 0, "%S::ReadEvent() = %d\n", NAME, result ) ;
	return( result ) ;
}

void
Check( char cwin[] )
{
	global	ObjectManager	OM ;
	global	NameDirectory	ND ;
	global	Object			OBJ ;
			char			args[][] ;						// Send arguments

	Monitor = 0 ;
	OM = Where() ;
	ND = OM->GetNameDirectory() ;
	try {
		OBJ = ND->Resolve( NameKey ) ;
		if ( OBJ ) {
			try {
				Monitor = narrow( LoadAndHeapMonitor, OBJ ) ;
			} except {
				default {
					length args = 3 ;
					args[0] = cwin ;
					args[1] = ChrFalse ;
					args[2] = ChrNarrowFailed ;
					NewExecProc( ProcPrint, args ) ;
				}
			}
		}
	} except {
		default {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrFalse ;
			args[2] = ChrResolveFailed ;
			NewExecProc( ProcPrint, args ) ;
		}
	}

	return ;
}

void
Install( char cwin[] )
{
	global	NameDirectory	ND ;
	global	ObjectManager	OM ;
	global	Object			OBJ ;
			char			args[][] ;						// Send arguments

	OM = Where() ;
	ND = OM->GetNameDirectory() ;
	try {
		try {
			ND->IsaDirectory( NameDir ) ;
		} except {
			DirectoryExceptions::UnknownDirectory( dummy ) {
				ND->NewDirectory( NameDir ) ;
			}
		}

		OBJ = ND->Resolve( NameKey ) ;
		if ( OBJ == 0 ) {
			ND->AddObject( NameKey, Monitor ) ;
			OM->PermanentizeObject( Monitor ) ;
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrFalse ;
			args[2] = ChrDone ;
			NewExecProc( ProcPrint, args ) ;
		} else if ( OBJ == Monitor ) {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrFalse ;
			args[2] = ChrAlreadyInstalled ;
			NewExecProc( ProcPrint, args ) ;
		} else {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrFalse ;
			args[2] = ChrAlreadyExisted ;
			NewExecProc( ProcPrint, args ) ;
		}
	} except {
		default {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrFalse ;
			args[2] = ChrRaised ;
			NewExecProc( ProcPrint, args ) ;
		}
	}

	return ;
}

void
Remove( char cwin[] )
{
	global	ObjectManager	OM ;
	global	NameDirectory	ND ;
	global	Object			OBJ ;
			char			args[][] ;						// Send arguments

	OM = Where() ;
	ND = OM->GetNameDirectory() ;
	try {
		OBJ = ND->RemoveObjectWithName( NameKey ) ;
		if ( OBJ ) {
			if ( OM->LookupObject( OBJ ) ) {
				OM->TransientizeObject( OBJ ) ;
				if ( OM->IsaPreloadingObject( OBJ ) ) {
					OM->RemovePreloadingObject( OBJ ) ;
				}
			}
		}
		length args = 3 ;
		args[0] = cwin ;
		args[1] = ChrFalse ;
		args[2] = ChrDone ;
		NewExecProc( ProcPrint, args ) ;
	} except {
		default {
			length args = 3 ;
			args[0] = cwin ;
			args[1] = ChrFalse ;
			args[2] = ChrRaised ;
			NewExecProc( ProcPrint, args ) ;
		}
	}

	return ;
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
// End of file: LoadAndHeapMeter.oz
