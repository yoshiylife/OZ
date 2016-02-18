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
class ComCopy : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Copy"; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    ProjectLinkSS from;
    SList to_list;
    ProjectSS parent;

    from = le -> Search( narrow( SList, args -> Car()));
    
    to_list = narrow( SList, args -> Cdr() -> Car());
    if(( parent = le -> Search( to_list ) -> GetParent()) == 0 )
      raise LauncherExceptions::IllegalCommand;

    while( !to_list -> Cdr() -> IsNil()){
      to_list = to_list -> Cdr();
    }
    parent -> PutLink( to_list -> Car() -> AsString(), from -> Clone());
    le -> SendEvent( 0 );
    return 0;
  }
}
    
