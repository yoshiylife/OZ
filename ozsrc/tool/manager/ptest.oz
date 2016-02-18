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
 * ptest.oz
 *
 * Test suits for getting path name of the class property.
 */

class GetPropertyPathNameTester : Tester (alias Initialize SuperInitialize;) {
  constructor: New;

    ArchitectureID AID;

/* method implementations */
    String Title () {
	String title;

	title
	  =>NewFromArrayOfChar ("Test Suits for Object::GetPropertyPathName");
	return title;
    }

    void Initialize () {
	SuperInitialize ();
	AID=>Any ();
    }

    void AddProperty (global VersionID vid, char name []) {
	Where ()->SearchClass (vid, AID)->AddProperty (vid, name);
    }

    void CheckKnownProperty (global VersionID vid, char name []) {
	String path;

	TypeStr ("Checking GetPropertyPathName (for known property) ... ");
	path=>NewFromArrayOfChar (GetPropertyPathName (name));
	if (! (path->NCompareToArrayOfChar ("images/", 7) == 0
	       && path->GetSubString (13, 9)
	                  ->CompareToArrayOfChar ("/classes/") == 0
	       && path->GetSubString (38, 1)
	                  ->CompareToArrayOfChar ("/") == 0
	       && path->GetSubString (39, 0)
	                  ->CompareToArrayOfChar (name) == 0)) {
	    TypeStr ("failed.\n");
	    TypeStr ("   Couldn't retrieve correct path name.\n");
	    TypeStr ("   ");
	    TypeString (path);
	    TypeStr (" is returned.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckUnknownProperty (global VersionID vid) {
	char unknown_property [] = "unknown_property";

	TypeStr ("Checking GetPropertyPathName (for unknown property) ... ");
	try {
	    GetPropertyPathName (unknown_property);
	    TypeStr ("failed.\n");
	    TypeStr ("   No exception was raised.\n");
	    TestStop ();
	} except {
	  ClassExceptions::UnknownProperty (name) {
	      ArrayOfCharOperators acops;

	      if (acops.Compare (name, unknown_property) == 0) {
		  TypeStr ("pass.\n");
	      } else {
		  TypeStr ("failed.\n");
		  TypeStr ("   The argument of the exception (");
		  TypeStr (name);
		  TypeStr (") differs from the original (");
		  TypeStr (unknown_property);
		  TypeStr (").\n");
		  TestStop ();
	      }
	  }
	    default {
		TypeStr ("failed.\n");
		TypeStr ("   An exception is raised, ");
		TypeStr ("but not the expected one.\n");
		TestStop ();
	    }
	}
    }

    void RemoveProperty (global VersionID vid, char name []) {
	Where ()->SearchClass (vid, AID)->RemoveProperty (vid, name);
    }

    void Test () {
	global VersionID pub_id_of_tester, impl_id_of_tester;
	char property_name [] = "gui.tcl";
	global Class c;

	inline "C" {
	    pub_id_of_tester = (self - 1)->head.a;
	}
	impl_id_of_tester
	  = Where ()->SearchClass (pub_id_of_tester, AID)
	                ->GetImplementationPart (pub_id_of_tester);
	AddProperty (impl_id_of_tester, property_name);
	try {
	    CheckKnownProperty (impl_id_of_tester, property_name);
	    CheckUnknownProperty (impl_id_of_tester);
	} except {
	    default {
		RemoveProperty (impl_id_of_tester, property_name);
		raise;
	    }
	}
	RemoveProperty (impl_id_of_tester, property_name);
    }
}
