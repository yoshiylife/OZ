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
 * ndtest.oz
 *
 * name directory tester
 */

class NameDirectoryTester :
  Tester (alias Initialize SuperInitialize;),
  ResolvableObject
{
  constructor: New;
  public: Launch;

/* instance variables */
    String Me;
    String Me2;
    String Name;

/* method implementations */
    void Initialize () {
	String o=>OIDtoHexa (Where ());

	SuperInitialize ();
	Me=>NewFromArrayOfChar (":NameDirectoryTester-");
	Me = Me->Concatenate (o);
	Me2=>NewFromArrayOfChar (":NameDirectoryTester-2-");
	Me2 = Me2->Concatenate (o);
	Name=>NewFromArrayOfChar (":name");
    }

    void CheckIncludes (global NameDirectory nd) {
	TypeStr ("Checking Includes ... ");
	if (! nd->Includes (Name)) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Counldn't find name directory itself.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckResolve (global NameDirectory nd) {
	TypeStr ("Checking Resolve ... ");
	if (nd->Resolve (Name) != nd) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't resolve \":name\" to the NameDirectory "
		     "itself.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
	TypeStr ("Checking ResolveWithArrayOfChar ... ");
	if (nd->ResolveWithArrayOfChar (Name->Content ()) != nd) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't resolve \":name\" to the NameDirectory "
		     "itself.\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckAddObject (global NameDirectory nd, global ResolvableObject ro) {
	TypeStr ("Checking AddObject ... ");
	nd->AddObject (Me, ro);
	if (nd->Resolve (Me) != ro) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve added object ");
	    TypeOID (ro);
	    TypeStr (" by the name \"");
	    TypeString (Me);
	    TypeStr ("\".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
	TypeStr ("Checking AddObjectWithArrayOfChar ... ");
	nd->AddObjectWithArrayOfChar (Me2->Content (), ro);
	if (nd->Resolve (Me2) != ro) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve added object ");
	    TypeOID (ro);
	    TypeStr (" by the name \"");
	    TypeString (Me2);
	    TypeStr ("\".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckChangeObject (global NameDirectory nd,
			    global ResolvableObject ro) {
	TypeStr ("Checking ChangeObject ... ");
	nd->ChangeObject (Me, nd);
	if (nd->Resolve (Me) != nd) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve changed object ");
	    TypeOID (nd);
	    TypeStr (" by the name \"");
	    TypeString (Me);
	    TypeStr ("\".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
	TypeStr ("Checking ChangeObjectWithArrayOfChar ... ");
	nd->ChangeObjectWithArrayOfChar (Me->Content (), ro);
	if (nd->Resolve (Me) != ro) {
	    TypeStr ("failed.\n");
	    TypeStr ("  Couldn't retrieve changed object ");
	    TypeOID (ro);
	    TypeStr (" by the name \"");
	    TypeString (Me);
	    TypeStr ("\".\n");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void CheckRemoveObjectWithName (global NameDirectory nd) {
	TypeStr ("Checking RemoveObjectWithName ... ");
	nd->RemoveObjectWithName (Me);
	if (nd->Resolve (Me) != 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  NameDirectory couldn't remove correctly\n.");
	    TestStop ();
	}
	TypeStr ("pass.\n");
	TypeStr ("Checking RemoveObjectWithNameWithArrayOfChar ... ");
	nd->RemoveObjectWithNameWithArrayOfChar (Me2->Content ());
	if (nd->Resolve (Me) != 0) {
	    TypeStr ("failed.\n");
	    TypeStr ("  NameDirectory couldn't remove correctly\n.");
	    TestStop ();
	}
	TypeStr ("pass.\n");
    }

    void PrintList (global NameDirectory nd) {
	String st=>NewFromArrayOfChar ("");
	Set <String> src=>New ();
	Set <String> dst=>New ();

	TypeStr ("Checking List ... ");
	src->Add (st);
	while (src->Size () > 0) {
	    String st = src->RemoveAny ();
	    String stdir = st->ConcatenateWithArrayOfChar (":");
	    Set <String> s = nd->ListDirectory (st);

	    while (s->Size () > 0) {
		String any = s->RemoveAny ();

		if (any->Length () > 0) {
		    String dir = stdir->Concatenate (any);

		    src->Add (dir);
		    dst->Add (dir);
		}
	    }
	    s = nd->ListEntry (st);
	    while (s->Size () > 0) {
		dst->Add (stdir->Concatenate (s->RemoveAny ()));
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

    void Test () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	global ResolvableObject ro = Where ();

	TypeStr ("NameDirectoryTester\n");
	TypeStr ("NameDirectory = ");
	TypeOID (nd);
	TypeStr (".\n");
	if (nd->IsReady () == 0) {
	    TypeStr ("Error:NameDirectory is not Ready.\n");
	    TestStop ();
	}
	try {
	    CheckIncludes (nd);
	    CheckResolve (nd);
	    CheckAddObject (nd, ro);
	    CheckChangeObject (nd, ro);
	    CheckRemoveObjectWithName (nd);
	    PrintList (nd);
	} except {
	    default {
		if (nd->Resolve (Me) != 0) {
		    nd->RemoveObjectWithName (Me);
		}
		if (nd->Resolve (Me2) != 0) {
		    nd->RemoveObjectWithName (Me2);
		}
		raise;
	    }
	}
    }

    String Title () {
	String title=>NewFromArrayOfChar ("Test Suits for NameDirectory");

	return title;
    }
}
