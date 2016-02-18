/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	List Object Table
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
//		class	ListObjectThread
//
//	indirect:
//		class	SubString
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	ListObjectTable.tcl
//
class	ListObjectTable : Launchable, GUI
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
String	O_Threads ;

// Etc...
char	Yes[] ;
char	No[] ;
char	Nothing[] ;
char	Done[] ;
char	Error[] ;
char	ExceptionRaised[] ;
char	NoSuchObject[] ;
char	ForbiddenOp[] ;
char	True[] ;
char	Zero[] ;


//
// Public method to be managed by an Launcher
//
void
Initialize()
{
	Name = "ListObjectTable" ;
	debug( 0, "%S::Initialize()\n", Name ) ;

	Property = "ListObjectTable.tcl" ;

	EventList = "LOT.List" ;
	EventReady = "LOT.Ready" ;
	EventOperate = "LOT.Operate" ;
	EventQuit = "LOT.Quit" ;

	ProcList = "LOT.List" ;
	ProcClear = "LOT.Clear" ;
	ProcPrint = "LOT.Print" ;
	ProcSet = "LOT.Set" ;
	ProcUpdate = "LOT.Update" ;
	ProcDisable = "LOT.Disable" ;
	ProcEnable = "LOT.Enable" ;
	ProcExit = "Exit" ;

	O_Suspend => NewFromArrayOfChar( "Suspend" ) ;
	O_Resume => NewFromArrayOfChar( "Resume" ) ;
	O_Threads => NewFromArrayOfChar( "Threads" ) ;

	Yes = "Yes" ;
	No = "No" ;
	Nothing = "Nothing." ;
	Done = " Done." ;
	Error = "Error." ;
	ExceptionRaised = "Exception raised." ;
	NoSuchObject = "No such object." ;
	ForbiddenOp = "Forbidden operation." ;
	True = "true" ;
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
		args[1] = "List of Object Table" ;
		args[2] = "OTable" ;
		ExecProc( "LOT.Window", args ) ;
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
			result = 1 ;
		}
	}

	if ( result ) {
		DF = 0 ;
		if ( DC ) {
			DC->Close() ;
			DC = 0 ;
		}
		length sArgs = 1 ;
		sArgs[0] = Zero ;
		ExecProc( ProcExit, sArgs ) ;
		Quit() ;
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
	DmOTableSlot	slot[], s ;
	DmObjectStatus	status ;
	DmObjectFlags	flags ;
		int			i ;

	try {
		slot = DF->DmOTABLE( DC ) ;
	} except {
		default {
			debug( 0 , "%S::List Error in DmOTABLE\n", Name ) ;
			return( result ) ;
		}
	}

	length sArgs = 6 ;
	sArgs[0] = cwin ;
	result = (slot == 0 ) ? 0 : length slot ;
	length uArgs = result + 1 ;
	uArgs[0] = cwin ;
	for ( i = 0 ; i < result ; i ++ ) {
		s = slot[i] ;
		status.Value = s.status ;
		flags.Value = s.flags ;
		try {
			sArgs[1] = uArgs[i+1] = (s.o).ToChars() ;
			sArgs[2] = status.ToChars() ;
			sArgs[3] = (s.c).ToChars() ;
			sArgs[4] = flags.IsLoaded() ? Yes : No ;
			sArgs[5] = flags.IsSuspend() ? Yes : No ;
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
	global	Object	go ;
			int		result ;
			char	sArgs[][] ;						// Send arguments
			char	msg[] ;

	go = ToOID( id->Content() ) ;
	if ( go == Where() ) msg = ForbiddenOp ;
	else {
		if ( op->IsEqual( O_Suspend ) ) result = Suspend( go ) ;
		else if ( op->IsEqual( O_Resume ) ) result = Resume( go ) ;
		else if ( op->IsEqual( O_Threads ) ) result = Threads( go ) ;
		msg = (result == 0) ? Done : NoSuchObject ;
	}
	length sArgs = 3 ;
	sArgs[0] = cwin ;
	sArgs[1] = msg ;
	sArgs[2] = True ;
	ExecProc( ProcPrint, sArgs ) ;
}

int
Suspend( global Object aObj )
{
	int			result = 0 ;
	DmOEntry	entry ;

	try {
		entry = DF->DmOGETENTRY( DC, aObj ) ;
	} except {
		default {
			debug( 0 , "%S::Suspend Error in DmOGETENTRY\n", Name ) ;
			raise ;
		}
	}

	try {
		DF->DmOSUSPEND( DC, entry ) ;
	} except {
		DebugException::Error( status ) {
			debug( 0 , "%S::Suspend Error in DmOSUSPEND\n", Name ) ;
			result = 1 ;
		}
		default {
			debug( 0 , "%S::Suspend Error in DmOSUSPEND\n", Name ) ;
			try {
				DF->DmORELENTRY( DC, entry ) ;
			} except {
				default {
					/* Nothing */
				}
			}
			raise ;
		}
	}

	try {
		DF->DmORELENTRY( DC, entry ) ;
	} except {
		default {
			debug( 0 , "%S::Suspend Error in DmORELENTRY\n", Name ) ;
			raise ;
		}
	}

	return( result ) ;
}

int
Resume( global Object aObj )
{
	int			result = 0 ;
	DmOEntry	entry ;

	try {
		entry = DF->DmOGETENTRY( DC, aObj ) ;
	} except {
		default {
			debug( 0 , "%S::Resume Error in DmOGETENTRY\n", Name ) ;
			raise ;
		}
	}

	try {
		DF->DmORESUME( DC, entry ) ;
	} except {
		DebugException::Error( status ) {
			debug( 0 , "%S::Resume Error in DmORESUME\n", Name ) ;
			result = 1 ;
		}
		default {
			debug( 0 , "%S::Resume Error in DmORESUME\n", Name ) ;
			try {
				DF->DmORELENTRY( DC, entry ) ;
			} except {
				default {
					/* Nothing */
				}
			}
			raise ;
		}
	}

	try {
		DF->DmORELENTRY( DC, entry ) ;
	} except {
		default {
			debug( 0 , "%S::Resume Error in DmORELENTRY\n", Name ) ;
			raise ;
		}
	}

	return( result ) ;
}

int
Threads( global Object  aObj )
{
	int		result = 0 ;
	ListObjectThread	LOT ;
	LOT => New() ;
	LOT->Launch( aObj ) ;
	return( result ) ;
}

global	Object
ToOID ( char id[] )
{
	global	Object	o ;
	inline "C" {
		char	*cp ;
		int		l, h ;
		cp = OZ_ArrayElement(id,char) ;
		l = OzStrtol( cp+8, 0, 16 ) ;
		*(cp+8) = 0 ;
		h = OzStrtol( cp, 0, 16 ) ;
		o = h ;
		o <<= 32 ;
		o |= l ;
	}
	return( o ) ;
}

} // End of file: ListObjectTable.oz
