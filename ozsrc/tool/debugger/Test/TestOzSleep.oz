/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test OzSleep()
//
//
class	TestOzSleep : Launchable
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
	NAME = "TestOzSleep" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Sleep( int s )
{
		inline "C" {
			OzSleep( s ) ;
		}
}

void
Test()
{
	int		i ;
	int		n = 60 * 3 ;
	void	@p ;
	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Test %P Start\n", NAME, p ) ;
	for ( i = 0 ; i < n ; i ++ ) {
		Sleep( 1 ) ;
		debug( 0, "%S::Test %P %d/%d\n", NAME, p, i, n ) ;
	}
	debug( 0, "%S::Test %P Finish\n", NAME, p ) ;
	return ;
}

void
Launch()
{
	void	@p ;
	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;
	p = fork Test() ;
	detach p ;
	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestOzSleep.oz
