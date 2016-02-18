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
class UnixIO;
class ObjectManager;
class String;
class SubString;
*/

class Inspector : Launchable {
 public: Launch, Initialize;

 protected: ReadEvents;

   UnixIO wish, debugp;

   void  Initialize ()
     {
       debugp=>New ();
     }

   void WishStart ()
     {
       char eid[];
       char argv[][];
       global Object id = Where ();

       length eid = 9;

       inline "C"
	 {
	   OzSprintf (OZ_ArrayElement (eid, char), "0x%06x", 
		      (int) (((int) (id >> 24)) & 0x00ffffff));
	 }

       length argv = 2;
       
       argv[0] = "inspect";
       argv[1] = eid;

       wish=>Spawn (argv);
     }

   void Launch ()
     {
       if (wish)
	 {
	   debugp->PutStr ("already launched\n");
	   return;
	 }
       WishStart ();
       detach fork ReadEvents ();
     }

   void ReadEvents ()
     {
       SubString substr;
       String resp;

       while(1)
	 { 
	   resp = wish->ReadString (256);

//	   debugp->PutString (resp);
	   
	   substr = resp->GetSubString (0, 2);

	   if (substr->IsEqualToArrayOfChar ("@q"))
	     {
	       wish->Close ();
	       wish = 0;
	       return;
	     }
	 }
     }
 }







