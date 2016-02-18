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
 * otest.oz
 *
 * Test suits for configuration set handling facility in class Object
 */

class ConfigurationSetTester : Tester {
  constructor: New;
  public: Launch;

/* method implementations */
    String Title () {
	String title;

	title=>NewFromArrayOfChar
	         ("Test Suits for ConfigurationSet Handling at Object");
	return title;
    }

    void Check0 () {
	Object o;

	o = self;
	TypeStr ("Checking SetConfigurationSet (0) ... ");
	o->SetConfigurationSet (0);
	if (o->GetConfigurationSet () != 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve 0 by GetConfigurationSet.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckCset (ConfigurationTable cset) {
	Object o;

	o = self;
	TypeStr ("Checking SetConfigurationSet (cset) ... ");
	o->SetConfigurationSet (cset);
	if (o->GetConfigurationSet () != cset) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve cset by GetConfigurationSet.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckLookup (ConfigurationTable cset, global VersionID pubid) {
	Object o = self;

	TypeStr ("Checking LookupConfigurationSet ... ");
	if (o->LookupConfigurationSet (pubid) != cset->Lookup (pubid)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve ccid by vid\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }
	
    void Test () {
	ConfigurationTable cset;
	global ConfiguredClassID ccid;
	global VersionID pubid;
	ArchitectureID any=>Any ();

	inline "C" {
	    ccid = OzExecGetObjectTop (self)->head [0].a;
	}
	pubid
	  = Where ()
	    ->SearchClass (ccid, any)->VersionIDFromConfiguredClassID (ccid);
	cset=>New ();
	cset->Set (pubid, ccid);
	Check0 ();
	CheckCset (cset);
	CheckLookup (cset, pubid);
    }
}
