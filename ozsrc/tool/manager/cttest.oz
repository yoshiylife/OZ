/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

// we don't use record

//#define NORECORDACOPS

// we flush objects
//#define NOFLUSH

// we are debugging
//#define NDEBUG

// we have no bug in remote instantiation
//#define NOREMOTEINSTANTIATION

// we lookup configuration table for configured class ID


// we don't list directory by unix 'ls' command, but opendir library
//#define LISTBYLS

// we need change directory to $OZHOME before OzRead and OzSpawn


// we don't use OzRemoveCode
//#define USEOZREMOVECODE

// we don't read parents version IDs from private.i.
//#define READPARENTSFROMPRIVATEDOTI

// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we have no bug in class StreamBuffer
//#define STREAMBUFFERBUG

// we have no support for getting executor ID


// we use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// boot classes are modifiable


// when object manager is started, its configuration cache won't be cleared
//#define CLEARCONFIGURATIONCACHEATSTART

// the executor doesn't expect a class cannot be found


// now, creating Feb.1 sources


// Executing Plan Plum: compressing the size of class object

/*
 * cttest.oz
 *
 * catalog tester
 */

class CatalogTester : Tester {
  constructor: New;
  public: Go, Initialize, Launch;

/* no instance variables */

/* method implementations */
    void CheckCopy (global Catalog ct) {
	TypeStr ("Checking Copy...\n");
	CheckCopySub (ct, 1, ":nishioka:test2", ":nishioka:test3",
		      ":nishioka:test3");
	CheckCopySub (ct, 2, ":nishioka:test3", ":test4", ":test4");
	CheckCopySub (ct, 3, ":test4", ":nishioka", ":nishioka:test4");
	CheckCopySub (ct, 4, ":nishioka", ":nishioka2",
		      ":nishioka2:nishioka:test4");
    }

    void CheckCopySub (global Catalog ct, unsigned int step,
		       char from [], char to [], char check []) {
	String st1, st2, sc;

	TypeStr ("  step");
	TypeInt (step);
	TypeStr (" (cp ");
	TypeStr (from);
	TypeStr (" ");
	TypeStr (to);
	TypeStr (")... ");
	ct->Copy (st1=>NewFromArrayOfChar (from),
		  st2=>NewFromArrayOfChar (to));
	RetrieveTest (ct, sc=>NewFromArrayOfChar (check));
	TypeStr ("pass.\n");
    }

