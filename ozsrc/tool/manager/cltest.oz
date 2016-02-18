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

class ClassTester : Tester (alias Initialize SuperInitialize;) {
  constructor: New;
  public: Launch;

/* instance variables */
    ArchitectureID AID;
    global Class C;

/* method implementations */
    void Initialize () {
	SuperInitialize ();
	AID=>Any ();
    }

    String Title () {
	String title=>NewFromArrayOfChar ("Test Suits for Class");

	return title;
    }

    void WhichPartTest (global VersionID public_ID_of_ClassTester,
			global ConfiguredClassID ccid_of_ClassTester) {
	unsigned int res;

	TypeStr ("Checking WhichPart ... ");
	if ((res = C->WhichPart (public_ID_of_ClassTester))
	    != ClassPartName::aPublicPart) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't get correct part name ");
	    TypeStr ("(aPublicPart) from public part ID.\n");
	    TypeStr ("  Returned value was ");
	    TypeInt (res);
	    TypeStr (".\n");
	    TestStop ();
	}
	if ((res = C->WhichPart (ccid_of_ClassTester))
	    != ClassPartName::aConfiguredClass) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't get correct part name ");
	    TypeStr ("(aConfiguredClass) from configured class ID.\n");
	    TypeStr ("  Returned value was ");
	    TypeInt (res);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void WhichKindTest (global VersionID public_ID_of_ClassTester) {
	unsigned int res;

	TypeStr ("Checking WhichKind ... ");
	if ((res = C->WhichKind (public_ID_of_ClassTester))
	    != KindOfClassPart::anOrdinaryClass) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't get correct kind name ");
	    TypeStr ("(anOrdinaryClass) from public part ID.\n");
	    TypeStr ("  Returned value was ");
	    TypeInt (res);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void VersionIDFromConfiguredClassIDTest (global VersionID vid,
					     global ConfiguredClassID ccid) {
	global VersionID res;

	TypeStr ("Checking VersionIDFromConfiguredClassID ... ");
	res = C->VersionIDFromConfiguredClassID (ccid);
	if (res != vid) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't get correct public ID (");
	    TypeOID (vid);
	    TypeStr (") from configured class ID (");
	    TypeOID (ccid);
	    TypeStr (").\n");
	    TypeStr ("  Returned ID was ");
	    TypeOID (res);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void GetParentsTest (global VersionID class_tester,
			 global VersionID launchable) { 
	global VersionID parents [];

	TypeStr ("Checking GetParents ... ");
	parents = C->GetParents (class_tester);
	inline "C" {
	    launchable = launchable + 1;
	}
	if (length parents > 0 && parents [0] != launchable) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't get correct parents ID (");
	    TypeOID (launchable);
	    TypeStr (") from version ID (");
	    TypeOID (parents [0]);
	    TypeStr (").\n");
	    TypeStr ("  Returned ID was ");
	    TypeOID (parents [0]);
	    TypeReturn ();
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void GeneralizedVersionOfTest (global VersionID class_tester) {
	global VersionID prot;
	global VersionID res;

	TypeStr ("Checking GeneralizedVersionOf ... ");
	prot = C->GetProtectedPart (class_tester);
	res = C->GeneralizedVersionOf (prot);
	if (res != class_tester) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't get correct public ID (");
	    TypeOID (class_tester);
	    TypeStr (") from protected class ID (");
	    TypeOID (prot);
	    TypeStr (").\n");
	    TypeStr ("  Returned ID was ");
	    TypeOID (res);
	    TypeReturn ();
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    global VersionID CreateNewPartTest ()[] {
	global VersionID vid [];

	length vid = 4;
	TypeStr ("Checking CreateNewPart ... \n");
	TypeStr ("  Creating root part ... ");
	vid [0] = C->CreateNewPart (0);
	if (C->WhichPart (vid [0]) != ClassPartName::aRootPart) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't create root part.\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("  Creating public part ... ");
	vid [1] = C->CreateNewPart (vid [0]);
	if (C->WhichPart (vid [1]) != ClassPartName::aPublicPart) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't create public part of ");
	    TypeOID (vid [0]);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("  Creating protected part ... ");
	vid [2] = C->CreateNewPart (vid [1]);
	if (C->WhichPart (vid [2]) != ClassPartName::aProtectedPart) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't create protected part of ");
	    TypeOID (vid [1]);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("  Creating implementation part ... ");
	vid [3] = C->CreateNewPart (vid [2]);
	if (C->WhichPart (vid [3]) != ClassPartName::anImplementationPart) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't create implementation part of ");
	    TypeOID (vid [2]);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("pass.\n");
	return vid;
    }

    global ConfiguredClassID
      CreateNewConfiguredClassTest (global VersionID vid)[] {
	  global ConfiguredClassID ccid [];

	  length ccid = 2;
	  TypeStr ("Checking CreateNewConfiguredClass ... \n");
	  TypeStr ("  Creating configured class ... ");
	  ccid [0] = C->CreateNewConfiguredClass (vid);
	  if (C->WhichPart (ccid [0]) != ClassPartName::aConfiguredClass) {
	      TypeStr ("failed.\n");
	      TypeStr ("  Couldn't create configured class of ");
	      TypeOID (vid);
	      TypeStr (".\n");
	      TestStop ();
	  }
	  TypeStr ("done.\n");
	  TypeStr ("  Setting default configured class ... ");
	  C->SetDefaultConfiguredClassID (vid, ccid [0]);
	  if (C->GetDefaultConfiguredClassID (vid) != ccid [0]) {
	      TypeStr ("failed.\n");
	      TypeStr ("  Couldn't set a configured class ID (");
	      TypeOID (ccid [0]);
	      TypeStr (") to a public part (");
	      TypeOID (vid);
	      TypeStr (") as default.\n");
	      TestStop ();
	  }
	  TypeStr ("done.\n");
	  TypeStr ("  Creating another configured class ... ");
	  ccid [1] = C->CreateNewConfiguredClass (vid);
	  TypeStr ("done.\n");
	  TypeStr ("  Setting default configured class in another way ... ");
	  C->SetItAsDefaultConfiguredClass (ccid [1]);
	  if (C->GetDefaultConfiguredClassID (vid) != ccid [1]) {
	      TypeStr ("failed.\n");
	      TypeStr ("  Couldn't set a configured class ID (");
	      TypeOID (ccid [1]);
	      TypeStr (") to a public part (");
	      TypeOID (vid);
	      TypeStr (") as default.\n");
	      TestStop ();
	  }
	  TypeStr ("done.\n");
	  TypeStr ("pass.\n");
	  return ccid;
      }

    void AddPropertyTest (global ConfiguredClassID ccid) {
	FileOperators fops;
	String path;

	TypeStr ("Checking AddProperty ... ");
	path=>NewFromArrayOfChar (C->GetClassFileDirectory (ccid));
	fops.Touch (path->ConcatenateWithArrayOfChar ("/private.r"));
	C->AddProperty (ccid, "private.r");
	if (C->LookupProperty (ccid, "private.r") == 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't add a property \"private.r\" ");
	    TypeStr ("to the configured class ");
	    TypeOID (ccid);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void RemovePropertyTest (global ConfiguredClassID ccid) {
	TypeStr ("Checking RemoveProperty ... ");
	C->RemoveProperty (ccid, "private.r");
	if (C->LookupProperty (ccid, "private.r") != 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't remove a property \"private.r\" ");
	    TypeStr ("from the configured class ");
	    TypeOID (ccid);
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void GetClassInformationsTest (global VersionID has_propeties,
				   global VersionID no_properties) {
	String path, work, work2;
	String id=>OIDtoHexa (has_propeties);

	TypeStr ("Checking GetClassInformations ... ");
	if (C->GetClassInformations (no_properties) != 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Class with no properties returned ");
	    TypeStr ("a class file directory name.\n");
	    TestStop ();
	}
	work=>NewFromArrayOfChar (C->GetClassInformations (has_propeties));
	path=>NewFromArrayOfChar ("images/");
	path = path->Concatenate (work2=>OIDtoHexa (C)->GetSubString (4, 6));
	path = path->ConcatenateWithArrayOfChar ("/classes/");
	path = path->Concatenate (id);
	if (path == 0 || work->IsNotEqualTo (path)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve correct path of ");
	    TypeStr ("class directory.\n");
	    TypeStr ("      (");
	    TypeString (path);
	    TypeStr (" => ");
	    TypeString (work);
	    TypeStr (")\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void ListProperties (String properties []) {
	unsigned int i, len = length properties;

	TypeStr ("    properties are:\n");
	for (i = 0; i < len; i++) {
	    TypeStr ("      ");
	    TypeString (properties [i]);
	}
    }

    void RegisterClassInformationsTest (global VersionID vid) {
	FileOperators fops;
	String dev_null=>NewFromArrayOfChar ("/dev/null");
	String arg;
	String vid_path=>OIDtoHexa (vid);
	String properties [];
	unsigned int len;

	TypeStr ("Checking RegisterClassInformations ... ");
	fops.Touch (arg
		    =>NewFromArrayOfChar (C->GetClassDirectoryPath ())
		    ->ConcatenateWithArrayOfChar ("/")
		    ->Concatenate (vid_path)
		    ->ConcatenateWithArrayOfChar ("/private.oz"));
	fops.Touch (arg
		    =>NewFromArrayOfChar (C->GetClassDirectoryPath ())
		    ->ConcatenateWithArrayOfChar ("/")
		    ->Concatenate (vid_path)
		    ->ConcatenateWithArrayOfChar ("/private.o"));
	C->RegisterClassInformations (vid);
	properties = C->GetProperties (vid);
	len = length properties;
	if (len != 2) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Number of properties is different (2 =>");
	    TypeInt (len);
	    TypeStr (").\n");
	    ListProperties (properties);
	    TestStop ();
	}
	if (! ((properties [0]->IsEqualToArrayOfChar ("private.oz")
		&& properties [1]->IsEqualToArrayOfChar ("private.o"))
	       || (properties [0]->IsEqualToArrayOfChar ("private.o")
		   && properties [1]->IsEqualToArrayOfChar ("private.oz")))) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Unknown properties.\n");
	    ListProperties (properties);
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void DelegateClassTest () {
	/* under implementation */
    }

    void RemoveClassTest (global VersionID vid [], 
			  global ConfiguredClassID ccid []) {
	unsigned int i;

	TypeStr ("Checking RemoveClass ... ");
	for (i = 0; i < 4; i ++) {
	    C->RemoveClass (vid [i]);
	    if (C->LookupClass (vid [i]) != 0) {
		TypeStr ("failed.\n");
		TypeStr ("  Couldn't remove class ");
		TypeOID (vid [i]);
		TypeStr (".\n");
		TestStop ();
	    }
	}
	for (i = 0; i < 2; i ++) {
	    C->RemoveClass (ccid [i]);
	    if (C->LookupClass (ccid [i]) != 0) {
		TypeStr ("failed.\n");
		TypeStr ("  Couldn't remove class ");
		TypeOID (ccid [i]);
		TypeStr (".\n");
		TestStop ();
	    }
	}
	TypeStr ("pass.\n");
    }

    void VersionStringTest () {
	global VersionID root_vid = 0, pub_vid, prot_vid, prot2_vid, impl_vid;
	global VersionID res_vid;
	VersionString p, res_p, vs;

	TypeStr ("Checking VersionString ...\n");
	root_vid = C->CreateNewPart (root_vid);
	pub_vid = C->CreateNewPart (root_vid);
	prot_vid = C->CreateNewPart (pub_vid);
	prot2_vid = C->CreateNewPart (pub_vid);
	impl_vid = C->CreateNewPart (prot2_vid);
	TypeStr ("  Checking CreateNewVersion ... ");
	C->CreateNewVersion (pub_vid);
	C->CreateNewVersion (prot_vid);
	C->CreateNewVersion (prot2_vid);
	C->CreateNewVersion (impl_vid);
	TypeStr ("done.\n");
	TypeStr ("  Checking SetItAsDefaultLowerVersion ... ");
	C->SetItAsDefaultLowerVersion (pub_vid);
	C->SetItAsDefaultLowerVersion (prot_vid);
	C->SetItAsDefaultLowerVersion (prot2_vid);
	C->SetItAsDefaultLowerVersion (impl_vid);
	TypeStr ("done.\n");
	TypeStr ("  Checking GetDefaultVersionID ... ");
	if (C->GetDefaultVersionID (root_vid) != pub_vid ||
	    C->GetDefaultVersionID (pub_vid) != prot2_vid ||
	    C->GetDefaultVersionID (prot_vid) != 0 ||
	    C->GetDefaultVersionID (prot2_vid) != impl_vid) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve correct default version ID.\n");
	    TypeStr ("      UpperPart        Correct Default    Returned\n    ");
	    TypeOID (root_vid);
	    TypeStr ("  ");
	    TypeOID (pub_vid);
	    TypeStr ("  ");
	    TypeOID (C->GetDefaultVersionID (root_vid));
	    TypeReturn ();

	    TypeOID (pub_vid);
	    TypeStr ("  ");
	    TypeOID (prot2_vid);
	    TypeStr ("  ");
	    TypeOID (C->GetDefaultVersionID (pub_vid));
	    TypeReturn ();

	    TypeOID (prot_vid);
	    TypeStr ("  ");
	    TypeOID (0);
	    TypeStr ("  ");
	    TypeOID (C->GetDefaultVersionID (prot_vid));
	    TypeReturn ();

	    TypeOID (prot2_vid);
	    TypeStr ("  ");
	    TypeOID (impl_vid);
	    TypeStr ("  ");
	    TypeOID (C->GetDefaultVersionID (prot2_vid));
	    TypeReturn ();

	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("  Checking GetVersionString ... ");
	if (C->GetVersionString (root_vid)
	    ->AsString ()->IsNotEqualToArrayOfChar ("*.*.*") ||
	    C->GetVersionString (pub_vid)
	    ->AsString ()->IsNotEqualToArrayOfChar ("1.*.*") ||
	    C->GetVersionString (prot_vid)
	    ->AsString ()->IsNotEqualToArrayOfChar ("1.1.*") ||
	    C->GetVersionString (prot2_vid)
	    ->AsString ()->IsNotEqualToArrayOfChar ("1.2.*") ||
	    C->GetVersionString (impl_vid)
	    ->AsString ()->IsNotEqualToArrayOfChar ("1.2.1")) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve correct version string.\n");
	    TypeStr ("                       Correct Returned\n");
	    TypeStr ("    RootPart:           *.*.*   ");
	    TypeStr (C->GetVersionString (root_vid)->Content ());
	    TypeReturn ();

	    TypeStr ("    PublicPart:         1.*.*   ");
	    TypeStr (C->GetVersionString (pub_vid)->Content ());
	    TypeReturn ();

	    TypeStr ("    ProtectedPart:      1.1.*   ");
	    TypeStr (C->GetVersionString (prot_vid)->Content ());
	    TypeReturn ();

	    TypeStr ("    ProtectedPart:      1.2.*   ");
	    TypeStr (C->GetVersionString (prot2_vid)->Content ());
	    TypeReturn ();

	    TypeStr ("    ImplementationPart: 1.2.1   ");
	    TypeStr (C->GetVersionString (impl_vid)->Content ());
	    TypeReturn ();

	    TestStop ();
	}
	TypeStr ("done.\n");
	p = C->GetVersionString (pub_vid);
	TypeStr ("  Checking DefaultVersionString ... ");
	res_p = C->DefaultVersionString (root_vid);
	if (p->IsNotEqualTo (res_p)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve correct default version string (");
	    TypeStr (p->Content ());
	    TypeStr (") from root part (");
	    TypeOID (root_vid);
	    TypeStr (")\n");
	    TypeStr ("  Returned version string was ");
	    TypeStr (res_p->Content ());
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("  Checking VersionIDFromVersionString ... ");
	if (C->VersionIDFromVersionString (root_vid, p) != pub_vid) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve correct version ID (");
	    TypeOID (pub_vid);
	    TypeStr (") from public version string (");
	    TypeStr (p->Content ());
	    TypeStr (")\n");
	    TypeStr ("  Returned ID was ");
	    TypeOID (C->VersionIDFromVersionString (root_vid, p));
	    TypeStr (".\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	C->RemoveClass (impl_vid);
	C->RemoveClass (prot2_vid);
	C->RemoveClass (prot_vid);
	C->RemoveClass (pub_vid);
	C->RemoveClass (root_vid);
	TypeStr ("pass.\n");
    }

    void Test () {
	global VersionID parents_of_ClassTester [];
	global ConfiguredClassID ccid_of_ClassTester;
	global VersionID public_ID_of_ClassTester;
	global VersionID public_ID_of_Launchable;
	global VersionID new_vid [];
	global ConfiguredClassID ccid [];

	inline "C" {
	    public_ID_of_ClassTester = self->head.a;
	    ccid_of_ClassTester = OzExecGetObjectTop (self)->head[0].a;
	    public_ID_of_Launchable = OzExecGetObjectTop (self)->head[2].a;
	}

	C = Where ()->SearchClass (public_ID_of_ClassTester, AID);
	WhichPartTest (public_ID_of_ClassTester, ccid_of_ClassTester);
	WhichKindTest (public_ID_of_ClassTester);
	VersionIDFromConfiguredClassIDTest (public_ID_of_ClassTester,
					    ccid_of_ClassTester);
	GetParentsTest (public_ID_of_ClassTester, public_ID_of_Launchable);
	GeneralizedVersionOfTest (public_ID_of_ClassTester);
	new_vid = CreateNewPartTest ();
	ccid = CreateNewConfiguredClassTest (new_vid [1]);
	AddPropertyTest (ccid [1]);
	RemovePropertyTest (ccid [1]);
	GetClassInformationsTest (public_ID_of_ClassTester, new_vid [0]);
	RegisterClassInformationsTest (new_vid [3]);
	RemoveClassTest (new_vid, ccid);
	VersionStringTest ();
    }
}
