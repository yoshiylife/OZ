/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	List threads on global object
//
//	inherits:
//		Object
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
//		7.3jp/3.4jp(Pixmap)	ListObjectThread.tcl
//
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	ListObjectThread : GUI
{
constructor:
	New
;
public:	// To be managed by a Launcher
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

// Etc...
char	Yes[] ;
char	No[] ;
char	Done[] ;
char	True[] ;
char	Zero[] ;
char	Nothing[] ;
char	Error[] ;
char	ExceptionRaised[] ;
char	NoSuchObject[] ;
char	NoSuchOperation[] ;

global	Object	Target ;


//
// Public method
//
void
New()
{
	Name = "ListObjectThread" ;
	debug( 0, "%S::New()\n", Name ) ;

	Property = "ListObjectThread.tcl" ;

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
	O_Kill => NewFromArrayOfChar( "Kill" ) ;

	Yes = "Yes" ;
	No = "No" ;
	Done = " Done." ;
	True = "true" ;
	Zero = "0" ;
	Nothing = "Nothing." ;
	Error = "Error." ;
	ExceptionRaised = "Exception raised." ;
	NoSuchObject = "No such object." ;
	NoSuchOperation = "No such operation." ;

	debug( 0, "%S::New() return\n", Name ) ;
}

void
Launch( global Object aObj )
{
	char	args[][] ;
	char	script[] ;

	debug( 0, "%S::Launch()\n", Name ) ;

	script = GetPropertyPathName( Property ) ;
	debug( 0, "%S::Launch script = %S\n", Name, script ) ;

	Target = aObj ;
	DC => New() ;

	try {
		DC->Open( aObj ) ;
	} except {
		default {
			debug( 0 , "%S::Launch Can't Open DebugChannel\n", Name ) ;
			DC = 0 ;
			raise ;
		}
	}
	DF => New() ;

	length args = 1 ;
	args[0] = script ;
	if ( ! StartWish( args, ':', '|' ) ) {
		char	buf[] ;
		length args = 4 ;
		args[0] = "." ;
		args[1] = "List of Object's Thread" ;
		args[2] = "OThread" ;
		inline "C" {
			buf = OzFormat( "%O", aObj ) ;
		}
		args[3] = buf ;
		ExecProc( "LOT.Window", args ) ;
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
			DF = 0 ;
			if ( DC ) {
				DC->Close() ;
				DC = 0 ;
			}
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
		int		ret ;
		try {
			ret = ObjectSuspend( Target ) ;
			if ( ret ) {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = NoSuchObject ;
				sArgs[2] = True ;
				ExecProc( ProcPrint, sArgs ) ;
			} else {
				length sArgs = 1 ;
				sArgs[0] = cwin ;
				ExecProc( ProcList, sArgs ) ;
			}
		} except {
			default {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = ExceptionRaised ;
				sArgs[2] = True ;
				ExecProc( ProcPrint, sArgs ) ;
			}
		}
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
		try {
			int		ret ;
			ret = ObjectResume( Target ) ;
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = (ret == 0) ? Done : NoSuchObject ;
			sArgs[2] = True ;
			ExecProc( ProcPrint, sArgs ) ;
		} except {
			default {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = ExceptionRaised ;
				sArgs[2] = True ;
				ExecProc( ProcPrint, sArgs ) ;
			}
		}
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
	DmOEntry		entry ;
	DmTListSlot		slot[], s ;
	DmThreadStatus	status ;
		int			i ;

	try {
		entry = DF->DmOGETENTRY( DC, Target ) ;
	} except {
		default {
			debug( 0 , "%S::List Error in DmOGETENTRY\n", Name ) ;
			raise ;
		}
	}

	try {
		slot = DF->DmTLIST( DC, entry ) ;
	} except {
		default {
			debug( 0 , "%S::List Error in DmTLIST\n", Name ) ;
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
			debug( 0 , "%S::List Error in DmORELENTRY\n", Name ) ;
			raise ;
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
		try {
			char			buf[] ;
			unsigned int	t ;
					int		sc ;
			t = s.t ;
			inline "C" {
				buf = OzFormat( "0x%08x", t ) ;
			}
			sArgs[1] = uArgs[i+1] = buf ;
			sArgs[2] = status.ToChars() ;
			sc = s.suspend_count ;
			inline "C" {
				buf = OzFormat( "%d", sc ) ;
			}
			sArgs[3] = buf ;
			sArgs[4] = (s.pid).ToChars() ;
			sArgs[5] = (s.caller).ToChars() ;
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
Operate( char cwin[], String op, String tid )
{
	int				result ;
	unsigned int	t ;
	char			buf[] ;
	char			sArgs[][] ;						// Send arguments

	buf = tid->Content() ;
	inline "C" {
		char	*cp ;
		cp = OZ_ArrayElement(buf,char) ;
		t = OzStrtol( cp, 0, 16 ) ;
	}
	if ( op->IsEqual( O_Suspend ) ) result = Suspend( t ) ;
	else if ( op->IsEqual( O_Resume ) ) result = Resume( t ) ;
	else if ( op->IsEqual( O_Kill ) ) result = Kill( t ) ;

	length sArgs = 3 ;
	sArgs[0] = cwin ;
	if ( result < 0 ) sArgs[1] = NoSuchOperation ;
	else sArgs[1] = (result == 0) ? Done : Error ;
	sArgs[2] = True ;
	ExecProc( ProcPrint, sArgs ) ;
}

int
Suspend( unsigned int t )
{
	int		result = 0 ;
	try {
		DF->DmTSUSPEND( DC, t ) ;
	} except {
		default {
			debug( 0 , "%S::Suspend Error in DmTSUSPEND\n", Name ) ;
			result = 1 ;
		}
	}

	return( result ) ;
}

int
Resume( unsigned int t )
{
	int		result = 0 ;
	try {
		DF->DmTRESUME( DC, t ) ;
	} except {
		default {
			debug( 0 , "%S::Resume Error in DmTRESUME\n", Name ) ;
			result = 1 ;
		}
	}

	return( result ) ;
}

int
Kill( unsigned int t )
{
	int		result = -1 ;
/*
	try {
		DF->DmTKILL( DC, t ) ;
	} except {
		default {
			debug( 0 , "%S::Kill Error in DmTKILL\n", Name ) ;
			result = 1 ;
		}
	}

*/
	return( result ) ;
}

int
ObjectSuspend( global Object aObj )
{
	int			result = 0 ;
	DmOEntry	entry ;

	try {
		entry = DF->DmOGETENTRY( DC, aObj ) ;
	} except {
		default {
			debug( 0 , "%S::ObjectSuspend Error in DmOGETENTRY\n", Name ) ;
			raise ;
		}
	}

	try {
		DF->DmOSUSPEND( DC, entry ) ;
	} except {
		DebugException::Error( status ) {
			debug( 0 , "%S::ObjectSuspend Error in DmOSUSPEND\n", Name ) ;
			result = 1 ;
		}
		default {
			debug( 0 , "%S::ObjectSuspend Error in DmOSUSPEND\n", Name ) ;
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
			debug( 0 , "%S::ObjectSuspend Error in DmORELENTRY\n", Name ) ;
			raise ;
		}
	}

	return( result ) ;
}

int
ObjectResume( global Object aObj )
{
	int			result = 0 ;
	DmOEntry	entry ;

	try {
		entry = DF->DmOGETENTRY( DC, aObj ) ;
	} except {
		default {
			debug( 0 , "%S::ObjectResume Error in DmOGETENTRY\n", Name ) ;
			raise ;
		}
	}

	try {
		DF->DmORESUME( DC, entry ) ;
	} except {
		DebugException::Error( status ) {
			debug( 0 , "%S::ObjectResume Error in DmORESUME\n", Name ) ;
			result = 1 ;
		}
		default {
			debug( 0 , "%S::ObjectResume Error in DmORESUME\n", Name ) ;
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
			debug( 0 , "%S::ObjectResume Error in DmORELENTRY\n", Name ) ;
			raise ;
		}
	}

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

}
// End of file: ListObjectThread.oz
