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
 * cltest.oz
 *
 * class tester
 */

class ClassObjectChecker : LaunchableWithKterm {
/* no instance variable */

/* method implementation */
    void Check (global Class c) {
	FileOperators fops;
	String cd=>NewFromArrayOfChar (c->GetClassDirectoryPath ());
	global ClassID images [] = c->ListClassID ();
	Set <OIDAsKey <global ClassID>> directories;

	directories = TailerDirectories (fops.List (cd));
	CheckFromImage (c, images, directories);
	CheckFromDirectory (c, images, directories);
    }

    void CheckFromDirectory (global Class c, global ClassID images [],
			     Set <OIDAsKey <global ClassID>> directories) {
	unsigned int j, len = length images;
	Iterator <OIDAsKey <global ClassID>> i;
	OIDAsKey <global ClassID> key;
	global ClassID cid;

	for (i=>New (directories); (key = i->PostIncrement ()) != 0;) {
	    cid = key->Get ();
	    for (j = 0; j < len; j ++) {
		if (images [j] == cid) {
		    break;
		}
	    }
	    if (j == len) {
		UnknownDirectory (c, cid);
	    }
	}
    }

    void CheckFromImage (global Class c, global ClassID images [],
			 Set <OIDAsKey <global ClassID>> directories) {
	unsigned int i, len = length images;
	OIDAsKey <global ClassID> key;

	for (i = 0; i < len; i ++) {
	    if (directories->Includes (key=>New (images [i]))) {
		CheckProperty (c, images [i]);
	    } else {
		NoDirectory (c, images [i]);
	    }
	}
    }

    void CheckProperty (global Class c, global ClassID cid) {
	Set <String> properties = GetSetOfProperties (c, cid);
	Set <String> files = GetSetOfFiles (c, cid);

	if (! properties->IsEqual (files)) {
	    Set <String> p_diff = properties->Difference (files);
	    Set <String> f_diff = files->Difference (properties);
	    Iterator <String> i;
	    String s;

	    for (i=>New (p_diff); (s = i->PostIncrement ()) != 0;) {
		NoFile (c, cid, s);
	    }
	    for (i=>New (f_diff); (s = i->PostIncrement ()) != 0;) {
		UnknownFile (c, cid, s);
	    }
	}
    }

    Set <String> GetSetOfFiles (global Class c, global ClassID cid) {
	String path;
	char p [];
	Set <String> set=>New ();
	FileOperators fops;
	char files [][];
	unsigned int i, len;

	p = c->GetClassFileDirectory (cid);
	path=>NewFromArrayOfChar (p);
	files = fops.List (path);
	len = length files;
	for (i = 0; i < len; i ++) {
	    String st=>NewFromArrayOfChar (files [i]);

	    set->Add (st);
	}
	return set;
    }

    Set <String> GetSetOfProperties (global Class c, global ClassID cid) {
	String properties [] = c->GetProperties (cid);
	Set <String> set=>New ();
	unsigned int i, len = length properties;

	for (i = 0; i < len; i ++) {
	    set->Add (properties [i]);
	}
	return set;
    }

    void NoFile (global Class c, global ClassID cid, String s) {
	TypeStr ("Property file of the property ");
	TypeString (s);
	TypeStr (" of class ");
	TypeOID (cid);
	TypeStr (" is not found.  Do you remove the property (y/n) ? [y] ");
	if (ReadYN (1)) {
	    try {
		c->RemoveProperty (cid, s->Content ());
	    } except {
		default {}
	    }
	}
    }

    void NoDirectory (global Class c, global ClassID cid) {
	TypeStr ("There is no directory for class part ");
	TypeOID (cid);
	TypeStr (".  Do you remove the class part (y/n) ? [y] ");
	if (ReadYN (1)) {
	    try {
		c->RemoveClass (cid);
	    } except {
	        default {
		}
	    }
	}
    }

