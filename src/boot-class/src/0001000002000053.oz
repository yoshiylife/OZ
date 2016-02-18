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

//class ProjectLink, Launchable;
class CIDHolderSS : ProjectLinkSS{
 constructor: New, NewFromVid;
 public: GetCID, Clone, Instanciate;

   long CID;
   
   void New( long id ) { CID = id; Type = 2; }
   void NewFromVid( global VersionID vid ){
     unsigned long id;
     inline "C"{
       id = (unsigned long long)vid;
     }
     CID = id;
     Type = 2;
   }

   long GetCID(){ return CID; }

   ProjectLinkSS Clone(){ 
     ProjectLinkSS link;
     CIDHolderSS hold;
     hold => New( CID );
     link = hold;
     return hold;
   }

   void Instanciate( String name ){
     LaunchableHolderSS holder => New( CID );
     Parent -> PutLink( name, holder );
   }
}
