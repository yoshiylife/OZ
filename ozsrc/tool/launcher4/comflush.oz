/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComFlush : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Flush"; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();

    if( Where() -> IsPermanentObject( cell ))
      cell -> Flush();
    le -> SendEvent( 0 );
    return 0;
  }
}
