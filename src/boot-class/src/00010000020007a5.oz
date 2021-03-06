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
 * dserver.oz
 *
 * Directory server
 */

/* TYPE PARAMETERS: TEnt */

/*
 * Pessimistic transaction:
 * An entire set of related resources must be locked before starting a
 * transaction.
 */

/*
 * Start up and shutdown sequence:
 *
 *     "Start slow, shutdown fast:
 *      i.e., check consistencies in the start-up sequence and do nothing at
 *      shutdown."
 *
 * Go:
 *   1. Self check (if any)
 *   2. fork Initialize
 * Initialize:
 *   1. Name registration
 *   2. Exclude dead members
 *   3. Join the system
 *
 * Shutdown:
 *   1. Do nothing
 */

abstract class DirectoryServer <global ResolvableObject> :
  ResolvableObject (rename New SuperNew;
		    alias Flush SuperFlush;)
{
  public: Go, Removing, Stop;
  protected: Initialize, Shutdown;

  constructor: New, NewDirectorySystem;

  public:
    Copy, CopyDirectory, CopyEntryTo, DirectoryServerOf, EliminateAllOrphans,
    Exclude, ExcludeLocally, Flush, Includes, IsaDirectory, IsReady, Join,
    LinkDirectory, List, ListEntry, ListDirectory, Migrate, MigrateFromTo,
    Move, MoveDirectory, NewDirectory, NewDirectoryServer, Register, Remove,
    RemoveDirectory, RemoveDirectoryLocally, Retrieve, RetrieveDirectory,
    RetrieveDirectoryLocally, Terminate, Update, WhichDirectoryServer;

  public: /* accessor */
    AddToMembers, AddToSystemMapLocally, DirectoryServers, DoYouHave,
    FlushImpl, GetOwnMap, GetOwnTops, GetSystemMap, IsaMember, IsEmpty,
    RemoveFromMembers, RemoveFromSystemMapLocally, SetSystemInformation,
    TestAndLock, UnLock;

  protected: /* method */
    AskToSystemNameOwner, CheckAndExclude, ConvertPathNameToSubsystem,
    DirectoryServerOfImpl, ExcludeDeadMembers, Header, JoinImpl, JoinSystem,
    LockSelf, PrepareToBeLockedForEmerging, RegisterToNameDirectory, Trailer,
    UnRegisterFromNameDirectory;


  protected: Ping;


  protected: /* abstract */
    CreateNewDirectoryServer, GetDelimiter, GetSystemName;

  protected: /* accessor */
    AddToOwnMap, AddToOwnTops, PrepareToBeLockedGlobal, RemoveFromOwnMap,
    SearchOwnMap, SearchSystemMap;

  protected: OwnMap, SystemMap, Members, OwnTops, Delimiter, SystemName;

/* instance variables */
    Dictionary <String, Directory <global ResolvableObject>> OwnMap;
    Dictionary <String, global DirectoryServer <global ResolvableObject>> SystemMap;
    Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> Members;
    Set <String> OwnTops;
    String Delimiter;
    String SystemName;
    global LockID ID;

    UnixIO Debug;


/* abstract methods */
    String GetDelimiter () : abstract;
    String GetSystemName () : abstract;
    global DirectoryServer <global ResolvableObject>
      CreateNewDirectoryServer (global ObjectManager where) : abstract;

/* method implementations */
    void New (Dictionary <String, global DirectoryServer <global ResolvableObject>> system_map,
	      Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> members)
      : global {
	  SuperNew ();
	  NewSub (members, system_map);
      }

    void NewDirectorySystem () : global {
	/* to be used in constructor in concrete subclasses */
	String s=>NewFromArrayOfChar ("");
	Directory <global ResolvableObject> d=>New ();
	Dictionary <String, global DirectoryServer <global ResolvableObject>> system_map;
	Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> members;

	SuperNew ();
	members=>New ();
	system_map=>New ();
	system_map->AddAssoc (s, oid);
	NewSub (members, system_map);
	AddToOwnMap (s, d);
	OwnTops->Add (s);
    }

    void NewSub (Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> members,
		 Dictionary <String, global DirectoryServer <global ResolvableObject>> systemmap){
	OIDAsKey <global DirectoryServer <global ResolvableObject>> key=>New (oid);

	OwnMap=>New ();
	OwnTops=>New ();
	members->Add (key);
	SetSystemInformation (members, systemmap);
	Delimiter = GetDelimiter ();
	SystemName = GetSystemName ();
	ID = 0;

	Debug=>New ();

    }

    void Go () : global {detach fork Initialize ();}

    void Initialize () {
	String s;

	/*
	 * Add self to Members if not included.  This is for the first
	 * activation after newimage.
	 */
	if (! IsaMember (oid)) {
	    AddToMembers (oid);
	}
	RegisterToNameDirectory ();
	ExcludeDeadMembers ();
	try {
	    JoinSystem ();
	} except {
	  DirectoryExceptions::OverWriteProhibited (s) {
	      /* Fatal! -- error should be reported to the user! */

	      inline "C" {
		  _oz_debug_flag = 1;
	      }
	      debug (0,
		     "*FATAL* DirectoryServer::Initialize: Failed to "
		     "initialize due to confliction with system.\n");
	      debug (0,
		     "*FATAL* DirectoryServer::Initialize: Check if the "
		     "directory \"%S\" is governed by more than one directory "
		     "server.\n", s->Content ());
	  }
	}
    }

    void Stop () : global {Shutdown ();}

    void Shutdown () {UnRegisterFromNameDirectory ();}

    void Flush () : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();

	LockSelf (lock_set);
	lock_set->Commit ();
	lock_set->UnLock ();
    }

    void FlushImpl () : global, locked {
	if (Where ()->IsPermanentObject (oid)) {
	    global LockID id = ID;

	    ID = 0;
	    SuperFlush ();
	    ID = id;
	}
    }

    void AddToMembers (global DirectoryServer <global ResolvableObject> ds) : global, locked {
	OIDAsKey <global DirectoryServer <global ResolvableObject>> key=>New (ds);

	Members->Add (key);
    }

    void AddToOwnMap (String s, Directory <global ResolvableObject> d) : locked {
	OwnMap->AddAssoc (s, d);
    }

    void AddToOwnTops (String s) : locked {OwnTops->Add (s);}

    void AddToSystemMap (String path) {
	/* notice: global locking must be acquired by caller */
	Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;
	OIDAsKey <global DirectoryServer <global ResolvableObject>> k;

	OwnTops->Add (path);
	for (i=>New (Members);
	     (k = i->PostIncrement ()) != 0;) {
	    k->Get ()->AddToSystemMapLocally (path, oid);
	}
	i->Finish ();
    }

    void AddToSystemMapLocally (String path, global DirectoryServer <global ResolvableObject> ds)
      : global, locked {
	  SystemMap->AddAssoc (path, ds);
      }

    int AskToSystemNameOwner (global NameDirectory nd) {
	global DirectoryServer <global ResolvableObject> ds;
	String s;
	int res;

	try {
	    ds = narrow (DirectoryServer <global ResolvableObject>, nd->Resolve (SystemName));
	    if (ds != 0) {
		try {
		    if (! IsaMember (ds) || ! ds->IsaMember (oid)) {
			ds->Join (oid);
		    }
		    res = 1;
		} except {
		    default {
			Waiter w=>New ();
			detach fork Ping (ds, w);
			detach fork w->Timer (30);
			if (! w->WaitAndTest ()) {
			    if (nd->Resolve (SystemName) == ds) {
				nd->RemoveObjectWithName (SystemName);
			    }
			}
			raise;
		    }
		}
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

    void CheckAndExclude (Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> set){
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> to_be_excluded=>New ();
	Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i, j;
	OIDAsKey <global DirectoryServer <global ResolvableObject>> k, l;
	global DirectoryServer <global ResolvableObject> ds, m;
	int finished = 0;

	while (! finished) {
	    PrepareToBeLockedGlobal (lock_set);
	    for (i=>New (set); (k = i->PostIncrement ()) != 0;) {
		ds = k->Get ();
		if (ds != oid) {
		    Waiter w=>New ();
		    detach fork Ping (ds, w);
		    detach fork w->Timer (30);
		    if (! w->WaitAndTest ()) {
			if (lock_set->Includes (ds)) {
			    lock_set->Remove (ds);
			    to_be_excluded->Add (k);
			}
		    }
		}
	    }
	    i->Finish ();
	    if (lock_set->Lock ()) {
		set = lock_set;
		for (i=>New (set); (k = i->PostIncrement ()) != 0;) {
		    m = k->Get ();
		    for (j=>New (to_be_excluded);
			 (l = j->PostIncrement ()) != 0;) {
			ds = l->Get ();
			m->RemoveFromMembers (ds);
			m->ExcludeLocally (ds);
		    }
		    j->Finish ();
		}
		i->Finish ();
		finished = 0;
	    } /* else -- continue */
	}
    }

    /*
     * path name conversion services for non-uniform directory systems
     */
    String ConvertPathNameToSubsystem (String path,
				       global DirectoryServer <global ResolvableObject> ds) {
	return path;
    }

    /*
      valid copy operations:
      copy entry1 to entry2
           entry1 is copied to entry2. entry2 must not be exist
      copy entry to directory
           entry is copied to directory/entry:t.
           directory must be exist and directory/entry:t must not be exist
      copy directory1 to directory2
           directory1 is copied to directory2/directory1:t 
           directory2/directory1:t must not be exist.
      returns the source physical directory.
      */
    global DirectoryServer <global ResolvableObject> Copy (String path1, String path2) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set;
	global DirectoryServer <global ResolvableObject> ds;
	String h;
	int finished = 0;

	lock_set=>New ();
	h = Header (path1);
	while (! finished) {
	    LockSelf (lock_set);
	    try {
		ds = DirectoryServerOfImpl (h);
		if (ds != oid) {
		    lock_set->UnLock ();
		    ds = ds->Copy (ConvertPathNameToSubsystem (path1, ds),
				   ConvertPathNameToSubsystem (path2, ds));
		    finished = 1;
		} else {
		    PrepareToBeLockedForEmerging (lock_set, path1, path2);
		    if (lock_set->Lock ()) {
			Directory <global ResolvableObject> d = SearchOwnMap (h);
			String t = Trailer (path1);

			if (d == 0) {
			    raise DirectoryExceptions::UnknownDirectory (h);
			}

			if (d->IncludesEntry (t) != 0) {
			    ds = DirectoryServerOfImpl (path2);
			    path1 = ConvertPathNameToSubsystem (path1, ds);
			    path2 = ConvertPathNameToSubsystem (path2, ds);
			    ds->CopyEntryTo (path1, path2, d->Retrieve (t));
			} else {
			    CopyDirectory (path1,
					   path2->Concatenate (Delimiter)
					        ->Concatenate (t));
			}
			lock_set->Commit ();
			lock_set->UnLock ();
			ds = oid;
			finished = 1;
		    } else {
			CheckAndExclude (lock_set);
			lock_set->RemoveAllContent ();
			/* continue to loop */
		    }
		}
	    } except {
		default {
		    lock_set->UnLock ();
		    raise;
		}
	    }
	}
	return ds;
    }

    void CopyDirectory (String path1, String path2) : global {
	Directory <global ResolvableObject> d1;
	Directory <global ResolvableObject> d2;

	d1 = oid->RetrieveDirectoryLocally (path1);
	if (d1 != 0) {
	    String h = Header (path2);
	    String t = Trailer (path2);

	    if ((d2 = SearchOwnMap (h)) == 0) {
		/*
		  PrepareToBeLockedForEmerging has already locked all
		  members if this AddToSystemMap will be called.
		  */
		LinkDirectory (h, t);
		AddToSystemMap (path2);
	    } else {
		d2->AddDirectory (t, d1);
	    }
	}
	CopyTreeFromTo (path1, path2, d1);
    }

    void CopyEntryTo (String path1, String path2, global ResolvableObject e) : global {
	Directory <global ResolvableObject> d = SearchOwnMap (path2);

	if (d != 0) {
	    String t = Trailer (path1);

	    if (d->Includes (t)) {
		raise
		  DirectoryExceptions::OverWriteProhibited
		    (path2->Concatenate (Delimiter)->Concatenate (t));
	    } else {
		d->AddEntry (t, e);
	    }
	} else {
	    String h = Header (path2);

	    d = SearchOwnMap (h);
	    if (d != 0) {
		String t = Trailer (path2);

		if (d->Includes (t)) {
		    d->Update (t, e);
		} else {
		    d->AddEntry (t, e);
		}
	    } else {
		raise DirectoryExceptions::UnknownDirectory (path2);
	    }
	}
    }

    void CopyTreeFromTo (String path1, String path2, Directory <global ResolvableObject> dir) {
	if (dir != 0) {
	    Set <String> s;
	    unsigned int size;

	    AddToOwnMap (path2, dir);
	    s = dir->ListDirectory ();
	    for (size = s->Size (); size -- != 0;) {
		String st = s->RemoveAny ();
		String trailer = Delimiter->Concatenate (st);

		CopyTreeFromTo (path1->Concatenate (trailer),
				path2->Concatenate (trailer),
				dir->RetrieveDirectory (st));
	    }
	} else { /* in case of oversea subtree */
	    global DirectoryServer <global ResolvableObject> ds = DirectoryServerOfImpl (path1);

	    ds->CopyDirectory (ConvertPathNameToSubsystem (path1, ds),
			       ConvertPathNameToSubsystem (path2, ds));
	}
    }

    global DirectoryServer <global ResolvableObject> DirectoryServerOf (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	global DirectoryServer <global ResolvableObject> ds;

	LockSelf (lock_set);
	try {
	    ds = DirectoryServerOfImpl (path);
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	lock_set->UnLock ();
	return ds;
    }

    global DirectoryServer <global ResolvableObject> DirectoryServerOfImpl (String path) {
	if (SearchOwnMap (path) != 0) {
	    return oid;
	} else {
	    String s = path;

	    do {
		global DirectoryServer <global ResolvableObject> ds = SearchSystemMap (s);
 
		if (ds != 0) {
		    return ds;
		} else {
		    if (s->Length () > 0) {
			s = Header (s);
		    } else {
			raise DirectoryExceptions::UnknownDirectory (s);
		    }
		}
	    } while (s != 0);
	    raise DirectoryExceptions::IllegalPathString (path);
	}
    }

    Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> DirectoryServers ()
      : global, locked {
	  return Members;
      }

    int DoYouHave (String path) : global {return SearchOwnMap (path) != 0;}

    /* Eliminate links which is not on the system map */
    void EliminateAllOrphans () : global {
	Iterator <Assoc <String, Directory <global ResolvableObject>>> i;
	Assoc <String, Directory <global ResolvableObject>> a;
	int changed = 0;

	for (i=>New (OwnMap); (a = i->PostIncrement ()) != 0;) {
	    Directory <global ResolvableObject> d = a->Value ();
	    Set <String> s = d->ListDirectory ();
	    Iterator <String> j;
	    String st;

	    for (j=>New (s); (st = j->PostIncrement ()) != 0;) {
		if (d->RetrieveDirectory (st) == 0) {
		    if (SearchSystemMap (a->Key ()
					 ->Concatenate (Delimiter)
					 ->Concatenate (st)) == 0) {
			d->RemoveDirectory (st);
			changed = 1;
		    }
		}
	    }
	    j->Finish ();
	}
	i->Finish ();
    }
  
    void Exclude (global DirectoryServer <global ResolvableObject> ds) : global {
	/*
	 * 1. lock self.
	 * 2. check ds is included in Members.
	 * 3. lock all members.
	 * 4. delete ds from Members of all members.
	 * 5. delete SystemMap entries which is managed by ds for all members.
	 * 6. unlock members.
	 */

	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	int finished = 0;

	while (! finished) {
	    LockSelf (lock_set);
	    try {
		OIDAsKey <global DirectoryServer <global ResolvableObject>> k=>New (ds);

		if (Members->Includes (k)) {
		    RemoveFromMembers (ds);
		    PrepareToBeLockedGlobal (lock_set);
		    if (lock_set->Lock ()) {
			Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;

			for (i=>New (Members);
			     (k = i->PostIncrement ()) != 0;) {
			    global DirectoryServer <global ResolvableObject> m = k->Get ();

			    if (m != oid) {
				m->RemoveFromMembers (ds);
				m->ExcludeLocally (ds);
			    }
			}
			i->Finish ();
			ExcludeLocally (ds);
			finished = 1;
		    } else {
			CheckAndExclude (lock_set);
			lock_set->RemoveAllContent ();
			/* continue */
		    }
		} else {
		    raise DirectoryExceptions::UnknownDirectoryServer (ds);
		}
	    } except {
		default {
		    AddToMembers (ds);
		    lock_set->UnLock ();
		    raise;
		}
	    }
	}
	lock_set->Commit ();
	lock_set->UnLock ();
    }

    /* Ping all members I know, and exclude the ones which cannot reply. */
    void ExcludeDeadMembers () {
	Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;
	OIDAsKey <global DirectoryServer <global ResolvableObject>> k;

	for (i=>New (Members); (k = i->PostIncrement ()) != 0;) {
	    global DirectoryServer <global ResolvableObject> ds = k->Get ();

	    if (ds != oid) {
		Waiter w=>New ();

		detach fork Ping (ds, w);
		detach fork w->Timer (30);
		if (! w->WaitAndTest ()) {
		    RemoveFromMembers (ds);
		    ExcludeLocally (ds);
		}
	    }
	}
	i->Finish ();
    }

    void ExcludeLocally (global DirectoryServer <global ResolvableObject> ds) : global {
	Iterator <Assoc <String, global DirectoryServer <global ResolvableObject>>> i;
	Assoc <String, global DirectoryServer <global ResolvableObject>> a;

	for (i=>New (SystemMap); (a = i->PostIncrement ()) != 0;) {
	    if (a->Value () == ds) {
		String path = a->Key ();
		String h = Header (path);
		Directory <global ResolvableObject> d = SearchOwnMap (h);

		RemoveFromSystemMapLocally (path);
		if (d != 0) {
		    d->RemoveDirectory (Trailer (path));
		}
	    }
	}
	i->Finish ();
    }

    Dictionary <String, Directory <global ResolvableObject>> GetOwnMap () : global, locked {
	return OwnMap;
    }

    Set <String> GetOwnTops () : global, locked {return OwnTops;}

    Dictionary <String, global DirectoryServer <global ResolvableObject>> GetSystemMap ()
      : global, locked {
	  return SystemMap;
      }

    String Header (String path) {
	unsigned int r = Seperate (path);

	if (r == -1) {
	    raise DirectoryExceptions::IllegalPathString (path);
	} else if (r == 0) {
	    String s;
	    return s=>NewFromArrayOfChar ("");
	} else {
	    return path->GetSubString (0, r);
	}
    }

    int Includes (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;
	int res;

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (path);
	    if (d != 0) {
		res = 1;
		lock_set->UnLock ();
	    } else {
		String h = Header (path);

		d = SearchOwnMap (h);
		if (d != 0) {
		    String t = Trailer (path);

		    res = d->Includes (t);
		    lock_set->UnLock ();
		} else {
		    global DirectoryServer <global ResolvableObject> ds;

		    ds = DirectoryServerOfImpl (path);
		    if (ds == oid) {
			raise DirectoryExceptions::UnknownDirectory (h);
		    } else {
			lock_set->UnLock ();
			res = ds->Includes (ConvertPathNameToSubsystem (path,
									ds));
		    }
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return res;
    }

    int IsaDirectory (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;
	int res;

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (path);
	    if (d != 0) {
		res = 1;
		lock_set->UnLock ();
	    } else {
		String h = Header (path);
		d = SearchOwnMap (h);

		if (d != 0) {
		    res = d->IncludesSubdirectory (Trailer (path));
		    lock_set->UnLock ();
		} else {
		    global DirectoryServer <global ResolvableObject> ds;

		    ds = DirectoryServerOfImpl (h);
		    if (ds == oid) {
			raise DirectoryExceptions::UnknownDirectory (h);
		    } else {
			lock_set->UnLock ();
			path = ConvertPathNameToSubsystem (path, ds);
			res = ds->IsaDirectory (path);
		    }
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return res;
    }

    int IsEmpty () : global, locked {return OwnMap->IsEmpty ();}

    int IsaMember (global DirectoryServer <global ResolvableObject> ds) : global, locked {
	OIDAsKey <global DirectoryServer <global ResolvableObject>> key=>New (ds);

	return Members->Includes (key);
    }

    int IsReady () : global {return 1;}

    void Join (global DirectoryServer <global ResolvableObject> ds) : global {
	/*
	 * 1. lock all members.
	 * 2. get OwnTops from ds and check confliction.
	 * 3. remove all entry of Members of ds.
	 * 4. add ds to Members' of all members.
	 * 5. add all entries in OwnTops of ds to the SystemMap's of all
	 *    members.
	 * 6. set Members and SystemMap to ds.
	 * 7. unlock all members.
	 */

	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();

	try {
	    PrepareToBeLockedGlobal (lock_set);
	    while (! lock_set->Lock ()) {
		CheckAndExclude (lock_set);
	    }
	    JoinImpl (ds);
	    lock_set->Commit ();
	    lock_set->UnLock ();
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
    }

    void JoinImpl (global DirectoryServer <global ResolvableObject> ds) {
	Set <String> own_tops;
	Iterator <String> i;
	String st;
	Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> members;
	Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> j;
	OIDAsKey <global DirectoryServer <global ResolvableObject>> k;
	global DirectoryServer <global ResolvableObject> d;

	own_tops = ds->GetOwnTops ();
	for (i=>New (own_tops); (st = i->PostIncrement ()) != 0;) {
	    d = DirectoryServerOfImpl (st);

	    if (d != ds && d->DoYouHave (st)) {
		raise DirectoryExceptions::OverWriteProhibited (st);
	    }
	}
	i->Finish ();

	if (! IsaMember (ds)) {
	    for (j=>New (Members); (k = j->PostIncrement ()) != 0;) {
		d = k->Get ();
		d->AddToMembers (ds);
	    }
	    AddToMembers (ds);
	}
	j->Finish ();

	ds->SetSystemInformation (Members, SystemMap);

	/*
	 * under implementation:
	 * Following LinkDirectory doesn't always succeed.  In that case, the
	 * directory cannot be traced from root directory ":".  Nevertheless,
	 * it can be searched if an entire path into the directory is given.
	 * Thus, such a directory should not be removed, and to recover the
	 * trace from the root directory to such a directory, a newly joined
	 * directory server should be searched whether it has a directory which
	 * should has a link to such a directory.
	 */
	for (i=>New (own_tops); (st = i->PostIncrement ()) != 0;) {
	    if (SearchSystemMap (st) == 0) {
		DirectoryServerOfImpl (st)->LinkDirectory (Header (st),
							   Trailer (st));
		for (j=>New (Members); (k = j->PostIncrement ()) != 0;) {
		    k->Get ()->AddToSystemMapLocally (st, ds);
		}
		j->Finish ();
	    }
	}
	i->Finish ();

	ds->FlushImpl ();
    }

    /*
     * If a server is found by the system name, ask it to join.  If I'm the
     * root server, replace the name directory entry by me after joining.
     *
     * If no server is found by the system name, or the server is down, try to
     * register me by the system name.
     */
    void JoinSystem () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	int res = AskToSystemNameOwner (nd);

	if (res) {
	    String null=>NewFromArrayOfChar ("");

	    if (SearchOwnMap (null) != 0) {
		int finished = 0;

		while (! finished) {
		    String s;

		    try {
			if (nd->Resolve (SystemName) == 0) {
			    nd->AddObject (SystemName, oid);
			} else {
			    nd->ChangeObject (SystemName, oid);
			}
			finished = 1;
		    } except {
		      DirectoryExceptions::OverWriteProhibited (s) {}
		      DirectoryExceptions::UnknownDirectory (s) {}
		      DirectoryExceptions::UnknownEntry (s) {}
		    }
		}
	    }
	} else {
	    int finished = 0;

	    while (! finished) {
		try {
		    if (nd->Resolve (SystemName) == 0) {
			nd->AddObject (SystemName, oid);
			finished = 1;
		    } else {
			finished = AskToSystemNameOwner (nd);
		    }
		} except {
		  DirectoryExceptions::OverWriteProhibited (s) {}
		  DirectoryExceptions::UnknownDirectory (s) {}
		  DirectoryExceptions::UnknownEntry (s) {}
		}
	    }
	}
    }

    void LinkDirectory (String header, String trailer) : global {
	Directory <global ResolvableObject> dir = SearchOwnMap (header);




	if (dir != 0) {
	    if (dir->Includes (trailer)) {
		raise
		  DirectoryExceptions
		    ::OverWriteProhibited (header->Concatenate (Delimiter)
					         ->Concatenate (trailer));
	    } else {
		dir->AddDirectory (trailer, 0);
	    }
	} else {
	    global DirectoryServer <global ResolvableObject> ds;

	    ds = DirectoryServerOfImpl (header);
	    if (ds == oid) {
		raise DirectoryExceptions::UnknownDirectory (header);
	    } else {
		ds->LinkDirectory (ConvertPathNameToSubsystem (header, ds),
				   ConvertPathNameToSubsystem (trailer, ds));
	    }
	}
    }

    Set <String> List (String path) : global {
	return ListEntry (path)->AddContentsTo (ListDirectory (path));
	/* inefficient implementation */
    }

    Set <String> ListEntry (String path) : global {
	Set <String> s;
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (path);
	    if (d != 0) {
		s = d->ListEntry ();
		lock_set->UnLock ();
	    } else {
		String h = Header (path);
		String t = Trailer (path);
		d = SearchOwnMap (h);

		if (d != 0) {
		    s=>New ();
		    if (d->IncludesEntry (t)) {
			s->Add (t);
		    }
		    lock_set->UnLock ();
		} else {
		    global DirectoryServer <global ResolvableObject> ds;

		    ds = DirectoryServerOfImpl (path);
		    if (ds == oid) {
			raise DirectoryExceptions::UnknownDirectory (h);
		    } else {
			lock_set->UnLock ();
			s = ds->ListEntry (ConvertPathNameToSubsystem (path,
								       ds));
		    }
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return s;
    }

    Set <String> ListDirectory (String path) : global {
	Set <String> s;
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (path);
	    if (d != 0) {
		s = d->ListDirectory ();
		lock_set->UnLock ();
	    } else {
		global DirectoryServer <global ResolvableObject> ds =DirectoryServerOfImpl (path);

		if (ds == oid) {
		    raise DirectoryExceptions::UnknownDirectory (path);
		} else {
		    lock_set->UnLock ();
		    s = ds->ListDirectory (ConvertPathNameToSubsystem (path,
								       ds));
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return s;
    }

    void LockSelf (LockSet <global DirectoryServer <global ResolvableObject>> lock_set) {
	lock_set->Add (oid);
	while (! lock_set->Lock ())
	  ;
    }

    global DirectoryServer <global ResolvableObject>
      Migrate (String path, global DirectoryServer <global ResolvableObject> where) : global {
	  LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	  Directory <global ResolvableObject> d;
	  int finished = 0;




	  while (! finished) {
	      try {
		  LockSelf (lock_set);
		  d = SearchOwnMap (path);
		  if (d != 0) {
		      if (where != oid) {
			  PrepareToBeLockedGlobal (lock_set);
			  if (lock_set->Lock ()) {
			      global DirectoryServer <global ResolvableObject> hd;

			      RemoveDirectoryImpl (lock_set, path);
			      if (DirectoryServerOfImpl (Header (path)) ==
				  oid) {
				  LinkDirectory (Header (path),Trailer (path));
			      }
			      try {
				  where->MigrateFromTo (path, d);
			      } except {
				  default {
				      MigrateFromTo (path, d);
				      raise;
				  }
			      }
			      lock_set->Commit ();
			      lock_set->UnLock ();
			      finished = 1;
			  } else {
			      CheckAndExclude (lock_set);
			      lock_set->RemoveAllContent ();
			      /* continue */
			  }
		      } else {
			  lock_set->UnLock ();
			  finished = 1;
		      }
		  } else {
		      global DirectoryServer <global ResolvableObject> ds;

		      ds = DirectoryServerOfImpl (path);
		      lock_set->UnLock ();
		      if (ds == oid) {
			  raise DirectoryExceptions::UnknownDirectory (path);
		      } else {
			  path = ConvertPathNameToSubsystem (path, ds);
			  where = ds->Migrate (path, where);
			  finished = 1;
		      }
		  }
	      } except {
		TransactionExceptions::LockConfliction {
		    lock_set->UnLock ();
		    lock_set->RemoveAllContent (); /* continue loop */
		}
		  default {
		      lock_set->UnLock ();
		      raise;
		  }
	      }
	  }
	  return where;
      }

    void MigrateFromTo (String path, Directory <global ResolvableObject> dir) : global {
	if (SearchOwnMap (Header (path)) == 0) {
	    AddToSystemMap (path);
	}
	MigrateFromToRecursively (path, dir);
    }

    void MigrateFromToRecursively (String path, Directory <global ResolvableObject> dir) {
	if (dir != 0) {
	    Set <String> s;
	    unsigned int size;

	    AddToOwnMap (path, dir);
	    s = dir->ListDirectory ();
	    for (size = s->Size (); size -- != 0;) {
		String st = s->RemoveAny ();

		MigrateFromToRecursively (path->Concatenate (Delimiter)
					      ->Concatenate (st),
					  dir->RetrieveDirectory (st));
	    }
	}
    }

    /*
      valid move operations:
      move entry1 to entry2
	   entry1 is moved to entry2. entry2 must not be exist
      move entry to directory
	   entry is moved to directory/entry:g.
	   directory must be exist and directory/entry:t must not be exist
      move directory1 to directory2
	   directory1 is moved to directory2/directory1:t
	   directory2/directory1:t must not be exist.
      returns the source physical directory.
      */
    global DirectoryServer <global ResolvableObject> Move (String path1, String path2) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set;
	String h;
	global DirectoryServer <global ResolvableObject> ds;
	int finished = 0;

	lock_set=>New ();
	h = Header (path1);
	while (! finished) {
	    LockSelf (lock_set);
	    try {
		ds = DirectoryServerOfImpl (h);
		if (ds != oid) {
		    lock_set->UnLock ();
		    ds = ds->Move (ConvertPathNameToSubsystem (path1, ds),
				   ConvertPathNameToSubsystem (path2, ds));
		    finished = 1;
		} else {
		    PrepareToBeLockedForEmerging (lock_set, path1, path2);
		    PrepareToBeLockedForDiminishing (lock_set, path1);
		    if (lock_set->Lock ()) {
			Directory <global ResolvableObject> d = SearchOwnMap (h);
			String t = Trailer (path1);

			if (d != 0) {
			    if (d->IncludesEntry (t) != 0) {
				global DirectoryServer <global ResolvableObject> ds;
				global ResolvableObject e;

				ds = DirectoryServerOfImpl (path2);
				e = SearchOwnMap (h)->RemoveEntry (t);
				if (ds == oid) {
				    CopyEntryTo (path1, path2, e);
				} else {
				    ds->CopyEntryTo (ConvertPathNameToSubsystem
						     (path1, ds),
						     ConvertPathNameToSubsystem
						     (path2, ds), e);
				}
			    } else {
				MoveDirectory (path1,
					       path2->Concatenate (Delimiter)
					            ->Concatenate (t));
			    }
			    lock_set->Commit ();
			    lock_set->UnLock ();
			    ds = oid;
			    finished = 1;
			} else {
			    raise DirectoryExceptions::UnknownDirectory (h);
			}
		    } else {
			raise TransactionExceptions::LockConfliction;
		    }
		}
	    } except {
	      TransactionExceptions::LockConfliction {
		  CheckAndExclude (lock_set);
		  lock_set->RemoveAllContent ();
	      }
		default {
		    lock_set->UnLock ();
		    raise;
		}
	    }
	}
	return ds;
    }

    void MoveDirectory (String path1, String path2) : global {
	Directory <global ResolvableObject> d1;
	Directory <global ResolvableObject> d2;




	d1 = SearchOwnMap (path1);
	RemoveDirectoryLocally (path1);
	if (d1 != 0) {
	    String h = Header (path2);
	    String t = Trailer (path2);

	    if ((d2 = SearchOwnMap (h)) == 0) {
		/*
		  PrepareToBeLockedForEmerging has already locked all
		  members if this AddToSystemMap will be called.
		  */
		AddToSystemMap (path2);
		LinkDirectory (h, t);
	    } else {
		d2->AddDirectory (t, d1);
	    }
	}
	MoveTreeFromTo (path1, path2, d1);
    }

    void MoveTreeFromTo (String path1, String path2, Directory <global ResolvableObject> dir) {



	if (dir != 0) {
	    Set <String> s;
	    unsigned int size;

	    AddToOwnMap (path2, dir);

	    s = dir->ListDirectory ();
	    for (size = s->Size (); size -- != 0;) {
		String st = s->RemoveAny ();

		MoveTreeFromTo (path1
				->Concatenate (Delimiter)->Concatenate (st),
				path2
				->Concatenate (Delimiter)->Concatenate (st),
				dir->RetrieveDirectory (st));
	    }
	} else { /* in case of oversea subtree */
	    global DirectoryServer <global ResolvableObject> ds = DirectoryServerOfImpl (path1);

	    ds->MoveDirectory (ConvertPathNameToSubsystem (path1, ds),
			       ConvertPathNameToSubsystem (path2, ds));
	}
    }

    global DirectoryServer <global ResolvableObject> NewDirectory (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	String h = Header (path);
	Directory <global ResolvableObject> d;
	global DirectoryServer <global ResolvableObject> ret;

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (h);
	    if (d != 0) {
		String t = Trailer (path);

		if (d->Includes (t)) {
		    raise DirectoryExceptions::OverWriteProhibited (path);
		} else {
		    Directory <global ResolvableObject> new=>New ();

		    d->AddDirectory (t, new);
		    AddToOwnMap (path, new);
		    lock_set->Commit ();
		    lock_set->UnLock ();
		    ret = oid;
		}
	    } else {
		global DirectoryServer <global ResolvableObject> ds =DirectoryServerOfImpl (path);

		if (ds == oid) {
		    raise DirectoryExceptions::UnknownDirectory (h);
		} else {
		    lock_set->UnLock ();
		    ret = ds->NewDirectory (ConvertPathNameToSubsystem (path,
									ds));
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return ret;
    }

    global DirectoryServer <global ResolvableObject>
      NewDirectoryServer (global ObjectManager where) : global {
	  Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;
	  OIDAsKey <global DirectoryServer <global ResolvableObject>> dskey;
	  LockSet <global DirectoryServer <global ResolvableObject>> lock_set;
	  global DirectoryServer <global ResolvableObject> new;

	  new = CreateNewDirectoryServer (where);
	  lock_set=>New ();
	  PrepareToBeLockedGlobal (lock_set);
	  while (! lock_set->Lock ()) {
	      CheckAndExclude (lock_set);
	  }
	  try {
	      for (i=>New (Members); (dskey = i->PostIncrement ()) != 0;) {
		  dskey->Get ()->AddToMembers (new);
	      }
	      i->Finish ();
	  } except {
	      default {
		  lock_set->UnLock ();
		  raise;
	      }
	  }
	  lock_set->Commit ();
	  lock_set->UnLock ();
	  return new;
      }

    int Ping (global DirectoryServer <global ResolvableObject> ds, Waiter w) {
	try {
	    if (ds->IsReady ()) {
		w->Done ();
	    } else {
		w->Abort ();
	    }
	} except {
	    default {
		w->Abort ();
	    }
	}
    }

    void
      PrepareToBeLockedForDiminishing
	(LockSet <global DirectoryServer <global ResolvableObject>> lock_set, String path) {
	    Iterator <Assoc <String, global DirectoryServer <global ResolvableObject>>> i;
	    Assoc <String, global DirectoryServer <global ResolvableObject>> assoc;
	    unsigned int len = path->Length ();

	    for (i=>New (SystemMap); (assoc = i->PostIncrement ()) != 0;) {
		if (assoc->Key ()->NCompare (path, len) == 0){
		    PrepareToBeLockedGlobal (lock_set);
		    break;
		}
	    }
	    i->Finish ();
	}

    void
      PrepareToBeLockedForEmerging
	(LockSet <global DirectoryServer <global ResolvableObject>> lock_set,
	 String path1, String path2) {
	    String h = Header (path1);
	    Directory <global ResolvableObject> d = SearchOwnMap (h);

	    if (d != 0) {
		String t = Trailer (path1);

		if (d->IncludesSubdirectory (t)) {
		    if (SearchOwnMap (path2) == 0) {
			PrepareToBeLockedGlobal (lock_set);
		    } else {
			Iterator <Assoc <String,
			                 global DirectoryServer <global ResolvableObject>>> i;
			Assoc <String, global DirectoryServer <global ResolvableObject>> assoc;
			unsigned int len = path1->Length ();

			for (i=>New (SystemMap);
			     (assoc = i->PostIncrement ()) != 0;) {
			    if (assoc->Key ()->NCompare (path1, len) == 0){
				PrepareToBeLockedGlobal (lock_set);
				  break;
			    }
			}
			i->Finish ();
		    }
		} else if (d->IncludesEntry (t)) {
		    lock_set->Add (DirectoryServerOfImpl (path2));
		} else {
		    raise DirectoryExceptions::UnknownEntry (path1);
		}
	    } else {
		raise DirectoryExceptions::UnknownDirectory (h);
	    }
	}

    void
      PrepareToBeLockedGlobal (LockSet<global DirectoryServer <global ResolvableObject>> lock_set)
	: locked {
	    Members->AddContentsTo (lock_set);
	}

    global DirectoryServer <global ResolvableObject> Register (String path, global ResolvableObject e) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> dir;
	String h = Header (path);
	global DirectoryServer <global ResolvableObject> ret;

	LockSelf (lock_set);
	try {
	    dir = SearchOwnMap (h);
	    if (dir != 0) {
		String t = Trailer (path);

		if (dir->Includes (t)) {
		    raise DirectoryExceptions::OverWriteProhibited (path);
		} else {
		    dir->AddEntry (t, e);
		    lock_set->Commit ();
		    lock_set->UnLock ();
		    ret = oid;
		}
	    } else {
		global DirectoryServer <global ResolvableObject> ds =DirectoryServerOfImpl (path);

		if (ds == oid) {
		    raise DirectoryExceptions::UnknownDirectory (h);
		} else {
		    lock_set->UnLock ();
		    ret = ds->Register (ConvertPathNameToSubsystem (path, ds),
					e);
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return ret;
    }

    global ResolvableObject Remove (String path) : global {
	global ResolvableObject e;
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (Header (path));
	    if (d != 0) {
		e = d->RemoveEntry (Trailer (path));
		lock_set->Commit ();
		lock_set->UnLock ();
	    } else {
		global DirectoryServer <global ResolvableObject> ds =DirectoryServerOfImpl (path);

		if (ds == oid) {
		    raise DirectoryExceptions::UnknownEntry (path);
		} else {
		    lock_set->UnLock ();
		    e = ds->Remove (ConvertPathNameToSubsystem (path, ds));
		}
	    }
	} except {
	    CollectionExceptions <String>::UnknownKey (s) {
		lock_set->UnLock ();
		raise DirectoryExceptions::UnknownEntry (path);
	    }
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return e;
    }

    Directory <global ResolvableObject> RemoveDirectory (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;
	int finished = 0;

	while (! finished) {
	    try {
		LockSelf (lock_set);
		if ((d = SearchOwnMap (Header (path))) != 0) {
		    if (d->IncludesSubdirectory (Trailer (path))) {
			RemoveDirectoryImpl (lock_set, path);
			lock_set->Commit ();
			lock_set->UnLock ();
			finished = 1;
		    } else {
			raise DirectoryExceptions::UnknownDirectory (path);
		    }
		} else {
		    global DirectoryServer <global ResolvableObject> ds;

		    ds = DirectoryServerOfImpl (path);
		    if (ds == oid) {
			raise DirectoryExceptions::UnknownDirectory (path);
		    } else {
			lock_set->UnLock ();
			path = ConvertPathNameToSubsystem (path, ds);
			d = ds->RemoveDirectory (path);
		    }
		}
	    } except {
	      TransactionExceptions::LockConfliction {
		  lock_set->UnLock ();
		  lock_set->RemoveAllContent ();
		  /* continue */
	      }
		CollectionExceptions <String>::UnknownKey (s) {
		    lock_set->UnLock ();
		    raise DirectoryExceptions::UnknownDirectory (path);
		}
		default {
		    lock_set->UnLock ();
		    raise;
		}
	    }
	}
	return d;
    }

    void
      RemoveDirectoryImpl (LockSet <global DirectoryServer <global ResolvableObject>> lock_set,
			   String path) {
	  Iterator <Assoc <String, global DirectoryServer <global ResolvableObject>>> i;
	  Assoc <String, global DirectoryServer <global ResolvableObject>> assoc;
	  Dictionary <String, global DirectoryServer <global ResolvableObject>> dic;
	  Set <Assoc <String, global DirectoryServer <global ResolvableObject>>> s;
	  int len = path->Length ();

	  dic=>New ();
	  s = dic;
	  for (i=>New (SystemMap); (assoc = i->PostIncrement ()) != 0;) {
	      String st = assoc->Key ();

	      if (st->NCompare (path, len) == 0) {
		  s->Add (assoc);
	      }
	  }
	  i->Finish ();
	  if (s->Size () > 0) {
	      PrepareToBeLockedGlobal (lock_set);
	      if (! lock_set->Lock ()) {
		  CheckAndExclude (lock_set);
		  raise TransactionExceptions::LockConfliction;
	      }
	  }
	  if (! OwnTops->Includes (path)) {
	      RemoveDirectoryLocally (path);
	  }
	  for (i=>New (dic); (assoc = i->PostIncrement ()) != 0;) {
	      assoc->Value ()->RemoveDirectoryLocally (assoc->Key ());
	  }
	  i->Finish ();
      }

    void RemoveDirectoryFromOwnMap (String path) {
	Directory <global ResolvableObject> dir = SearchOwnMap (path);




	if (dir != 0) {
	    Set <String> s = dir->ListDirectory ();
	    unsigned int size;

	    for (size = s->Size (); size -- != 0;) {
		RemoveDirectoryFromOwnMap (path
					   ->Concatenate (Delimiter)
					   ->Concatenate (s->RemoveAny ()));
	    }
	    RemoveFromOwnMap (path);
	}
    }

    void RemoveDirectoryLocally (String path) : global {
	Directory <global ResolvableObject> d;

	/*
	  notice: global locking must be acquired by caller when
	  removed directory is one of top directories in the dir. server.
	  */



	RemoveDirectoryFromOwnMap (path);
	if (OwnTops->Includes (path)) {
	    RemoveFromSystemMap (path);
	}
	if ((d = SearchOwnMap (Header (path))) != 0) {
	    d->RemoveDirectory (Trailer (path));
	}
    }

    void RemoveFromMembers (global DirectoryServer <global ResolvableObject> ds) : global, locked{
	OIDAsKey <global DirectoryServer <global ResolvableObject>> key=>New (ds);

	Members->Remove (key);
    }

    void RemoveFromOwnMap (String path) : locked {



	OwnMap->RemoveKey (path);
    }

    void RemoveFromSystemMap (String path) {
	/* notice: global locking must be acquired by caller */
	Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;
	OIDAsKey <global DirectoryServer <global ResolvableObject>> k;

	OwnTops->Remove (path);
	for (i=>New (Members); (k = i->PostIncrement ()) != 0;) {
	    k->Get ()->RemoveFromSystemMapLocally (path);
	}
	i->Finish ();
    }

    void RemoveFromSystemMapLocally (String path) : global, locked {
	SystemMap->RemoveKey (path);
    }

    global ResolvableObject Retrieve (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	String h = Header (path);
	Directory <global ResolvableObject> d;
	global ResolvableObject e;

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (h);
	    if (d != 0) {
		e = d->Retrieve (Trailer (path));
		lock_set->UnLock ();
	    } else {
		global DirectoryServer <global ResolvableObject> ds =DirectoryServerOfImpl (path);

		if (ds == oid) {
		    raise DirectoryExceptions::UnknownDirectory (h);
		} else {
		    lock_set->UnLock ();
		    e = ds->Retrieve (ConvertPathNameToSubsystem (path, ds));
		}
	    }
	} except {
	    CollectionExceptions <String>::UnknownKey (s) {
		lock_set->UnLock ();
		raise DirectoryExceptions::UnknownEntry (path);
	    }
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return e;
    }

    Directory <global ResolvableObject> RetrieveDirectory (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;

	LockSelf (lock_set);
	try {
	    if (SearchOwnMap (Header (path)) != 0) {
		d = SearchOwnMap (path);
		lock_set->UnLock ();
	    } else {
		global DirectoryServer <global ResolvableObject> ds = DirectoryServerOf (path);

		if (ds == oid) {
		    raise DirectoryExceptions::UnknownDirectory (path);
		} else {
		    lock_set->UnLock ();
		    path = ConvertPathNameToSubsystem (path, ds);
		    d = ds->RetrieveDirectory (path);
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	if (d == 0) {
	    raise DirectoryExceptions::UnknownDirectory (path);
	} else {
	    return d;
	}
    }

    Directory <global ResolvableObject> RetrieveDirectoryLocally (String path) : global {
	return SearchOwnMap (path);
    }

    Directory <global ResolvableObject> SearchOwnMap (String path) : locked {
	if (OwnMap->IncludesKey (path)) {
	    return OwnMap->AtKey (path);
	} else {
	    return 0;
	}
    }

    global DirectoryServer <global ResolvableObject> SearchSystemMap (String path) : locked {
	if (SystemMap->IncludesKey (path)) {
	    return SystemMap->AtKey (path);
	} else {
	    return 0;
	}
    }

    void
      SetSystemInformation
	(Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>> members,
	 Dictionary <String, global DirectoryServer <global ResolvableObject>> systemmap): global{
	     SystemMap = systemmap;
	     Members = members;
	 }

    unsigned int Seperate (String path) {
	String s = path;
	unsigned int r;




	if (path->Length () == 0) {
	    return -1;
	}
	while (1) {
	    if (Delimiter->Length () > 0) {
		r = s->StrRChr (Delimiter->At (0));
		if (r == -1) {
		    return -1;
		}
	    } else {
		return -1;
	    }



	    if (Delimiter
		->IsEqualTo (s->GetSubString (r, Delimiter->Length ()))) {
		return r;
	    } else {



		if (r == 0) {
		    return -1;
		} else {
		    s = path->GetSubString (0, r);
		}
	    }
	}
    }

    void Terminate () : global {
	if (IsEmpty ()) {
	    Iterator <OIDAsKey <global DirectoryServer <global ResolvableObject>>> i;
	    OIDAsKey <global DirectoryServer <global ResolvableObject>> key;

	    try {
		for (i=>New (Members); (key = i->PostIncrement ()) != 0;) {
		    try {
			key->Get ()->Exclude (oid);
			break;
		    } except {
			default {
			    /*
			     * continue to loop, seeking the one who
			     * can exclude me from system
			     */
			}
		    }
		}
		i->Finish ();
		Where ()->RemoveMe (oid);
	    } except {
		default {
		    raise;
		}
	    }
	} else {
	    raise DirectoryExceptions::NotEmtpy;
	}
    }

    int TestAndLock (global LockID lock_id) : global, locked {



	debug (0, "DirectoryServer<*>::TestAndLock: ID = %O, lock_id = %O\n",
	       ID, lock_id);
	if (ID == 0) {
	    ID = lock_id;
	    return 1;
	} else {
	    return ID == lock_id;
	}
    }

    String Trailer (String path) {
	unsigned int r = Seperate (path);

	if (r == -1) {
	    return path;
	} else {
	    return path->GetSubString (r + Delimiter->Length (), 0);
	}
    }

    void UnLock (global LockID lock_id) : global, locked {


	inline "C" {
	    _oz_debug_flag = 0;
	}


	debug (0, "DirectoryServer<*>::UnLock: ID = %O, lock_id = %O\n",
	       ID, lock_id);
	if (ID == lock_id) {
	    ID = 0;
	} else {
	    raise TransactionExceptions::UnknownLockID (lock_id);
	}
    }

    global DirectoryServer <global ResolvableObject> Update (String path, global ResolvableObject new) : global {
	global DirectoryServer <global ResolvableObject> ret;
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	Directory <global ResolvableObject> d;
	String h = Header (path);

	LockSelf (lock_set);
	try {
	    d = SearchOwnMap (h);
	    if (d != 0) {
		d->Update (Trailer (path), new);
		ret = oid;
		lock_set->Commit ();
		lock_set->UnLock ();
	    } else {
		global DirectoryServer <global ResolvableObject> ds = DirectoryServerOf (path);

		if (ds == oid) {
		    raise DirectoryExceptions::UnknownDirectory (h);
		} else {
		    lock_set->UnLock ();
		    ret = ds->Update (ConvertPathNameToSubsystem (path, ds),
				      new);
		}
	    }
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	return ret;
    }

    global DirectoryServer <global ResolvableObject> WhichDirectoryServer (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set=>New ();
	global DirectoryServer <global ResolvableObject> ds;

	LockSelf (lock_set);
	try {
	    ds = WhichDirectoryServerImpl (path);
	} except {
	    default {
		lock_set->UnLock ();
		raise;
	    }
	}
	lock_set->UnLock ();
	return ds;
    }

    global DirectoryServer <global ResolvableObject> WhichDirectoryServerImpl (String path) {
	if (SearchOwnMap (path) != 0) {
	    return oid;
	} else {
	    Directory <global ResolvableObject> d = SearchOwnMap (Header (path));

	    if (d != 0) {
		if (d->Includes (Trailer (path))) {
		    return oid;
		} else {
		    raise DirectoryExceptions::UnknownEntry (path);
		}
	    } else {
		global DirectoryServer <global ResolvableObject> ds;
		ds = DirectoryServerOfImpl (path);
		path = ConvertPathNameToSubsystem (path, ds);
		return ds->WhichDirectoryServer (path);
	    }
	}
    }
}
