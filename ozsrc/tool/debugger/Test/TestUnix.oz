/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	TestUnix is testing for Unix/
//
//	inherits:
//		Launchable
//
//	used:
//		class	Unix:UnixShell
//		class	Unix:UnixWish
//		shared	Unix:SIGNAL
//		shared	Unix:ErrorException
//		shared	Unix:SignalException
//		record	Unix:System
//
//	Tcl/Tk:
//		7.3jp/3.4jp(Pixmap)	TestUnix.tcl
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	TestUnix : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch
;
protected:	// Method
	Error,
	Printer,
	WishWatcher,
	ShellWatcher
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

UnixShell	Shell ;
UnixWish	Wish ;


//------------------------------------------------------------------------------
//
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestUnix" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;

	Property = "TestUnix.tcl" ;

	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Printer()
{
	int		ret ;
	char	buffer[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	length buffer = 1024 ;

	debug( 0, "%S::Printer() start\n", NAME ) ;

	try {
		for(;;) {
			ret = Shell->Recv( buffer, length buffer ) ;
			if ( 0 < ret ) {
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
Error()
{
	int		ret ;
	char	buffer[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Error() start\n", NAME ) ;
	length buffer = 1024 ;
	try {
		while(1) {
			ret = Shell->Catch( buffer, 1024 ) ;
			if ( 0 < ret ) Wish->Send( buffer, ret ) ;
			else break ;
		}
	} except {
		default {
			/* Nothing */
		}
	}
	debug( 0, "%S::Error() stop\n", NAME ) ;
}

void
ShellWatcher()
{
	int		ret ;
	char	msg[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::ShellWatcher() start\n", NAME ) ;

	try {
		ret = Shell->Watch() ;
		debug( 0, "%S::ShellWatcher: Shell->Watch() = %d\n", NAME, ret ) ;
		if ( ret ) {
			inline "C" {
				msg = OzFormat( "Exited %d\n", ret ) ;
			}
		} else {
			msg = 0 ;
			Wish->Kill( SIGNAL::SIGTERM ) ;
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
	if ( msg ) {
		debug( 0, "%S::ShellWatcher: %S", NAME, msg ) ;
		try {
			Wish->Send( msg, length msg -1 ) ;
		} except {
			default {
				/* Nothing */
			}
		}
	}
	Shell->Quit() ;

	debug( 0, "%S::ShellWatcher() stop\n", NAME ) ;
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
	try {
		Shell->Kill( SIGNAL::SIGHUP ) ;
	} except {
		default {
			/* Nothing */
		}
	}
	Wish->Quit() ;

	debug( 0, "%S::WishWatcher() stop\n", NAME ) ;
}

void
Launch()
{
	int		ret ;
	int		err ;
	int		i, n ;
	char	buffer[] ;
	char	msg[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;

	buffer = GetPropertyPathName( Property ) ;
	Wish => New( buffer ) ;
	detach fork WishWatcher() ;

	Shell => New( "/bin/sh" ) ;
	// Shell => New( "/usr/local/gdb-4.15.1/gdb/gdb" ) ;
	detach fork ShellWatcher() ;

	detach fork Printer() ;

	detach fork Error() ;

	length buffer = 1024 ;
	try {
		for(;;) {
			ret = Wish->Recv( buffer, length buffer ) ;
			if ( 0 < ret ) {
				Shell->Send( buffer, ret ) ;
				buffer[0] = '\n' ;
				ret = 1 ;
				try {
					Shell->Send( buffer, ret ) ;
				} except {
					default {
						/* Nothing */
					}
				}
			} else break ;
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
	debug {
		if ( msg ) debug( 0, "%S::Launcher: %S", NAME, msg ) ;
	}

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestUnix.oz
