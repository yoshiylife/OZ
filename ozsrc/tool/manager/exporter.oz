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
 * exporter.oz
 *
 * configuration cache changer
 */

class PackageExporter : CatalogTool {
/* no instance variables */

/* method implementations */

    global Class ReadClass () {
	global Object o;

	o = ReadObject ("Enter the name (or object ID) of a class object: ");
	return narrow (Class, o);
    }

    void Do (School school, global Class c) {
	global ObjectManager om = Where ();
	Set <String> s = school->ListNames ();
	Iterator <String> i;
	String name;
	global Class target = ReadClass ();

	for (i=>New (s); (name = i->PostIncrement ()) != 0;) {
	    global VersionID public_id = school->VersionIDOf (name);
	    global ClassID unknown;

	    TypeString (name);
	    TypeStr (": ");
	    if (c->LookupClass (public_id) != 0) {
		global VersionID root_id = c->GetRootPart (public_id);
		ExportRootPart (root_id, c, target);
	    } else {
		TypeStr ("Not local. Ignored.\n");
	    }
	}
    }

    void ExportConfiguredClass (global ConfiguredClassID ccid,
				global Class c, global Class target) {
	if (c->LookupClass (ccid)) {
	    SendClass (ccid, c, target);
	} else {
	    TypeStr ("The configured class ");
	    TypeOID (ccid);
	    TypeStr (" is not local. Ignored.\n");
	}
    }

    void ExportImplementationPart (global VersionID impl_id,
				   global Class c, global Class target) {
	if (c->LookupClass (impl_id)) {
	    SendClass (impl_id, c, target);
	} else {
	    TypeStr ("The implementation part ");
	    TypeOID (impl_id);
	    TypeStr (" is not local. Ignored.\n");
	}
    }

    void ExportProtectedPart (global VersionID prot_id, global Class c,
			      global Class target) {
	global VersionID impl_ids [];
	unsigned int i, len;

	if (c->LookupClass (prot_id)) {
	    SendClass (prot_id, c, target);
	    impl_ids = c->GetLowerVersions (prot_id);
	    len = length impl_ids;
	    for (i = 0; i < len ; i ++) {
		ExportImplementationPart (impl_ids [i], c, target);
	    }
	} else {
	    TypeStr ("The protected part ");
	    TypeOID (prot_id);
	    TypeStr (" is not local. Ignored.\n");
	}
    }

    void ExportPublicPart (global VersionID pub_id, global Class c,
			   global Class target) {
	global VersionID prot_ids [];
	global ConfiguredClassID ccids [];
	unsigned int i, len;

	if (c->LookupClass (pub_id)) {
	    SendClass (pub_id, c, target);
	    prot_ids = c->GetLowerVersions (pub_id);
	    len = length prot_ids;
	    for (i = 0; i < len; i ++) {
		ExportProtectedPart (prot_ids [i], c, target);
	    }
	    ccids = c->ConfiguredClassIDs (pub_id);
	    len = length ccids;
	    for (i = 0; i < len; i ++) {
		ExportConfiguredClass (ccids [i], c, target);
	    }
	} else {
	    TypeStr ("The public part ");
	    TypeOID (pub_id);
	    TypeStr (" is not local. Ignored.\n");
	}
    }

    void ExportRootPart (global VersionID root_id, global Class c,
			 global Class target) {
	global VersionID pub_ids [];
	unsigned int i, len;

	if (c->LookupClass (root_id)) { 
	    SendClass (root_id, c, target);
	    pub_ids = c->GetLowerVersions (root_id);
	    len = length pub_ids;
	    for (i = 0; i < len; i ++) {
		ExportPublicPart (pub_ids [i], c, target);
	    }
	    TypeStr ("done.\n");
	} else {
	    TypeStr ("The root part ");
	    TypeOID (root_id);
	    TypeStr (" is not local. Ignored.\n");
	}
    }

    void SendClass (global ClassID cid, global Class c, global Class target) {
	if (target->LookupClass (cid)) {
	    target->RemoveClass (cid);
	}
	c->DelegateClass (cid, target);
    }

    global Object StringToOID (String arg, Console dialog) {
	global Object o;

	o = arg->Str2OID ();
	if (o == 0) {
	    WriteStr (dialog, "16 hex-decimal digits ([0-9a-fA-F]) are ");
	    WriteStr (dialog, "needed to represent global Object ID.\n");
	    return 0;
	}
	return o;
    }

    String Title () {
	String title=>NewFromArrayOfChar ("Package Exporter");

	return title;
    }
}
