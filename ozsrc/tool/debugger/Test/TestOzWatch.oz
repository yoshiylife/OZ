/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test OzWatch()
//
//
class	TestOzWatch : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch,
	Watch
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
	NAME = "TestOzWatch" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
Watch( int fd )
{
	int		ret ;
	int		status ;

	inline "C" {
	    _oz_debug_flag = 1 ;
	}

	inline "C" {
		ret = OzWatch( fd, &status ) ;
	}
	debug( 0, "%S::Watch( %d ) = %d, status = %d\n", NAME, fd, ret, status ) ;
}

void
Test1()
{
	void	@p ;
	int		fd ;
	int		ret ;

	inline "C" {
	    _oz_debug_flag = 1 ;
	}

	debug( 0, "%S::Test1 Start(%P)\n", NAME, p ) ;
	inline "C" {
		char	*argv[3] ;
		argv[0] = "OZ++(sleep)" ;
		argv[1] = "10" ;
		argv[2] = NULL ;
		fd = OzVspawn( "sleep", argv ) ;
	}
	if ( 0 < fd ) {
		void	@p ;
		p = fork Watch( fd ) ;
		inline "C" {
			OzSleep( 2 ) ;
		}
		inline "C" {
			ret = OzKill( fd, 0 ) ;
		}
		debug( 0, "%S::Test1 OzKill( %d, 0 ) = %d\n", NAME, fd, ret ) ;
		inline "C" {
			ret = OzKill( fd, 15 ) ;
		}
		debug( 0, "%S::Test1 OzKill( %d, 15 ) = %d\n", NAME, fd, ret ) ;
		inline "C" {
			ret = OzKill( fd, 0 ) ;
		}
		debug( 0, "%S::Test1 OzKill( %d, 0 ) = %d\n", NAME, fd, ret ) ;
		inline "C" {
			OzClose( fd ) ;
		}
		join p ;
	}
	debug( 0, "%S::Test1 Finish(%P)\n", NAME, p ) ;
}

void
Test2()
{
	void	@p ;
	int		fd ;
	int		ret ;

	inline "C" {
	    _oz_debug_flag = 1 ;
	}

	debug( 0, "%S::Test2 Start(%P)\n", NAME, p ) ;
	inline "C" {
		char	*argv[3] ;
		argv[0] = "OZ++(sleep)" ;
		argv[1] = "10" ;
		argv[2] = NULL ;
		fd = OzVspawn( "sleep", argv ) ;
	}
	if ( 0 < fd ) {
		void @p ;
		p = fork Watch( fd ) ;
		inline "C" {
			OzSleep( 2 ) ;
		}
		inline "C" {
			ret = OzClose( fd ) ;
		}
		debug( 0, "%S::Test2 OzClose( %d ) = %d\n", NAME, fd, ret ) ;
		join p ;
	}
	debug( 0, "%S::Test2 Finish(%P)\n", NAME, p ) ;
}

void
Launch()
{
	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;
	Test1() ;
	Test2() ;
	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestOzWatch.oz
