/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger: User I/F
//	
// CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
class	T : GUI, Launchable
{
constructor:
	New
;
public:
	Initialize,
	Launch
;
protected:	/* instance */
	aWish
;

	int		aWish ;

void Initialize() : locked
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
ReadEvent()
{
	String	args[] ;
	inline "C" {
		OzExecDebugMessage( 0LL, "ReadEvent()\n" ) ;
	}
	args = RecvCommandArgs () ;
	if ( CommandIs( "Quit" ) ) {
		ExecProc( "Quit", 0 ) ;
		Quit() ;
		return( 1 ) ;
	}
	return( 0 ) ;
}

void
Launch()
{
	char	args[][] ;

	debug( default, "%V: Launch() begin\n", self ) ;
	length args = 1 ;
	args[0] = "lib/gui/debugger/test.tcl" ;
	StartWish( args, ':', '|' ) ;
	ExecProc( "Main", 0 ) ;
	debug( default, "%V: Launch() end\n", self ) ;
}

} // class T [t.oz]
