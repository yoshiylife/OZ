/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger: Manage current working directory.
//
//	uses:
//		class	ObjectManager
//		class	NameDirectory
//		class	String
//		class	Set <String>
//		class	DirectoryServer<*>
//
// CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
class	CWDirectory<Directory, Entry>
{
constructor: 
	New
;
public:
	ChRoot,
	GetRoot,
	Getcwd,
	Chdir,
	ListEntry,
	ListDirectory,
	Retrieve
;
protected:	// Instance
	WorkServer,
	WorkPath
;
//------------------------------------------------------------------------------
//
//	Protected instance
//
global	Directory		WorkServer ;	// Current working server
		String			WorkPath ;		// Current working path

//------------------------------------------------------------------------------
//
//	Protected instance
//

//------------------------------------------------------------------------------
//	Constructor method
//
void
New( char aName[] )
{
	global	ObjectManager	OM ;
	global	NameDirectory	ND ;
	String	key ;

	OM = Where() ;
	ND = OM->GetNameDirectory() ;
	key => NewFromArrayOfChar( aName ) ;
	WorkServer = narrow( Directory, ND->Resolve( key ) ) ;
	WorkPath => NewFromArrayOfChar( "" ) ;
}

//------------------------------------------------------------------------------
//	Public method:	Change root directory server
//
int
ChRoot( global Directory aServer ) : locked
{
	WorkServer = aServer ;
	WorkPath => NewFromArrayOfChar( "" ) ;
	return( WorkServer->IsEmpty() ) ;
}

//------------------------------------------------------------------------------
//	Public method:	Get server of root directory
//
global Directory
GetRoot() : locked
{
	return( WorkServer ) ;
}

//------------------------------------------------------------------------------
//	Public method:	Get path name of current working directory
//
String
Getcwd() : locked
{
	String	ret ;
	if ( WorkPath->Length() == 0 ) ret => NewFromArrayOfChar( ":" ) ;
	else ret = WorkPath->Duplicate() ;
	return( ret ) ;
}

//------------------------------------------------------------------------------
//	Public method:	Change current working directory
//
String
Chdir( String name ) : locked
{
	String			path ;
	String			tmp ;
	int				pos ;
	int				len ;

	/* change to parent */
	if ( name == 0 ) {
		pos = WorkPath->StrRChr( ':' ) ;
		if ( pos <= 0 ) path => NewFromArrayOfChar( "" ) ;
		else path = WorkPath->GetSubString( 0, pos ) ;
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
					} else path = name->Duplicate() ;
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
				path = WorkPath->Concatenate( tmp )->Concatenate( name ) ;
				debug( 0, "change to child: '%S'\n", path->Content() ) ;
			}
		/* change to current */
		} else {
			path = WorkPath->Duplicate() ;
			debug( 0, "change to current: '%S'\n", path->Content() ) ;
		}
	}

	/* check */
	if ( WorkServer->IsaDirectory( path ) ) WorkPath = path->Duplicate() ;
	else path = 0 ;

	return( path ) ;
}

//------------------------------------------------------------------------------
//	Public method:	List of current working directory
//
Set <String>
ListEntry() : locked
{
	global	DirectoryServer <Entry>	DS = WorkServer ;
	return( DS->ListEntry( WorkPath ) ) ;
}

//------------------------------------------------------------------------------
//	Public method:	List of current working directory
//
Set <String>
ListDirectory() : locked
{
	global	DirectoryServer <Entry>	DS = WorkServer ;
	return( DS->ListDirectory( WorkPath ) ) ;
}

//------------------------------------------------------------------------------
//	Public method:	Retrieve a entry from current working directory
//
Entry
Retrieve( String name ) : locked
{
	global	DirectoryServer <Entry>	DS = WorkServer ;
	String	tmp, path ;
	Entry	entry ;
	int		pos ;

	debug( 0, "Retrieve %S", name->Content() ) ;
	pos = name->StrChr( ':' ) ;
	if ( pos <= 0 ) {
		if ( pos == 0 ) {
			path = name->Duplicate() ;
		} else {
			// buggy path->ConcatenateWithArrayOfChar( ":" ) ; ?
			tmp => NewFromArrayOfChar( ":" ) ;
			path = WorkPath->Concatenate( tmp )->Concatenate( name ) ;
		}
		entry = DS->Retrieve( path ) ;
	}

	return( entry ) ;
}

} // End of file: CWDirectory.oz
