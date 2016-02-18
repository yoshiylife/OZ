/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
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


// we distribute class not by tar'ed directory


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

/*
 * namedir.oz
 *
 * name directory by directory server
 */

/*
   Now, methods below are not supported 
   AddResolver, IsRegisteredResolver, ListAllResolverNames,
   RemoveObject, RemoveResolver, RemoveResolverFromTable,
   RemoveResolverWithName,
 */

class NameDirectory :
  DirectoryServer <global ResolvableObject>
  (alias New SuperNew;
   alias JoinSystem SuperJoinSystem;
   rename Update ChangeObject;
   rename Remove RemoveObjectWithName;
   rename DirectoryServerOf ResponsibleResolver;)
{
  constructor: New, NewDirectorySystem;

  public: Go, Removing, Stop;

  public:
    AddObject, AddObjectWithArrayOfChar, ChangeObject,
    ChangeObjectWithArrayOfChar, Copy, Exclude, Flush, Includes, IsaDirectory,
    IsaMember, IsEmpty, IsReady, Join, List, ListDirectory, ListEntry,
    MakeDirectory, Migrate, Move, NewDirectory, RemoveDirectory,
    RemoveObjectWithName, RemoveObjectWithNameWithArrayOfChar, Resolve,
    ResolveWithArrayOfChar, ResponsibleResolver, Terminate;

  protected: /* methods */
    BroadcastToSearchOther, CheckAndExclude, ConvertPathNameToSubsystem,
    DirectoryServerOfImpl, EliminateAllOrphans, Header, Initialize, JoinSystem,
    LockSelf, MigrateFromTo, MoveDirectory, RegisterToNameDirectory, Retrieve,
    Shutdown, Trailer, UnRegisterFromNameDirectory;

  protected: /* accessor */
    AddToMembers, AddToOwnMap, AddToOwnTops, AddToSystemMapLocally,
    DirectoryServers, DoYouHave, FlushImpl, GetOwnMap, GetOwnTops,
    GetSystemMap, PrepareToBeLockedGlobal, RemoveFromMembers, RemoveFromOwnMap,
    RemoveFromSystemMapLocally, SearchOwnMap, SearchSystemMap,
    SetSystemInformation, TestAndLock, UnLock;


  protected: SetNameDirectory;


  protected: /* instance variables */
    OwnMap, SystemMap, Members, OwnTops, Delimiter;

    /* I/F of this class */

  public: ChangeDomain, SetDomainName, WhichDomain;

/* instance variables */
  protected: DomainName, MyName;

    String DomainName;
    String MyName;

/* method implementations */
    global DirectoryServer <global ResolvableObject>
      CreateNewDirectoryServer (global ObjectManager where) {
	  global NameDirectory new=>New (SystemMap, Members)@where;

	  new->SetDomainName (DomainName);
	  return new;
      }

    void Go () : global {


	inline "C" {
	    _oz_debug_flag = 1;
	}


	debug (0, "NameDirectory::Go: Name Directory Started.\n");
	detach fork Initialize ();
    }

    void Shutdown () {}

    global DirectoryServer <global ResolvableObject>
      AddObject (String path, global ResolvableObject o)
	: global {
	    String header;

	    try {
		return Register (path, o);
	    } except {
	      DirectoryExceptions::UnknownDirectory (header) {
		  MakeDirectory (header);
		  return Register (path, o);
	      }
	    }
	}

    global DirectoryServer <global ResolvableObject>
      AddObjectWithArrayOfChar (char s [], global ResolvableObject o)
	: global {
	    String path=>NewFromArrayOfChar (s);

	    return AddObject (path, o);
	}

    int AskToJoin (global DirectoryServer <global ResolvableObject> ds,
		   String dir) {
	String s;
	int res;

	try {
	    if ((dir == 0) || ds->DoYouHave (dir)) {
		if (! IsaMember (ds) || ! ds->IsaMember (oid)) {
		    ds->Join (oid);
		}
		res = 1;
	    } else {
		res = 0;
	    }
	} except {
	  DirectoryExceptions::OverWriteProhibited (s) {
	      raise;
	  }
	    default {
		res = 0;
	    }
	}
	return res;
    }

    global NameDirectory BroadcastToSearchOther () {
	global NameDirectory nd;
	Waiter w=>New ();

	nd = 0;
	detach fork SetNameDirectory (nd, w);
	detach fork w->Timer (60);
	if (w->WaitAndTest ()) {
	    nd = Where ()->GetNameDirectory ();
	}
	Where ()->SetNameDirectory (oid);
	return nd;
    }

    global DirectoryServer <global ResolvableObject>
      ChangeObjectWithArrayOfChar (char s [], global ResolvableObject new)
	: global {
	    String path=>NewFromArrayOfChar (s);

	    return ChangeObject (path, new);
	}

    String GetDelimiter () {
	String delimiter=>NewFromArrayOfChar (":");

	return delimiter;
    }

    String GetSystemName () {
	String system_name=>NewFromArrayOfChar (":name");

	return system_name;
    }

    void Join (global DirectoryServer <global ResolvableObject> ds) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set;
	String domain;
	int finished = 0;

	lock_set=>New ();
	while (! finished) {
	    try {
		lock_set->Add (oid);
		lock_set->Add (ds);
		while (! lock_set->Lock ())
		  ;
		domain = narrow (NameDirectory, ds)->WhichDomain ();
		if (DomainName->IsEqualTo (domain)) {
		    PrepareToBeLockedGlobal (lock_set);
		    if (lock_set->Lock ()) {
			JoinImpl (ds);
			finished = 1;
		    } else {
			lock_set->RemoveAllContent ();
			/* retry */
		    }
		} else {
		    raise DirectoryExceptions::DomainConfliction (domain);
		}
	    } except {
		default {
		    lock_set->UnLock ();
		    raise;
		}
	    }
	}
	lock_set->UnLock ();
    }

    /*
     * If I'm the root server, register self to me.  All Members' are tried in
     * order.  If one of them is alive, ask it to join.  If no other member is
     * alive, try broadcasting.
     *
     * If I'm not the root server, all Members' are tried in order.  If it is
     * the root server, ask it to join.  If the root server cannot be found,
     * try broadcasting.
     */
    void JoinSystem () {
	Iterator
	  <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;
	OIDAsKey <global DirectoryServer <global ResolvableObject>> k;
	global DirectoryServer <global ResolvableObject> ds;
	global NameDirectory nd;
	String null=>NewFromArrayOfChar (""), s;
	int finished = 0;

	if (SearchOwnMap (null) != 0) {
	    if (Resolve (SystemName) == 0) {
		AddObject (SystemName, oid);
	    } else {
		ChangeObject (SystemName, oid);
	    }
	    for (i=>New (Members); (k = i->PostIncrement ()) != 0;) {
		ds = k->Get ();
		finished = AskToJoin (ds, 0);
	    }
	    if (! finished) {
		nd = BroadcastToSearchOther ();
		if (nd != 0 && nd != oid) {
		    finished = AskToJoin (nd, 0);
		}
	    }
	} else {
	    for (i=>New (Members); (k = i->PostIncrement ()) != 0;) {
		ds = k->Get ();
		finished = AskToJoin (ds, null);
	    }
	    while (! finished) {
		nd = BroadcastToSearchOther ();
		if (nd != 0 && nd != oid) {
		    finished = AskToJoin (nd, null);
		}
	    }
	}
    }

    global DirectoryServer <global ResolvableObject>
      MakeDirectory (String path)
	: global {
	    String header;

	    while (1) {
		try {
		    return NewDirectory (path);
		} except {
		  DirectoryExceptions::UnknownDirectory (header) {
		      MakeDirectory (header);
		      /* continue */
		  }
		}
	    }
	}
 
    global ResolvableObject RemoveObjectWithNameWithArrayOfChar (char s [])
      : global {
	  String path=>NewFromArrayOfChar (s);

	  return RemoveObjectWithName (path);
      }

    global ResolvableObject Resolve (String path) : global {
	try {
	    if (ListEntry (path)->Size () > 0) {
		return Retrieve (path);
	    } else {
		return 0;
	    }
	} except {
	  DirectoryExceptions::UnknownDirectory (path) {
	      return 0;
	  }
	  DirectoryExceptions::UnknownEntry (path) {
	      return 0;
	  }
	}
    }

    global ResolvableObject ResolveWithArrayOfChar (char s []) : global {
	String path=>NewFromArrayOfChar (s);

	return Resolve (path);
    }

    void ChangeDomain (String new_domain) : global {
	Iterator
	  <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;
	OIDAsKey <global DirectoryServer <global ResolvableObject>> k;
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set;

	lock_set=>New ();
	while (1) {
	    PrepareToBeLockedGlobal (lock_set);
	    if (lock_set->Lock ())
	      break;
	    lock_set->RemoveAllContent ();
	}
	for (i=>New (Members); (k = i->PostIncrement ()) != 0;) {
	    narrow (NameDirectory, k->Get ())->SetDomainName (new_domain);
	}
	lock_set->UnLock ();
    }

    void SetDomainName (String new_domain) : global {
	DomainName = new_domain;
	FlushImpl ();
    }

    void SetNameDirectory (global NameDirectory nd, Waiter w) {
	Where ()->SetNameDirectory (nd);
	w->Done ();
    }

    String WhichDomain () : global {return DomainName;}
}
