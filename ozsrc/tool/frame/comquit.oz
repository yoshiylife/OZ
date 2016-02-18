/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComFrameQuit : CommandFor<Series> {
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Quit"; }

  int Execute( SList args ){
    Client -> Quit();
    return 1;
  }
}
