/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/
// we don't use record


// we use exceptions with parameters
//#define NOEXCEPTIONPARAMETER

// we use broadcast
//#define NOBROADCAST

// we flush objects
//#define NOFLUSH

// we don't test flush
//#define FLUSHTESTATSTARTING

// we are debugging
//#define NDEBUG

// we have a bug in remote instantiation


// we lookup configuration table for configured class ID


// we don't list directory by unix 'ls' command, but opendir library
//#define LISTBYLS

// we need change directory to $OZHOME before OzRead and OzSpawn


// we don't use OzRemoveCode
//#define USEOZREMOVECODE

// we don't read parents version IDs from private.i.
//#define READPARENTSFROMPRIVATEDOTI

// we have bug in alias
//#define NOALIASBUG

// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we distribute class not by tar'ed directory


// we have bug in StreamBuffer


// we have no support for getting executor ID


// we don't use Object::GetPropertyPathName


// we have a bug in gen-spec-src

/*
 * dserver.oz
 *
 * Directory server
 */

/* TYPE PARAMETERS: TEnt */

/*
  transaction control scheme is pessimistic.
  i.e., complete lock must be acquired before starting process.
  */

abstract class DirectoryServerOfBroker :
  ResolvableObject (rename New SuperNew;) {
    public: Go, Stop;

    constructor: New, NewDirectorySystem;


    public:
      AddToSystemMapLocally, Copy, CopyDirectory, CopyEntryTo,
      DirectoryServers, Exclude, IsEmpty, Join, Kill, LinkDirectory,
      List, ListEntry, ListDirectory, Migrate, MigrateFromTo, Move,
      MoveDirectory, NewDirectory, NewDirectoryServer,
      Register, Remove, RemoveDirectory, RemoveFromSystemMapLocally,
      RemoveDirectoryLocally, Retrieve, RetrieveDirectory,
      RetrieveDirectoryLocally, TestAndLock, UnLock, Update,
      WhichDirectoryServer;

    protected:
      CreateNewDirectoryServer, GetDelimiter;

    protected:
      OwnMap, SystemMap, Members, OwnTops, Delimiter;

/* instance variables */
      Dictionary <String, Directory <Broker>> OwnMap;
      Dictionary <String, global DirectoryServerOfBroker> SystemMap;
      Set <OIDAsKey <global DirectoryServerOfBroker>> Members;
      Set <String> OwnTops;
      String Delimiter;
      global LockID ID;

      UnixIO Debug;


/* abstract methods */
      String GetDelimiter () : abstract;
      global DirectoryServerOfBroker
	CreateNewDirectoryServer (global ObjectManager where) : abstract;

/* method implementations */
      void New (Dictionary <String, global DirectoryServerOfBroker> system_map,
		Set <OIDAsKey <global DirectoryServerOfBroker>> members)
	: global {
	    SuperNew ();
	    SetMembers (members, system_map);
	}

      void NewDirectorySystem () : global {
	  String s=>NewFromArrayOfChar ("");
	  Directory <Broker> d=>New ();
	  Dictionary <String, global DirectoryServerOfBroker> system_map;
	  Set <OIDAsKey <global DirectoryServerOfBroker>> members;

	  SuperNew ();
	  system_map=>New ();
	  system_map->AddAssoc (s, oid);
	  members=>New ();
	  SetMembers (members, system_map);
	  AddToOwnMap (s, d);
	  OwnTops->Add (s);
      }

      void Go () : global {RegisterToNameDirectory ();}

      void Stop () : global {UnRegisterFromNameDirectory ();}

      void AddToOwnMap (String s, Directory <Broker> d) : locked {
	  OwnMap->AddAssoc (s, d);
      }

      void AddToSystemMap (String path) : global {
	  /* notice: global locking must be acquired by caller */
	  Iterator <OIDAsKey <global DirectoryServerOfBroker>> i;
	  OIDAsKey <global DirectoryServerOfBroker> k;

	  OwnTops->Add (path);
	  for (i=>New (Members);
	       (k = i->PostIncrement ()) != 0;) {
	      k->Get ()->AddToSystemMapLocally (path, oid);
	  }
	  i->Finish ();
      }

      void
	AddToSystemMapLocally (String path, global DirectoryServerOfBroker ds)
	  : global, locked {
	      SystemMap->AddAssoc (path, ds);
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
      global DirectoryServerOfBroker Copy (String path1, String path2)
	: global {
	    LockSet <global DirectoryServerOfBroker> lock_set;
	    global DirectoryServerOfBroker ds;
	    String h;

	    lock_set=>New ();
	    h = Header (path1);
	    while (1) {
		LockIt (lock_set, oid);
		try {
		    ds = DirectoryServerOfImpl (h);
		    if (ds != oid) {
			lock_set->UnLock ();
			return ds->Copy (path1, path2);
		    }

		    try {
			PrepareToBeLockedForEmerging (lock_set, path1, path2);
			if (lock_set->Lock ()) {
			    Directory <Broker> d = SearchOwnMap (h);
			    String t = Trailer (path1);

			    if (d == 0) {
				raise DirectoryExceptions::UnknownDirectory(h);
			    }

			    if (d->IncludesEntry (t) != 0) {
				DirectoryServerOfImpl (path2)
				  ->CopyEntryTo (path1, path2, d->Retrieve(t));
			    } else {
				CopyDirectory (path1,
					       path2->Concatenate (Delimiter)
					                ->Concatenate (t));
			    }
			    lock_set->UnLock ();
			    return oid;
			} else {
			    raise TransactionExceptions::LockConfliction;
			}
		    } except {
		      TransactionExceptions::LockConfliction {
			  lock_set->UnLock ();
			  lock_set->RemoveAllContent ();
		      }
		    }
		} except {
		    default {
			lock_set->UnLock ();
			raise;
		    }
		}
	    }
	}

      void CopyDirectory (String path1, String path2) : global {
	  Directory <Broker> d1;
	  Directory <Broker> d2;

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

      void CopyEntryTo (String path1, String path2, Broker e) : global {
	  Directory <Broker> d = SearchOwnMap (path2);

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

      void CopyTreeFromTo (String path1, String path2, Directory <Broker> dir) {
	  if (dir != 0) {
	      Set <String> s;
	      unsigned int size;

	      AddToOwnMap (path2, dir);
	      s = dir->ListDirectory ();
	      for (size = s->Size (); size -- != 0;) {
		  String st = s->RemoveAny ();

		  CopyTreeFromTo (path1->Concatenate (Delimiter)
				           ->Concatenate (st),
				  path2->Concatenate (Delimiter)
				           ->Concatenate (st),
				  dir->RetrieveDirectory (st));
	      }
	  } else { /* in case of oversea subtree */
	      DirectoryServerOfImpl (path1)->CopyDirectory (path1, path2);
	  }
      }

      global DirectoryServerOfBroker DirectoryServerOf (String path) {
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  global DirectoryServerOfBroker ds;

	  LockIt (lock_set, oid);
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

      global DirectoryServerOfBroker DirectoryServerOfImpl (String path) {
	  if (SearchOwnMap (path) != 0) {
	      return oid;
	  } else {
	      String s = path;

	      do {
		  global DirectoryServerOfBroker ds = SearchSystemMap (s);
 
		  if (ds != 0) {
		      return ds;
		  } else {
		      s = Header (s);
		  }
	      } while (s != 0);
	      raise DirectoryExceptions::IllegalPathString (path);
	  }
      }

      Set <OIDAsKey <global DirectoryServerOfBroker>> DirectoryServers ()
	: locked {
	    return Members;
	}

      void Exclude (global DirectoryServerOfBroker ds) : global, locked {
	  OIDAsKey <global DirectoryServerOfBroker> key=>New (ds);

	  Members->Remove (key);
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

      int IsEmpty () : global, locked {return OwnMap->IsEmpty ();}

      void Join (global DirectoryServerOfBroker ds) : global, locked {
	  OIDAsKey <global DirectoryServerOfBroker> key=>New (ds);

	  Members->Add (key);
      }

      void Kill () : global {
	  if (IsEmpty ()) {
	      Iterator <OIDAsKey <global DirectoryServerOfBroker>> i;
	      OIDAsKey <global DirectoryServerOfBroker> key;

	      for (i=>New (Members);
		   (key = i->PostIncrement ()) != 0;) {
		  key->Get ()->Exclude (oid);
	      }
	      i->Finish ();
	      Where ()->RemoveMe (oid);
	  } else {
	      raise DirectoryExceptions::NotEmtpy;
	  }
      }

      void LinkDirectory (String header, String trailer) : global {
	  Directory <Broker> dir = SearchOwnMap (header);




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
	      global DirectoryServerOfBroker ds;

	      ds = DirectoryServerOfImpl (header);
	      if (ds == oid) {
		  raise DirectoryExceptions::UnknownDirectory (header);
	      } else {
		  ds->LinkDirectory (header, trailer);
	      }
	  }
      }

      Set <String> List (String path) : global {
	  return ListEntry (path)->AddContentsTo (ListDirectory (path));
	  /* inefficient implementation */
      }

      Set <String> ListEntry (String path) : global {
	  Set <String> s;
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  Directory <Broker> d;

	  LockIt (lock_set, oid);
	  d = SearchOwnMap (path);
	  if (d != 0) {
	      s = d->ListEntry ();
	      lock_set->UnLock ();
	      return s;
	  } else {
	      String h = Header (path);
	      d = SearchOwnMap (h);

	      if (d != 0) {
		  String t = Trailer (path);

		  s=>New ();
		  if (d->Includes (t)) {
		      s->Add (t);
		  }
		  lock_set->UnLock ();
		  return s;
	      } else {
		  global DirectoryServerOfBroker ds;

		  ds = DirectoryServerOfImpl (path);
		  lock_set->UnLock ();
		  if (ds == oid) {
		      raise DirectoryExceptions::UnknownDirectory (h);
		  } else {
		      return ds->ListEntry (path);
		  }
	      }
	  }
      }

      Set <String> ListDirectory (String path) : global {
	  Set <String> s;
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  Directory <Broker> d;

	  LockIt (lock_set, oid);
	  d = SearchOwnMap (path);
	  if (d != 0) {
	      s = d->ListDirectory ();
	      lock_set->UnLock ();
	      return s;
	  } else {
	      global DirectoryServerOfBroker ds = DirectoryServerOfImpl (path);

	      lock_set->UnLock ();
	      if (ds == oid) {
		  raise DirectoryExceptions::UnknownDirectory (path);
	      } else {
		  return ds->ListDirectory (path);
	      }
	  }
      }

      void LockIt (LockSet <global DirectoryServerOfBroker> lock_set,
		   global DirectoryServerOfBroker ds) {
	  lock_set->Add (ds);
	  while (! lock_set->Lock ())
	    ;
      }

      global DirectoryServerOfBroker
	Migrate (String path, global DirectoryServerOfBroker where) : global {
	    LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	    Directory <Broker> d;




	    while (1) {
		try {
		    LockIt (lock_set, oid);
		    d = SearchOwnMap (path);
		    if (d != 0) {
			if (where != oid) {
			    PrepareToBeLockedGlobal (lock_set);
			    if (lock_set->Lock ()) {
				global DirectoryServerOfBroker hd;

				RemoveDirectoryImpl (lock_set, path);
				hd = DirectoryServerOfImpl (Header (path));
				hd->LinkDirectory (Header (path),
						   Trailer (path));
				where->MigrateFromTo (path, d);
				lock_set->UnLock ();
				return where;
			    } /* else -- continue */
			} else {
			    lock_set->UnLock ();
			    return where;
			}
		    } else {
			global DirectoryServerOfBroker ds;

			ds = DirectoryServerOfImpl (path);
			lock_set->UnLock ();
			if (ds == oid) {
			    raise DirectoryExceptions::UnknownDirectory (path);
			} else {
			    return ds->Migrate (path, where);
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
	}

      void MigrateFromTo (String path, Directory <Broker> dir) : global {
	  if (SearchOwnMap (Header (path)) == 0) {
	      AddToSystemMap (path);
	  }
	  MigrateFromToRecursively (path, dir);
      }

      void MigrateFromToRecursively (String path, Directory <Broker> dir) {
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
      global DirectoryServerOfBroker Move (String path1, String path2)
	: global {
	    LockSet <global DirectoryServerOfBroker> lock_set;
	    String h;
	    global DirectoryServerOfBroker ds;

	    lock_set=>New ();
	    h = Header (path1);
	    while (1) {
		LockIt (lock_set, oid);
		ds = DirectoryServerOfImpl (h);
		if (ds != oid) {
		    lock_set->UnLock ();
		    return ds->Move (path1, path2);
		}

		try {
		    PrepareToBeLockedForEmerging (lock_set, path1, path2);
		    PrepareToBeLockedForDiminishing (lock_set, path1);
		    if (lock_set->Lock ()) {
			Directory <Broker> d = SearchOwnMap (h);
			String t = Trailer (path1);

			if (d != 0) {
			    if (d->IncludesEntry (t) != 0) {
				global DirectoryServerOfBroker ds;
				Broker e;

				ds = DirectoryServerOfImpl (path2);
				e = SearchOwnMap (h)->RemoveEntry (t);
				if (ds == oid) {
				    CopyEntryTo (path1, path2, e);
				} else {
				    ds->CopyEntryTo (path1, path2, e);
				}
			    } else {
				MoveDirectory (path1,
					       path2->Concatenate (Delimiter)
						        ->Concatenate (t));
			    }
			    lock_set->UnLock ();
			    return oid;
			} else {
			    raise DirectoryExceptions::UnknownDirectory (h);
			}
		    } else {
			raise TransactionExceptions::LockConfliction;
		    }
		} except {
		  TransactionExceptions::LockConfliction {
		      lock_set->UnLock ();
		      lock_set->RemoveAllContent ();
		  }
		    default {
			lock_set->UnLock ();
			raise;
		    }
		}
	    }
	}

      void MoveDirectory (String path1, String path2) : global {
	  Directory <Broker> d1;
	  Directory <Broker> d2;




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

      void MoveTreeFromTo (String path1, String path2, Directory <Broker> dir) {



	  if (dir != 0) {
	      Set <String> s;
	      unsigned int size;

	      AddToOwnMap (path2, dir);

	      s = dir->ListDirectory ();
	      for (size = s->Size (); size -- != 0;) {
		  String st = s->RemoveAny ();

		  MoveTreeFromTo (path1->Concatenate (Delimiter)
				       ->Concatenate (st),
				  path2->Concatenate (Delimiter)
				       ->Concatenate (st),
				  dir->RetrieveDirectory (st));
	      }
	  } else { /* in case of oversea subtree */
	      DirectoryServerOfImpl (path1)->MoveDirectory (path1, path2);
	  }
      }

      global DirectoryServerOfBroker NewDirectory (String path) : global {
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  String h = Header (path);
	  Directory <Broker> d;

	  LockIt (lock_set, oid);
	  d = SearchOwnMap (h);
	  if (d != 0) {
	      String t = Trailer (path);

	      if (d->Includes (t)) {
		  lock_set->UnLock ();
		  raise DirectoryExceptions::OverWriteProhibited (path);
	      } else {
		  Directory <Broker> new=>New ();

		  d->AddDirectory (t, new);
		  AddToOwnMap (path, new);
		  lock_set->UnLock ();
		  return oid;
	      }
	  } else {
	      global DirectoryServerOfBroker ds = DirectoryServerOfImpl (path);

	      if (ds == oid) {
		  lock_set->UnLock ();
		  raise DirectoryExceptions::UnknownDirectory (h);
	      } else {
		  lock_set->UnLock ();
		  return ds->NewDirectory (path);
	      }
	  }
      }

      global DirectoryServerOfBroker
	NewDirectoryServer (global ObjectManager where) : global {
	    Iterator <OIDAsKey <global DirectoryServerOfBroker>> i;
	    OIDAsKey <global DirectoryServerOfBroker> dskey;
	    LockSet <global DirectoryServerOfBroker> lock_set;
	    global DirectoryServerOfBroker new;

	    new = CreateNewDirectoryServer (where);
	    lock_set=>New ();
	    PrepareToBeLockedGlobal (lock_set);
	    while (! lock_set->Lock ())
	      ;
	    try {
		for (i=>New (Members);
		     (dskey = i->PostIncrement ()) != 0;) {
		    dskey->Get ()->Join (new);
		}
		i->Finish ();
	    } except {
		default {
		    lock_set->UnLock ();
		    raise;
		}
	    }
	    lock_set->UnLock ();
	    return new;
	}

/*      global DirectoryServerOfBroker NewEntry (String path) : global {
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  String h = Header (path);
	  Directory <Broker> d;

	  LockIt (lock_set, oid);
	  d = SearchOwnMap (h);
	  if (d != 0) {
	      String t = Trailer (path);

	      if (d->Includes (t)) {
		  lock_set->UnLock ();
		  raise DirectoryExceptions::OverWriteProhibited (path);
	      } else {
		  Broker new=>New ( );

		  d->AddEntry (t, new);
		  lock_set->UnLock ();
		  return oid;
	      }
	  } else {
	      global DirectoryServerOfBroker ds = DirectoryServerOfImpl (path);
	      if (ds == oid) {
		  lock_set->UnLock ();
		  raise DirectoryExceptions::UnknownDirectory (h);
	      } else {
		  lock_set->UnLock ();
		  return ds->NewEntry (path);
	      }
	  }
      }
*/
      void
	PrepareToBeLockedForDiminishing
	  (LockSet <global DirectoryServerOfBroker> lock_set, String path) {
	      Iterator <Assoc <String, global DirectoryServerOfBroker>> i;
	      Assoc <String, global DirectoryServerOfBroker> assoc;
	      unsigned int len = path->Length ();

	      for (i=>New (SystemMap);
		   (assoc = i->PostIncrement ()) != 0;) {
		  if (assoc->Key ()->NCompare (path, len) == 0){
		      PrepareToBeLockedGlobal (lock_set);
		      break;
		  }
	      }
	  }

      void
	PrepareToBeLockedForEmerging
	  (LockSet <global DirectoryServerOfBroker> lock_set,
	   String path1, String path2) {
	      String h = Header (path1);
	      Directory <Broker> d = SearchOwnMap (h);

	      if (d != 0) {
		  String t = Trailer (path1);

		  if (d->IncludesSubdirectory (t)) {
		      if (SearchOwnMap (path2) == 0) {
			  PrepareToBeLockedGlobal (lock_set);
		      } else {
			  Iterator <Assoc <String,
			                   global DirectoryServerOfBroker>> i;
			  Assoc <String, global DirectoryServerOfBroker> assoc;
			  unsigned int len = path1->Length ();

			  for (i=>New (SystemMap);
			       (assoc = i->PostIncrement ()) != 0;) {
			      if (assoc->Key ()->NCompare (path1, len) == 0){
				  PrepareToBeLockedGlobal (lock_set);
				  break;
			      }
			  }
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
	PrepareToBeLockedGlobal
	  (LockSet <global DirectoryServerOfBroker> lock_set)
	    : locked {
		Members->AddContentsTo (lock_set);
	    }

      global DirectoryServerOfBroker Register (String path, Broker e) : global {
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  Directory <Broker> dir;
	  String h = Header (path);

	  LockIt (lock_set, oid);
	  dir = SearchOwnMap (h);
	  if (dir != 0) {
	      String t = Trailer (path);

	      if (dir->Includes (t)) {
		  lock_set->UnLock ();
		  raise DirectoryExceptions::OverWriteProhibited (path);
	      } else {
		  dir->AddEntry (t, e);
		  lock_set->UnLock ();
		  return oid;
	      }
	  } else {
	      global DirectoryServerOfBroker ds = DirectoryServerOfImpl (path);
	      lock_set->UnLock ();
	      if (ds == oid) {
		  raise DirectoryExceptions::UnknownDirectory (h);
	      } else {
		  return ds->Register (path, e);
	      }
	  }
      }

      Broker Remove (String path) : global {
	  Broker e;
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  Directory <Broker> d;

	  LockIt (lock_set, oid);
	  d = SearchOwnMap (Header (path));
	  if (d != 0) {
	      try {
		  e = d->RemoveEntry (Trailer (path));
		  lock_set->UnLock ();
		  return e;
	      } except {
		  CollectionExceptions <String>::UnknownKey (s) {
		      lock_set->UnLock ();
		      raise DirectoryExceptions::UnknownEntry (path);
		  }
	      }
	  } else {
	      global DirectoryServerOfBroker ds = DirectoryServerOfImpl (path);

	      lock_set->UnLock ();
	      if (ds == oid) {
		  raise DirectoryExceptions::UnknownEntry (path);
	      } else {
		  return ds->Remove (path);
	      }
	  }
      }

      Directory <Broker> RemoveDirectory (String path) : global {
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  Directory <Broker> d;

	  while (1) {
	      try {
		  LockIt (lock_set, oid);
		  if ((d = SearchOwnMap (path)) != 0) {
		      RemoveDirectoryImpl (lock_set, path);
		      lock_set->UnLock ();
		      return d;
		  } else {
		      global DirectoryServerOfBroker ds;

		      ds = DirectoryServerOfImpl (path);
		      lock_set->UnLock ();
		      if (ds == oid) {
			  raise DirectoryExceptions::UnknownDirectory (path);
		      } else {
			  return ds->RemoveDirectory (path);
		      }
		  }
	      } except {
		TransactionExceptions::LockConfliction {
		    lock_set->UnLock ();
		    lock_set->RemoveAllContent ();
		    /* continue */
		}
		  CollectionExceptions<String>::UnknownKey (s) {
		      lock_set->UnLock ();
		      raise DirectoryExceptions::UnknownDirectory (path);
		  }
		  default {
		      lock_set->UnLock ();
		      raise;
		  }
	      }
	  }
      }

      void
	RemoveDirectoryImpl (LockSet <global DirectoryServerOfBroker> lock_set,
			     String path) {
	    Iterator <Assoc <String, global DirectoryServerOfBroker>> i;
	    Assoc <String, global DirectoryServerOfBroker> assoc;
	    Dictionary <String, global DirectoryServerOfBroker> dic;
	    Set <Assoc <String, global DirectoryServerOfBroker>> s;
	    int len = path->Length ();

	    dic=>New ();
	    s = dic;
	    for (i=>New (SystemMap);
		 (assoc = i->PostIncrement ()) != 0;) {
		String st = assoc->Key ();

		if (st->NCompare (path, len) == 0) {
		    s->Add (assoc);
		}
	    }
	    if (s->Size () > 0) {
		PrepareToBeLockedGlobal (lock_set);
		if (! lock_set->Lock ()) {
		    raise TransactionExceptions::LockConfliction;
		}
	    }
	    if (! OwnTops->Includes (path)) {
		RemoveDirectoryLocally (path);
	    }
	    for (i=>New (dic); (assoc = i->PostIncrement ()) != 0;) {
		assoc->Value ()->RemoveDirectoryLocally (assoc->Key ());
	    }
	}

      void RemoveDirectoryFromOwnMap (String path) {
	  Directory <Broker> dir = SearchOwnMap (path);




	  if (dir != 0) {
	      Set <String> s = dir->ListDirectory ();
	      unsigned int size;

	      for (size = s->Size (); size -- != 0;) {
		  RemoveDirectoryFromOwnMap (path->Concatenate (Delimiter)
					     ->Concatenate (s->RemoveAny ()));
	      }
	      RemoveFromOwnMap (path);
	  }
      }

      void RemoveDirectoryLocally (String path) : global {
	  Directory <Broker> d;

	  /*
	    notice: global locking must be acquired by caller when
	    removed directory is one of top directories in the ph.dir.
	    */



	  RemoveDirectoryFromOwnMap (path);
	  if (OwnTops->Includes (path)) {
	      RemoveFromSystemMap (path);
	  }
	  if ((d = SearchOwnMap (Header (path))) != 0) {
	      d->RemoveDirectory (Trailer (path));
	  }
      }

      void RemoveFromOwnMap (String path) : locked {



	  OwnMap->RemoveKey (path);
      }

      void RemoveFromSystemMap (String path) : global {
	  /* notice: global locking must be acquired by caller */
	  Iterator <OIDAsKey <global DirectoryServerOfBroker>> i;
	  OIDAsKey <global DirectoryServerOfBroker> k;

	  OwnTops->Remove (path);
	  for (i=>New (Members);
	       (k = i->PostIncrement ()) != 0;) {
	      k->Get ()->RemoveFromSystemMapLocally (path);
	  }
	  i->Finish ();
      }

      void RemoveFromSystemMapLocally (String path) : global, locked {
	  SystemMap->RemoveKey (path);
      }

      Broker Retrieve (String path) : global {
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  String h = Header (path);
	  Directory <Broker> d;

	  LockIt (lock_set, oid);
	  d = SearchOwnMap (h);
	  if (d != 0) {
	      Broker e;
	      String s;

	      try {
		  e = d->Retrieve (Trailer (path));
	      } except {
		  CollectionExceptions<String>::UnknownKey (s) {
		      lock_set->UnLock ();
		      raise DirectoryExceptions::UnknownEntry (path);
		  }
		  default {
		      lock_set->UnLock ();
		      raise;
		  }
	      }
	      lock_set->UnLock ();
	      return e;
	  } else {
	      global DirectoryServerOfBroker ds = DirectoryServerOfImpl (path);

	      lock_set->UnLock ();
	      if (ds == oid) {
		  raise DirectoryExceptions::UnknownDirectory (h);
	      } else {
		  return ds->Retrieve (path);
	      }
	  }
      }

      Directory <Broker> RetrieveDirectory (String path) : global {
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();

	  LockIt (lock_set, oid);
	  if (SearchOwnMap (Header (path)) != 0) {
	      Directory <Broker> d;
	      String s;

	      try {
		  d = SearchOwnMap (path);
		  lock_set->UnLock ();
		  if (d == 0) {
		      raise DirectoryExceptions::UnknownDirectory (path);
		  } else {
		      return d;
		  }
	      } except {
		  default {
		      lock_set->UnLock ();
		      raise;
		  }
	      }
	  } else {
	      global DirectoryServerOfBroker ds = DirectoryServerOf (path);

	      lock_set->UnLock ();
	      if (ds == oid) {
		  raise DirectoryExceptions::UnknownDirectory (path);
	      } else {
		  return ds->RetrieveDirectory (path);
	      }
	  }
      }

      Directory <Broker> RetrieveDirectoryLocally (String path) : global {
	  return SearchOwnMap (path);
      }

      Directory <Broker> SearchOwnMap (String path) : locked {
	  if (OwnMap->IncludesKey (path)) {
	      return OwnMap->AtKey (path);
	  } else {
	      return 0;
	  }
      }

      global DirectoryServerOfBroker SearchSystemMap (String path) : locked {
	  if (SystemMap->IncludesKey (path)) {
	      return SystemMap->AtKey (path);
	  } else {
	      return 0;
	  }
      }

      void
	SetMembers
	  (Set <OIDAsKey <global DirectoryServerOfBroker>> members,
	   Dictionary <String, global DirectoryServerOfBroker> systemmap) {
	      OIDAsKey <global DirectoryServerOfBroker> key=>New (oid);

	      OwnMap=>New ();
	      OwnTops=>New ();
	      SystemMap = systemmap;
	      (Members = members)->Add (key);
	      Delimiter = GetDelimiter ();
	      ID = 0;

	      Debug=>New ();

	  }

      unsigned int Seperate (String path) {
	  String s = path;
	  unsigned int r;




	  if (path->Length () == 0) {
	      return -1;
	  }
	  while (1) {
	      r = s->StrRChr (Delimiter->At (0));



	      if (r == -1) {
		  return -1;
	      } else {
		  if (Delimiter
		      ->IsEqualTo (s->GetSubString (r,
						    Delimiter->Length ()))) {
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
      }

      int TestAndLock (global LockID lock_id) : global, locked {
	  if (ID == 0) {
	      ID = lock_id;
	      return 1;
	  } else {
	      return ID == lock_id;
	  }
      }

      String Trailer (String path) {
	  unsigned int r = Seperate (path);
	  return path->GetSubString (r + Delimiter->Length (), 0);
      }

      void UnLock (global LockID lock_id) : global, locked {
	  if (ID == lock_id) {
	      ID = 0;
	  } else {
	      raise TransactionExceptions::UnknownLockID (lock_id);
	  }
      }

      global DirectoryServerOfBroker Update (String path, Broker new) : global {
	  global DirectoryServerOfBroker ret;
	  LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	  Directory <Broker> d;
	  String h = Header (path);

	  LockIt (lock_set, oid);
	  try {
	      d = SearchOwnMap (h);
	      if (d != 0) {
		  d->Update (Trailer (path), new);
		  ret = oid;
	      } else {
		  global DirectoryServerOfBroker ds = DirectoryServerOf (path);

		  if (ds == oid) {
		      raise DirectoryExceptions::UnknownDirectory (h);
		  } else {
		      ret = ds->Update (path, new);
		  }
	      }
	      lock_set->UnLock ();
	      return ret;
	  } except {
	      default {
		  lock_set->UnLock ();
		  raise;
	      }
	  }
      }

      global DirectoryServerOfBroker WhichDirectoryServer (String path)
	: global {
	    LockSet <global DirectoryServerOfBroker> lock_set=>New ();
	    global DirectoryServerOfBroker ds;

	    LockIt (lock_set, oid);
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

      global DirectoryServerOfBroker WhichDirectoryServerImpl (String path) {
	  if (SearchOwnMap (path) != 0) {
	      return oid;
	  } else {
	      Directory <Broker> d = SearchOwnMap (Header (path));

	      if (d != 0) {
		  if (d->Includes (Trailer (path))) {
		      return oid;
		  } else {
		      raise DirectoryExceptions::UnknownEntry (path);
		  }
	      } else {
		  return
		    DirectoryServerOfImpl (path)->WhichDirectoryServer (path);
	      }
	  }
      }
  }
