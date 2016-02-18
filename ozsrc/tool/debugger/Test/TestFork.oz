/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Fork too many process
//
//
class	TestFork : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch,
	Test
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
	NAME = "TestFork" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Test( int id )
{
	inline "C" {
		OzSleep( 2 ) ;
	}
	return ;
}

void
Fork( int n )
{
	int		i ;
	void	@p ;
	inline "C" {
		_oz_debug_flag =1 ;
	}
	try {
		for ( i = 0 ; i < n ; i ++ ) {
			p = fork Test( i ) ;
			detach p ;
		}
	} except {
		ForkFailed {
			debug( 0, "%S::Fork ForkFailed at %d.\n", NAME, i  ) ;
			debug( 0, "%S::Fork Test OK.\n", NAME ) ;
		}
	}
	return ;
}

void
Launch()
{
	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;
	Fork( 256 ) ;
	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestFork.oz
