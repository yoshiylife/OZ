/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger: Exception capture.
//	
// CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
class	DebuggerExceptionCapture : Launchable
{
constructor:
	New
;
public:
	Initialize,
	Launch,
	Start,
	Watch
;
protected:	/* instance */
	aWish
;

	int		aWish ;

void
Initialize() : locked
{
	aWish = 0 ;
	debug( default, "%V: Initialize()\n", self ) ;
}

void
New()
{
	Initialize() ;
	debug( default, "%V: New()\n", self ) ;
}

int
Watch() : locked
{
	int		wish = aWish ;
	int		ret ;
	int		status ;

	if ( wish ) {
		inline "C" {
			ret = OzWatch( wish, &status ) ;
		}
		//debug( default, "%V: OzWatch() = %d, status = %d\n", self, ret, status ) ;
		debug( default, "%V: OzWatch()", self ) ;
		debug( default, " = %d", ret ) ;
		debug( default, ", status = %d\n", status ) ;
		inline "C" {
			OzSetCaptureException( -1 ) ;
			OzClose( wish ) ;
		}
	} else ret = -1 ;
	aWish = 0 ;
	//debug( default, "%V: Watch() = %d\n", self, ret ) ;
	debug( default, "%V: Watch()", self ) ;
	debug( default, " = %d\n", ret ) ;

	return( ret ) ;
}

int
Start() : locked
{
 global	ObjectManager	om ;
		int				wish ;
		int				ret ;

	om = Where() ;
	aWish = 0 ;

	inline "C" {
		char	*argv[4] ;
		argv[0] = "wish" ;
		argv[1] = "-f" ;
		argv[2] = "../../lib/gui/debugger2/exception.tcl" ;
		argv[3] = NULL ;
		wish = OzVspawn( "wish", argv ) ;
	}
	if ( wish < 0 ) {
		//debug( default, "%V: OzVspawn() = %d\n", self, wish ) ;
		debug( default, "%V: OzVspawn()", self ) ;
		debug( default, " = %d\n", wish ) ;
		//debug( default, "%V: Start() = %d\n", self, wish ) ;
		debug( default, "%V: Start()", self ) ;
		debug( default, " = %d\n", wish ) ;
		return( wish ) ;
	}
	inline "C" {
		char	buf[32] ;
		OzSprintf( buf, "%O\n", om ) ;
		OzWrite( wish, buf, OzStrlen(buf) ) ;
		ret = OzSetCaptureException( wish ) ;
	}
	if ( ret < 0 ) {
		//debug( default, "%V: OzSetCaptureException() = %d\n", self, ret ) ;
		debug( default, "%V: OzSetCaptureException()", self ) ;
		debug( default, " = %d\n", ret ) ;
		inline "C" {
			OzWrite( wish, "quit\n", 5 ) ;
			OzClose( wish ) ;
		}
		//debug( default, "%V: Start() = %d\n", self, ret ) ;
		debug( default, "%V: Start()", self ) ;
		debug( default, " = %d\n", ret ) ;
		return( ret ) ;
	}

	aWish = wish ;
	//debug( default, "%V: Start() = %d\n", self, wish ) ;
	debug( default, "%V: Start()", self ) ;
	debug( default, " = %d\n", wish ) ;
	return( wish ) ;
}

void
Launch()
{
		int				wish ;
		int				ret ;

	debug( default, "%V: Launch() begin\n", self ) ;
	if ( aWish ) {
		debug( default, "%V: Launch() Already launched\n", self ) ;
	} else {
		if ( Start() > 0 ) detach fork Watch() ;
	}
	debug( default, "%V: Launch() end\n", self ) ;
}

} // class DebuggerExceptionCapture [exception.oz]
