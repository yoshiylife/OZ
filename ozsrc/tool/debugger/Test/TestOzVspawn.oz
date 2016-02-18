/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test OzVspawn()
//
//
class	TestOzVspawn : Launchable
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
	NAME = "TestOzVspawn" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Test()
{
		void	@p ;
		int		i ;

	inline "C" {
	    _oz_debug_flag = 1 ;
	}
	debug( 0, "%S::Test %P Start\n", NAME, p ) ;
	for ( i = 1 ; i <= 1000 ; i ++ ) {
		inline "C" {
			char	*argv[3] ;
			int		fd ;
			argv[0] = "OZ++(sleep)" ;
			argv[1] = "2" ;
			argv[2] = NULL ;
			fd = OzVspawn( "sleep", argv ) ;
			OzClose( fd ) ;
		}
		if ( i % 100 == 0 ) {
			debug( 0, "%S::Test %d/1000 OzSleep( 3 ) \n", NAME, i ) ;
			inline "C" {
				OzSleep( 3 ) ;
			}
		}
	}
	debug( 0, "%S::Test %P Finish\n", NAME, p ) ;
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
// End of file: TestOzVspawn.oz
