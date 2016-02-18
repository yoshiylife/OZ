/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
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
