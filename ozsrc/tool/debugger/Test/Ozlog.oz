/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Viewer of ozlog file
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	Ozlog : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch
;
protected:	// Method
	Printer,
	WishWatcher,
	LogFile
;
protected:	// Instance
	Property
;
//------------------------------------------------------------------------------
//
//	Protected instance
//
char	Property[] ;	// Tcl/Tk script file name

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)

File		LogFile ;
UnixWish	Wish ;


//------------------------------------------------------------------------------
//
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "Ozlog" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	Property = "Ozlog.tcl" ;

	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Printer()
{
	System	sys ;
	int		ret ;
	char	buffer[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	length buffer = 1024 ;

	debug( 0, "%S::Printer() start\n", NAME ) ;

	try {
		for(;;) {
			if ( LogFile->FileNo() == 0 ) break ;
			ret = LogFile->Read( buffer, length buffer ) ;
			if ( ret == 0 ) sys.Sleep( 2 ) ;
			else if ( 0 < ret ) {
				try {
					Wish->Send( buffer, ret ) ;
				} except {
					default {
						/* Nothing */
					}
				}
			} else break ;
		}
	} except {
		default {
			/* Nothing */
		}
	}

	debug( 0, "%S::Printer() stop\n", NAME ) ;
}


void
WishWatcher()
{
	int		ret ;
	char	msg[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::WishWatcher() start\n", NAME ) ;

	try {
		ret = Wish->Watch() ;
		debug( 0, "%S::WishWatcher: Wish->Watch() = %d\n", NAME, ret ) ;
		inline "C" {
			msg = OzFormat( "Exited %d\n", ret ) ;
		}
	} except {
		ErrorException::ERROR( errno ) {
			System	sys ;
			char	err[] ;
			err = sys.Strerror( errno ) ;
			inline "C" {
				msg = OzFormat( "Error %S\n", err ) ;
			}
		}
		SignalException::SIGNAL( signo ) {
			System	sys ;
			char	sig[] ;
			sig = sys.Strsignal( signo ) ;
			inline "C" {
				msg = OzFormat( "Signal %S\n", sig ) ;
			}
		}
		default {
			msg = "Fatal unknown error\n" ;
		}
	}
	debug( 0, "%S::WishWatcher: %S", NAME, msg ) ;
	LogFile->Close() ;
	Wish->Quit() ;

	debug( 0, "%S::WishWatcher() stop\n", NAME ) ;
}

void
Launch()
{
	System	sys ;
	long	exid ;
	char	ozroot[] ;
	char	path[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;

	path = GetPropertyPathName( Property ) ;
	Wish => New( path ) ;
	detach fork WishWatcher() ;

	exid = Where()->ExecutorID() ;
	ozroot = sys.Getenv( "OZROOT" ) ;
	inline "C" {
		path = OzFormat( "%S/images/%06x/ozlog",
							ozroot, (int)((exid>>24)&0xffffff) ) ;
	}

	LogFile => Open( path, O::RDONLY, 0 ) ;

	detach fork Printer() ;

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: Ozlog.oz
