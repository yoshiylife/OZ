/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	List Process Table
//
//	inherits:
//		Object
//		Launchable
//		GUI
//
//	uses:
//		class	DebugFunction
//		class	DebugChannel
//		class	String
//
//	indirect:
//		class	SubString
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	ListProcessTable.tcl
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	ListProcessTable : Launchable, GUI
{
public:	// To be managed by a Launcher
	Initialize,
	Launch
;
protected:	// Instance
	Property,
	DF,
	DC
;


//
//	Protected instance
//
char			Name[] ;	// Class Name (Ready only)
char			Property[] ;// Tcl/Tk script
DebugFunction	DF ;		// To call debug function
DebugChannel	DC ;		// To comm debug channel


//
//	Private instance
//

// Event from Tcl/Tk
char	EventList[] ;
char	EventReady[] ;
char	EventOperate[] ;
char	EventQuit[] ;

// Tck/Tk procedure
char	ProcList[] ;
char	ProcClear[] ;
char	ProcPrint[] ;
char	ProcSet[] ;
char	ProcUpdate[] ;
char	ProcDisable[] ;
char	ProcEnable[] ;
char	ProcExit[] ;

// Operation
String	O_Suspend ;
String	O_Resume ;
String	O_Kill ;
String	O_Status ;

// Etc...
char	Yes[] ;
char	No[] ;
char	Nothing[] ;
char	Done[] ;
char	Error[] ;
char	ExceptionRaised[] ;
char	True[] ;
char	NoSuchProc[] ;
char	Zero[] ;


//
// Public method to be managed by a Launcher
//
void
Initialize()
{
	Name = "ListProcessTable" ;
	debug( 0, "%S::Initialize()\n", Name ) ;

	Property = "ListProcessTable.tcl" ;

	EventList = "LPT.List" ;
	EventReady = "LPT.Ready" ;
	EventOperate = "LPT.Operate" ;
	EventQuit = "LPT.Quit" ;

	ProcList = "LPT.List" ;
	ProcClear = "LPT.Clear" ;
	ProcPrint = "LPT.Print" ;
	ProcSet = "LPT.Set" ;
	ProcUpdate = "LPT.Update" ;
	ProcDisable = "LPT.Disable" ;
	ProcEnable = "LPT.Enable" ;
	ProcExit = "Exit" ;

	O_Suspend => NewFromArrayOfChar( "Suspend" ) ;
	O_Resume => NewFromArrayOfChar( "Resume" ) ;
	O_Kill => NewFromArrayOfChar( "Kill" ) ;
	O_Status => NewFromArrayOfChar( "Status" ) ;

	Yes = "Yes" ;
	No = "No" ;
	Nothing = "Nothing." ;
	Done = " Done." ;
	Error = "Error." ;
	ExceptionRaised = "Exception raised." ;
	True = "true" ;
	NoSuchProc = "No souch process." ;
	Zero = "0" ;

	debug( 0, "%S::Initialize() return\n", Name ) ;
}

void
Launch()
{
	char	args[][] ;
	char	script[] ;

	debug( 0, "%S::Launch()\n", Name ) ;

	script = GetPropertyPathName( Property ) ;
	debug( 0, "%S::Launch script = %S\n", Name, script ) ;

	length args = 1 ;
	args[0] = script ;
	if ( ! StartWish( args, ':', '|' ) ) {
		length args = 3 ;
		args[0] = "." ;
		args[1] = "List of Process Table" ;
		args[2] = "PTable" ;
		ExecProc( "LPT.Window", args ) ;
	}

	DF => New() ;
	DC => New() ;

	try {
		DC->Open( Where() ) ;
	} except {
		default {
			debug( 0 , "%S::Launch Can't Open DebugChannel\n", Name ) ;
			DC = 0 ;
			raise ;
		}
	}

	debug( 0, "%S::Launch() return\n", Name ) ;
}

//
//	class GUI
//	Override protected method
//
int
ReadEvent()
{
	int		result = 0 ;								// Return value
	String	rArgs[] ;									// Received arguments
	char	sArgs[][] ;									// Send arguments
	char	cwin[] ;									// A current window path
	int		i, n ;

	debug( 0, "%S::ReadEvent()\n", Name ) ;

	try {
		rArgs = RecvCommandArgs () ;
	} except {
		default {
			Quit() ;
			return( 1 ) ;
		}
	}
	debug {
		n = length rArgs ;
		for ( i = 0 ; i < n ; i ++ ) {
			debug( 0, "%S::ReadEvent [%d]='%S'\n",Name,i,rArgs[i]->Content() ) ;
		}
	}
	if ( rArgs ) cwin = rArgs[0]->Content() ;
	else cwin = 0 ;

	if ( CommandIs( EventReady ) ) {
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( ProcList, sArgs ) ;
	} else if ( CommandIs( EventList ) ) {
		int		ret ;
		ret = List( cwin ) ;
		if ( ret == 0 ) {
			length sArgs = 2 ;
			sArgs[0] = cwin ;
			sArgs[1] = Nothing ;
			ExecProc( ProcPrint, sArgs ) ;
		} else if ( ret < 0 ) {
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = Error ;
			sArgs[2] = True ;
			ExecProc( ProcPrint, sArgs ) ;
		} else {
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = Done ;
			sArgs[2] = True ;
			ExecProc( ProcPrint, sArgs ) ;
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( ProcEnable, sArgs ) ;
	} else if ( CommandIs( EventOperate ) ) {
		try {
			Operate( cwin, rArgs[1], rArgs[2] ) ;
		} except {
			default {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = ExceptionRaised ;
				sArgs[2] = True ;
				ExecProc( ProcPrint, sArgs ) ;
			}
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( ProcEnable, sArgs ) ;
	} else if ( CommandIs( EventQuit ) ) result = 1 ;

	try {
		abortable ;
	} except {
		default {
			result = 1  ;
		}
	}

	if ( result ) {
		DF = 0 ;
		if ( DC ) {
			DC->Close() ;
			DC = 0 ;
		}
		length sArgs = 1 ;
		sArgs[0] = "0" ;
		ExecProc( ProcExit, sArgs ) ;
		Quit() ;
		result = 1 ;
	}

	debug( 0, "%S::ReadEvent() = %d\n", Name, result ) ;
	return( result ) ;
}
	

//
//	Private method
//
int
List( char cwin[] )
{
		int			result = 0 ;	// Return value
		char		sArgs[][] ;		// For ProcSet
		char		uArgs[][] ;		// For ProcUpdate
		char		buf[] ;
	DmPTableSlot	slot[], s ;
		int			i ;
	unsigned int	t ;

	try {
		slot = DF->DmPTABLE( DC ) ;
	} except {
		default {
			debug( 0 , "%S::List Error in DmOTABLE\n", Name ) ;
			return( result ) ;
		}
	}

	length sArgs = 5 ;
	sArgs[0] = cwin ;
	result = (slot == 0 ) ? 0 : length slot ;
	length uArgs = result + 1 ;
	uArgs[0] = cwin ;
	for ( i = 0 ; i < result ; i ++ ) {
		s = slot[i] ;
		t = s.t ;
		try {
			sArgs[1] = uArgs[i+1] = (s.pid).ToChars() ;
			sArgs[2] = (s.status).ToChars() ;
			sArgs[3] = (s.callee).ToChars() ;
			inline "C" {
				buf = OzFormat( "0x%08x", t ) ;
			}
			sArgs[4] = buf ;
			ExecProc( ProcSet, sArgs ) ;
		} except {
			default {
				/* nothing */
			}
		}
	}
	ExecProc( ProcUpdate, uArgs ) ;

	return( result ) ;
}

void
Operate( char cwin[], String op, String id )
{
	DmProcessID	pid ;
	char		sArgs[][] ;						// Send arguments
	int			ret ;

	pid.ToValue( id->Content() ) ;
	if ( op->IsEqual( O_Suspend ) ) ret = Suspend( pid ) ;
	else if ( op->IsEqual( O_Resume ) ) ret = Resume( pid ) ;
	else if ( op->IsEqual( O_Kill ) ) ret = Kill( pid ) ;
	else if ( op->IsEqual( O_Status ) ) ret = Status( pid ) ;
	length sArgs = 3 ;
	sArgs[0] = cwin ;
	sArgs[1] = (ret == 0) ? Done : NoSuchProc ;
	sArgs[2] = True ;
	ExecProc( ProcPrint, sArgs ) ;
}

int
Suspend( DmProcessID pid )
{
	int		result = 0 ;
	return( 0 ) ;
}

int
Resume( DmProcessID pid )
{
	int		result = 0 ;
	return( 0 ) ;
}

int
Kill( DmProcessID pid )
{
	int		result = 0 ;

	try {
		DF->DmPKILL( DC, pid ) ;
	} except {
		DebugException::Error( status ) {
			result = 1 ;
		}
		default {
			debug( 0 , "%S::Kill Error in DmPKILL\n", Name ) ;
			raise ;
		}
	}

	return( 0 ) ;
}

int
Status( DmProcessID pid )
{
	int		result = 0 ;
	return( 0 ) ;
}

}
// End of file: ListProcessTable.oz
