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
 * dropper.oz
 *
 * Remove public class parts and their lower parts and configured
 * classes for all classes in a school.  The configuration cache on
 * the ObjectManager is also flushed.
 */

class Dropper : CatalogTool {
    String GetPackageName () {
	String name=>NewFromArrayOfChar (":nishioka:to-be-removed");

	return name;
    }

    void DropAllConfiguredClasses (global Class c,
				   global ConfiguredClassID ccids []) {
	unsigned int i, len = length ccids;

	for (i = 0; i < len; i ++) {
	    global ClassID unknown;

	    try {
		c->RemoveClass (ccids [i]);
	    } except {
	      ClassExceptions::UnknownClass (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	      CollectionExceptions <global ClassID>::UnknownKey (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	    }
	}
    }

    void DropAllProtectedParts (global Class c,
				global VersionID protected_ids []) {
	global VersionID impl_ids [];
	unsigned int i, len = length protected_ids;

	for (i = 0; i < len; i ++) {
	    try {
		impl_ids = c->GetLowerVersions (protected_ids [i]);
		DropAllImplementationParts (c, impl_ids);
		c->RemoveClass (protected_ids [i]);
	    } except {
	      ClassExceptions::UnknownClass (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	      CollectionExceptions <global ClassID>::UnknownKey (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	    }
	}
    }

    void DropAllImplementationParts (global Class c,
				     global VersionID impl_ids []) {
	unsigned int i, len = length impl_ids;
	global ClassID unknown;

	for (i = 0; i < len; i ++) {
	    try {
		c->RemoveClass (impl_ids [i]);
	    } except {
	      ClassExceptions::UnknownClass (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	      CollectionExceptions <global ClassID>::UnknownKey (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	    }
	}
    }

    void FlushConfigurationCache (global ObjectManager om,
				  global VersionID public_id) {
	om->ChangeConfigurationCache (public_id, 0);
    }

    void Do (School school, global Class c) {
	global ObjectManager om = Where ();
	Set <String> s = school->ListNames ();
	Iterator <String> i;
	String name;

	for (i=>New (s); (name = i->PostIncrement ()) != 0;) {
	    global VersionID public_id = school->VersionIDOf (name);
	    global ClassID unknown;

	    TypeString (name);
	    TypeStr (": ");
	    try {
		global VersionID protected_ids [];
		global ConfiguredClassID ccids [];

		ccids = c->ConfiguredClassIDs (public_id);
		DropAllConfiguredClasses (c, ccids);
		protected_ids = c->GetLowerVersions (public_id);
		DropAllProtectedParts (c, protected_ids);
		FlushConfigurationCache (om, public_id);
		c->RemoveClass (public_id);
		TypeStr ("done.\n");
	    } except {
	      ClassExceptions::UnknownClass (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	      CollectionExceptions <global ClassID>::UnknownKey (unknown) {
		  TypeStr ("Unknown (not local?) class part ");
		  TypeOID (unknown);
		  TypeStr (".\n");
	      }
	    }
	}
    }

    String Title () {
	String title=>NewFromArrayOfChar ("Dropper");

	return title;
    }
}
