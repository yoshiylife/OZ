/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class	TestDFE : DebuggerFrontendLaunchable
{
public:
	Initialize,
	Launch,
	Test
;

void
Test()
{
	debug( 0, "TestDFE::Test\n" ) ;
}

}
