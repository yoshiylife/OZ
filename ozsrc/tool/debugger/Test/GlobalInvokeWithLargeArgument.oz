/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Global invoke with large argument test.
//
class TestGlobalInvokeWithLargeArgument : Launchable, ResolvableObject
{
constructor:
	New
;
public:	/* for Local */
	Initialize,
	Launch
;
public:	/* for Global */
	Invoke,
	Go
;
protected:	/* Method */
	Start,
	Test
;

	char	Name[] ;	/* Class Name */

	/* for Launchable */
	int		ArgSize ;		/* Argument size */
	int		RetSize ;		/* Retrun size */
	Lock	P_Lock ;		/* Mutex for instance variable: Process */
	int		@Process ;		/* Process of recursive global invoke */

	global	TestGlobalInvokeWithLargeArgument	Self ;

	//char	Gomi[] ;		/* Test for object image decode */

void
New() : global
{
	Name = "TestGlobalInvokeWithLargeArgument" ;
	debug( 0, "%S::New()\n", Name ) ;
	Self = oid ;
	debug( 0, "%S::New() return\n", Name ) ;
}

void
Go() : global
{
	debug( 0, "%S::Go()\n", Name ) ;
	debug( 0, "%S::Go() return\n", Name ) ;
}

char
Invoke( int aSize, char aData[] )[] : global
{
	int		len ;
	char	result[] ;
	len = (aData == 0) ? 0 : length aData ;
	debug( 0, "%S::Invoke( length aData=%d )\n", Name, len ) ;
	//Gomi = aData ;
	length result = aSize ;
	len = length result ;
	debug( 0, "%S::Invoke() length result = %d\n", Name, len ) ;
	return( result ) ;
}

void
Initialize()
{
	Number	number ;
	Input	input ;
	char	buf[] ;
	long	id ;
	int		a, r ;
	global	TestGlobalInvokeWithLargeArgument	o ;

	number => New() ;
	input => New( "TestGlobalInvokeWithLargeArgument" ) ;
	buf = input->Get( "Argument Size" ) ;
	a = ArgSize = number->Integer( buf ) ;
	buf = input->Get( "Return Size" ) ;
	r = RetSize = number->Integer( buf ) ;
	buf = input->Get( "Target OID" ) ;
	id = number->Long( buf ) ;
	input->Delete() ;

	if ( id == 0 ) {
		Self => New() ;
		o = Self ;
		inline "C" {
			OzDebugf( "New OID = %O\n", o ) ;
			id = o ;
		}
		Where()->PermanentizeObject( o ) ;
	} else {
		inline "C" {
			o = id ;
		}
		Self = o ;
	}

	inline "C" {
		OzDebugf( "Target:%O ArgSize:%d RetSize:%d\n", id, a, r ) ;
	}

	P_Lock => New() ;
}

long
Start()
{
	long	result ;
	char	args[] ;
	char	rets[] ;
	length args = ArgSize ;
	rets = Self->Invoke( RetSize, args ) ;
	result = length rets ;
	inline "C" {
		OzDebugf( "result = %ld\n", result ) ;
	}
	return( -1 ) ;
}

void
Test() : locked
{
	long		ret ;

	debug( 0, "%S::Test()\n", Name ) ;
	P_Lock->Lock() ;
	try {
		Process = fork Start() ;
	} except {
		default {
			Process = 0 ;
		}
	}
	P_Lock->UnLock() ;
	if ( Process ) {
		try {
			ret = join Process ;
			debug( 0, "%S::Test @Process = %ld\n", Name, ret ) ;
			inline "C" {
				OzDebugf( "@Process = %ld\n", ret ) ;
			}
		} except {
			default {
				/* nothing */
			}
		}
		P_Lock->Lock() ;
		Process = 0 ;
		P_Lock->UnLock() ;
	}
	debug( 0, "%S::Test() return\n", Name ) ;
}

void
Launch()
{
	debug( 0, "%S::Launch()\n", Name ) ;
	P_Lock->Lock () ;
	if ( Process == 0 ) {
		detach fork Test() ;
	} else {
		debug( 0, "%S::Test Process=%P\n", Name, Process ) ;
	}
	P_Lock->UnLock () ;
	debug( 0, "%S::Launch() return\n", Name ) ;
}

} // End of file: TestGlobalInvokeWithLargeArgument.oz
