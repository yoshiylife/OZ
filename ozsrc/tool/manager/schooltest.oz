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
 * newschooltest.oz
 *
 * School tester
 */

class SchoolTester : Tester {
  constructor: New;
  public: Go, Initialize, Launch;

/* instance variables */
    School S;
    String Key;
    unsigned int Kind;
    global VersionID VID;

/* method implementations */

    void CheckRegister () {
	TypeStr ("Checking Register ... ");
	S->Register (Key, Kind, VID);
	if (S->KindOf (Key) != Kind) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve correct kind.\n");
	    TestStop ();
	}
	if (S->VersionIDOf (Key) != VID) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve correct version ID.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckIncludes () {
	TypeStr ("Checking Includes ... ");
	if (! S->Includes (Key)) {
	    TypeStr ("failed.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckChange () {
	global VersionID vid;

	TypeStr ("Checking Change ... ");
	inline "C" {
	    vid = self->head.a;
	}
	S->Change (Key, Kind, vid);
	if (S->VersionIDOf (Key) != vid) {
	    TypeStr ("failed.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckRemove () {
	TypeStr ("Checking Remove ... ");
	S->Remove (Key);
	if (S->Includes (Key)) {
	    TypeStr ("failed.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckIsEqual () {
	School s1=>New (), s2=>New ();
	global VersionID vid1, vid2;

	TypeStr ("Checking IsEqual ... ");
	inline "C" {
	    vid1 = s1->head.a;
	    vid2 = vid1 + 1;
	}
	s1->Register (Key, Kind, vid1);
	if (s1->IsEqual (s2) || s2->IsEqual (s1)) {
	    TypeStr ("failed.\n");
	    TestStop ();
	}
	s2->Register (Key, Kind, vid2);
	if (s1->IsEqual (s2) || s2->IsEqual (s1)) {
	    TypeStr ("failed.\n");
	    TestStop ();
	}
	s1->Change (Key, Kind, vid2);
	if (! s1->IsEqual (s2) || ! s2->IsEqual (s1)) {
	    TypeStr ("failed.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    School CheckLoad (char p []) {
	String path=>NewFromArrayOfChar (p);
	String st=>NewFromArrayOfChar ("School");
	global VersionID pubid;
	School s;

	TypeStr ("Checking Load ... ");
	S=>Load (path);
	s = S;
	inline "C" {
	    pubid = s->head.a;
	}
	if (S->PublicIDOf (st) != pubid) {
	    TypeStr ("failed.\n");
	    TypeStr ("  A correct public version ID of school cannot be ");
	    TypeStr ("retrived from loaded boot-school.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
	return s;
    }

    void CheckPrintIt () {
	String st;

	TypeStr ("Checking PrintIt ... ");
	S->PrintIt (st=>NewFromArrayOfChar ("tmp/printit.test"));
	TypeStr ("pass.\n");
    }

    void CheckListNames () {
	Set <String> s;
	String st=>NewFromArrayOfChar ("School");

	TypeStr ("Checking ListNames ... ");
	s = S->ListNames ();
	if (! s->Includes (st)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The name list of boot-school doesn't include class ");
	    TypeStr ("\"School\".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void Test () {
	global VersionID vid;
	String k;

	S=>New ();
	Key=>NewFromArrayOfChar ("SchoolTester");
	Kind = 5;
	k = Key;
	inline "C" {
	    vid = k->head.a;
	}
	VID = vid;

	CheckRegister ();
	CheckIncludes ();
	CheckChange ();
	CheckRemove ();
	CheckIsEqual ();
	CheckLoad ("etc/boot-school");
	CheckPrintIt ();
	CheckListNames ();
    }

    String Title () {
	String title;

	title=>NewFromArrayOfChar ("Test Suits for School");
	return title;
    }
}
