/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class LauncherEvaluator : Evaluator {
 constructor:
  New;
 public:
  Spawn, EventLoop, GetOText;
 public:
  GetCurrentProject, SendEvent, Search, Change;

  /* instance variables */
  ProjectSS Root;
  ProjectSS Current;

  /* constructors */
  void New(){
    Parser1 par => New();
    NewWithParser( par );

    Root => New();
    Current = Root;
  }

  /* called as super class */
  void Initialize(){
    ComGetCurrent c1 => New( self );
    ComGetSub c2 => New( self );
    ComCreate c3 => New( self );
    ComLaunch c4 => New( self );
    ComChange c5 => New( self );
    ComDelete c6 => New( self );
    ComGetCid c7 => New( self );
    ComImport c8 => New( self );
    ComMove c9 => New( self );
    ComFlush c10 => New( self );
    ComShutdown c11 => New( self );
    ComCatalog c12 => New( self );

    PutCommand( c1 );
    PutCommand( c2 );
    PutCommand( c3 );
    PutCommand( c4 );
    PutCommand( c5 );
    PutCommand( c6 );
    PutCommand( c7 );
    PutCommand( c8 );
    PutCommand( c9 );
    PutCommand( c10 );
    PutCommand( c11 );
    PutCommand( c12 );
  }

  /* public methods */
  void SendEvent( String rec ){
    OText sock = GetOText();
    if( rec == 0 )
      rec => New();
rec -> DebugPrint();        
    sock -> PutLine( rec );
    sock -> FlushBuf();
  }

  ProjectSS GetCurrentProject(){ return Current; }

  ProjectLinkSS Search( SList list ){
    if( list -> Car() -> AsString() -> IsEqualToArrayOfChar( "~" ))
      return Root -> Search( list -> Cdr());

    return Current -> Search( list );
  }

  void Change( SList path ){
    Current = narrow( ProjectSS, Search( path ));
  }

}