    global Class ReadClass () {
	char m1 [] = "Enter the name (or object ID) of a class object: ";

	return narrow (Class, ReadObject (m1));
    }

    void Start () {
	Check (ReadClass ());
	TypeStr ("All done.\n");
	TypeStr ("\nType return to close.\n");
	Read ();
    }

    Set <OIDAsKey <global ClassID>> TailerDirectories (char list [][]) {
	Set <OIDAsKey <global ClassID>> set=>New ();
	unsigned int len = length list, i;
	ArrayOfCharOperators acops;

	for (i = 0; i < len; ++ i) {
	    global ClassID cid = narrow (ClassID, acops.Str2OID (list [i]));

	    if (cid != 0) {
		OIDAsKey <global ClassID> key=>New (cid);

		set->Add (key);
	    }
	}
	return set;
    }

    String Title () {
	String st=>NewFromArrayOfChar ("Class Directory Checker");

	return st;
    }

    int ReadInt () {
	String ans = Read ();

	return ans->AtoI ();
    }

    void GetLowerVersions (global Class c, global ClassID cid,
			   UpperPart upper) {
	int i, len;
	global VersionID vid;
	int visible = (upper->GetVersionString () != 0);

	TypeStr ("  How many lower versions are there? ");
	len = ReadInt ();
	for (i = 0; i < len; i ++) {
	    int flag = 1;

	    while (flag) {
		flag = 0;
		TypeStr ("    Which is the lower version [");
		TypeInt (i);
		TypeStr ("] ? ");
		vid = narrow (VersionID, ReadOID ());
		if (c->LookupClass (vid) != 0) {
		    if (c->GetUpperPart (vid) != cid) {
			TypeStr ("    ? ");
			TypeOID (cid);
			TypeStr (" is not the upper part of it.\n");
			TypeStr ("    Quit the directory registration ");
			TypeStr ("(y/n) ? [n] ");
			if (ReadYN (0)) {
			    raise CommandInterpreterExceptions::Quit;
			} else {
			    flag = 1;
			}
		    }
		}
	    }
	    upper->AddAsNewLowerVersion (vid);
	    if (c->LookupClass (vid) != 0) {
		if (c->GetVersionString (vid) != 0) {
		    if (visible) {
			upper->GetNewVersionString (vid);
		    } else {
			TypeStr ("  ? Visible lower version exists.\n");
			TypeStr ("  Then ");
			TypeOID (cid);
			TypeStr (" must be visible.  ");
			TypeStr ("Turning it as visible and repeat ");
			TypeStr ("registration...\n");
			/* under construction */
		    }
		}
	    } else if (visible) {
		TypeStr ("    Is it visible (y/n) ? [n] ");
		if (ReadYN (0)) {
		    upper->GetNewVersionString (vid);
		}
	    }
	}
    }

    void RegisteraRootPart (global Class c, global ClassID cid, int copy_kind){
	RootPart rp;

	rp=>New (cid, 0, copy_kind);
	GetLowerVersions (c, cid, rp);
	c->AddToClassTable (rp);
	c->RegisterClassInformations (cid);
    }

    void RegisteraPublicPart (global Class c, global ClassID cid,
			      int copy_kind) {
	UpperPart up;
	PublicPart publp;
	global VersionID upper;
	global ConfiguredClassID ccid;
	int i, len;

	TypeStr ("  Which is the upper part ? ");
	upper = narrow (VersionID, ReadOID ());
	publp=>New (cid, 0, upper, KindOfClassPart::anOrdinaryClass,copy_kind);
	if (c->LookupClass (upper) != 0) {
	    if (c->GetVersionString (upper) != 0) {
		/* under construction */
		/* turn it visible */
	    }
	}
	GetLowerVersions (c, cid, publp);
	TypeStr ("  How many configured classes does it have ? ");
	len = ReadInt ();
	for (i = 0; i < len; i ++) {
	    TypeStr ("    Which is the configured class [");
	    TypeInt (i);
	    TypeStr ("] ? ");
	    ccid = narrow (ConfiguredClassID, ReadOID ());
	    publp->AddAsNewConfiguration (ccid);
	    TypeStr ("    Is it the default configured class (y/n) ? [n] ");
	    if (ReadYN (0)) {
		publp->SetDefaultConfiguredClassID (ccid);
	    }
	}
	up = publp;
	c->AddToClassTable (up);
	c->RegisterClassInformations (cid);
    }

