/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
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
