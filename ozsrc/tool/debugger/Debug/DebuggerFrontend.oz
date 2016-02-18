/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger Frontend (and for local objet)
//
//	Tcl/Tk(7.3/3.4): DebuggerFrontend.tcl
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	DebuggerFrontend : Launchable, GUI
{
public:
	Initialize,
	Launch
;

//
//	Protected instance
//
char	Property[] ;	// Tcl/Tk script file name
char	PropertyCB[] ;
char	WinTop[] ;


//
//	Private instance
//
char	Name[] ;		// Class Name (Read only)

// Event from Tcl/Tk
char	EventDFE_Ready[] ;
char	EventDFE_Update[] ;
char	EventDFE_Launcher[] ;
char	EventDFE_Message[] ;
char	EventDFE_Exception[] ;
char	EventDFE_Quit[] ;
char	EventDFE_Select[] ;

char	EventCB_Ready[] ;
char	EventCB_Select[] ;
char	EventCB_Chdir[] ;

// Tcl/Tk procedure
char	ProcDFE_Enable[] ;
char	ProcDFE_Disable[] ;
char	ProcDFE_Print[] ;
char	ProcDFE_Update[] ;
char	ProcCB_Update[] ;
char	ProcExit[] ;

// Etc...
char	Done[] ;
char	True[] ;
char	Zero[] ;

global	ObjectManager	OM ;
CatalogBrowser	CB ;
Package			CP ;
String	PackageName ;

//
//	Public method
//

void
Initialize()
{
	Name = "DebuggerFrontend" ;
	debug( 0, "%S::Initialize()\n", Name ) ;

	Property = "DebuggerFrontend.tcl" ;
	PropertyCB = "CatalogBrowser.tcl" ;
	WinTop = "." ;

	EventDFE_Ready = "DFE.Ready" ;
	EventDFE_Update = "DFE.Update" ;
	EventDFE_Launcher = "DFE.Launcher" ;
	EventDFE_Message = "DFE.Message" ;
	EventDFE_Exception = "DFE.Excepton" ;
	EventDFE_Select = "DFE.Select" ;
	EventDFE_Quit = "DFE.Quit" ;
	EventCB_Ready = "CB.Ready" ;
	EventCB_Select = "CB.Select" ;
	EventCB_Chdir = "CB.Chdir" ;

	ProcDFE_Enable = "DFE.Enable" ;
	ProcDFE_Disable = "DFE.Disable" ;
	ProcDFE_Print = "DFE.Print" ;
	ProcDFE_Update = "DFE.Update" ;
	ProcCB_Update = "CB.Update" ;
	ProcExit = "Exit" ;

	Done = " Done." ;
	True = "true" ;
	Zero = "0" ;

	OM = Where() ;
	CB => New() ;
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
		long	exid ;
		char	buf[] ;
		exid = Where()->ExecutorID() ;
		inline "C" {
			buf = OzFormat( "%016lx", exid ) ;
		}
		length args = 4 ;
		args[0] = WinTop ;
		args[1] = "OZ++ Debugger Frontend" ;
		args[2] = "DFE" ;
		args[3] = buf ;
		ExecProc( "DFE.Window", args ) ;
	}

	debug( 0, "%S::Launch() return\n", Name ) ;
}


