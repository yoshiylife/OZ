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
/*
  Copyright (c) 1994 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ProjectSS : ProjectLinkSS( alias Gather SGather; ){
 constructor: New;
 public: Search, Gather, PutLink, DeleteLink, ExistLink, ReleaseLink,
  Clone, Fullname, GetSubs;

  Dictionary<String,ProjectLinkSS> Subs;

  void New(){ Type = 0; Subs => New(); }

  ProjectLinkSS Search( SList list ){
    Atom car;
    SList cdr;
    ProjectLinkSS target;
    Atom dot => NewFromArrayOfChar( "." );
    Atom dotdot => NewFromArrayOfChar( ".." );

    car = narrow( Atom, list -> Car());
    if( car -> IsNil())
      return self;

    cdr = list -> Cdr();
    if( car -> IsEqual( dot )){
      return Search( cdr );
    }

    if( car -> IsEqual( dotdot )){
      if( Parent )
        return Parent -> Search( cdr );
      raise LauncherExceptions::NotFound(0);
    }

    if( !Subs -> IncludesKey( car -> AsString()))
      raise LauncherExceptions::NotFound( car -> AsString());

    target = Subs -> AtKey( car -> AsString());
    return target -> Search( cdr );
  }

  void Gather( Set<ProjectLinkSS> list, String n ){
    Iterator<Assoc<String,ProjectLinkSS>> ite;
    Collection<Assoc<String,ProjectLinkSS>>  cole;
    Assoc<String,ProjectLinkSS>   asc;

    SGather( list, n );
    cole = Subs;
    ite => New( cole );
    while(( asc = ite -> PostIncrement()) != 0 ){
      asc -> Value() -> Gather( list, n );
    }
    ite -> Finish();
  }

  int ExistLink( String key ){
    return Subs -> IncludesKey( key );
  }

   void PutLink( String key, ProjectLinkSS value ) : locked{
     if( ExistLink( key ))
        raise LauncherExceptions::Duplicate;
     value -> SetDatas( key, self );
     Subs -> AddAssoc( key, value );
  }

  void DeleteLink( String key ){
    Subs -> RemoveKey( key );
  }
         
  void ReleaseLink( String key ){
    Subs -> RemoveKey( key );
  }

  ProjectLinkSS Clone(){
    ProjectLinkSS link;
    ProjectSS  prj;
    Iterator<Assoc<String,ProjectLinkSS>> ite;
    Collection<Assoc<String,ProjectLinkSS>> cole;
    Assoc<String,ProjectLinkSS> asc;
        
    prj => New();
    cole = Subs;
    ite => New( cole );
    ite -> Reset();
    while(( asc = ite -> PostIncrement()) != 0 ){
      prj -> PutLink( asc -> Key(), asc -> Value() );
    }
    ite -> Finish();
    link = prj;
    return link;
  }
   
  SList GetSubs( int type ){
    String r;
    Iterator<Assoc<String,ProjectLinkSS>> ite;
    Assoc<String,ProjectLinkSS> asc;
    SList list => New();
    Atom  a;

    ite => New( Subs );
    while(( asc = ite -> PostIncrement()) != 0 ){
      if( asc -> Value() -> GetType() == type ){
        a => NewFromString( asc -> Key());
        list -> Add( a );
      }
    }
    ite -> Finish();
    return list;
  }

   /* for bug */
   SList Fullname(){
     SList list;
     if( Parent != 0 ){
       Atom a => NewFromString( Name );
       list = Parent -> Fullname();
       list -> Add( a );
     }
     else{
       list => New();
       return list;
     }
     return list;
   }

}
