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
 * dnsresolver.oz
 *
 * DNS Resolver
 */

/*
 * DNS Resolver Ver. 1
 *
 * A DNS resolver serves a name resolution functionality over domain.
 * A DNS resolver of version 1 doesn't use DNS to resolve a name.  Instead, it
 * fristly reads a setup file to make initial mappings between a domain name
 * and a global object ID of a name directory of the domain.
 *
 * It is implemented as a variation of a name directory such that a path name
 * like
 *
 *    "::ipa.go.jp"
 *
 * is a name of a remote directory and the owner of the directory is the name
 * directory of that domain.
 *
 * OwnMap        ... Contains only the directory "(null):(null)"
 * Members       ... As usual (i.e., not including name directories in other
 *                   domain).
 * SystemMap     ... As usual (i.e., not including directories in other
 *                   domain).
 * OwnTops       ... Contains only the directory "(null):(null)"
 * Directory ":" ... Contains only sub-directories whose name is domain names
 *                   and the value is a link (0).
 * DomainMap     ... A table from a domain name to an object ID of the name
 *                   directory of the domain.
 */

/*
 * Summary of the file format of a DNS resolver setup file:
 * One record per line as following:
 *
 * etl.go.jp:0003000001000003
 * mri.co.jp:0004000001000003
 *    :
 *
 * Do not insert blanks and tabs.
 */

inline "C" {
#include <fcntl.h>
}

