/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class LauncherCommand : Command ( alias New SuperNew; ){
 protected:
  MyEvaluator;
 protected:
  MyName, Execute;
 constructor:
  New;

  /* instance variabels */
  LauncherEvaluator LE;

  /* constructors for sub classes */
  void New( LauncherEvaluator l ){ 
    LE = l;
    SuperNew();
  }

  /* protected methods */
  /* service to sub classes */
  LauncherEvaluator MyEvaluator(){ return LE; }
}
