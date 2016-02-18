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
/*
  Copyright (c) 1994 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/
// we don't use record

//#define NORECORDACOPS

// we flush objects
//#define NOFLUSH

// we don't test flush
//#define FLUSHTESTATSTARTING

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


// we have a bug in class StreamBuffer


// we have no support for getting executor ID


// we use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// we have no str[fp]time


// boot classes are modifiable


// we don't expire configuration cache
//#define EXPIRECONFIGURATIONCACHE
/*
 * cpubv.oz
 *
 * a public version of a class
 */

class PublicPart :
  UpperPart (rename New UpperNew;
	     alias Eliminate SuperEliminate;
	     alias Purge SuperPurge;),
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
    ChangeCopyKind, GetInvalidatedSource, Invalidate, IsDirty,
    IsDistributable, SetDistributability, WhichKindOfCopy;

  protected:
    ChangeLowerPartOfVersionString, DoesFileExist,
    SetInitialLengthOfPropertyTable;

  /* instance variables */
  protected: DefaultLowerVersion, LowerVersions, VisibleLowerVersions;

/* interface from LowerPart */
  /* methods */
  public: GetUpperPart;
  protected: LowerNew;

  /* instance variables */
  protected: UpperPart;

/* interface from this class */
  constructor: New;
  public:
    AddAsNewConfiguration, ConfiguredClassIDs, GetDefaultConfiguredClassID,
    RemoveConfiguredClass, SetDefaultConfiguredClassID, WhichKind;
  protected: SetInitialLengthOfConfiguredClassIDList;

/* instance variables */
  protected:
    InitialLengthOfConfiguredClassIDList, ConfiguredClassIDList,
    DefaultConfiguredClassID, Kind;

    unsigned int InitialLengthOfConfiguredClassIDList; /* = 8; */
    SimpleArray <global ConfiguredClassID> ConfiguredClassIDList;
    global ConfiguredClassID DefaultConfiguredClassID;
    unsigned int Kind;

/* method implementations */
    void New (global ClassID cid, Class class_object,
	      global VersionID upper_version,
	      unsigned int kind, int copy_kind) {
	UpperNew (cid, class_object, copy_kind);
	LowerNew (cid, class_object, upper_version, copy_kind);
	SetInitialLengthOfConfiguredClassIDList ();
	ConfiguredClassIDList
	  =>NewWithSize (InitialLengthOfConfiguredClassIDList);
	Kind = kind;
    }

    void AddAsNewConfiguration (global ConfiguredClassID ccid) : locked {
	if (ConfiguredClassIDList->Includes (ccid)) {
	    ConfiguredClassIDList->Remove (ccid);
	}
	ConfiguredClassIDList->Add (ccid);
    }

    VersionString ChangeLowerPartOfVersionString (unsigned int n) {
	VersionString vs = GetVersionString ()->Duplicate ();

	return vs->SetProtectedPart (n);
    }

    global ConfiguredClassID ConfiguredClassIDs ()[] : locked {
	return ConfiguredClassIDList->Content ();
    }

    void Eliminate () {
	unsigned int i, len = ConfiguredClassIDList->Size ();
	Class c = GetClassLink ();

	SuperEliminate ();
	for (i = 0; i < len; i ++) {
	    global ConfiguredClassID ccid = ConfiguredClassIDList->At (i);

	    if (c->LookupClass (ccid)) {
		c->RemoveClass (ccid);
	    }
	}
    }

    global ConfiguredClassID GetDefaultConfiguredClassID () {
	return DefaultConfiguredClassID;
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
	    return DefaultLowerVersion;
	} else {
	    raise ClassExceptions::NoLowerVersion;
	}
    }

    global VersionID GetPublicPart () {return narrow (VersionID, GetID ());}

    global VersionID GetRootPart () {return UpperPart;}

    int IsConfiguredClass () {return 0;}
    int IsImplementationPart () {return 0;}
    int IsProtectedPart () {return 0;}
    int IsPublicPart () {return 1;}
    int IsRootPart () {return 0;}

    LowerPart NewLowerVersion (global VersionID vid, unsigned int kind) {
	ProtectedPart protp;

	protp=>New (vid, GetClassLink (),
		    narrow (VersionID, GetID ()), ClassCopyKind::Original);
	return protp;
    }

    void Purge () {
	unsigned int i, len = ConfiguredClassIDList->Size (), len2;
	Class c = GetClassLink ();
	ProtectedPart prots [];

	SuperPurge ();
	len2 = LowerVersions->Size ();
	length prots = len2;
	for (i = 0; i < len2; i ++) {
	    global VersionID lower = LowerVersions->At (i);

	    if (c->LookupClass (lower)) {
		prots [i] = narrow (ProtectedPart,
				    c->LookupAsClassPart (lower));
	    }
	}

	for (i = 0; i < len; i ++) {
	    global ConfiguredClassID ccid = ConfiguredClassIDList->At (i);

	    if (c->LookupClass (ccid) != 0) {
		global VersionID impl_ids [] =c->GetImplementationParts (ccid);
		global VersionID vid = impl_ids [length impl_ids - 1];
		unsigned int j;

		for (j = 0; j < len2; j ++) {
		    if (prots [j] != 0 && prots [j]->IsLowerVersion (vid)) {
			break;
		    }
		}
		if (j == len2) {
		    c->RemoveConfiguredClass (ccid);
		    -- i;
		    -- len;
		}
	    }
	}
    }

    void RemoveConfiguredClass (global ConfiguredClassID ccid) {
	if (ConfiguredClassIDList->Includes (ccid)) {
	    ConfiguredClassIDList->Remove (ccid);
	} else {
	    raise ClassExceptions::UnknownClass (ccid);
	}
    }

    void SetDefaultConfiguredClassID (global ConfiguredClassID ccid) {
	if (ConfiguredClassIDList->Includes (ccid)) {
	    DefaultConfiguredClassID = ccid;
	} else {
	    raise ClassExceptions::UnknownClass (ccid);
	}
    }

    void SetInitialLengthOfConfiguredClassIDList () {
	InitialLengthOfConfiguredClassIDList = 8;
    }

    char UsedClassTable ()[] {return UsedClassTableImpl ("public.t");}

    global VersionID VersionIDFromVersionString (VersionString vs) {
	unsigned int n;

	if ((n = vs->GetPublicPart ()) == 0) {
	    return UpperPart;
	} else {
	    VersionString vs_self = GetVersionString ();

	    if (vs_self != 0) {
		if (n == vs_self->GetPublicPart ()) {
		    if ((n = vs->GetProtectedPart ()) == 0) {
			return narrow (VersionID, GetID ());
		    } else if (1 <= n && n <= VisibleLowerVersions->Size ()){
			global VersionID vid;

			vid = VisibleLowerVersions->At (n - 1);
			return
			  GetClassLink ()
			    ->SearchClass (vid)
			      ->VersionIDFromVersionString (vid, vs);
		    } else {
			raise ClassExceptions::InvalidVersionOrder;
		    }
		}
	    }
	    return
	      GetClassLink ()
		->SearchClass (UpperPart)
		  ->VersionIDFromVersionString (UpperPart, vs);
	}
    }

    unsigned int WhichKind () {return Kind;}

    unsigned int WhichPart () {return ClassPartName::aPublicPart;}

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
