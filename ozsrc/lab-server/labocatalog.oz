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
 * labocatalog.oz
 *
 * Secure Catalog of Distributed Software Laboratory
 */

class LaboCatalog : Catalog
  (alias New SuperNew;
   alias Copy SuperCopy;
   alias Exclude SuperExclude;
   alias Includes SuperIncludes;
   alias Initialize SuperInitialize;
   alias IsaDirectory SuperIsaDirectory;
   alias Join SuperJoin;
   alias List SuperList;
   alias ListDirectory SuperListDirectory;
   alias ListPackage SuperListPackage;
   alias Migrate SuperMigrate;
   alias Move SuperMove;
   alias NewDirectory SuperNewDirectory;
   alias NewDirectoryServer SuperNewDirectoryServer;
   alias Register SuperRegister;
   alias Remove SuperRemove;
   alias RemoveDirectory SuperRemoveDirectory;
   alias Retrieve SuperRetrieve;
   alias RetrieveDirectory SuperRetrieveDirectory;
   alias Terminate SuperTerminate;
   alias Update SuperUpdate;
   alias WhichDirectoryServer SuperWhichDirectoryServer;)
{
  public: Go, Removing, Stop;
  constructor: New, NewDirectorySystem;

  public:
    DirectoryServers, Includes, IsaDirectory, IsaMember, IsEmpty, IsReady,
    List, ListPackage, ListDirectory, NewDirectory, Register, Retrieve,
    RetrieveDirectory, WhichDirectoryServer;

  public:
    SecureCopy, SecureExclude, SecureJoin, SecureMigrate, SecureMove,
    SecureNewDirectory, SecureNewDirectoryServer,
    SecureRegister, SecureRemove, SecureRemoveDirectory, SecureTerminate,
    SecureUpdate;

  public:
    ReloadKey;

  protected: /* methods */
    CheckAndExclude, ConvertPathNameToSubsystem, CreateNewDirectoryServer,
    DirectoryServerOfImpl, Flush, GetDelimiter, Header, Initialize,
    JoinSystem, LockSelf, MigrateFromTo, MoveDirectory,
    PrepareToBeLockedForEmerging, Trailer;

  protected: /* accessor */
    AddToMembers, AddToOwnMap, AddToOwnTops, AddToSystemMapLocally, DoYouHave,
    GetOwnMap, GetOwnTops, GetSystemMap, PrepareToBeLockedGlobal,
    RemoveFromMembers, RemoveFromOwnMap, RemoveFromSystemMapLocally,
    SearchOwnMap, SearchSystemMap, SetSystemInformation, TestAndLock, UnLock;

  protected: /* instance variables */
    OwnMap, SystemMap, Members, OwnTops, Delimiter;

/* instance variables */

    LaboratorySecurity Security;

/* method implementations */

    void New(
	Dictionary<String, global DirectoryServer<Package>> systemMap,
	Set<OIDAsKey<global DirectoryServer<Package>>> members
    ) : global {
	SuperNew(systemMap, members);
	Security=>New();
    }

    String ReloadKey() : global {
	Security->ReloadKey();
    }

    void Initialize() {
	SuperInitialize();
	ReloadKey();
    }

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

    global DirectoryServer<Package> Copy(String path1, String path2) : global {
	InsecureCopy(path1, path2);
    }

    global DirectoryServer<Package> SecureCopy(
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

    void Exclude(global DirectoryServer<Package> ds) : global {
	InsecureExclude(ds);
    }

    void SecureExclude(
	Credential cred, global DirectoryServer<Package> ds
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperExclude(ds);
	} else {
	    InsecureExclude(ds);
	}
    }

    void InsecureExclude(global DirectoryServer<Package> ds) {
	Security->SecurityException(ConcatenateOID("Exclude", ds));
    }

    void Join(global DirectoryServer<Package> ds) : global {
	InsecureJoin(ds);
    }

    void SecureJoin(
	Credential cred, global DirectoryServer<Package> ds
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperJoin(ds);
	} else {
	    InsecureJoin(ds);
	}
    }

    void InsecureJoin(global DirectoryServer<Package> ds) {
	Security->SecurityException(ConcatenateOID("Join", ds));
    }

    global DirectoryServer<Package> Migrate(
	String path, global DirectoryServer<Package> where
    ) : global {
	InsecureMigrate(path, where);
    }

    global DirectoryServer<Package> SecureMigrate(
	  Credential cred, String path, global DirectoryServer<Package> where
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperMigrate(path, where);
	} else {
	    InsecureMigrate(path, where);
	}
    }

    void InsecureMigrate(String path, global DirectoryServer<Package> where) {
	String st=>NewFromArrayOfChar("Migrate(");
	String d=>OIDtoHexa(where);
	Security->CheckString(path);
	st->Concatenate(path);
	st->ConcatenateWithArrayOfChar(",");
	st->Concatenate(d);
	st->ConcatenateWithArrayOfChar(")");
	Security->SecurityException(st);
    }

    global DirectoryServer<Package> Move(String path1, String path2) : global {
	InsecureMove(path1, path2);
    }

    global DirectoryServer<Package> SecureMove(
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

    global DirectoryServer<Package> NewDirectory(String path) : global {
	Security->CheckString(path);
	if (SuperIncludes(path)) {
	    InsecureNewDirectory(path);
	} else {
	    SuperNewDirectory(path);
	}
    }

    global DirectoryServer<Package> SecureNewDirectory(
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

    global DirectoryServer<Package> NewDirectoryServer(
	global ObjectManager where
    ) : global {
	InsecureNewDirectoryServer(where);
    }

    global DirectoryServer<Package> SecureNewDirectoryServer(
	Credential cred, global ObjectManager where
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperNewDirectoryServer(where);
	} else {
	    InsecureNewDirectoryServer(where);
	}
    }

    void InsecureNewDirectoryServer(global ObjectManager where) {
	Security->SecurityException(ConcatenateOID("NewDirectoryServer",
						   where));
    }

    global DirectoryServer<Package> Register(String path, Package e) : global {
	Security->CheckString(path);
	if (SuperIncludes(path)) {
	    InsecureRegister(path, e);
	} else {
	    SuperRegister(path, e);
	}
    }

    global DirectoryServer<Package> SecureRegister(
	Credential cred, String path, Package e
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperRegister(path, e);
	} else {
	    InsecureRegister(path, e);
	}
    }

    void InsecureRegister(String path, Package e) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("Register", path));
    }

    Package Remove(String path) : global {
	InsecureRemove(path);
    }

    Package SecureRemove(Credential cred, String path) {
	if (Security->IsSecureInvocation(cred)) {
	    SuperRemove(path);
	} else {
	    InsecureRemove(path);
	}
    }

    void InsecureRemove(String path) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("Remove", path));
    }

    Directory<Package> RemoveDirectory(String path) : global {
	InsecureRemoveDirectory(path);
    }

    Directory<Package> SecureRemoveDirectory(
	Credential cred, String path
    ) : global {
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

    void Terminate() : global {InsecureTerminate();}

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

    global DirectoryServer<Package> Update(String path, Package new) : global {
	InsecureUpdate(path, new);
    }

    global DirectoryServer<Package> SecureUpdate(
	Credential cred, String path, Package new
    ) : global {
	if (Security->IsSecureInvocation(cred)) {
	    SuperUpdate(path, new);
	} else {
	    InsecureUpdate(path, new);
	}
    }

    void InsecureUpdate(String path, Package new) {
	Security->CheckString(path);
	Security->SecurityException(ConcatenatePath("Update", path));
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

    Set<String> ListPackage(String path) : global {
	Security->CheckString(path);
	return SuperListPackage(path);
    }

    Set<String> ListDirectory(String path) : global {
	Security->CheckString(path);
	return SuperListDirectory(path);
    }

    Package Retrieve (String path) : global {
	Security->CheckString(path);
	return SuperRetrieve(path);
    }

    Directory<Package> RetrieveDirectory(String path) : global {
	Security->CheckString(path);
	return SuperRetrieveDirectory(path);
    }

    global DirectoryServer<Package> WhichDirectoryServer(String path) : global{
	Security->CheckString(path);
	return SuperWhichDirectoryServer(path);
    }

/**/
    String GetSystemName () {
	String s=>NewFromArrayOfChar (":labo-catalog");

	return s;
    }
}
