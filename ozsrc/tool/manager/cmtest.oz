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
 * cmtest.oz
 *
 * class copy management tester
 */

class ClassCopyManagementTester : Tester (alias Initialize SuperInitialize;) {
  constructor: New;
  public: Launch;

/* instance variables */
    ArchitectureID AID;
    global Class C1, C2;
    global ConfiguredClassID MyCCID;
    global VersionID MyPublicID;
    global VersionID ObjectPublicID;

/* method implementations */
    void Initialize () {
	SuperInitialize ();
	AID=>Any ();
    }

    String Title () {
	String title;

	title=>NewFromArrayOfChar ("Test Suits for Class Copy Management");
	return title;
    }

    global Class ReadClass (char msg []) {
	String
	  prompt=>NewFromArrayOfChar ("Enter the name (or object ID) of the ");

	prompt
	  = prompt->ConcatenateWithArrayOfChar (msg)
	    ->ConcatenateWithArrayOfChar (" target class: ");
	return narrow (Class, ReadObject (prompt->Content ()));
    }

    void GetMyIDs () {
	global ConfiguredClassID ccid;
	global VersionID vid1, vid2;

	inline "C" {
	    ccid = OzExecGetObjectTop (self)->head [0].a;
	    vid1 = self->head.a;
	    vid2 = OzExecGetObjectTop (self)->head [1].a;
	}
	MyCCID = ccid;
	MyPublicID =  vid1;
	ObjectPublicID = vid2;
    }

    int CheckCopyKind (int kind, int correct) {
	if (kind != correct) {
	    TypeStr ("failed.\n");
	    switch (kind) {
	      case ClassCopyKind::Original:
		TypeStr ("  It's Original.\n");
		break;
	      case ClassCopyKind::Mirror:
		TypeStr ("  It's Mirror.\n");
		break;
	      case ClassCopyKind::Boot:
		TypeStr ("  It's Boot.\n");
		break;
	      case ClassCopyKind::Snapshot:
		TypeStr ("  It's Snapshot.\n");
		break;
	      case ClassCopyKind::Private:
		TypeStr ("  It's Private.\n");
		break;
	    }
	    return 0;
	} else {
	    return 1;
	}
    }

