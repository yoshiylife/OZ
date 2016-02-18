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
 * upperpart.oz
 *
 * An abstraction of a class part which is 'upper' to other class parts.
 * abstract class
 */

abstract class UpperPart : ClassVersion (rename New SuperNew;) {
/* interface from super classes */
  /* method interface */
  public: 
    CutClassLink,
    GetImplementationPart, GetProtectedPart, GetPublicPart, GetRootPart,
    IsAvailableOn,
    IsConfiguredClass, IsImplementationPart, IsProtectedPart,
    IsPublicPart, IsRootPart,
    Purge, UsedClassTable, VersionIDFromVersionString, WhichPart;
  protected: CheckVisible, DoesFileExist, UsedClassTableImpl;

  /* accessor methods */
  public:
    AddProperty, ClearProperties, GetClassFileDirectory, GetID,
    GetParents, GetProperties, GetVersionString, LookupProperty,
    RemoveProperty, SetClassLink, SetParents, SetVersionString;
  protected: GetClassLink, SetInitialLengthOfPropertyTable;
    /* for copy management */
  public:
    ChangeCopyKind, GetInvalidatedSource, Invalidate, IsDirty,
    IsDistributable, SetDistributability, WhichKindOfCopy;

/* interface from this class */
  constructor: New;
  public:
    AddAsNewLowerVersion, Eliminate, GetDefaultLowerVersionID,
    GetLowerVersions, GetNewVersionString, GetVisibleLowerVersions,
    IsLowerVersion, IsVisibleLowerVersion, MakeALowerVersionVisible,
    NewLowerVersion, LatestLowerVersion, LatestVersionNumber,
    LatestVisibleLowerVersion, RemoveLowerVersion,
    SetDefaultLowerVersionID;

  protected:
    ChangeLowerPartOfVersionString,
    SetInitialCapacityOfLowerVersions,
    SetInitialCapacityOfVisibleLowerVersions;

/* instance variables */
  protected: DefaultLowerVersion, LowerVersions, VisibleLowerVersions;

    unsigned int InitialCapacityOfLowerVersions; /* = 2 */
    unsigned int InitialCapacityOfVisibleLowerVersions; /* = 2 */

    SimpleArray <global VersionID> LowerVersions;
    global VersionID DefaultLowerVersion;
    SimpleArray <global VersionID> VisibleLowerVersions;
    /* SimpleArray VisibleLowerVersions is 0 origin.  That is, version */
    /* 1 is stored in VisibleLowerVersions->At (0). */

/* abstract methods */
    VersionString ChangeLowerPartOfVersionString (unsigned int new) : abstract;
    LowerPart
      NewLowerVersion (global VersionID vid, unsigned int kind) : abstract;

/* constructors (used in concrete classes) */
    void New (global ClassID cid, Class class_object, int copy_kind) {
	SuperNew (cid, class_object, copy_kind);
	SetInitialCapacityOfLowerVersions ();
	SetInitialCapacityOfVisibleLowerVersions ();
	LowerVersions=>NewWithSize (InitialCapacityOfLowerVersions);
	DefaultLowerVersion = 0;
	VisibleLowerVersions
	  =>NewWithSize (InitialCapacityOfVisibleLowerVersions);
    }

/* public method implementations */
    void AddAsNewLowerVersion (global VersionID vid) : locked {
	if (LowerVersions->Includes (vid)) {
	    if (VisibleLowerVersions->Includes (vid)) {
		VisibleLowerVersions->Remove (vid);
	    }
	    LowerVersions->Remove (vid);
	}
	LowerVersions->Add (vid);
    }

    void Eliminate () {
	Class c = GetClassLink ();
	unsigned int i, len = LowerVersions->Size ();

	for (i = 0; i < len; i ++) {
	    global VersionID vid = LowerVersions->At (i);

	    if (c->LookupClass (vid) != 0) {
		c->RemoveClassVersion (vid);
	    }
	}
    }

    global VersionID GetDefaultLowerVersionID () {return DefaultLowerVersion;}

    global VersionID GetLowerVersions ()[] : locked {
	return LowerVersions->Content ();
    }

    VersionString GetNewVersionString (global VersionID vid) {
	unsigned int index;

	CheckVisible ();
	index = MakeALowerVersionVisible (vid);
	return ChangeLowerPartOfVersionString (index);
    }

    global VersionID GetVisibleLowerVersions ()[] : locked {
	return VisibleLowerVersions->Content ();
    }

    int IsLowerVersion (global VersionID vid) : locked {
	return LowerVersions->Includes (vid);
    }

    int IsVisibleLowerVersion (global VersionID vid) : locked {
	return VisibleLowerVersions->Includes (vid);
    }

    unsigned int MakeALowerVersionVisible (global VersionID vid) : locked {
	unsigned int latest_visible = VisibleLowerVersions->Size ();
	unsigned int index = LowerVersions->Lookup (vid);

	if (index < LowerVersions->Size ()) {
	    if (latest_visible == 0
		|| LowerVersions
		     ->Lookup (VisibleLowerVersions->At (latest_visible - 1))
		   < index) {
		VisibleLowerVersions->Add (vid);
		return latest_visible + 1;
	    } else {
		raise ClassExceptions::InvalidVersionOrder;
	    }
	} else {
	    raise ClassExceptions::UnknownLowerPart (vid);
	}
    }

    void Purge () {
	unsigned int i, j, len = VisibleLowerVersions->Size ();
	Class c = GetClassLink ();
	global VersionID vid;

	for (i = 0, j = 0; i < len; i ++) {
	    int to = LowerVersions->Lookup (VisibleLowerVersions->At (i));

	    for (; j < to; -- to) {
		vid = LowerVersions->At (j);
		if (c->LookupClass (vid) != 0) {
		    c->RemoveLowerVersion (vid);
		}
	    }
	    j = to + 1;
	}
	len = LowerVersions->Size ();
	for (i = 0; i < len; i ++) {
	    vid = LowerVersions->At (i);
	    if (c->LookupClass (vid) != 0) {
		c->Purge (vid);
	    }
	}
    }

    void RemoveLowerVersion (global VersionID vid) : locked {
	try {
	    LowerVersions->Remove (vid);
	} except {
	    CollectionExceptions <global VersionID>::ElementNotFound (c) {
		raise ClassExceptions::UnknownLowerPart (vid);
	    }
	}
    }

    global VersionID LatestLowerVersion () : locked {
	unsigned int size = LowerVersions->Size ();

	if (size > 0) {
	    return LowerVersions->At (size - 1);
	} else {
	    return 0;
	}
    }

    global VersionID LatestVisibleLowerVersion () : locked {
	unsigned int size = VisibleLowerVersions->Size ();

	if (size > 0) {
	    return VisibleLowerVersions->At (size - 1);
	} else {
	    return 0;
	}
    }

    unsigned int LatestVersionNumber () : locked {
	return VisibleLowerVersions->Size ();
    }

    void SetDefaultLowerVersionID (global VersionID vid) : locked {
	if (LowerVersions->Includes (vid)) {
	    DefaultLowerVersion = vid;
	} else {
	    raise ClassExceptions::UnknownLowerPart (vid);
	}
    }

    void SetInitialCapacityOfLowerVersions () {
	InitialCapacityOfLowerVersions = 2;
    }

    void SetInitialCapacityOfVisibleLowerVersions () {
	InitialCapacityOfVisibleLowerVersions = 2;
    }
}
