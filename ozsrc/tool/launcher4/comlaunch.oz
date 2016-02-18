/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComLaunch : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Launch"; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    ProjectLinkSS link = le -> Search( narrow( SList, args ));
    detach fork link -> Launch();
    le -> SendEvent( 0 );
    return 0;
  }
}
