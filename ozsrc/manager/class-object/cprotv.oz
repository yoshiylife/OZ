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
 * cprotv.oz
 *
 * A protected version of a class
 */

class ProtectedPart :
  UpperPart (rename New UpperNew;),
  LowerPart (rename New LowerNew;
	     rename AddProperty LowerAddProperty;
	     rename GetClassFileDirectory LowerGetClassFileDirectory;
	     rename GetClassLink LowerGetClassLink;
	     rename GetID LowerGetID;
	     rename GetImplementationPart LowerGetImplementationPart;
	     rename GetParents LowerGetParents;
	     rename GetProperties LowerGetProperties;
	     rename GetProtectedPart LowerGetProtectedPart;
	     rename GetPublicPart LowerGetPublicPart;
	     rename GetRootPart LowerGetRootPart;
	     rename GetVersionString LowerGetVersionString;
	     rename IsAvailableOn LowerIsAvailableOn;
	     rename IsConfiguredClass LowerIsConfiguredClass;
	     rename IsImplementationPart LowerIsImplementationPart;
	     rename IsProtectedPart LowerIsProtectedPart;
	     rename IsPublicPart LowerIsPublicPart;
	     rename IsRootPart LowerIsRootPart;
	     rename LookupProperty LowerLookupProperty;
	     rename RemoveProperty LowerRemoveProperty;
	     rename SetInitialLengthOfPropertyTable
		      LowerSetInitialLengthOfPropertyTable;
	     rename SetClassLink LowerSetClassLink;
	     rename SetParents LowerSetParents;
	     rename SetVersionString LowerSetVersionString;
	     rename UsedClassTable LowerUsedClassTable;
	     rename UsedClassTableImpl LowerUsedClassTableImpl;
	     rename VersionIDFromVersionString
		      LowerVersionIDFromVersionString;
	     rename WhichPart LowerWhichPart;
	     rename ChangeCopyKind LowerChangeCopyKind;
	     rename GetInvalidatedSource LowerGetInvalidatedSource;
	     rename Invalidate LowerInvalidate;
	     rename IsDirty LowerIsDirty;
	     rename IsDistributable LowerIsDistributable;
	     rename SetDistributability LowerSetDistributability;
	     rename WhichKindOfCopy LowerWhichKindOfCopy;)
{
/* interface from UpperPart */
  /* method */
  public:
    AddAsNewLowerVersion, AddProperty, CheckVisible, CutClassLink,
    GetClassFileDirectory, GetDefaultLowerVersionID, GetID,
    GetImplementationPart, GetLowerVersions, GetNewVersionString,
    GetParents, GetProperties, GetProtectedPart, GetPublicPart,
    GetRootPart, GetVersionString, GetVisibleLowerVersions, IsAvailableOn,
    IsConfiguredClass, IsImplementationPart, IsLowerVersion,
    IsProtectedPart, IsPublicPart, IsRootPart, IsVisibleLowerVersion,
    LatestLowerVersion, LatestVisibleLowerVersion, LookupProperty,
    MakeALowerVersionVisible, NewLowerVersion, RemoveLowerVersion,
    RemoveProperty, SetDefaultLowerVersionID, SetParents, UsedClassTable,
    VersionIDFromVersionString, WhichPart;
    /* for copy management */
  public:
    ChangeCopyKind, GetInvalidatedSource, Invalidate, IsDirty, IsDistributable,
    SetDistributability, WhichKindOfCopy;

  protected:
    ChangeLowerPartOfVersionString, DoesFileExist,
    SetInitialLengthOfPropertyTable;

  /* instance variables */
  protected: DefaultLowerVersion, LowerVersions, VisibleLowerVersions;

/* interface from LowerPart */
  /* methods */
  public: GetUpperPart;
  protected: LowerNew;

/* interface from this class */
  constructor: New;

/* no instance variable */

/* method implementations */
    void New (global ClassID cid, Class class_object,
	      global VersionID upper_part, int copy_kind) {
	UpperNew (cid, class_object, copy_kind),
	LowerNew (cid, class_object, upper_part, copy_kind);
    }

    global VersionID GetImplementationPart () {
	if (DefaultLowerVersion != 0) {
	    return DefaultLowerVersion;
	} else {
	    raise ClassExceptions::NoLowerVersion;
	}
    }

    global VersionID GetProtectedPart () {return narrow (VersionID, GetID ());}

    global VersionID GetPublicPart () {return UpperPart;}

    global VersionID GetRootPart () {
	return
	  GetClassLink ()
	    ->SearchClass (UpperPart)->GetRootPart (UpperPart);
    }

    int IsConfiguredClass () {return 0;}
    int IsImplementationPart () {return 0;}
    int IsProtectedPart () {return 1;}
    int IsPublicPart () {return 0;}
    int IsRootPart () {return 0;}

    LowerPart NewLowerVersion (global VersionID vid, unsigned int kind) {
	ImplementationPart implp;

	implp=>New (vid, GetClassLink (), narrow (VersionID, GetID ()),
		    ClassCopyKind::Original);
	/* quick hack: should be considered in multi architecture support */
	implp->AddArchitecture (Where ()->MyArchitecture ());
	return implp;
    }

    VersionString ChangeLowerPartOfVersionString (unsigned int n) {
	VersionString vs = GetVersionString ()->Duplicate ();

	return vs->SetImplementationPart (n);
    }

    char UsedClassTable ()[] {return UsedClassTableImpl ("protected.t");}

    global VersionID VersionIDFromVersionString (VersionString vs) {
	VersionString vs_self = GetVersionString ();
	unsigned int n;

	if (vs_self != 0) {
	    if (vs->GetPublicPart () == vs_self->GetPublicPart ()) {
		if ((n = vs->GetProtectedPart ()) == 0) {
		    return UpperPart;
		} else if (n == vs_self->GetProtectedPart ()) {
		    if ((n = vs->GetImplementationPart ()) == 0) {
			return narrow (VersionID, GetID ());
		    } else if (1 <= n && n <= VisibleLowerVersions->Size ()) {
			return VisibleLowerVersions->At (n - 1);
		    } else {
			raise ClassExceptions::InvalidVersionOrder;
		    }
		}
	    }
	}
	return
	  GetClassLink ()
	    ->SearchClass (UpperPart)
	      ->VersionIDFromVersionString (UpperPart, vs);
    }

    unsigned int WhichPart () {return ClassPartName::aProtectedPart;}

/* accessor renames */
    void LowerAddProperty (char property []) {AddProperty (property);}
    String LowerGetClassFileDirectory () {return GetClassFileDirectory ();}
    Class LowerGetClassLink () {return GetClassLink ();}
    global ClassID LowerGetID () {return GetID ();}
    global VersionID LowerGetImplementationPart () {
	return GetImplementationPart ();
    }
    global VersionID LowerGetParents ()[] {return GetParents ();}
    String LowerGetProperties ()[] {return GetProperties ();}
    global VersionID LowerGetProtectedPart () {return GetProtectedPart ();}
    global VersionID LowerGetPublicPart () {return GetPublicPart ();}
    global VersionID LowerGetRootPart () {return GetRootPart ();}
    VersionString LowerGetVersionString () {return GetVersionString ();}
    int LowerIsAvailableOn (ArchitectureID aid) {return IsAvailableOn (aid);}
    int LowerIsConfiguredClass () {return IsConfiguredClass ();}
    int LowerIsImplementationPart () {return IsImplementationPart ();}
    int LowerIsProtectedPart () {return IsProtectedPart ();}
    int LowerIsPublicPart () {return IsPublicPart ();}
    int LowerIsRootPart () {return IsRootPart ();}
    String LowerLookupProperty (char property []) {
	return LookupProperty (property);
    }
    void LowerRemoveProperty (char property []) {RemoveProperty (property);}
    void LowerSetInitialLengthOfPropertyTable () {
	SetInitialLengthOfPropertyTable ();
    }
    void LowerSetClassLink (Class c) {SetClassLink (c);}
    void LowerSetParents (global VersionID parents []) {SetParents (parents);}
    void LowerSetVersionString (VersionString vs) {SetVersionString (vs);}
    char LowerUsedClassTable ()[] {return UsedClassTable ();}
    char LowerUsedClassTableImpl (char file_name [])[] {
	return UsedClassTableImpl (file_name);
    }
    global VersionID LowerVersionIDFromVersionString (VersionString vs) {
	return VersionIDFromVersionString (vs);
    }
    unsigned int LowerWhichPart () {return WhichPart ();}
    void LowerChangeCopyKind (int copy_kind) {ChangeCopyKind (copy_kind);}
    global ClassPackageID LowerGetInvalidatedSource () {
	return GetInvalidatedSource ();
    }
    void LowerInvalidate (int mode, global ClassPackageID cpid) {
	Invalidate (mode, cpid);
    }
    int LowerIsDirty () {return IsDirty ();}
    int LowerIsDistributable () {return IsDistributable ();}
    void LowerSetDistributability (int d) {SetDistributability (d);}
    int LowerWhichKindOfCopy () {return WhichKindOfCopy ();}
}
