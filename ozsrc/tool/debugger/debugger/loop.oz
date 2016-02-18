/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class TestLoopDebugMessage : Launchable
{
public:
	Initialize,
	Launch
;
protected:
	test
;

	int		count ;

void
Initialize()
{
	Input		input ;
	Number		number ;
	char		buf[] ;

	number=>New() ;
	input=>New( "TestLoopDebugMessage" ) ;
	buf = input->Get( "Loop Count" ) ;
	count = number->Integer( buf ) ;
	input->Delete() ;
}

void
test()
{
	int		i ;
	for ( i = 0 ; i < count ; i ++ ) {
		inline "C" {
			OzExecDebugMessage( 0LL, "TestLoopDebugMessage: Count = %d\n", i ) ;
		}
	}
}

void
Launch()
{
	int		cnt = count ;
	global ObjectManager	om ;
	om = Where() ;
	inline "C" {
		OzExecDebugMessage(om,"TestLoopDebugMessage: Begin Count = %d\n",cnt);
		OzExecDebugMessage(om,"TestLoopDebugMessage: ccid = %C\n",self);
	}
	join fork test() ;
	inline "C" {
		OzExecDebugMessage(om,"TestLoopDebugMessage: End   Count = %d\n",cnt);
	}
}

} // class TestLoopDebugMessage [loop.oz]
