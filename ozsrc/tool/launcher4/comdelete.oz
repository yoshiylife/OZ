/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
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
    
    