    int CheckMirrorMode (global Class from, global Class to,
			 global ClassPackageID cpid, int correct_mode,
			 char msg []) {
	OriginalClassPackage ocp;
	int mode;

	TypeStr ("  What is the mirror mode? ... ");
	ocp = from->GetOriginalClassPackage (cpid);
	mode = ocp->WhichMirrorMode (to);
	if (mode != correct_mode) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The mirror mode is not correct: it's ");
	    switch (ocp->WhichMirrorMode (to)) {
	      case MirrorMode::Polling:
		TypeStr ("polling.\n");
		break;
	      case MirrorMode::CopyOnWrite:
		TypeStr ("copy-on-write.\n");
		break;
	      case MirrorMode::WriteInvalidate:
		TypeStr ("write-invalidate.\n");
		break;
	      default:
		TypeStr ("unknown mode.\n");
		break;
	    }
	    TestStop ();
	}
	TypeStr (msg);
    }

    void TestBootClass () {
	TypeStr ("Checking boot classes ...\n");
	TypeStr ("  Is the class Object is boot class? ... ");
	if (! C1->IsBootClass (ObjectPublicID)) {
	    TypeStr ("  failed.\n");
	    TypeStr ("  Public ID of class Object is not a boot class.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Which kind of copy is the class Object? ... ");
	if (CheckCopyKind (C1->WhichKindOfCopy (ObjectPublicID),
			   ClassCopyKind::Boot)) {
	    TypeStr ("Boot.\n");
	} else {
	    TestStop ();
	}
	TypeStr ("  Listing boot classes ... ");
	if (C1->ListBootClasses () == 0) {
	    TypeStr ("  failed.\n");
	    TypeStr ("  No boot class is found.\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
    }

    global VersionID TestOriginal () {
	global VersionID new_root;
	global ClassID cids [];
	unsigned int i, len;

	TypeStr ("Checking original classes ...\n");
	TypeStr ("  Creating new root part ... ");
	new_root = C1->CreateNewPart (0);
	TypeOID (new_root);
	TypeStr (".\n");
	TypeStr ("  Is the new root part original? ... ");
	if (! C1->IsOriginal (new_root)) {
	    TypeStr ("  failed.\n");
	    TypeStr ("  Newly created root part is not  original.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Which kind of copy is the new root part? ... ");
	if (CheckCopyKind (C1->WhichKindOfCopy (new_root),
			   ClassCopyKind::Original)) {
	    TypeStr ("Original.\n");
	} else {
	    TestStop ();
	}
	TypeStr ("  Listing original classes ... ");
	cids = C1->ListOriginals ();
	if (cids == 0) {
	    TypeStr ("  failed.\n");
	    TypeStr ("  No original class is found.\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("  Does the list include the newly created root part? ... ");
	len = length cids;
	for (i = 0; i < len; i ++) {
	    if (cids [i] == new_root) {
		TypeStr ("yes.\n");
		return new_root;
	    }
	}
	TypeStr ("  failed.\n");
	TypeStr ("  Newly created root part is not listed ");
	TypeStr ("as an original class.\n");
	TestStop ();
    }

    global VersionID TestPrivate (global VersionID root) {
	global VersionID pub;
	global ClassID cids [];
	unsigned int i, len;

	TypeStr ("Checking private classses ...\n");
	TypeStr ("  Creating new public part under the new root part ... ");
	pub = C1->CreateNewPart (root);
	TypeOID (pub);
	TypeStr (".\n");
	TypeStr ("  Privatizing it ... ");
	C1->Privatize (pub);
	TypeStr ("done.\n");
	TypeStr ("  Is the privatized public part private? ... ");
	if (! C1->IsPrivate (pub)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The privatized public part is not private.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Which kind of copy is the new public part? ... ");
	if (CheckCopyKind (C1->WhichKindOfCopy (pub),
			   ClassCopyKind::Private)) {
	    TypeStr ("Private.\n");
	} else {
	    TestStop ();
	}
	TypeStr ("  Listing private classes ... ");
	cids = C1->ListPrivates ();
	if (cids == 0) {
	    TypeStr ("  failed.\n");
	    TypeStr ("  No private class is found.\n");
	    TestStop ();
	}
	TypeStr ("done.\n");
	TypeStr ("  Does the list include the newly create public part? ... ");
	len = length cids;
	for (i = 0; i < len; i ++) {
	    if (cids [i] == pub) {
		TypeStr ("yes.\n");
	    }
	}
	return pub;
    }

    global ClassPackageID
      TestOriginalPackage (global VersionID root, global VersionID pub) {
	  ClassPackage cp;
	  ClassPackage cps [];
	  global ClassPackageID cpid;
	  global ClassPackageID cpids [];
	  global ClassID cids [];
	  unsigned int i, len;

	  TypeStr ("Checking original package ...\n");
	  TypeStr
	    ("  Creating a new original package by the new root part ... ");
	  cp=>New ();
	  cp->Add (root);
	  cpid = C1->RegisterClassPackage (cp);
	  TypeStr ("done.\n");
	  TypeStr ("  Is the class package is original class package? ... ");
	  if (! C1->IsOriginalClassPackage (cpid)) {
	      TypeStr ("failed.\n");
	      TypeStr ("  The newly created class package is ");
	      TypeStr ("not a original class package.\n");
	      TestStop ();
	  }
	  TypeStr ("yes.\n");
	  TypeStr ("  Getting the new original class package ... ");
	  cp = C1->GetOriginalClassPackage (cpid);
	  TypeStr ("done.\n");
	  TypeStr ("  Does the class package include the class parts? ... ");
	  if (! cp->Includes (root)) {
	      TypeStr ("failed.");
	      TypeStr ("  The class package doesn't include the root part.\n");
	      TestStop ();
	  }
	  TypeStr ("yes.\n");
	  TypeStr ("  Adding a public part to the class package ... ");
	  length cids = 1;
	  cids [0] = pub;
	  C1->AddToClassPackage (cpid, cids);
	  TypeStr ("done.\n");
	  TypeStr ("  Does the class package include the both part? ... ");
	  cp = C1->GetOriginalClassPackage (cpid);
	  if (! cp->Includes (pub) || ! cp->Includes (root)) {
	      TypeStr ("failed.\n");
	      if (! cp->Includes (pub) && cp->Includes (root)) {
		  TypeStr ("  The class package doesn't ");
		  TypeStr ("include the public part.\n");
	      }
	      if (cp->Includes (pub) && ! cp->Includes (root)) {
		  TypeStr ("  The class package doesn't ");
		  TypeStr ("include the root part.\n");
	      }
	      if (! cp->Includes (pub) && ! cp->Includes (root)) {
		  TypeStr ("  The class package doesn't ");
		  TypeStr ("include the root part and the public part.\n");
	      }
	      TestStop ();
	  }
	  TypeStr ("yes.\n");
	  TypeStr ("  Deleting the root part from the class package ... ");
	  cids [0] = root;
	  C1->DeleteFromClassPackage (cpid, cids);
	  TypeStr ("done.\n");
	  TypeStr
	    ("  Does the class package include only the public part? ...");
	  cp = C1->GetOriginalClassPackage (cpid);
	  if (! cp->Includes (pub) || cp->Includes (root)) {
	      TypeStr (" failed.\n");
	      if (! cp->Includes (pub) && ! cp->Includes (root)) {
		  TypeStr ("  The class package doesn't ");
		  TypeStr ("include the public part.\n");
	      }
	      if (cp->Includes (pub) && cp->Includes (root)) {
		  TypeStr ("  The class package include the root part.\n");
	      }
	      if (! cp->Includes (pub) && cp->Includes (root)) {
		  TypeStr ("  The class package doesn't ");
		  TypeStr ("include the public part ");
		  TypeStr ("and include the root part.\n");
	      }
	      TestStop ();
	  }
	  TypeStr (" yes.\n");
	  TypeStr ("  Getting a list of belonging class packages ");
	  TypeStr ("of the root part ... ");
	  cpids = C1->GetBelongingOriginalClassPackages (root);
	  TypeStr ("  done.\n");
	  TypeStr ("  Is the list empty? ... ");
	  if (length cpids != 0) {
	      TypeStr ("failed.\n");
	      TypeStr ("  The list is not empty.\n");
	      TestStop ();
	  }
	  TypeStr ("yes.\n");
	  TypeStr ("  Getting a list of belonging class packages ");
	  TypeStr ("of the public part ... ");
	  cpids = C1->GetBelongingOriginalClassPackages (pub);
	  TypeStr ("done.\n");
	  TypeStr ("  Does the list consists of only the class package? ... ");
	  if (length cpids != 1 || cpids [0] != cpid) {
	      TypeStr ("failed.\n");
	      if (length cpids != 1) {
		  TypeStr ("  The list consists of more than 1 package.\n");
	      } else {
		  TypeStr ("  The contents of the list is ");
		  TypeStr ("not the class package.\n");
	      }
	      TestStop ();
	  }
	  TypeStr ("yes.\n");
	  TypeStr ("  Listing original class packages ... ");
	  cpids = C1->ListOriginalClassPackages ();
	  TypeStr ("done.\n");
	  TypeStr ("  Does the list include the class package? ... ");
	  len = length cpids;
	  for (i = 0; i < len; i ++) {
	      if (cpids [i] == cpid) {
		  TypeStr ("yes.\n");
		  return cpid;
	      }
	  }
	  TypeStr ("failed.\n");
	  TypeStr ("  The list doesn't include the class package.\n");
	  TestStop ();
      }

    void TestSnapshot (global VersionID root) {
	global ClassID cids [];
	unsigned int i, len;

	TypeStr ("Checking snapshot ... \n");
	TypeStr ("  Distributing the root part ");
	TypeStr ("to the second target class object ... ");
	C1->DelegateClass (root, C2);
	TypeStr ("done.\n");
	TypeStr ("  Is the root part snapshot? ... ");
	if (! C2->IsSnapshot (root)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  A distributed class part is not snapshot.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Which kind of copy is the distributed root part? ... ");
	if (CheckCopyKind (C2->WhichKindOfCopy (root),
			   ClassCopyKind::Snapshot)) {
	    TypeStr ("Snapshot.\n");
	} else {
	    TestStop ();
	}
	TypeStr ("  Listing snapshot classes ... ");
	cids = C2->ListSnapshots ();
	TypeStr ("done.\n");
	TypeStr ("  Does the list include the root part? ... ");
	len = length cids;
	for (i = 0; i < len; i ++) {
	    if (cids [i] == root) {
		TypeStr ("yes.\n");
		return;
	    }
	}
	TypeStr ("failed.\n");
	TypeStr
	  ("  The list of snapshot doesn't include the distributed part.\n");
	TestStop ();
    }

    void TestMirror (global ClassPackageID cpid, global VersionID root,
		     global VersionID pub) {
	MirroredClassPackage mcp;
	global ClassID cids [];
	global ClassPackageID cpids [];
	unsigned int i, len;

	TypeStr ("Checking mirror ... \n");
	TypeStr ("  Setting mirror of the class package ");
	TypeStr ("from the main target (C1) to the second\n");
	TypeStr ("  target (C2) in mode CopyOnWrite ... ");
	C2->SetMirror (C1, cpid, MirrorMode::CopyOnWrite);
	TypeStr ("done.\n");
	TypeStr ("  Is the class package id mirrored class package? ... ");
	if (! C2->IsMirroredClassPackage (cpid)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The newly mirrored class package is ");
	    TypeStr ("not registered as a mirroed class package.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Is the public part mirror? ... ");
	if (! C2->IsMirror (pub)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The public part is not a mirror.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Which kind of copy is the mirrored public part? ... ");
	if (CheckCopyKind (C2->WhichKindOfCopy (pub),
			   ClassCopyKind::Mirror)) {
	    TypeStr ("Mirror.\n");
	} else {
	    TestStop ();
	}
	CheckMirrorMode (C1, C2, cpid, MirrorMode::CopyOnWrite,
			 "copy-on-write.\n");
	TypeStr ("  Getting a list of class package IDs of mirrors ");
	TypeStr ("which include the public part\n");
	TypeStr ("  from the second target ... ");
	cpids = C2->GetBelongingMirrors (pub);
	TypeStr ("done.\n");
	TypeStr ("  Does the list consist of only the class package? ... ");
	if (length cpids > 1) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The list include more than one class packages ID.\n");
	    TestStop ();
	} else if (length cpids == 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The list is empty.\n");
	    TestStop ();
	} else if (cpids [0] != cpid) {
	    TypeStr ("  The member of the list is not the class package.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  The mirrored class package include the public part? ... ");
	mcp = C2->GetMirroredClassPackage (cpid);
	if (! mcp->Includes (pub)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The mirrored class package ");
	    TypeStr ("doesn't include the public part.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Listing mirrors in C2 ... ");
	cpids = C2->ListMirrors ();
	TypeStr ("done.\n");
	TypeStr ("  Does the list include the class package? ... ");
	len = length cpids;
	for (i = 0; i < len; i ++) {
	    if (cpids [i] == cpid) {
		break;
	    }
	}
	if (i == len) {
	    TypeStr ("failed.\n");
	    TypeStr ("The list doesn't include the class package.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
	TypeStr ("  Changing the original public part ");
	TypeStr ("by adding properties ... ");
	C1->RegisterClassInformations (pub);
	TypeStr ("done.\n");
	TypeStr ("  Confirm that the class distribution has started.\n");
	TypeStr ("  Type Return to progress: ");
	Read ();
	TypeStr ("  Changing the mirror mode to WriteInvalidate ... ");
	C2->ChangeMirrorMode (cpid, MirrorMode::WriteInvalidate);
	TypeStr ("done.\n");
	CheckMirrorMode (C1, C2, cpid, MirrorMode::WriteInvalidate,
			 "write-invalidate.\n");
	TypeStr ("  Again, changing the original public part ");
	TypeStr ("by adding properties ... ");
	C1->RegisterClassInformations (pub);
	TypeStr ("done.\n");
	TypeStr ("  Confirm that the class distribution has not started.\n");
	TypeStr ("  Type Return to progress: ");
	Read ();
	TypeStr ("  Accessing the mirrored class ... ");
	C2->GetClassFileDirectory (pub);
	TypeStr ("done.\n");
	TypeStr ("  Confirm that the class distribution has started.\n");
	TypeStr ("  Type Return to progress: ");
	Read ();
	TypeStr ("  Adding the new root part ");
	TypeStr ("to the original class package ... ");
	length cids = 1;
	cids [0] = root;
	C1->AddToClassPackage (cpid, cids);
	TypeStr ("done.\n");
	TypeStr ("  Addition of new member must be propagated to mirrors.\n");
	TypeStr ("  Confirm that the class distribution has started.\n");
	TypeStr ("  Type Return to progress: ");
	Read ();
	TypeStr ("  Unsetting the mirror ... ");
	C2->UnsetMirror (cpid);
	TypeStr ("done.\n");
	TypeStr ("  An unsetted mirror should be a snapshot.\n");
	TypeStr ("  Are the root and the public part snapshots? ... ");
	if (! C2->IsSnapshot (root)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The root part is not a snapshot.\n");
	    TestStop ();
	} else if (! C2->IsSnapshot (pub)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  The public part is not a snapshot.\n");
	    TestStop ();
	}
	TypeStr ("yes.\n");
    }

    void RemoveClasses (global ClassPackageID cpid,
			global VersionID root, global VersionID pub) {
	TypeStr ("Destroying the original class package ... ");
	C1->DestroyClassPackage (cpid);
	TypeStr ("done.\n");
	TypeStr ("Removing newly created class parts ...\n");
	TypeStr ("  The new root part from C1 ... ");
	C1->RemoveClass (root);
	TypeStr ("done.\n");
	TypeStr ("  The new public part from C1 ... ");
	C1->RemoveClass (pub);
	TypeStr ("done.\n");
	TypeStr ("  The new root part from C2 ... ");
	C2->RemoveClass (root);
	TypeStr ("done.\n");
	TypeStr ("  The new public part from C2 ... ");
	C2->RemoveClass (pub);
	TypeStr ("done.\n");
    }

    void Test () {
	global VersionID root, pub;
	global ClassPackageID cpid;

	GetMyIDs ();
	C1 = ReadClass ("main");
	C2 = ReadClass ("second");
	TestBootClass ();
	root = TestOriginal ();
	pub = TestPrivate (root);
	cpid = TestOriginalPackage (root, pub);
	TestSnapshot (root);
	TestMirror (cpid, root, pub);
	RemoveClasses (cpid, root, pub);
    }
}
