/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger: School directory browser.
//
// CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
class	DebuggerSchoolDirectoryBrowser
{
constructor: 
	New
;
public:
	Getcwo,
	Getcwd,
	Chdir,
	List,
	Retrieve
;

	global	ObjectManager			OM ;
	global	NameDirectory			ND ;
	global	PhysicalSchoolDirectory	PSD ;
			String					CWD ;

void
New()
{
	String	key ;
	OM = Where() ;
	ND = OM->GetNameDirectory() ;
	key => NewFromArrayOfChar( "school" ) ;
	PSD = narrow( PhysicalSchoolDirectory, ND->Resolve( key ) ) ;
	CWD => NewFromArrayOfChar( "" ) ;
}

global Object
Getcwo()
{
	return( PSD ) ;
}

String
Getcwd()
{
	String	ret ;
	if ( CWD->Length() == 0 ) ret => NewFromArrayOfChar( ":" ) ;
	else ret => NewFromArrayOfChar( CWD->Content() ) ;
	return( ret ) ;
}

String
Chdir( String name )[]
{
	Set <String>	sets ;
	String			dirs[] ;
	String			path ;
	String			tmp ;
	int				pos ;
	int				len ;

	/* change to parent */
	if ( name == 0 ) {
		pos = CWD->StrRChr( ':' ) ;
		if ( pos <= 0 ) path => NewFromArrayOfChar( "" ) ;
		else path = CWD->GetSubString( 0, pos ) ;
		debug( 0, "change to parent: '%S'\n", path->Content() ) ;
	} else {
		len = name->Length() ;
		if ( len ) {
			/* change to root or abs path*/
			if ( name->At(0) == ':' ) {
				/* root */
				if ( len == 1 ) {
					path => NewFromArrayOfChar( "" ) ;
					debug( 0, "change to root: '%S'\n", path->Content() ) ;
				/* abs */
				} else {
					/* trim right */
					pos = name->StrRChr( ':' ) ;
					if ( 0 < pos && (pos + 1) == len ) {
						path = name->GetSubString( 0, pos ) ;
					} else path => NewFromArrayOfChar( name->Content() ) ;
					debug( 0, "change to abs: '%S'\n", path->Content() ) ;
				}
			/* change to child */
			} else {
				/* trim right */
				pos = name->StrRChr( ':' ) ;
				if ( 0 < pos && (pos + 1) == len ) {
					name = name->GetSubString( 0, pos ) ;
				}
				// buggy path->ConcatenateWithArrayOfChar( ":" ) ; ?
				tmp => NewFromArrayOfChar( ":" ) ;
				path = CWD->Concatenate( tmp )->Concatenate( name ) ;
				debug( 0, "change to child: '%S'\n", path->Content() ) ;
			}
		/* change to current */
		} else {
			path => NewFromArrayOfChar( CWD->Content() ) ;
			debug( 0, "change to current: '%S'\n", path->Content() ) ;
		}
	}

	/* check & retrieve */
	sets = PSD->ListDirectory( path ) ;
	dirs = sets->AsArray() ;
	CWD => NewFromArrayOfChar( path->Content() ) ;

	return( dirs ) ;
}

String
List()[]
{
	Set <String>	sets ;
	String			dirs[] ;

	sets = PSD->ListSchool( CWD ) ;
	dirs = sets->AsArray() ;
	return( dirs ) ;
}

School
Retrieve( String name )
{
	String	tmp, path ;
	School	school ;
	int		pos ;

	debug( 0, "Retrieve %S", name->Content() ) ;
	pos = name->StrChr( ':' ) ;
	if ( pos <= 0 ) {
		if ( pos == 0 ) {
			path => NewFromArrayOfChar( name->Content() ) ;
		} else {
			// buggy path->ConcatenateWithArrayOfChar( ":" ) ; ?
			tmp => NewFromArrayOfChar( ":" ) ;
			path = CWD->Concatenate( tmp )->Concatenate( name ) ;
		}
		school = PSD->Retrieve( path ) ;
	}

	return( school ) ;
}

} // class DebuggerSchoolDirectoryBrowser [sdb.oz]
