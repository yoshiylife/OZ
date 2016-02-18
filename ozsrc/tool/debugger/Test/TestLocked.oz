/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Test OZ_Monitor & OZ_Condition
//
//
class	TestLocked : Launchable
{
public:	// To be managed by a Launcher
	Initialize,
	Launch,
	Producer,
	Consumer,
	Demon
;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;		// Class Name (Ready only)
condition		full ;
condition		empty ;
unsigned int	count ;
unsigned int	nbuff ;

//------------------------------------------------------------------------------
//
//	Public method to be managed by a Launcher
//
void
Initialize()
{
	NAME = "TestLocked" ;
	debug( 0, "%S::Initialize()\n", NAME ) ;
	debug( 0, "%S::Initialize() return\n", NAME ) ;
}

void
put() : locked
{
	while( count == nbuff ) wait full ;
	if ( count ++ == 0 ) signalall empty ;
}

void
get() : locked
{
	while( count == 0 ) wait empty ;
	if ( count -- == nbuff ) signalall full ;
}

unsigned int
look() : locked
{
	return( count ) ;
}

void
Producer( unsigned int n )
{
	unsigned int	i ;
			void	@p ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Producer Start[%P]\n", NAME, p ) ;
	try {
		for ( i = 1 ; i <= n ; i ++ ) {
			put() ;
			if ( i % 10 == 0 ) {
				debug( 0, "%S::Producer [%P] %u/%u\n", NAME, p, i, n ) ;
			}
			abortable ;
		}
	} except {
		Abort {
			debug( 0, "%S::Producer Abort[%P]\n", NAME, p ) ;
		}
	}
	debug( 0, "%S::Producer Finish[%P]\n", NAME, p ) ;
	return ;
}

void
Consumer( unsigned int n )
{
	unsigned int	i ;
			void	@p ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Consumer Start[%P]\n", NAME, p ) ;
	try {
		for ( i = 1 ; i <= n ; i ++ ) {
			get() ;
			if ( i % 10 == 0 ) {
				debug( 0, "%S::Consumer [%P] %u/%u\n", NAME, p, i, n ) ;
			}
			abortable ;
		}
	} except {
		Abort {
			debug( 0, "%S::Consumer Abort[%P]\n", NAME, p ) ;
		}
	}
	debug( 0, "%S::Consumer Finish[%P]\n", NAME, p ) ;
	return ;
}

void
Demon()
{
	void	@p ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Demon Start[%P]\n", NAME, p ) ;
	try {
		for(;;) {
			look() ;
			abortable ;
		}
	} except {
		Abort {
			debug( 0, "%S::Demon Abort[%P]\n", NAME, p ) ;
		}
	}
	debug( 0, "%S::Demon Finish[%P]\n", NAME, p ) ;
}

void
Launch()
{
	void	@p1 ;
	void	@p2 ;
	void	@c1 ;
	void	@c2 ;
	void	@d ;

	inline "C" {
		_oz_debug_flag =1 ;
	}

	debug( 0, "%S::Launch()\n", NAME ) ;
	count = 0 ;
	nbuff = 5 ;
	p1 = fork Producer( 1000 ) ;
	c1 = fork Consumer( 1000 ) ;
	p2 = fork Producer( 1000 ) ;
	c2 = fork Consumer( 1000 ) ;
	d = fork Demon() ;
	join p1 ;
	join p2 ;
	join c1 ;
	join c2 ;
	kill d ;
	join d;
	if ( count ) debug( 0, "%S::Launch Test NG\n", NAME ) ;
	debug( 0, "%S::Launch() return\n", NAME ) ;
}

}
// End of file: TestLocked.oz