    int AskCopyKind (global ClassID cid) {
	/* under implementation */
    }

    void RegisteraDirectory (global Class c, global ClassID cid) {
	int flag = 1;
	int part, copy_kind;

	while (flag) {
	    flag = 0;
	    TypeStr ("Which is the kind of the class part ?\n");
	    TypeStr ("  Root part ... 0\n");
	    TypeStr ("  Public part ... 1\n");
	    TypeStr ("  Protected part ... 2\n");
	    TypeStr ("  Implementation part ... 3\n");
	    TypeStr ("  Configured class ... 4\n");
	    TypeStr ("  Shared ... 5\n");
	    TypeStr ("  Static class ... 6\n");
	    TypeStr ("  Record ... 7\n");
	    part = ReadInt ();
	    switch (part) {
	      case ClassPartName::aRootPart:
		copy_kind = AskCopyKind (cid);
		RegisteraRootPart (c, cid, copy_kind);
		break;
	      case ClassPartName::aPublicPart:
		copy_kind = AskCopyKind (cid);
		RegisteraPublicPart (c, cid, copy_kind);
		break;
	      case ClassPartName::aProtectedPart:
//		RegisteraProtectedPart (c, cid);
		break;
	      case ClassPartName::anImplementationPart:
//		RegisteranImplementationPart (c, cid);
		break;
	      case ClassPartName::aConfiguredClass:
//		RegisteraConfiguredClass (c, cid);
		break;
	      case KindOfClassPart::aShared:
//		RegisteraShared (c, cid);
		break;
	      case KindOfClassPart::aStaticClass:
//		RegisteraStaticClass (c, cid);
		break;
	      case KindOfClassPart::aRecord:
//		RegisteraRecord (c, cid);
		break;
	      default:
		TypeStr ("Invalid part.  ");
		TypeStr ("Quit the directory registration (y/n) ? [n] ");
		if (! ReadYN (0)) {
		    flag = 1;
		}
		break;
	    }
	}
    }

    void UnknownDirectory (global Class c, global ClassID cid) {
	TypeStr ("Unknown class part directory ");
	TypeOID (cid);
/*
	TypeStr (". Do you register it (y/n) ? [y] ");
	if (ReadYN (1)) {
	    RegisteraDirectory (c, cid);
	} else {
*/
	    TypeStr (". Do you remove the directory (y/n) ? [y] ");
	    if (ReadYN (1)) {
		FileOperators fops;
		String st1=>NewFromArrayOfChar (c->GetClassDirectoryPath ());
		String st2=>OIDtoHexa (cid);

		st1 = st1->ConcatenateWithArrayOfChar ("/")->Concatenate (st2);
		fops.RemoveDirectory (st1);
	    }
/*
	}
*/
    }

    void UnknownFile (global Class c, global ClassID cid, String s) {
	TypeStr ("Unknown property file ");
	TypeString (s);
	TypeStr (" in class part ");
	TypeOID (cid);
	TypeStr (". Do you register it (y/n) ? [y] ");
	if (ReadYN (1)) {
	    c->AddProperty (cid, s->Content ());
	} else {
	    TypeStr ("Do you remove it (y/n) ? [y] ");
	    if (ReadYN (1)) {
		FileOperators fops;
		String st=>NewFromArrayOfChar (c->GetClassInformations (cid));

		st = st->ConcatenateWithArrayOfChar ("/")->Concatenate (s);
		fops.Remove (st);
	    }
	}
    }
}