    void CheckIsEmpty (global Catalog ct) {
	TypeStr ("Checking IsEmpty (Checking ");
	TypeOID (ct);
	TypeStr (" is empty)... ");
	if (! ct->IsEmpty ()) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Newly constructed catalog is not empty.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckTerminate (global Catalog ct) {
	TypeStr ("Checking Terminate (Terminating ");
	TypeOID (ct);
	TypeStr (")... ");
	ct->Terminate ();
	TypeStr ("pass.\n");
    }

    global Catalog CheckNew () {
	global Catalog ct;

	TypeStr ("Checking NewDirectorySystem ... ");
	ct=>NewDirectorySystem ();
	TypeStr ("pass (New catalog ");
	TypeOID (ct);
	TypeStr (" was created).\n");
	return ct;
    }

    void CheckNewDirectory (global Catalog ct) {
	TypeStr ("Checking NewDirectory ...\n");
	CheckNewDirectorySub (ct, 1, ":nishioka");
	CheckNewDirectorySub (ct, 2, ":nishioka2");
	CheckNewDirectorySub (ct, 3, ":nishioka3");
    }

    void CheckNewDirectorySub (global Catalog ct, unsigned int step,
			       char dir []) {
	String s=>NewFromArrayOfChar (dir);
	TypeStr ("  mkdir ");
	TypeString (s);
	TypeStr (" ... ");
	ct->NewDirectory (s);
	if (! ct->RetrieveDirectory (s)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't make directory");
	    TypeString (s);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    global Catalog CheckNewDirectoryServer (global Catalog ct)  {
	global Catalog new;

	TypeStr ("Checking NewDirectoryServer ... ");
	new = ct->NewDirectoryServer (Where ());
	TypeStr ("pass.\n");
	TypeStr ("  New directory server ");
	TypeOID (new);
	TypeStr (" is created.\n");
	return new;
    }

    void CheckRegister (global Catalog ct) {
	String st1=>NewFromArrayOfChar (":test1");
	String st2=>NewFromArrayOfChar (":nishioka:test2");

	TypeStr ("Checking Register (touch ");
	TypeString (st1);
	TypeStr (" ");
	TypeString (st2);
	TypeStr (")... ");
	CheckRegisterSub (ct, st1);
	CheckRegisterSub (ct, st2);
	TypeStr (" pass.\n");
    }

    void CheckRegisterSub (global Catalog ct, String st) {
	Package p;

	p=>New ();
	ct->Register (st, p);
	RetrieveTest (ct, st);
    }

    Package CheckUpdate (global Catalog ct) {
	Package p=>New ();
	School s=>New ();
	String v1, v2, st;
	ArchitectureID aid;
	global VersionID pub1, pub2, prot, impl;

	TypeStr ("Checking Update ... ");
	st=>New ();
	inline "C" {
	    pub1 = st->head.a;
	    prot = pub1 + 1;
	    impl = prot + 1;
	}
	s->NewEntry ("String", 0, pub1, prot, impl);
	aid=>Any ();
	inline "C" {
	    pub2 = aid->head.a;
	    prot = pub2 + 1;
	    impl = prot + 1;
	}
	s->NewEntry ("ArchitectureID", 0, pub2, prot, impl);
	p->SetSchool (s);
	ct->Update (st=>NewFromArrayOfChar (":nishioka:test2"), p);
	p = ct->Retrieve (st);
	s = p->GetSchool ();
	if (s->VersionIDOf (v1=>NewFromArrayOfChar ("String")) != pub1 ||
	    s->VersionIDOf (v2=>NewFromArrayOfChar ("ArchitectureID")) !=pub2){
	    TypeStr ("failed.\n");
	    TestStop ();
	}
	TypeStr (" pass.\n");
	return p;
    }

    void PrintList (global Catalog ct) {
	String st=>NewFromArrayOfChar ("");
	Set <String> src=>New ();
	Set <String> dst=>New ();

	src->Add (st);
	while (src->Size () > 0) {
	    Set <String> s;

	    st = src->RemoveAny ();
	    s = ct->ListDirectory (st);
	    while (s->Size () > 0) {
		String dir
		  = st->ConcatenateWithArrayOfChar (":")
		    ->Concatenate (s->RemoveAny ());
		src->Add (dir);
		dst->Add (dir);
	    }
	    s = ct->ListPackage (st);
	    while (s->Size () > 0) {
		dst->Add (st->ConcatenateWithArrayOfChar (":")
			  ->Concatenate (s->RemoveAny ()));
	    }
	}
	TypeStr ("Listings ...\n");
	while (dst->Size () > 0) {
	    st = dst->RemoveAny ();
	    TypeStr ("  ");
	    TypeString (st);
	    TypeReturn ();
	}
    }

    void CheckMigrate (global Catalog ct1, global Catalog ct2) {
	String st=>NewFromArrayOfChar (":nishioka2");

	TypeStr ("Checking Migrate ... ");
	ct1->Migrate (st, ct2);
	TypeStr ("pass.\n");
    }

    void CheckMove (global Catalog ct) {
	TypeStr ("Checking Move ...\n");
	CheckMoveSub (ct, 1, ":nishioka:test3", ":nishioka:test5",
		      ":nishioka:test5");
	CheckMoveSub (ct, 2, ":nishioka:test5", ":test6", ":test6");
	CheckMoveSub (ct, 3, ":test6", ":nishioka2", ":nishioka2:test6");
	CheckMoveSub (ct, 4, ":nishioka2", ":nishioka3",
		      ":nishioka3:nishioka2:test6");
    }

    void CheckMoveSub (global Catalog ct, unsigned int step,
		       char from [], char to [], char check []) {
	String st1, st2, sc;

	TypeStr ("  step");
	TypeInt (step);
	TypeStr (" (mv ");
	TypeStr (from);
	TypeStr (" ");
	TypeStr (to);
	TypeStr (")... ");
	ct->Move (st1=>NewFromArrayOfChar (from),
		  st2=>NewFromArrayOfChar (to));
	RetrieveTest (ct, sc=>NewFromArrayOfChar (check));
	TypeStr ("pass.\n");
    }

    void CheckRemove (global Catalog ct) {
	String st=>NewFromArrayOfChar (":nishioka3:nishioka2:test6");
	Set <String> s;

	TypeStr ("Checking Remove (rm ");
	TypeString (st);
	TypeStr (")... ");
	ct->Remove (st);
	s = ct->ListPackage (st);
	if (s->Size () > 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't remove Package ");
	    TypeString (st);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckRemoveDirectory (global Catalog ct) {
	String st=>NewFromArrayOfChar (":nishioka3");
	Set <String> s;

	TypeStr ("Checking RemoveDirectory (rmdir ");
	TypeString (st);
	TypeStr (")... ");
	ct->RemoveDirectory (st);
	try {
	    if (ct->RetrieveDirectory (st) != 0) {
		TypeStr ("failed.\n");
		TypeStr ("  Couldn't remove directory ");
		TypeString (st);
		TypeStr (".\n");
	    } else {
		TypeStr ("failed.\n");
		TypeStr ("  0 is returned when retrieving");
		TypeString (st);
		TypeStr (".\n");
	    }
	    TestStop ();
	} except {
	  DirectoryExceptions::UnknownDirectory (st) {
	      TypeStr ("pass.\n");
	  }
	}
    }

    void CheckRetrieve (global Catalog ct, Package p) {
	String st=>NewFromArrayOfChar (":nishioka:test2");

	TypeStr ("Checking Retrieve ... ");
	if (! p->GetSchool ()->IsEqual (ct->Retrieve (st)->GetSchool ())) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Retrieved package is not same as original one.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void RetrieveTest (global Catalog ct, String st) {
	if (! ct->Retrieve (st)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve from ");
	    TypeString (st);
	    TypeStr (".\n");
	    TestStop ();
	}
    }

    void Test () {
	global Catalog ct1, ct2;
	Package p;

	ct1 = CheckNew ();
	try {
	    CheckNewDirectory (ct1); /* mkdir :nishioka
				        mkdir :nishioka2
					mkdir :nishioka3 */
	    CheckRegister (ct1); /* touch :test1 :nishioka:test2 */
	    p = CheckUpdate (ct1); /* touch :nishioka:test2 */
	    CheckCopy (ct1); /* cp :nishioka:test2 :nishioka:test3
			                           :test4
						   :nishioka:test4
			        cp :nishioka :nishioka2:nishioka
			        => :nishioka:test2
			                    :test3
					    :test4
				   :nishioka2:nishioka:test2
				                      :test3
						      :test4
			           :test1
				   :test4 */
	    ct2 = CheckNewDirectoryServer (ct1);
	    try {
		CheckMigrate (ct1, ct2); /* migrate :nishioka2 to ct2 */
		CheckMove (ct1); /* mv :nishioka:test3 :nishioka:test5
			                               :test6
						       :nishioka2:test6
				    mv :nishioka2 :nishioka3:nishioka2
				    => :nishioka:test2
			                        :test4
				       :nishioka3:nishioka2:nishioka:test2
				                                    :test3
								    :test4
						           :test6
				       :test1
				       :test4 */
		CheckRemove (ct1); /* rm :nishioka3:nishioka2:test6 */
	    } except {
		default {
		    Where ()->RemoveObject (ct2);
		    raise;
		}
	    }
	    CheckRemoveDirectory (ct1); /* rmdir :nishioka3 */
	    CheckIsEmpty (ct2);
	    CheckTerminate (ct2);
	    CheckRetrieve (ct1, p);
	    PrintList (ct1);
	} except {
	    default {
		Where ()->RemoveObject (ct1);
		raise;
	    }
	}
	Where ()->RemoveObject (ct1);
    }

    String Title () {
	String title;

	title=>NewFromArrayOfChar ("Test Suits for Catalog");
	return title;
    }
}
