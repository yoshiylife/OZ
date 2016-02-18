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
class LaunchableHolderSS : ProjectLinkSS{
 constructor: New, Copy;
 public: Get, Clone, GetCID, Launch;
   
   Launchable   Obj;
   unsigned long         CID;

   void New( long id  ) {
     Object o;
     global ConfiguredClassID ccid;
     global VersionID vid;

     Type = 1;
     CID = id;
     inline "C"{
       OzDebugf( "id=%08x%08x\n", (unsigned long)(id >> 32), (unsigned long)(0xffffffff & id ) );
       vid = id;
     }
     ccid = Where ()->GetConfiguredClassID (vid, 0);
     inline "C" {
       OZ_Object _obj = OzExecAllocateLocalObject( ccid );
       o = _obj - _obj -> head.e;
     }
     try{
       Obj = narrow( Launchable, o );
     }
     except{
       default{
         raise LauncherExceptions::NotLaunchable;
       }
     }
     Obj -> Initialize();
   }

   void Copy( int type, unsigned long cid, Launchable o ){ 
     Type = type;
     CID = cid;
     Obj = o;
   }

   Launchable Get(){ return Obj; }

   void Launch(){ Obj -> Launch();}

   ProjectLinkSS Clone(){ 
     ProjectLinkSS link;
     LaunchableHolderSS lh;

     lh => Copy( Type, CID, Obj );
     link = lh;
     return link;
   }
   long GetCID(){ return CID; }
 }
