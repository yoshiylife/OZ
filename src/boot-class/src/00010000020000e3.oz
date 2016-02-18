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
class ComInstanciate : LauncherCommand{
 constructor:
  New;
 protected:
  instanciate;
 public:
  Execute;

  /* Instance Variables */
  void @Proc;

  char MyName()[]{ return "Instanciate"; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    String name = args -> Car() -> AsString();
    args = args -> Cdr();

    if( name -> IsEqualToArrayOfChar( "Intrrupt" )){
inline "C"{
OzDebugf( "Intrrupted.\n" );
}
      kill Proc;
      return 0;
    }

    Proc = fork instanciate( le -> Search( narrow( SList, args -> Car())), name );
    detach Proc;
    return 0;
  }

  void instanciate( ProjectLinkSS link, String name ){
    String done => NewFromArrayOfChar( "done" );
    LauncherEvaluator le = MyEvaluator();

    try{
      link -> Instanciate( name );
    }
    except{
      LauncherExceptions::NotLaunchable{
        String err => NewFromArrayOfChar( "my_error \"The class must be a decendant of Launchable.\"" );
        le -> SendEvent( err );
        return;
      }
      LauncherExceptions::Duplicate{
        String err => NewFromArrayOfChar( "my_error \"This name is already used.\"" );
        le -> SendEvent( err );
      }
    }
    le -> SendEvent( done );
  }
  
}
