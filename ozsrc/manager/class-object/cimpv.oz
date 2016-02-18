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
 * cimp.oz
 *
 * An implementation part of a class
 */

class ImplementationPart : LowerPart (rename New SuperNew;) {
/* interface from ClassVersion */
  /* method interface */
  public:
    AddProperty, CheckVisible, GetClassFileDirectory, GetID,
    GetImplementationPart, GetParents, GetProperties, GetProtectedPart,
    GetPublicPart, GetRootPart, GetVersionString, IsAvailableOn,
    IsConfiguredClass, IsImplementationPart, IsProtectedPart, IsPublicPart,
    IsRootPart, LookupProperty, RemoveProperty, SetParents, UsedClassTable,
    VersionIDFromVersionString, WhichPart;
  protected: DoesFileExist, SetInitialLengthOfPropertyTable, SuperNew;
    /* for copy management */
  public:
    ChangeCopyKind, GetInvalidatedSource, Invalidate, IsDirty,
    IsDistributable, SetDistributability, WhichKindOfCopy;

/* interface from LowerPart */
  /* method interface */
  public: GetUpperPart;

  /* instance variables */
  protected: UpperPart;

/* interface from this class */
  constructor: New;
  public:
    AddArchitecture, Architectures, ClearArchitectures,
    GetPropertiesOfArchitecture;

/* instance variables */
    unsigned int InitialLengthOfArchitectureList; /* = 4; */
    ArchitectureID ArchitectureList [];
    unsigned int NumberOfArchitectures;

/* method implementations */
    void New (global ClassID cid, Class class_object,
	      global VersionID upper_part, int copy_kind) {
	SuperNew (cid, class_object, upper_part, copy_kind);
	length ArchitectureList = SetInitialLengthOfArchitectureList ();
	NumberOfArchitectures = 0;
    }

    void AddArchitecture (ArchitectureID aid) : locked {
	if (length ArchitectureList == NumberOfArchitectures) {
	    ExpandArchitectureList ();
	}
	ArchitectureList [NumberOfArchitectures ++] = aid;
    }

    ArchitectureID Architectures ()[] : locked {
	ArchitectureID tmp [] = ArchitectureList;

	length tmp = NumberOfArchitectures;
	return tmp;
    }

    void ClearArchitectures () : locked {NumberOfArchitectures = 0;}

    void ExpandArchitectureList () {length ArchitectureList *= 2;}

    String GetPropertiesOfArchitecture (ArchitectureID arch)[] {
	/* under implementation */
	return GetProperties ();
    }

    int IsAvailableOn (ArchitectureID aid) : locked {
	unsigned int i;

	for (i = 0; i < NumberOfArchitectures; i ++) {
	    if (ArchitectureList [i]->IsEqual (aid)) {
		return 1;
	    }
	}
	return 0;
    }

    global VersionID GetImplementationPart () {
	return narrow (VersionID, GetID ());
    }

    global VersionID GetProtectedPart () {return UpperPart;}

    global VersionID GetPublicPart () {
	return
	  GetClassLink ()
	    ->SearchClass (UpperPart)->GetPublicPart (UpperPart);
    }

    global VersionID GetRootPart () {
	return
	  GetClassLink ()->SearchClass (UpperPart)->GetRootPart (UpperPart);
    }

    int IsConfiguredClass () {return 0;}
    int IsImplementationPart () {return 1;}
    int IsProtectedPart () {return 0;}
    int IsPublicPart () {return 0;}
    int IsRootPart () {return 0;}

    unsigned int SetInitialLengthOfArchitectureList () {
	return InitialLengthOfArchitectureList = 4;
    }

    char UsedClassTable ()[] {return UsedClassTableImpl ("private.t");}

    global VersionID VersionIDFromVersionString (VersionString vs) {
	VersionString vs_self = GetVersionString ();
	unsigned int n;

	if (vs_self != 0) {
	    if (vs->GetPublicPart () == vs_self->GetPublicPart ()) {
		if (vs->GetProtectedPart () == vs_self->GetProtectedPart ()){
		    if ((n = vs->GetImplementationPart ()) == 0) {
			return UpperPart;
		    } else if (n == vs_self->GetImplementationPart ()) {
			return narrow (VersionID, GetID ());
		    }
		}
	    }
	}
	return
	  GetClassLink ()
	    ->SearchClass (UpperPart)
	      ->VersionIDFromVersionString (UpperPart, vs);
    }

    unsigned int WhichPart () {return ClassPartName::anImplementationPart;}
}
