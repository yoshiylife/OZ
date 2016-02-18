/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger Frontend Launchable.	(and for local objet)
//
//		Tcl/Tk(7.3/3.4): $OZROOT/lib/gui/debugger/dfe.tcl
//
// CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
class	Debugger.FrontendLaunchable : GUI, Launchable
{
constructor:
	New
;
public:
	Initialize,
	Launch
;

	/* Name of command from Tck/TK */
	char	CmdNameDFE_Ready[] ;
	char	CmdNameDFE_Update[] ;
	char	CmdNameDFE_Launcher[] ;
	char	CmdNameDFE_Message[] ;
	char	CmdNameDFE_Exception[] ;
	char	CmdNameDFE_Quit[] ;
	char	CmdNameDFE_Select[] ;
	char	CmdNameSDB_Chdir[] ;

	/* Name of procdure of Tck/Tk */
	char	ProcNameDFE_New[] ;
	char	ProcNameDFE_Launcher[] ;
	char	ProcNameDFE_Print[] ;
	char	ProcNameDFE_Update[] ;
	char	ProcNameSDB_Update[] ;
	char	ProcNameExit[] ;

	String	StrOfExID ;
	DebuggerSchoolDirectoryBrowser	SD ;
	School	CurrentSchool ;

void
Initialize() : locked
{
	global	ObjectManager	om ;
	char	id[] ;

	debug( 0, "%V: Initialize()\n", self ) ;

	om = Where() ;
	length id = 17 ;
	inline "C" {
		char	buf[32] ;
		OzSprintf( buf, "%O", om ) ;
		OzStrcpy( OZ_ArrayElement(id,char), buf ) ;
	}
	StrOfExID => NewFromArrayOfChar( id ) ;
	CmdNameDFE_Ready = "DFE.Ready" ;
	CmdNameDFE_Update = "DFE.Update" ;
	CmdNameDFE_Launcher = "DFE.Launcher" ;
	CmdNameDFE_Message = "DFE.Message" ;
	CmdNameDFE_Exception = "DFE.Excepton" ;
	CmdNameDFE_Select = "DFE.Select" ;
	CmdNameDFE_Quit = "DFE.Quit" ;
	CmdNameSDB_Chdir = "SDB.Chdir" ;

	ProcNameDFE_New = "DFE.New" ;
	ProcNameDFE_Launcher = "DFE.Launcher" ;
	ProcNameDFE_Print = "DFE.Print" ;
	ProcNameDFE_Update = "DFE.Update" ;
	ProcNameSDB_Update = "SDB.Update" ;
	ProcNameExit = "Exit" ;

	SD => New() ;

}

void
New()
{
	debug( 0, "%V: New()\n", self ) ;
	Initialize() ;
}

char
List( String path )[][]
{
	char	ret[][] ;
	String	delimiter ;
	String	tmp ;
	String	dirs[] ;
	String	schs[] ;
	int		index ;
	int		lenDirs ;
	int		lenSchs ;
	int		i ;

	delimiter => NewFromArrayOfChar( ":" ) ;
	try {
		dirs = SD->Chdir( path ) ;
		schs = SD->List() ;
		lenDirs = ( dirs == 0 ) ? 0 : length dirs ;
		lenSchs = ( schs == 0 ) ? 0 : length schs ;
		debug ( 0, "%V::List lenDirs:%d, lenSchs:%d\n",self,lenDirs,lenSchs ) ;
		length ret = 3 + lenDirs + lenSchs ;
		index = 0 ;
		index ++ ; /* for cwin */ ;
		tmp = SD->Getcwd() ;
		ret[index++] = tmp->Content() ;
		for ( i = 0 ; i < lenDirs ; i ++ ) {
			tmp = dirs[i]->Concatenate(delimiter) ;
			ret[index++] = tmp->Content() ;
			debug ( 0, "%V::List dirs[%d]:%S\n",self,i,ret[index-1] ) ;
		}
		for ( i = 0 ; i < lenSchs ; i ++ ) {
			ret[index++] = schs[i]->Content() ;
			debug ( 0, "%V::List schs[%d]:%S\n",self,i,ret[index-1] ) ;
		}
	} except {
		default {
			length ret = 2 ;
			ret[1] = SD->Getcwd()->Content() ;
		}
	}

	return( ret ) ;
}

char
Type( School aSchool )[][]
{
	String					name ;
	Set	<String>			names ;
	Iterator <String>		handle ;
	//SortableSet <String>	sortedNames ;
	Set <String>			sortedNames ;
	char					ret[][] ;
	int						index ;
	int						part ;

	names = aSchool->ListNames() ;

	/* Select name of ordinary class */
	handle => New( names ) ;
	sortedNames => New() ;
	while ( (name=names->DoNext( handle )) != 0 ) {
		debug( 0, "DFE::Type name=%S\n", name->Content() ) ;
		part = aSchool->KindOf( name ) ;
		if ( part == 0 ) {									/* ordinary class */
			if ( name->StrChr( '<' ) < 0 ) {
				sortedNames->Add( name ) ;
			}
		}
	}
	// sortedNames->DoReset( handle ) ;

	length ret = sortedNames->Size() + 2 ;
	index = 0 ;
	index ++ ; /* for cwin */
	index ++ ; /* for path */
	handle => New( sortedNames ) ;
	while ( (name=sortedNames->DoNext( handle )) != 0 ) {
		ret[index++] = name->Content() ;
	}
	return( ret ) ;
}

int
ReadEvent()
{
	String	recvArgs[] ;								// Received arguments
	char	sendArgs[][] ;								// Send arguments
	char	cwin[] ;									// A current window path

	debug( 0, "%V: ReadEvent()\n", self ) ;

	recvArgs = RecvCommandArgs () ;
	if ( recvArgs ) cwin = recvArgs[0]->Content() ;
	else cwin = 0 ;
	if ( CommandIs( CmdNameDFE_Update ) ) {
		try {
			CurrentSchool = SD->Retrieve( recvArgs[1] ) ;
			sendArgs = Type( CurrentSchool ) ;
			sendArgs[0] = cwin ;
			sendArgs[1] = recvArgs[1]->Content() ;
			ExecProc( ProcNameDFE_Update, sendArgs ) ;
			length sendArgs = 3 ;
			sendArgs[0] = cwin ;
			sendArgs[1] = "Done." ;
			sendArgs[2] = "true" ;
			ExecProc( ProcNameDFE_Print, sendArgs ) ;
		} except {
			default {
				String	path, tmp1, tmp2 ;
				length sendArgs = 1 ;
				sendArgs[0] = cwin ;
				ExecProc( ProcNameDFE_Update, sendArgs ) ;
				tmp1 => NewFromArrayOfChar( "School " ) ;
				tmp2 = tmp1->Concatenate( recvArgs[1] ) ;
				tmp1 => NewFromArrayOfChar( " not found." ) ;
				path = tmp2->Concatenate( tmp1 ) ;
				length sendArgs = 2 ;
				sendArgs[0] = cwin ;
				sendArgs[1] = path->Content() ;
				ExecProc( ProcNameDFE_Print, sendArgs ) ;
			}
		}
	} else if ( CommandIs( CmdNameDFE_Select ) ) {
		global VersionID		pid ;
			String				name ;
		name => NewFromArrayOfChar( recvArgs[1]->Content() ) ;
		pid = 0 ;
		if ( CurrentSchool ) {
			global Class		c ;
			global VersionID	vid ;
				ArchitectureID	aid ;
			try {
				aid => Any () ;
				vid = CurrentSchool->VersionIDOf( name ) ;
				c = Where()->SearchClass( vid, aid ) ;
				pid = c->GetPublicPart( vid ) ;
			} except {
				default {
					/* Nothing */
				}
			}
		}
		if ( pid == 0 ) {
			length sendArgs = 3 ;
			sendArgs[0] = cwin ;
			sendArgs[1] = "school not found." ;
			sendArgs[2] = "true" ;
			ExecProc( ProcNameDFE_Print, sendArgs ) ;
		} else {
			length sendArgs = 3 ;
			sendArgs[0] = cwin ;
			sendArgs[1] = recvArgs[1]->Content() ;
			sendArgs[2] = ToChars( pid ) ;
			ExecProc( ProcNameDFE_Launcher, sendArgs ) ;
		}
	} else if ( CommandIs( CmdNameDFE_Launcher ) ) {
		DebuggerLauncher	dl ;
		if ( length recvArgs <= 2 ) {
			dl => New( 0, 0 ) ;
			detach fork dl->Launch() ;
			length sendArgs = 3 ;
			sendArgs[0] = cwin ;
			sendArgs[1] = "Done." ;
			sendArgs[2] = "true" ;
			ExecProc( ProcNameDFE_Print, sendArgs ) ;
		} else {
				dl => New( recvArgs[1], recvArgs[2] ) ;
				detach fork dl->Launch() ;
				length sendArgs = 3 ;
				sendArgs[0] = cwin ;
				sendArgs[1] = "Done." ;
				sendArgs[2] = "true" ;
				ExecProc( ProcNameDFE_Print, sendArgs ) ;
		}
	} else if ( CommandIs( CmdNameDFE_Message ) ) {
		DebuggerMessageCapture	mc ;
		mc=>New() ;
		detach fork mc->Launch() ;
		length sendArgs = 3 ;
		sendArgs[0] = cwin ;
		sendArgs[1] = "Done." ;
		sendArgs[2] = "true" ;
		ExecProc( ProcNameDFE_Print, sendArgs ) ;
	} else if ( CommandIs( CmdNameDFE_Exception ) ) {
		DebuggerExceptionCapture	ec ;
		ec=>New() ;
		detach fork ec->Launch() ;
		length sendArgs = 3 ;
		sendArgs[0] = cwin ;
		sendArgs[1] = "Done." ;
		sendArgs[2] = "true" ;
		ExecProc( ProcNameDFE_Print, sendArgs ) ;
	} else if ( CommandIs( CmdNameDFE_Quit ) ) {
		length sendArgs = 1 ;
		sendArgs[0] = "0" ;
		ExecProc( ProcNameExit, sendArgs ) ;
		Quit() ;
		return( 1 ) ;
	} else if ( CommandIs( CmdNameSDB_Chdir ) ) {
		String	path ;
		if ( length recvArgs <= 1 ) path = 0 ;
		else path = recvArgs[1] ;
		sendArgs = List( path ) ;
		sendArgs[0] = cwin ;
		ExecProc( ProcNameSDB_Update, sendArgs ) ;
	}
	return( 0 ) ;
}

void
Launch()
{
			char			args[][] ;
			char			sendArgs[][] ;

	debug( 0, "%V::Launch() begin\n", self ) ;

	length args = 1 ;
	args[0] = "lib/gui/debugger2/dfe.tcl" ;
	if ( ! StartWish( args, ':', '|' ) ) {
		length sendArgs = 2 ;
		sendArgs[0] = ".dfe" ;
		sendArgs[1] = StrOfExID->Content() ;
		ExecProc( "DFE.Main", sendArgs ) ;
	}

	debug( 0, "%V::Launch() end\n", self ) ;

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

} // class DebuggerFrontendLaunchable [dfe.oz]