//
//	class GUI
//	Override protected method

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
			debug( 0, "%S::ReadEvent [%d]='%S'\n",Name,i,rArgs[i]->Content() );
		}
	}
	if ( rArgs ) cwin = rArgs[0]->Content() ;
	else cwin = 0 ;

	if ( CommandIs( EventDFE_Ready ) ) {
		char	script[] ;
		script = GetPropertyPathName( PropertyCB ) ;
		debug( 0, "%S::ReadEvent script = %S\n", Name, script ) ;
		length sArgs = 1 ;
		sArgs[0] = script ;
		ExecProc( "Source", sArgs ) ;
	} else if ( CommandIs( EventDFE_Update ) ) {
		Update( cwin, rArgs[1] ) ;
	} else if ( CommandIs( EventDFE_Select ) ) {
		Object		o ;
		Launchable	obj ;
		global ConfiguredClassID	ccid ;
				String				name ;
		name => NewFromArrayOfChar( rArgs[1]->Content() ) ;
		ccid = 0 ;
		if ( CP ) {
			global VersionID			vid ;
			global Class		c ;
					School				school ;
				ArchitectureID	aid ;
			try {
				ConfigurationTable	config ;
				school = CP->GetSchool() ;
				config = CP->GetConfigurationTable() ;
				vid = school->VersionIDOf( name ) ;
				ccid = (config != 0 ) ? config->Lookup( vid ) : 0 ;
				if ( ccid == 0 ) ccid = OM->GetConfiguredClassID( vid, 0 ) ;
			} except {
				default {
					/* Nothing */
				}
			}
		}
		if ( ccid == 0 ) {
			length sArgs = 3 ;
			sArgs[0] = cwin ;
			sArgs[1] = "ConfiguredClassID Not found." ;
			sArgs[2] = "true" ;
			ExecProc( ProcDFE_Print, sArgs ) ;
		} else {
			inline "C" {
				OZ_Object	_obj = OzExecAllocateLocalObject( ccid ) ;
				o = _obj - _obj->head.e ;
			}
			try {
				obj = narrow( Launchable, o ) ;
				length sArgs = 3 ;
				sArgs[0] = cwin ;
				sArgs[1] = "Ok." ;
				sArgs[2] = True ;
				ExecProc( ProcDFE_Print, sArgs ) ;
			} except {
				default {
					length sArgs = 3 ;
					sArgs[0] = cwin ;
					sArgs[1] = "Not Launchable." ;
					sArgs[2] = True ;
					ExecProc( ProcDFE_Print, sArgs ) ;
				}
			}
		}
		length sArgs = 1 ;
		sArgs[0] = cwin ;
		ExecProc( ProcDFE_Enable, sArgs ) ;
	} else if ( CommandIs( EventDFE_Launcher ) ) {
//		DebuggerLauncher	dl ;
//		if ( length rArgs <= 2 ) {
//			dl => New( 0, 0 ) ;
//			detach fork dl->Launch() ;
//			length sArgs = 3 ;
//			sArgs[0] = cwin ;
//			sArgs[1] = "Done." ;
//			sArgs[2] = "true" ;
//			ExecProc( ProcDFE_Print, sArgs ) ;
//		} else {
//				dl => New( rArgs[1], rArgs[2] ) ;
//				detach fork dl->Launch() ;
//				length sArgs = 3 ;
//				sArgs[0] = cwin ;
//				sArgs[1] = "Done." ;
//				sArgs[2] = "true" ;
//				ExecProc( ProcDFE_Print, sArgs ) ;
//		}
	} else if ( CommandIs( EventDFE_Message ) ) {
//		DebuggerMessageCapture	mc ;
//		mc=>New() ;
//		detach fork mc->Launch() ;
//		length sArgs = 3 ;
//		sArgs[0] = cwin ;
//		sArgs[1] = "Done." ;
//		sArgs[2] = "true" ;
//		ExecProc( ProcDFE_Print, sArgs ) ;
	} else if ( CommandIs( EventDFE_Exception ) ) {
//		DebuggerExceptionCapture	ec ;
//		ec=>New() ;
//		detach fork ec->Launch() ;
//		length sArgs = 3 ;
//		sArgs[0] = cwin ;
//		sArgs[1] = "Done." ;
//		sArgs[2] = "true" ;
//		ExecProc( ProcDFE_Print, sArgs ) ;
	} else if ( CommandIs( EventCB_Ready ) ) {
		String	path ;
		path = CB->Getcwd() ;
		sArgs = List( path ) ;
		sArgs[0] = cwin ;
		sArgs[1] = path->Content() ;
		ExecProc( ProcCB_Update, sArgs ) ;
	} else if ( CommandIs( EventCB_Select ) ) {
		Update( WinTop, rArgs[1] ) ;
	} else if ( CommandIs( EventCB_Chdir ) ) {
		sArgs = List( rArgs[1] ) ;
		sArgs[0] = cwin ;
		sArgs[1] = CB->Getcwd()->Content() ;
		ExecProc( ProcCB_Update, sArgs ) ;
	} else if ( CommandIs( EventDFE_Quit ) ) result = 1 ;

	try {
		abortable ;
	} except {
		default {
			result =1 ;
		}
	}

	if ( result ) {
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

void
Update( char cwin[], String path )
{
	char	args[][] ;

	try {
		CP = CB->Retrieve( path ) ;
		args = Type( CP->GetSchool() ) ;
		args[0] = cwin ;
		args[1] = path->Content() ;
		ExecProc( ProcDFE_Update, args ) ;
		length args = 3 ;
		args[0] = cwin ;
		args[1] = Done ;
		args[2] = True ;
		ExecProc( ProcDFE_Print, args ) ;
	} except {
		default {
			char	buf[], p[] ;
			length args = 1 ;
			args[0] = cwin ;
			ExecProc( ProcDFE_Update, args ) ;
			p = path->Content() ;
			inline "C" {
				buf = OzFormat( "School %S is not found.", p ) ;
			}
			length args = 2 ;
			args[0] = cwin ;
			args[1] = buf ;
			ExecProc( ProcDFE_Print, args ) ;
		}
	}
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
		dirs = CB->Chdir( path ) ;
		schs = CB->List() ;
		lenDirs = ( dirs == 0 ) ? 0 : length dirs ;
		lenSchs = ( schs == 0 ) ? 0 : length schs ;
		debug ( 0, "%V::List lenDirs:%d, lenSchs:%d\n",self,lenDirs,lenSchs ) ;
		length ret = 3 + lenDirs + lenSchs ;
		index = 0 ;
		index ++ ; /* for cwin */ ;
		tmp = CB->Getcwd() ;
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
			ret[1] = CB->Getcwd()->Content() ;
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

} // End of file: DebuggerFrontend.oz
