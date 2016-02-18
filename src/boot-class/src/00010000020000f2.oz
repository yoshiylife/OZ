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
class ComMove : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Move"; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    ProjectLinkSS from;
    ProjectSS     parent;
    String s => New();

    from = le -> Search( narrow( SList, args -> Car()));
    if( from == 0 )
      raise LauncherExceptions::NotFound( args -> Car() -> AsString());
    if(( parent =  from -> GetParent()) == 0 )
      raise LauncherExceptions::IllegalCommand;

    parent -> ReleaseLink( from -> GetName());
    parent -> PutLink( args -> Cdr() -> Car() -> AsString(), from );

    le -> SendEvent( s );
    return 0;
  }
/*
  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    ProjectLinkSS from, to;
    ProjectSS parent, prj;
    SList to_list;

    from = le -> Search( narrow( SList, args -> Car()));
    if( from == 0 )
      raise LauncherExceptions::NotFound( args -> Car() -> AsString());
    if( from -> GetParent() == 0 )
      raise LauncherExceptions::IllegalCommand;

    to_list = narrow( SList, args -> Cdr() -> Car());
    to = le -> Search( to_list );
    if( to != 0 ){ 
      try{
        prj = narrow( ProjectSS, to );
      }
      except{
        NarrowFailed{
          raise LauncherExceptions::IllegalCommand;
        }
      }
      from -> GetParent() -> DeleteLink( from -> GetName() );
      prj -> PutLink( from -> GetName(), from );
    }
    else{ 
      SList to_parent => New();
      while( !to_list -> Cdr() -> IsNil()){
        to_parent -> Add( to_list -> Car());
        to_list = to_list -> Cdr();
      }
      try{
        prj = narrow( ProjectSS, le -> Search( to_parent ));
        if( prj == 0 )
          raise LauncherExceptions::IllegalCommand;
      }
      except{
        NarrowFailed{
          raise LauncherExceptions::IllegalCommand;
        }
      }
      from -> GetParent() -> DeleteLink( from -> GetName() );
      prj -> PutLink( to_list -> AsString(), from );
    }

    return 0;
  }
*/
}
    
