/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test for long type
//	1. join a process that return long
//	2. join a process that return int
//	3. call a method with agument which type is int by long
//
//
class	TestLong : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch,
	ReturnLong,
	ReturnInt,
	CallWithInt
;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)

//------------------------------------------------------------------------------
//
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestLong" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

long
ReturnLong( long ret )
{
	return( ret ) ;
}

int
ReturnInt( int ret )
{
	return( ret ) ;
}

int
CallWithInt( int a )
{
	inline "C" {
		_oz_debug_flag =1 ;
	}
	debug( 0, "%S::CallWithInt( %d )\n", NAME, a ) ;
	return( a ) ;
}

void
Launch()
{
	long	@proc_long ;
	int		@proc_int ;
	long	value_long ;
	int		value_int ;
	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;

	// Test 1.
	debug( 0, "%S::proc_long = fork ReturnLong(1234567890123456LL)\n", NAME ) ;
	proc_long = fork ReturnLong(1234567890123456LL) ;
	value_long = join proc_long ;
	debug( 0, "%S::join proc_long = %ld\n", NAME, value_long ) ;

	// Test 2.
	debug( 0, "%S::proc_int = fork ReturnInt(123456789)\n", NAME ) ;
	proc_int = fork ReturnInt(123456789) ;
	value_int = join proc_int ;
	debug( 0, "%S::join proc_int = %d\n", NAME, value_int ) ;

	// Test 3.
	debug( 0, "%S::value_int = CallWithInt( 12345678LL )\n", NAME );
	value_int = CallWithInt( 12345678LL ) ;
	debug( 0, "%S::value_int = %d\n", NAME, value_int ) ;

	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestLong.oz
