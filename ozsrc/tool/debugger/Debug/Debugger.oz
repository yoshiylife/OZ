/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger
//
//	For global object.
//
//	inherits:
//		Object
//		ResolvableObject
//		Launchable
//
//	uses:
//		class	Object
//		class	String
//		class	ObjectManager
//		class	NameDirectory
//		shared	DirectoryExceptions
//
//	indirects:
//		class	SubString
//
inline "C" {
	extern	OZ_Array	OzFormat() ;
}
//
class	Debugger :
			ResolvableObject( rename New SuperNew ; ),
			Launchable	// for TEST
			
{
constructor:
	New
;
public:	// To be managed by a Launcher
	Initialize, Launch
;
public:	// To be managed by an ObjectManager
	Go, Removing, Stop, Flush
;
public:		// To be called by a client
	KeepAlive
;
protected:	// Instance
	NameDir, NameKey, OM, ND
;

//------------------------------------------------------------------------------
//
//	Protected Instance
//
String	NameDir ;
String	NameKey ;
global	ObjectManager	OM ;
global	NameDirectory	ND ;

//------------------------------------------------------------------------------
//	Private instance
//
char	NAME[] ;	// Class Name (Read only)
global	Debugger	aDebugger ;

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	inline "C" {
		_oz_debug_flag = 1 ;
	}

	NAME = "Debugger" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	aDebugger => New() ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by a Launcher
//
void
Launch()
{
	inline "C" {
		_oz_debug_flag = 1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;
	aDebugger->KeepAlive() ;
	debug( 0, "%S::Launch() return\n", NAME ) ;
}


//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
New() : global
{
	global	ResolvableObject	OBJ ;
	String	tmp ;
	long	exid ;
	char	buf[] ;

	inline "C" {
		_oz_debug_flag = 1 ;
	}

	NAME = "Debugger" ;
	debug( 0, "%S::New()\n", NAME ) ;
	debug( 0, "%S::New oid = %O\n", NAME, oid ) ;
	NameDir => NewFromArrayOfChar( ":Debuggers" ) ;
	OM = Where() ;
	ND = OM->GetNameDirectory() ;

	exid = OM->ExecutorID() ;
	inline "C" {
		buf = OzFormat( ":%06x", (int)(exid>>24) & 0x0ffffff ) ;
	}
	tmp => NewFromArrayOfChar( buf ) ;
	NameKey = NameDir->Duplicate()->Concatenate( tmp ) ;

	SuperNew() ;

	// Create directory if such directory not exist.
	// Check & Register myself to NameDirectory
	try {
		OBJ = ND->Resolve( NameKey ) ;
	} except {
		DirectoryExceptions::UnknownDirectory( nameDir ) {
			debug( 0, "%S::New Make '%S'.\n", NAME, nameDir->Content() ) ;
			ND->NewDirectory( nameDir ) ;
			OBJ = 0 ;
		}
	}
	if ( OBJ == 0 ) {
		debug( 0, "%S::New Regist %O to '%S'.\n", NAME,oid,NameKey->Content()) ;
		ND->AddObject( NameKey, oid ) ;
		OM->PermanentizeObject( oid ) ;
	} else if ( OBJ != oid ) {
		debug( 0, "%S::New Replace %O with %O.\n", NAME, OBJ, oid ) ;
		ND->ChangeObject( NameKey, oid ) ;
		OM->PermanentizeObject( oid ) ;
		try {
			if ( OM->Lookup( OBJ ) {
				OM->RemoveObject( OBJ ) ;
			}
		} except {
			default {
				/* Nothing */
			}
		}
	}

	try {
		Go() ;
	} except {
		default {
			debug( 0, "%S::New Go() failure.\n", NAME ) ;
		}
	}

	debug( 0, "%S::New() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Go() : global
{
	global	ResolvableObject	OBJ ;

	inline "C" {
		_oz_debug_flag = 1 ;
	}

	OM = Where() ;
	ND = OM->GetNameDirectory() ;

	debug( 0, "%S::Go()\n", NAME ) ;
	try {
		OBJ = ND->Resolve( NameKey ) ;
	} except {
		default {
			OBJ = 0 ;
		}
	}
	if ( OBJ == oid ) {
		debug( 0, "%S::Go Progress\n", NAME ) ;
	}
	debug( 0, "%S::Go() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Removing() : global
{
	inline "C" {
		_oz_debug_flag = 1 ;
	}

	debug( 0, "%S::Removing()\n", NAME ) ;

	try {
		Stop() ;
	} except {
		default {
			debug( 0, "%S::Removing Stop() failure.\n", NAME ) ;
		}
	}

	debug( 0, "%S::Removing() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Stop() : global
{
	global	ResolvableObject	OBJ ;

	inline "C" {
		_oz_debug_flag = 1 ;
	}

	debug( 0, "%S::Stop()\n", NAME ) ;
	// Remove myself from NameDirectory
	try {
		if ( ND->Resolve( NameKey ) == oid ) {
			ND->RemoveObjectWithName( NameKey ) ;
			OM->AddPreloadingObject( oid ) ;
		}
	} except {
		default {
			/* Nothing */
		}
	}
	debug( 0, "%S::Stop() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Flush() : global
{
	inline "C" {
		_oz_debug_flag = 1 ;
	}

	debug( 0, "%S::Flush()\n", NAME ) ;
	debug( 0, "%S::Flush ...\n", NAME ) ;
	debug( 0, "%S::Flush() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method: Test to keep alive
//
global Object
KeepAlive() : global
{
	inline "C" {
		_oz_debug_flag = 1 ;
	}

	debug( 0, "%S::KeepAlive()\n", NAME ) ;

	debug( 0, "%S::KeepAlive oid = %O\n", NAME, oid ) ;

	debug( 0, "%S::KeepAlive() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method
//

//------------------------------------------------------------------------------
//	Protected method
//

}
// End of file: Debugger.oz
