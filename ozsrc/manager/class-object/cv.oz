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
 * cv.oz
 *
 * a version of a class.
 * abstract class
 */

abstract class ClassVersion : ClassPart (alias New SuperNew;) {
/* interface from super classes */
  /* method interface */
  public:
    CutClassLink, IsAvailableOn, IsConfiguredClass, IsImplementationPart,
    IsProtectedPart, IsPublicPart, IsRootPart, WhichPart;
  protected: DoesFileExist;

  /* accessor methods */
  public:
    AddProperty, ClearProperties, GetClassFileDirectory, GetClassLink,
    GetID, GetProperties, LookupProperty, RemoveProperty, SetClassLink;
    /* for copy management */
  public:
    ChangeCopyKind, GetInvalidatedSource, Invalidate, IsDirty, IsDistributable,
    SetDistributability, WhichKindOfCopy;

  protected: SetInitialLengthOfPropertyTable;

/* interface from this class */
  constructor: New;
  public:
    Eliminate, GetImplementationPart, GetProtectedPart, GetPublicPart,
    GetRootPart, Purge, UsedClassTable, VersionIDFromVersionString;

  protected: CheckVisible, UsedClassTableImpl;

  /* accessor methods */
  public: GetParents, GetVersionString, SetParents, SetVersionString;

/* instance variables */
    VersionString aVersionString;
    global VersionID Parents [];
    unsigned int NumberOfParents;

/* abstract methods */
    global VersionID GetImplementationPart () : abstract;
    global VersionID GetProtectedPart () : abstract;
    global VersionID GetPublicPart () : abstract;
    global VersionID GetRootPart () : abstract;
    char UsedClassTable ()[] : abstract;
    global VersionID VersionIDFromVersionString (VersionString version_string)
      : abstract;

/* method implementations below */
    void New (global ClassID cid, Class class_object, int copy_kind) {
	SuperNew (cid, class_object, copy_kind);
	SetVersionString (0);
    }

    void CheckVisible () {
	if (GetVersionString () == 0) {
	    raise ClassExceptions::NotVisible (GetID ());
	}
    }

    void Eliminate () {}

    void Purge () {}

/* instance variable accessors */
    global VersionID GetParents ()[] {
	global VersionID tmp [] = Parents;

	length tmp = NumberOfParents;
	return tmp;
    }

    VersionString GetVersionString () {return aVersionString;}

    void SetParents (global VersionID parents []) {
	unsigned int i, len = length parents;

	Parents = parents;
	for (i = 0; i < len ; i++) {
	    if (Parents [i] == 0) {
		break;
	    }
	}
	NumberOfParents = i;
    }

    void SetVersionString (VersionString vs) {aVersionString = vs;}

    char UsedClassTableImpl (char file_name [])[] {
	String fn;

	if ((fn = LookupProperty (file_name)) != 0) {
	    return fn->Content ();
	} else {
	    fn = GetClassFileDirectory ()
	      ->ConcatenateWithArrayOfChar ("/")
		->ConcatenateWithArrayOfChar (file_name);
	    raise ClassExceptions::UnknownProperty (fn->Content ());
	}
    }
}
