/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComShutdown : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Shutdown"; }

  int Execute( SList args ){
    Where() -> Shutdown();
    return 1; // finish
  }
}

