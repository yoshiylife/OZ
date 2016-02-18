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

abstract class ProjectLinkSS {
 protected: Parent, Name, Type;
 public: Clone, Release, Fullname, Search, Gather, GetCID, SetDatas, GetType,
   PutLink, Launch, Instanciate, GetParent, Hash, IsEqual, GetName;

   ProjectSS   Parent;
   String    Name;
   int       Type;

   ProjectLinkSS Clone() : abstract;
   void Release(){ Parent -> ReleaseLink( Name ); }
   
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
   
   void Gather( Set<ProjectLinkSS> list, String n ){
     if(( Name != 0 ) && Name -> IsEqualTo( n )){
       list -> Add( self );
     }
   }
   
   ProjectLinkSS Search( SList n ){
     if( n -> IsNil())
       return self;
     raise LauncherExceptions::IllegalCommand;
   }

   void PutLink( String n, ProjectLinkSS l ){
     raise LauncherExceptions::IllegalCommand;
   }

   void Launch(){
     raise LauncherExceptions::IllegalCommand;
   }

   void Instanciate( String name ){
     raise LauncherExceptions::IllegalCommand;
   }

   long GetCID(){ return 0; }

   void SetDatas( String n, ProjectSS prj ){ Name = n; Parent = prj; }

   int GetType(){ return Type; }

   unsigned int Hash(){ return Name -> At( 0 ); }

   int IsEqual( ProjectLinkSS another ){
     return Fullname() -> IsEqual( another -> Fullname());
   }

   ProjectSS GetParent(){ return Parent; }
   String GetName(){ return Name; }
 }
