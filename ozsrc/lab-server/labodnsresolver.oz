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
 * labodnsresolver.oz
 *
 * Secure DNS Resolver of Distributed Software Laboratory
 */

class LaboDNSResolver : DNSResolver
  (alias AddObject SuperAddObject;
   alias AddObjectWithArrayOfChar SuperAddObjectWithArrayOfChar;
   alias ChangeObject SuperChangeObject;
   alias ChangeObjectWithArrayOfChar SuperChangeObjectWithArrayOfChar;
   alias Clear SuperClear;
   alias Copy SuperCopy;
   alias Includes SuperIncludes;
   alias IsaDirectory SuperIsaDirectory;
   alias List SuperList;
   alias ListDirectory SuperListDirectory;
   alias ListEntry SuperListEntry;
   alias MakeDirectory SuperMakeDirectory;
   alias Move SuperMove;
   alias New SuperNew;
   alias NewDirectory SuperNewDirectory;
   alias RemoveDirectory SuperRemoveDirectory;
   alias RemoveObjectWithName SuperRemoveObjectWithName;
   alias RemoveObjectWithNameWithArrayOfChar
           SuperRemoveObjectWithNameWithArrayOfChar;
   alias Resolve SuperResolve;
   alias ResponsibleResolver SuperResponsibleResolver;
   alias Terminate SuperTerminate;)
{
  constructor: New;

  public: Go, Removing, Stop;

  public:
    AddObject, AddObjectWithArrayOfChar, Includes, IsaDirectory, IsaMember,
    IsEmpty, IsReady, List, ListDirectory, ListEntry, MakeDirectory,
    NewDirectory, Resolve, ResolveWithArrayOfChar, ResponsibleResolver;

  public:
    SecureAddObject, SecureAddObjectWithArrayOfChar, SecureChangeObject,
    SecureChangeObjectWithArrayOfChar, SecureClear, SecureCopy,
    SecureMakeDirectory, SecureMove, SecureNewDirectory,
    SecureRemoveDirectory, SecureRemoveObjectWithName,
    SecureRemoveObjectWithNameWithArrayOfChar, SecureTerminate;

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

    LaboratorySecurity Security;

    String ConcatenatePath(char name[], String path) {
	String st=>NewFromArrayOfChar(name);
	st = st->ConcatenateWithArrayOfChar("(");
	st = st->Concatenate(path);
	return st->ConcatenateWithArrayOfChar(")");
    }

    String Concatenate2Pathes(char name[], String path1, String path2) {
	String st=>NewFromArrayOfChar(name);
	st = st->ConcatenateWithArrayOfChar("(");
	st = st->Concatenate(path1);
	st = st->ConcatenateWithArrayOfChar(",");
	st = st->Concatenate(path2);
	return st->ConcatenateWithArrayOfChar(")");
    }

    String ConcatenateOID(char name[], global Object o) {
	String st=>NewFromArrayOfChar(name);
	String d=>OIDtoHexa(o);
	st = st->ConcatenateWithArrayOfChar("(");
	st = st->Concatenate(d);
	return st->ConcatenateWithArrayOfChar(")");
    }

/**/

    void New () : global {
	SuperNew();
	Security=>New();
    }

    global DirectoryServer<global ResolvableObject> AddObject(
	String path, global ResolvableObject o
    ) : global {
	Security->CheckString(path);
	if (SuperIncludes(path)) {
	    InsecureAddObject(path);
	} else {
	    SuperAddObject(path, o);
	}
    }

    global DirectoryServer<global ResolvableObject> SecureAddObject(
	Credential cred, String path, global ResolvableObject o
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperAddObject(path, o);
	} else {
	    InsecureAddObject(path);
	}
    }

    void InsecureAddObject(String path) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("AddObject", path));
    }

    global DirectoryServer<global ResolvableObject> AddObjectWithArrayOfChar(
	char s[], global ResolvableObject o
    ) : global {
	String path=>NewFromArrayOfChar(s);
	if (SuperIncludes(path)) {
	    InsecureAddObjectWithArrayOfChar(s);
	} else {
	    SuperAddObject(path, o);
	}
    }

    global DirectoryServer<global ResolvableObject>
      SecureAddObjectWithArrayOfChar(
	  Credential cred, char s [], global ResolvableObject o
      ) : global {
	  if (Security->IsSecureInvocation(cred)) {
	      SuperAddObjectWithArrayOfChar(s, o);
	  } else {
	      InsecureAddObjectWithArrayOfChar(s);
	  }
      }

    void InsecureAddObjectWithArrayOfChar(char s[]) {
	String path=>NewFromArrayOfChar(s);
	Security->SecurityException(
	    ConcatenatePath("AddObjectWithArrayOfChar", path)
	);
    }

    global DirectoryServer<global ResolvableObject> ChangeObject(
	String path, global ResolvableObject new
    ) : global {
	InsecureChangeObject(path);
    }

    global DirectoryServer<global ResolvableObject> SecureChangeObject(
	Credential cred, String path, global ResolvableObject new
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperChangeObject(path, new);
	} else {
	    InsecureChangeObject(path);
	}
    }

    void InsecureChangeObject(String path) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("ChangeObject", path));
    }

    global DirectoryServer<global ResolvableObject>
      ChangeObjectWithArrayOfChar (
	  char s[], global ResolvableObject new
      ) : global {
	  InsecureChangeObjectWithArrayOfChar(s);
      }

    global DirectoryServer<global ResolvableObject>
      SecureChangeObjectWithArrayOfChar (
	  Credential cred, char s[], global ResolvableObject new
      ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperChangeObjectWithArrayOfChar(s, new);
	} else {
	    InsecureChangeObjectWithArrayOfChar(s);
	}
      }

    void InsecureChangeObjectWithArrayOfChar(char s[]) {
	String path=>NewFromArrayOfChar(s);
	Security->SecurityException(
	    ConcatenatePath("ChangeObjectWithArrayOfChar", path)
	);
    }

    void Clear() : global {InsecureClear();}

    void SecureClear(Credential cred) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperClear();
	} else {
	    InsecureClear();
	}
    }

    void InsecureClear() {
	String st=>NewFromArrayOfChar("Clear()");
	Security->SecurityException(st);
    }

    global DirectoryServer<global ResolvableObject> Copy(
	String path1, String path2
    ) : global {
	InsecureCopy(path1, path2);
    }

    global DirectoryServer<global ResolvableObject> SecureCopy(
	Credential cred, String path1, String path2
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperCopy(path1, path2);
	} else {
	    InsecureCopy(path1, path2);
	}
    }

    void InsecureCopy(String path1, String path2) {
	Security->CheckString(path1);
	Security->CheckString(path2);
	Security->SecurityException(Concatenate2Pathes("Copy", path1, path2));
    }

    global DirectoryServer<global ResolvableObject> MakeDirectory(
	String path
    ) : global {
	InsecureMakeDirectory(path);
    }

    global DirectoryServer<global ResolvableObject> SecureMakeDirectory(
	Credential cred, String path
    ) : global {
	Security->CheckString(path);
	if (Security->IsSecureInvocation(cred)) {
	    SuperMakeDirectory(path);
	} else {
	    InsecureMakeDirectory(path);
	}
    }

    void InsecureMakeDirectory(String path) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("MakeDirectory", path));
    }

    global DirectoryServer<global ResolvableObject> Move(
	String path1, String path2
    ) : global {
	InsecureMove(path1, path2);
    }

    global DirectoryServer<global ResolvableObject> SecureMove(
	Credential cred, String path1, String path2
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperMove(path1, path2);
	} else {
	    InsecureMove(path1, path2);
	}
    }

    void InsecureMove(String path1, String path2) {
	Security->CheckString(path1);
	Security->CheckString(path2);
	Security->SecurityException(Concatenate2Pathes("Move", path1, path2));
    }

    global DirectoryServer<global ResolvableObject> NewDirectory(
	String path
    ) : global {
	Security->CheckString(path);
	if (Includes(path)) {
	    InsecureNewDirectory(path);
	} else {
	    SuperNewDirectory(path);
	}
    }

    global DirectoryServer<global ResolvableObject> SecureNewDirectory(
	Credential cred, String path
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperNewDirectory(path);
	} else {
	    InsecureNewDirectory(path);
	}
    }

    void InsecureNewDirectory(String path) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("NewDirectory", path));
    }

    Directory<global ResolvableObject> RemoveDirectory(String path): global {
	InsecureRemoveDirectory(path);
    }

    Directory<global ResolvableObject> SecureRemoveDirectory(
	Credential cred, String path
    ): global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperRemoveDirectory(path);
	} else {
	    InsecureRemoveDirectory(path);
	}
    }

    void InsecureRemoveDirectory(String path) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("RemoveDirectory", path));
    }

    global ResolvableObject RemoveObjectWithName(String path) : global {
	InsecureRemoveObjectWithName(path);
    }

    global ResolvableObject SecureRemoveObjectWithName(
	Credential cred, String path
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperRemoveObjectWithName(path);
	} else {
	    InsecureRemoveObjectWithName(path);
	}
    }

    void InsecureRemoveObjectWithName(String path) {
	Security->CheckString(path);
	Security->SecurityException(
	    ConcatenatePath("RemoveObjectWithName", path)
	);
    }

    global ResolvableObject RemoveObjectWithNameWithArrayOfChar(
	char s[]
    ) : global {
	InsecureRemoveObjectWithNameWithArrayOfChar(s);
    }

    global ResolvableObject SecureRemoveObjectWithNameWithArrayOfChar(
	Credential cred, char s[]
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperRemoveObjectWithNameWithArrayOfChar(s);
	} else {
	    InsecureRemoveObjectWithNameWithArrayOfChar(s);
	}
    }

    void InsecureRemoveObjectWithNameWithArrayOfChar(char s[]) {
	String path=>NewFromArrayOfChar(s);
	Security->SecurityException(
	    ConcatenatePath("RemoveObjectWithNameWithArrayOfChar", path)
	);
    }

    void Terminate() : global {
	InsecureTerminate();
    }

    void SecureTerminate(Credential cred) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperTerminate();
	} else {
	    InsecureTerminate();
	}
    }

    void InsecureTerminate() {
	String message=>NewFromArrayOfChar("Terminate()");
	Security->SecurityException(message);
    }

/**/

    int Includes(String path) : global {
	Security->CheckString(path);
	return SuperIncludes(path);
    }

    int IsaDirectory(String path) : global {
	Security->CheckString(path);
	return SuperIsaDirectory(path);
    }

    Set<String> List(String path) : global {
	Security->CheckString(path);
	return SuperList(path);
    }

    Set<String> ListDirectory(String path) : global {
	Security->CheckString(path);
	return SuperListDirectory(path);
    }

    global ResolvableObject Resolve(String path) : global {
	Security->CheckString(path);
	return SuperResolve(path);
    }

    global DirectoryServer<global ResolvableObject> ResponsibleResolver (
	String path
    ) : global {
	Security->CheckString(path);
	return SuperResponsibleResolver(path);
    }

/**/

    char GetMyName ()[] {
	return ":labo-DNSresolver";
    }
}
