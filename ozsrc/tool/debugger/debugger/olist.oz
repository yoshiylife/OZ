/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	List of object(global)
//
class TestListObject : Launchable, GUI
{
public:
	Initialize,
	Launch
;

	global	ObjectManager	OM ;
		ObjectStatusName	OSN ;
				char		Name[] ;
				String		StrOfExID ;

				char		CmdUpdate[] ;
				char		CmdSuspend[] ;
				char		CmdResume[] ;
				char		CmdFlush[] ;
				char		CmdQuit[] ;
				char		PrcPrint[] ;
				char		PrcAppend[] ;
				char		PrcNormal[] ;
				char		PrcClear[] ;
				char		PrcUpdate[] ;
				char		PrcExit[] ;

				char		Yes[] ;
				char		No[] ;

void
Initialize()
{
	char	id[] ;
	global	Object	o ;

	Name = "TestListObject" ;
	debug( 0, "%S::Initialize()\n", Name ) ;

	o = OM = Where() ;
	length id = 17 ;
	inline "C" {
		char	buf[32] ;
		OzSprintf( buf, "%O", o ) ;
		OzStrcpy( OZ_ArrayElement(id,char), buf ) ;
	}
	StrOfExID => NewFromArrayOfChar( id ) ;

	CmdUpdate = "OLS.Update" ;
	CmdSuspend = "OLS.Suspend" ;
	CmdResume = "OLS.Resume" ;
	CmdFlush = "OLS.Flush" ;
	CmdQuit = "OLS.Quit" ;
	PrcPrint = "OLS.Print" ;
	PrcAppend = "OLS.Append" ;
	PrcNormal = "OLS.Normal" ;
	PrcClear = "OLS.Clear" ;
	PrcUpdate = "OLS.Update" ;
	PrcExit = "Exit" ;

	Yes = "Yes" ;
	No = "No" ;
}

int
ReadEvent()
{
	String	rArgs[] ;									// Received arguments
	char	sArgs[][] ;									// Send arguments
	char	cwin[] ;									// A current window path
	int		i, n ;

	debug( 0, "%S::ReadEvent()\n", Name ) ;

	rArgs = RecvCommandArgs () ;
	debug {
		n = length rArgs ;
		for ( i = 0 ; i < n ; i ++ ) {
			debug( 0, "%S::ReadEvent [%d]='%S'\n",Name,i,rArgs[i]->Content() ) ;
		}
	}
	if ( rArgs ) cwin = rArgs[0]->Content() ;
	else cwin = 0 ;
	if ( CommandIs( CmdUpdate ) ) {
		global	Object	objects[], o ;
				int		i, n ;
		objects = OM->ListObjects() ;
		n = length objects ;
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( PrcClear, sArgs ) ;
		length sArgs = 6 ;
		sArgs[0] = cwin ;
		for ( i = 0 ; i < n ; i ++ ) {
			try {
			sArgs[1] = ToChars( objects[i] ) ;
			sArgs[2] = OSN.Name( OM->WhichStatus( objects[i] ) ) ;
			sArgs[3] = OM->IsPermanentObject( objects[i] ) ? Yes : No ;
			sArgs[4] = OM->IsSuspendedObject( objects[i] ) ? Yes : No ;
			sArgs[5] = OM->WasSafelyShutdown( objects[i] ) ? Yes : No ;
			ExecProc( PrcAppend, sArgs ) ;
			} except {
				/* nothing */
			}
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( PrcNormal, sArgs ) ;
	} else if ( CommandIs( CmdSuspend ) ) {
		try {
			OM->SuspendObject( ToOID(rArgs[1]->Content()) ) ;
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = "Done." ;
			sArgs[2] = "true" ;
			ExecProc( PrcPrint, sArgs ) ;
			length sArgs = 1 ;
			sArgs[0] = cwin ;
			ExecProc( PrcUpdate, sArgs )  ;
		} except {
			default {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = "Error." ;
				sArgs[2] = "true" ;
				ExecProc( PrcPrint, sArgs ) ;
			}
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( PrcNormal, sArgs ) ;
	} else if ( CommandIs( CmdResume ) ) {
		try {
			OM->ResumeObject( ToOID(rArgs[1]->Content()) ) ;
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = "Done." ;
			sArgs[2] = "true" ;
			ExecProc( PrcPrint, sArgs ) ;
			length sArgs = 1 ;
			sArgs[0] = cwin ;
			ExecProc( PrcUpdate, sArgs )  ;
		} except {
			default {
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = "Error." ;
				sArgs[2] = "true" ;
				ExecProc( PrcPrint, sArgs ) ;
			}
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( PrcNormal, sArgs ) ;
	} else if ( CommandIs( CmdQuit ) ) {
		length sArgs = 1 ;
		sArgs[0] = "0" ;
		ExecProc( PrcExit, sArgs ) ;
		Quit() ;
		return( 1 ) ;
	}
	return( 0 ) ;
}

void
Launch()
{
	char	args[][] ;
	char	sArgs[][] ;

	debug( 0, "%S::Launch()\n", Name ) ;

	length args = 1 ;
	args[0] = "lib/gui/debugger2/ols.tcl" ;
	if ( ! StartWish( args, ':', '|' ) ) {
		length sArgs = 2 ;
		sArgs[0] = ".olist" ;
		sArgs[1] = StrOfExID->Content() ;
		ExecProc( "OLS.Start", sArgs ) ;
	}

	debug( 0, "%S::Launch()\n", Name ) ;
}

char
ToChars( global Object aObject )[]
{
	char	id[] ;
	length id = 17 ;
	inline "C" {
		char	buf[32] ;
		OzSprintf( buf, "%O", aObject ) ;
		OzStrcpy( OZ_ArrayElement(id,char), buf ) ;
	}
	return( id ) ;
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

} // class TestListObject [ols.oz]
