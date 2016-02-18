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
 * catalogtool.oz
 *
 * An abstract class for tools which use a package in a catalog.
 */

abstract class CatalogTool : LaunchableWithKterm {
  protected:
    Initialize, IsAlphabet, IsAlphanumeric, IsDigit, IsWhite, Read,
    ReadFromConsole, ReadObject, ReadOID, ReadOIDFromConsole, ReadYN,
    ReadYNFromConsole, SetPrompt, Start, Title, Trim, TypeChar, TypeInt,
    TypeOID, TypeReturn, TypeStr, TypeString, WriteStr;

  protected:
    Do, GetCatalog, GetLocalClass, GetPackageName, GetSchool,
    OMSearch, SearchClass;

    void Do (School school, global Class c) : abstract;
    String Title () : abstract;

    global Catalog GetCatalog () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	global Catalog catalog
	  = narrow (Catalog, nd->ResolveWithArrayOfChar (":catalog"));

	if (catalog) {
	    return catalog;
	} else {
	    TypeStr ("No catalog is registered in the NameDirectory.\n");
	    raise Abort;
	}
    }

    global Class GetLocalClass () {
	global ConfiguredClassID ccid;
	ArchitectureID aid=>Any ();

	inline "C" {
	    ccid = OzExecGetObjectTop (self)->head [0].a;
	}
	return Where ()->SearchClass (ccid, aid);
    }

    String GetPackageName () {
	TypeStr ("Enter the package name in the catalog: ");
	return Trim (Read ());
    }

    School GetSchool (global Catalog catalog, String name) {
	School s;

	try {
	    s = catalog->Retrieve (name)->GetSchool ();
	} except {
	    default {
		TypeStr ("Cannot get package ");
		TypeString (name);
		TypeStr (" from the catalog.\n");
		raise;
	    }
	}
	return s;
    }

    global Class OMSearch (global ObjectManager om, global VersionID public_id,
			   ArchitectureID aid, Waiter w) {
	global Class c = narrow (Class, om->SearchClass (public_id, aid));

	w->Done ();
	return c;
    }

    global Class SearchClass (global ObjectManager om,
			      global VersionID public_id, ArchitectureID aid) {
	global Class c;
	global Class @p;
	Waiter w=>New ();

	p = fork OMSearch (om, public_id, aid, w);
	w->Timer (5);
	if (w->WaitAndTest ()) {
	    return join p;
	} else {
	    TypeStr ("Searching class was aborted.\n");
	    detach p;
	    raise Abort;
	}
    }

    void Start () {
	global Catalog catalog;
	global Class c;
	String name;
	School school;

	try {
	    catalog = GetCatalog ();
	    c = GetLocalClass ();
	    name = GetPackageName ();
	    school = GetSchool (catalog, name);
	    Do (school, c);
	} except {
	    default {
		TypeStr ("Aborted with an exception.\n");
	    }
	}
	TypeStr ("\nType return to close.\n");
	Read ();
    }
}
