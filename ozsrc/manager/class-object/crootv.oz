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
 * crootv.oz
 *
 * A root part of a class.
 * Holds public versions of the class.
 */

class RootPart : UpperPart (rename New SuperNew;) {
/* interface from super classes */
  /* method interface */
  public: 
    AddAsNewLowerVersion, CutClassLink,
    GetDefaultLowerVersionID, GetImplementationPart, GetLowerVersions,
    GetNewVersionString, GetProtectedPart, GetPublicPart, GetRootPart,
    GetVisibleLowerVersions, IsAvailableOn, IsConfiguredClass,
    IsImplementationPart, IsLowerVersion, IsProtectedPart, IsPublicPart,
    IsRootPart, IsVisibleLowerVersion, LatestLowerVersion,
    LatestVisibleLowerVersion, MakeALowerVersionVisible, NewLowerVersion,
    RemoveLowerVersion, SetDefaultLowerVersionID, UsedClassTable,
    VersionIDFromVersionString, WhichPart;

  protected:
    ChangeLowerPartOfVersionString, CheckVisible, DoesFileExist;

  /* accessor methods */
  public:
    AddProperty, ClearProperties, GetClassFileDirectory, GetClassLink,
    GetID, GetParents, GetProperties, GetVersionString, LookupProperty,
    RemoveProperty, SetClassLink, SetParents, SetVersionString;
  protected: SetInitialLengthOfPropertyTable;
    /* for copy management */
  public:
    ChangeCopyKind, GetInvalidatedSource, Invalidate, IsDirty,
    IsDistributable, SetDistributability, WhichKindOfCopy;

  /* instance variables */
  protected:
    DefaultLowerVersion, LowerVersions, VisibleLowerVersions;

/* interface from this class */
  constructor: New;

/* no instance variable */

/* method implementations */
    void New (global ClassID cid, Class class_object, int copy_kind) {
	VersionString vs=>New ();

	SuperNew (cid, class_object, copy_kind);
	SetVersionString (vs);
    }

    VersionString ChangeLowerPartOfVersionString (unsigned int n) {
	VersionString vs=>New ();

	return vs->SetPublicPart (n);
    }

    global VersionID GetImplementationPart () {
	if (DefaultLowerVersion != 0) {
	    return
	      GetClassLink ()
		->SearchClass (DefaultLowerVersion)
		  ->GetImplementationPart (DefaultLowerVersion);
	} else {
	    raise ClassExceptions::NoLowerVersion;
	}
    }

    global VersionID GetProtectedPart () {
	if (DefaultLowerVersion != 0) {
	    return
	      GetClassLink ()
		->SearchClass (DefaultLowerVersion)
		  ->GetProtectedPart (DefaultLowerVersion);
	} else {
	    raise ClassExceptions::NoLowerVersion;
	}
    }

    global VersionID GetPublicPart () {
	if (DefaultLowerVersion != 0) {
	    return DefaultLowerVersion;
	} else {
	    raise ClassExceptions::NoLowerVersion;
	}
    }

    global VersionID GetRootPart () {return narrow (VersionID, GetID ());}

    int IsConfiguredClass () {return 0;}
    int IsImplementationPart () {return 0;}
    int IsProtectedPart () {return 0;}
    int IsPublicPart () {return 0;}
    int IsRootPart () {return 1;}

    LowerPart NewLowerVersion (global VersionID vid, unsigned int kind) {
	PublicPart pubp;

	pubp=>New (vid, GetClassLink (), narrow (VersionID, GetID ()),
		   kind, ClassCopyKind::Original);
	return pubp;
    }

    char UsedClassTable ()[] {
	raise ClassExceptions::UnknownProperty ("root.t");
    }

    global VersionID VersionIDFromVersionString (VersionString vs) {
	unsigned int n = vs->GetPublicPart ();

	if (n == 0) {
	    return narrow (VersionID, GetID ());
	} else if (1 <= n && n <= VisibleLowerVersions->Size ()) {
	    global VersionID vid;

	    vid = VisibleLowerVersions->At (n - 1);
	    return
	      GetClassLink ()
		->SearchClass (vid)->VersionIDFromVersionString (vid, vs);
	}
    }

    unsigned int WhichPart () {return ClassPartName::aRootPart;}
}
