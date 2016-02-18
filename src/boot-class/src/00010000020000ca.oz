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
class ComDelete : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Delete"; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    ProjectSS parent;
    Linkable  e;

    for( e = args -> Car(); !e -> IsNil(); args = args -> Cdr(), e = args -> Car()){
      SList path = narrow( SList, e );
      if(( parent = le -> Search( path ) -> GetParent()) == 0 )
        raise LauncherExceptions::IllegalCommand;

      while( !path -> Cdr() -> IsNil()){
        path = path -> Cdr();
      }
      parent -> DeleteLink( path -> Car() -> AsString());
    }
    le -> SendEvent( 0 );
    return 0;
  }
}
    
    
