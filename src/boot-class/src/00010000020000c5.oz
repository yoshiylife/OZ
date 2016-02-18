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
class ComCreate : LauncherCommand{
 constructor:
  New;
 protected:
  instanciate;
 public:
  Execute;

  /* Instance Variables */
  void @Proc;

  char MyName()[]{ return "Create"; }

  /* (Create type path name) */
  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    int type;
    SList path;
    String name;
    ProjectLinkSS link;
    ProjectSS new_prj;
    LaunchableHolderSS new_obj;
    CIDHolderSS new_class;
    unsigned long id;
    String done => NewFromArrayOfChar( "done" );

    type = narrow( Atom, args -> Car()) -> AsInteger();
    args = args -> Cdr();
    path= narrow( SList, args -> Car());
    args = args -> Cdr();
    name = args -> Car() -> AsString();
    link = le -> Search( path );
    args = args -> Cdr();

    switch( type ){
    case 0:
      try{
        new_prj => New();
        link -> PutLink( name, new_prj );
        le -> SendEvent( 0 );
      }
      except{
        LauncherExceptions::Duplicate{
          String err => NewFromArrayOfChar( "#This name is already used." );
          le -> SendEvent( err );
        }
      }        
      break;

      case 1:
        if( name -> IsEqualToArrayOfChar( "***" )){
          inline "C"{
            OzDebugf( "Intrrupted.\n" );
          }
          kill Proc;
          return 0;
        }

        id = narrow( Atom, args -> Car()) -> AsHexa();
        Proc = fork instanciate( link, id, name );
        detach Proc;
        break;

      case 2:
      try{
        id = narrow( Atom, args -> Car()) -> AsHexa();
        new_class => New( id );
        link -> PutLink( name, new_class );
        le -> SendEvent( done );
      }
      except{
        LauncherExceptions::Duplicate{
          String err => NewFromArrayOfChar( "#This name is already used." );
          le -> SendEvent( err );
        }
      }        
      break;

    }
    return 0;
  }

    void instanciate( ProjectLinkSS link, long id, String name ){
      String done => NewFromArrayOfChar( "done" );
      LauncherEvaluator le = MyEvaluator();
      LaunchableHolderSS new_obj;

      try{
        new_obj => New( id );
        link -> PutLink( name, new_obj );
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