class DNSResolver
  : NameDirectory (rename New SuperNew;
		   alias Copy SuperCopy;
		   alias Migrate SuperMigrate;
		   alias MigrateFromTo SuperMigrateFromTo;
		   alias Move SuperMove;
		   alias MoveDirectory SuperMoveDirectory;
		   alias NewDirectory SuperNewDirectory;
		   alias RemoveDirectory SuperRemoveDirectory;
		   alias DirectoryServerOfImpl SuperDirectoryServerOfImpl;)
{
  constructor: New;

  public: Go, Removing, Stop;

  public:
    AddObject, AddObjectWithArrayOfChar,
    ChangeObject, ChangeObjectWithArrayOfChar, Clear, Copy,
    Includes, IsaDirectory, IsaMember, IsEmpty, IsReady,
    List, ListDirectory, ListEntry,
    MakeDirectory, Move, NewDirectory,
    RemoveDirectory,
    RemoveObjectWithName, RemoveObjectWithNameWithArrayOfChar,
    Resolve, ResolveWithArrayOfChar, ResponsibleResolver, Terminate;

  protected: /* accessor */
    AddToMembers, AddToOwnMap, AddToOwnTops, AddToSystemMapLocally,
    DirectoryServers, DoYouHave, Flush, FlushImpl, PrepareToBeLockedGlobal,
    RemoveFromMembers, RemoveFromOwnMap, RemoveFromSystemMapLocally,
    SearchOwnMap, SearchSystemMap, SetSystemInformation, TestAndLock, UnLock;

  protected: /* method */
    CheckAndExclude, ConvertPathNameToSubsystem, Header, Initialize,
    JoinSystem, LockSelf, RegisterToNameDirectory, Shutdown, Trailer,
    UnRegisterFromNameDirectory;

  protected: OwnMap, SystemMap, Members, OwnTops, Delimiter;

    /* I/F from NameDirectory */

  public: ChangeDomain, GetMyName, SetDomainName, WhichDomain;
  protected: DomainName, MyName;

    /* I/F of this class */

  public:
    Dump, GetDomainMap, ListDomain, RegisterDomain, Setup, UnregisterDomain;
  protected: AddToDomainMap;	/* accessor */

/* instance variables */
  protected: DomainMap, RootDirectoryPath;

    Dictionary <String, global DirectoryServer <global ResolvableObject>>
      DomainMap;
    String RootDirectoryPath;

/* method implementations */
    void New () : global {
	Dictionary <String, global DirectoryServer <global ResolvableObject>>
	  system_map=>New ();
	Set <OIDAsKey <global DirectoryServer <global ResolvableObject>>>
	  members=>New ();
	OIDAsKey <global DirectoryServer <global ResolvableObject>>
	  key=>New (oid);
	Directory <global ResolvableObject> d=>New ();
	global NameDirectory nd = Where ()->GetNameDirectory ();
	ResolvableObject ro = self;

	SuperNew (system_map, members);
	RootDirectoryPath = Delimiter->Duplicate ();
	system_map->AddAssoc (RootDirectoryPath, oid);
	members->Add (key);
	SetDomainName (nd->WhichDomain ());
	MyName=>NewFromArrayOfChar (GetMyName());
	ro->AddName (GetMyName());
	AddToOwnTops (RootDirectoryPath);
	AddToOwnMap (RootDirectoryPath, d);
	DomainMap=>New ();
	RegisterToNameDirectory ();
	nd->Join (oid);
    }

    char GetMyName ()[] {
	return ":DNS-resolver";
    }

    void Removing () : global {
	global NameDirectory nd;

	nd = narrow (NameDirectory, ResolveWithArrayOfChar (":name"));
	if (nd->Resolve (MyName) == oid) {
	    nd->RemoveObjectWithName (MyName);
	}
	nd->Exclude (oid);
    }

    void Shutdown () {detach fork UnRegisterFromNameDirectory ();}

    void AddToDomainMap (String name,
			 global DirectoryServer <global ResolvableObject> ds)
      : locked {
	  DomainMap->AddAssoc (name, ds);
      }

    void AddToOwnMap (String s, Directory <global ResolvableObject> d): locked{
	if (s->IsEqualTo (RootDirectoryPath)) {
	    OwnMap->AddAssoc (s, d);
	} else {
	    raise DirectoryExceptions::IllegalPathString (s);
	}
    }

    void AddToOwnTops (String s) : locked {
	if (s->IsEqualTo (RootDirectoryPath)) {
	    OwnTops->Add (s);
	} else {
	    raise DirectoryExceptions::IllegalPathString (s);
	}
    }

    global NameDirectory BroadcastToSearchOther () {
	return Where ()->GetNameDirectory ();
    }

    void CheckPath (String path) {
	String head = RootDirectoryPath->Concatenate (Delimiter);
	unsigned int head_len = head->Length ();

	if (path->IsEqualTo (RootDirectoryPath)) {
	    raise DirectoryExceptions::OverWriteProhibited (path);
	} else if (path->NCompare (head, head_len) == 0) {
	    unsigned int i, len = path->Length ();

	    for (i = head_len; i < len; i ++) {
		if (path->At (i) == ':') {
		    return;
		}
	    }
	    raise DirectoryExceptions::OverWriteProhibited (path);
	}
    }

    void Clear () : global {
	LockSet <global DirectoryServer <global ResolvableObject>> lock_set;
	Dictionary <String, Directory <global ResolvableObject>> own_map;
	Directory <global ResolvableObject> d=>New ();
	Dictionary <String, global DirectoryServer <global ResolvableObject>>
	  domain_map;

	own_map=>New ();
	own_map->AddAssoc (RootDirectoryPath, d);
	domain_map=>New ();
	lock_set=>New ();
	LockSelf (lock_set);
	OwnMap = own_map;
	DomainMap = domain_map;
	lock_set->Commit ();
	lock_set->UnLock ();
    }

    String
      ConvertPathNameToSubsystem
	(String path,
	 global DirectoryServer <global ResolvableObject> ds) {
	    String domain_name = DomainNamePart (path);
	    String head;

	    head = RootDirectoryPath->Concatenate (Delimiter);
	    if (domain_name == 0) {
		head = head->Concatenate (DomainName)->Concatenate (Delimiter);
		path = head->Concatenate (path);
	    } else {
		if (SearchDomainMap (domain_name) == ds) {
		    head = head->Concatenate (domain_name);
		    path = path->GetSubString (head->Length (), 0);
		}
	    }
	    return path;
	}

    global DirectoryServer <global ResolvableObject>
      Copy (String path1, String path2) : global {
	  CheckPath (path1);
	  CheckPath (path2);
	  SuperCopy (path1, path2);
      }

    global DirectoryServer <global ResolvableObject>
      DirectoryServerOfImpl (String path) {
	  String h = DomainNamePart (path);

	  if (h != 0) {
	      global NameDirectory nd = SearchDomainMap (h);

	      if (nd != 0) {
		  return nd;
	      } else {
		  raise DirectoryExceptions::UnknownDirectory (h);
	      }
	  } else {
	      return SuperDirectoryServerOfImpl (path);
	  }
      }

    String DomainNamePart (String path) {
	String head = RootDirectoryPath->Concatenate (Delimiter);
	unsigned int head_len = head->Length ();

	if (path->NCompare (head, head_len) == 0) {
	    unsigned int i, len = path->Length ();

	    for (i = head_len; i < len; i ++) {
		if (path->At (i) == ':') {
		    return path->GetSubString (head_len, i - head_len);
		}
	    }
	    return path->GetSubString (head_len, 0);
	} else {
	    return 0;
	}
    }

    void Dump (String path) : global, locked {
	int flag;
	Stream sf;
	Iterator <Assoc <String,
                  global DirectoryServer <global ResolvableObject>>> i;
	Assoc <String, global DirectoryServer <global ResolvableObject>> a;

	inline "C" {
	    flag = O_WRONLY | O_CREAT | O_TRUNC;
	}
	sf=>NewWithFlag (path, flag);
	for (i=>New (DomainMap); (a = i->PostIncrement ()) != 0;) {
	    sf->PutStr (a->Key ()->Content ());
	    sf->PutStr (":");
	    sf->PutOID (a->Value ());
	    sf->PutStr ("\n");
	}
    }

    void EliminateAllOrphans () : global {}

    Dictionary <String, global DirectoryServer <global ResolvableObject>>
      GetDomainMap () : global {
	  return DomainMap;
      }

    Set <String> ListDomain () : global, locked {
	return DomainMap->SetOfKeies ();
    }

    global DirectoryServer <global ResolvableObject>
      Migrate (String path,
	       global DirectoryServer <global ResolvableObject> where)
	: global {
	    CheckPath (path);
	    SuperMigrate (path, where);
	}

    void MigrateFromTo (String path, Directory <global ResolvableObject> dir)
      : global {
	  CheckPath (path);
	  SuperMigrateFromTo (path, dir);
      }

    global DirectoryServer <global ResolvableObject>
      Move (String path1, String path2) : global {
	  CheckPath (path1);
	  CheckPath (path2);
	  SuperMove (path1, path2);
      }

    void MoveDirectory (String path1, String path2) : global {
	CheckPath (path1);
	CheckPath (path2);
	SuperMoveDirectory (path1, path2);
    }

    global DirectoryServer <global ResolvableObject>
      NewDirectory (String path) : global {
	  CheckPath (path);
	  SuperNewDirectory (path);
      }

    global DirectoryServer <global ResolvableObject>
      NewDirectoryServer (global ObjectManager where) : global {
	  raise DirectoryExceptions::CannotCreateDirectoryServer;
      }

    void RegisterDomain (String path, global NameDirectory nd)
      : global {
	  LockSet <global DirectoryServer <global ResolvableObject>>
	    lock_set=>New ();

	  LockSelf (lock_set);
	  try {
	      if (DomainMap->IncludesKey (path)) {
		  raise DirectoryExceptions::OverWriteProhibited (path);
	      } else {
		  if (Delimiter->Length () > 0) {
		      int r;
		      SubString ss;
		      String s = path;

		      while ((r = path->StrRChr (Delimiter->At (0))) != -1) {
			  ss = path->GetSubString (r, Delimiter->Length ());
			  if (Delimiter->IsEqualTo (ss)) {
			      raise
			      DirectoryExceptions::IllegalPathString (path);
			  } else {
			      s = path->GetSubString (0, r);
			  }
		      }
		  }

		  SearchOwnMap (RootDirectoryPath)->AddDirectory (path, 0);
		  AddToDomainMap (path, nd);
	      }
	  } except {
	      default {
		  lock_set->UnLock ();
		  raise;
	      }
	  }
	  FlushImpl ();
	  lock_set->UnLock ();
      }
	    
    Directory <global ResolvableObject> RemoveDirectory (String path): global {
	/*
	 * When a domain directory is designated, the domain should be removed
	 */
	CheckPath (path);
	SuperRemoveDirectory (path);
    }

    void RemoveFromDomainMap (String name) : locked {
	DomainMap->RemoveKey (name);
    }

    global ResolvableObject Resolve (String path) : global {
	try {
	    return Retrieve (path);
	} except {
	  DirectoryExceptions::UnknownEntry (path) {
	      return 0;
	  }
	}
    }

    global NameDirectory SearchDomainMap (String path) : locked {
	if (DomainMap->IncludesKey (path)) {
	    return narrow (NameDirectory, DomainMap->AtKey (path));
	} else {
	    return 0;
	}
    }

    void Setup (String path) : global, locked {
	Stream sf=>New (path);
	Directory <global ResolvableObject> d;
	char buf [];
	String domain;
	global NameDirectory o;
	ArrayOfCharOperators acops;

	d = OwnMap->AtKey (RootDirectoryPath);
	while (! sf->IsEndOfFile ()) {
	    domain=>NewFromArrayOfChar (sf->GetTillaChar (":"));
	    domain = domain->GetSubString (0, domain->Length () - 1);
	    buf = sf->GetS ();
	    buf [acops.Length (buf) - 1] = 0;
	    o = narrow (NameDirectory, acops.Str2OID (buf));
	    DomainMap->AddAssoc (domain, o);
	    d->AddDirectory (domain, 0);
	}
    }

    void Terminate () : global {
	Shutdown ();
	Exclude (oid);
	Where ()->RemoveMe (oid);
    }

    void UnregisterDomain (String path) : global {
	LockSet <global DirectoryServer <global ResolvableObject>>
	  lock_set=>New ();

	LockSelf (lock_set);
	if (DomainMap->IncludesKey (path)) {
	    SearchOwnMap (RootDirectoryPath)->RemoveDirectory (path);
	    DomainMap->RemoveKey (path);
	} else {
	    raise DirectoryExceptions::UnknownEntry (path);
	}
	lock_set->UnLock ();
    }
}
