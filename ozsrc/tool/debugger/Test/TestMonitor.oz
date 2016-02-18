/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test OZ_Monitor
//
//
class	TestMonitor : Launchable
{
constructor:
	New
;
public:	// To be managed by a Launcher
	Initialize,
	Launch,
	Loop
;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)
unsigned int		count ;

//------------------------------------------------------------------------------
//
//	Constructor
//
void
New()
{
	Initialize() ;
}

//------------------------------------------------------------------------------
//
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestMonitor" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	count = 0 ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

unsigned int
look() : locked
{
	return( ++ count ) ;
}

void
Loop()
{
	void			@p ;
	unsigned int	ret ;

	inline "C" {
		_oz_debug_flag = 0 ;
	}

	debug( 0, "%S::Demon Start[%P]\n", NAME, p ) ;
	try {
		for(;;) {
			ret = look() ;
			if ( ret % 1000 == 0 ) {
				debug( 0, "%S::Loop [%P] look() = %u\n", NAME, p, ret ) ;
			}
			abortable ;
		}
	} except {
		Abort {
			debug( 0, "%S::Loop Abort[%P]\n", NAME, p ) ;
		}
	}
	debug( 0, "%S::Demon Finish[%P]\n", NAME, p ) ;
}

void
Launch()
{
	int			i ;
	void		@(ps[]) ;
	TestMonitor	tm[] ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	length ps = 40 ;
	length tm = 10 ;
	debug( 0, "%S::Launch()\n", NAME ) ;
	for ( i = 0 ; i < 10 ; i ++ ) {
		tm[i] => New() ;
		tm[i]->Initialize() ;
	}
	for ( i = 0 ; i < 40 ; i ++ ) {
		ps[i] = fork tm[i/4]->Loop() ;
	}
	inline "C" {
		OzSleep( 30 ) ;
	}
	for ( i = 0 ; i < 40 ; i ++ ) {
		kill ps[i] ;
	}
	for ( i = 0 ; i < 40 ; i ++ ) {
		join ps[i] ;
	}
	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestMonitor.oz
