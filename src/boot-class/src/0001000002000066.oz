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
 * class.oz
 *
 * Class object
 */

class Class : ResolvableObject (rename New SuperNew;) {
/* application programming interface */
  constructor: New;

  public: AddName; /* from super class */
  public: /* global */
    AddArchitecture, AddProperty, AddToClassTable, Architectures,
    ClearProperties, ConfiguredClassIDs, CreateNewConfiguredClass,
    CreateNewGenericClass, CreateNewPart, CreateNewVersion,
    DefaultVersionString, DelegateAll, DelegateClass, Distribute, Do, Dump,
    GeneralizedVersionOf, GetCode, GetClassDirectoryPath,
    GetClassFileDirectory, GetClassInformations, GetClassPart,
    GetDefaultConfiguredClassID, GetDefaultVersionID, GetImplementationPart,
    GetImplementationParts, GetLayout, GetLowerVersions, GetParents,
    GetProperties, GetPropertyPath, GetProtectedPart, GetPublicPart,
    GetRootPart, GetRuntimeClassInformation, GetUpperPart, GetVersionString,
    GetVisibleLowerVersions, InheritanceHierarchy, Install, IsAvailableOn,
    KeepAlive, ListClassID, LoadClassPart, LookupClass, LookupProperty,
    MakeItVisible, Purge, RegisterClassInformations, RemoveClass,
    RemoveClassVersion, RemoveProperty, Restore, SearchClass,
    SetDefaultConfiguredClassID, SetDefaultLowerVersionID,
    SetImplementationParts, SetItAsDefaultConfiguredClass,
    SetItAsDefaultLowerVersion, SetParents, UsedClassTable,
    VersionIDFromConfiguredClassID, VersionIDFromVersionString, WhichKind,
    WhichPart;
  public: /* local */
    LookupAsClassPart, RemoveClassImpl, RemoveConfiguredClass,
    RemoveConfiguredClassImpl, RemoveLowerVersion, RemoveLowerVersionImpl,
    SetVersionString;

    /* for copy management */
  public:
    AddMirrorMember, AddToClassPackage, AddToOriginalPackages, AddToOriginals,
    AddToSnapshots, ChangeCopyKind, ChangeMirrorMode, ChangeMirrorSetting,
    DelegateClassAsOriginal, DeleteFromClassPackage, DeleteMirrorMember,
    DestroyClassPackage, GetBelongingMirrors,
    GetBelongingOriginalClassPackages, GetMirroredClassPackage,
    GetOriginalClassPackage, IsBootClass, IsMirror, IsMirroredClassPackage,
    IsOriginal, IsOriginalClassPackage, IsPrivate, IsSnapshot, ListBootClasses,
    ListMirrors, ListOriginalClassPackages, ListOriginals, ListPrivates,
    ListSnapshots, Privatize, RegisterClassPackage, RegisterMirror, SetMirror,
    SetMirrorImplementation, UnregisterMirror, UnsetMirror,
    UnsetMirrorImplementation, UpdateMirror, WhichKindOfCopy;

    /*
     * nature of copies:
     *
     *          modfiable expired distributable packable (== ~expired)
     * Original     o        x          o          o
     * Boot        *1        x          o          o
     * Private      o        x          x          o
     * Snapshot     x        o          o          x
     * Mirror       x        x         *2          o
     *
     * (*1) not modifiable.  But currently modifiable.
     * (*2) distributable iff mirroring a distributable copy.
     */


/* other interface */
  public: Flush, Stop;

  public: AddAsNewConfiguration, AddAsNewLowerVersion, CopyClassPart;

    /* obsolete */
  public: Read;

  protected:
    Initialize, RegisterToNameDirectory, SetInitialLengthOfNames,
    UnRegisterFromNameDirectory;

/* instance variables */
  protected:
    ClassDirectoryPath, ClassListFile, DumpPath, Names, ClassTable, Logger;

    /* class list file is the list of boot classes */
    char ClassListFile [];

    char ClassDirectoryPath [];
    SimpleTable <global ClassID, ClassPart> ClassTable;
    ClassLogger Logger;
    String DumpPath;

    /* for copy management */

    SimpleTable <global ClassID, Date> Originals;
    SimpleTable <global ClassPackageID, OriginalClassPackage> OriginalPackages;
    SimpleTable <global ClassPackageID, MirroredClassPackage> Mirrors;
    SimpleTable <global ClassID, Date> Snapshots;
    OIDSet <global ClassID> BootClasses;
    OIDSet <global ClassID> Privates;

    /*
     * to do list
     *
     * ClassObjectServiceInterface change
     *   show private setting
     *   setting/unsetting private
     *
     * Delegating an original class package to another class object
     * Supply Expiration parameter to the method LoadClassPart
     * Polling to copy/invalidate original package to dead mirrors
     * Polling the original to update mirrors in Polling mode
     * Protect remote invocation and
     *   polling to revisit the dead list for originals
     *   switch to Polling mode for mirrors
     * Set interval timer for snapshot expiration
     *
     * clarify lock scheme for class copy management facilities
     *
     * Supply only default configuration if public part is needed at runtime
     *
     * Eliminate all subclasses of ClassVersion (next F.Y.)
     */

/* method implementations */
    void New (char directory_path []) : global {
	String cd=>NewFromArrayOfChar (directory_path), s;
	FileOperators fops;

	SuperNew ();
	ClassTable=>New ();
	ClassDirectoryPath = directory_path;
	if (! fops.IsExists (cd)) {
	    fops.MakeDirectory (cd);
	}
	ClassListFile = 0;
	Originals=>New ();
	OriginalPackages=>NewWithSize (16);
	Mirrors=>NewWithSize (16);
	Snapshots=>NewWithSize (32);
	BootClasses=>New ();
	Privates=>NewWithSize (8);
	Logger=>New (cd->ConcatenateWithArrayOfChar ("/logfile"), 100);
	DumpPath=>NewFromArrayOfChar (directory_path);
	DumpPath = DumpPath->ConcatenateWithArrayOfChar ("/dump");
    }

    void Flush () : global {
	Where ()->FlushObject (oid);
	Logger->Close ();
	Logger->Open ();
    }

    void Go () : global {detach fork Initialize ();}

    void Initialize () {


	inline "C" {
	    OzDebugf ("Class::Initialize: started.\n");
	}


	InitializeClassPackages ();
	if (ClassListFile != 0 && ClassListFile [0] != '\0') {
	    InstallImpl (ClassListFile, 0);
	    Flush ();
	} else {
	    if (Logger->Start (Where ()->WasSafelyShutdown (oid), self))
	      Flush ();
	}
	Where ()->RegisterClass (oid);
	RegisterToNameDirectory ();


	inline "C" {
	    OzDebugf ("Class::Initialize: complete.\n");
	}


    }

    void Stop () : global, locked {
	FileOperators fops;

	try {
	    Where ()->UnregisterClass (oid);
	    UnRegisterFromNameDirectory ();
	} except {
	    default {}
	}
	Logger->Close ();
    }

    void AddArchitecture (global ClassID cid, ArchitectureID aid) : global {
	CheckModifiable (cid);
	LookupAsImplementationPart (cid)->AddArchitecture (aid);
	Logger->LogAddArchitecture (cid, aid);
	PropagateToMirrors (cid, MirrorModificationMode::OnlyObject);
    }

    void AddAsNewConfiguration (global VersionID vid,
				global ConfiguredClassID ccid) {
	LookupAsPublicPart (vid)->AddAsNewConfiguration (ccid);
	Logger->LogAddAsNewConfiguration (vid, ccid);
	PropagateToMirrors (vid, MirrorModificationMode::OnlyObject);
    }

    void AddAsNewLowerVersion (global VersionID vid, global VersionID new) {
	LookupAsUpperPart (vid)->AddAsNewLowerVersion (new);
	Logger->LogAddAsNewLowerVersion (vid, new);
	PropagateToMirrors (vid, MirrorModificationMode::OnlyObject);
    }

    void AddProperty (global ClassID cid, char name []) : global {

    }

    int AddToClassTable (ClassPart cp) : global {
	return AddToClassTableImpl (cp, 1);
    }

    int AddToClassTableImpl (ClassPart cp, int log_flag) {
	global ClassID cid;
	int overriding;

	cid = cp->GetID ();
	cp->SetClassLink (self);
	overriding = (ClassTable->Add (cid, cp) != 0);
	if (overriding) {
	    inline "C" {
		OzDebugf ("Class::AddToClassTableImpl: overriding class %O\n",
			  cid);
	    }
	}
	if (log_flag) {
	    Logger->LogAddToClassTable (cp);
	}
	return overriding;
    }

    ArchitectureID Architectures (global ClassID cid)[] : global {
	return LookupAsImplementationPart (cid)->Architectures ();
    }

    void CheckModifiable (global ClassID cid) {
	if (! LookupAsClassPart (cid)->IsModifiable ()) {
	    raise ClassExceptions::NotModifiableCopy (cid);
	}
    }

    ClassPart ClassPartInClassTable (global ClassID cid) {
	try {
	    MirroredClassPackage mcp;
	    ClassPart cp = ClassTable->AtKey (cid);
	    global ClassPackageID cpid;

	    if (cp->WhichKindOfCopy () == ClassCopyKind::Mirror) {
		switch (cp->IsDirty ()) {
		  case MirrorModificationMode::DoNothing:
		    break;
		  case MirrorModificationMode::OnlyObject:
		    cpid = cp->GetInvalidatedSource ();
		    mcp = Mirrors->AtKey (cpid);
		    RefreshObjectAsaMirror (cid, mcp->GetOriginal ());
		    break;
		  case MirrorModificationMode::WithClassFiles:
		    cpid = cp->GetInvalidatedSource ();
		    mcp = Mirrors->AtKey (cpid);
		    RemoveClassImpl (cid);
		    LoadaClassPartAsaMirror (cid, mcp->GetOriginal ());
		    break;
		}
	    }
	    return cp;
	} except {
	    CollectionExceptions<global ClassID>::UnknownKey (cid) {
		raise ClassExceptions::UnknownClass (cid);
	    }
	}
    }

    void ClearProperties (global ClassID cid) : global {

    }

    ClassPart CopyClassPart (ClassPart cp) : global {return cp;}

    global ConfiguredClassID ConfiguredClassIDs (global ClassID cid)[]
      : global {
	  return LookupAsPublicPart (cid)->ConfiguredClassIDs ();
      }

    global VersionID CreateNewGenericClass () : global {
	/* under implementation */
    }

    global ConfiguredClassID CreateNewConfiguredClass (global VersionID vid)
      : global {
	  global ConfiguredClassID ccid;
	  ConfiguredClass cc;
	  FileOperators fops;

	  CheckModifiable (vid);
	  ccid = narrow (ConfiguredClassID, Where ()->NewOID ());
	  cc=>New (self, ccid, vid, ClassCopyKind::Original);
	  fops.MakeDirectory (cc->GetClassFileDirectory ());
	  AddToClassTable (cc);
	  AddToOriginals (ccid);
	  AddAsNewConfiguration (vid, ccid);
	  return ccid;
      }

    global VersionID CreateNewLowerPart (global VersionID vid,
					 unsigned int kind) {
	global VersionID new_vid;
	ClassVersion cv;
	FileOperators fops;

	if (vid != 0) {
	    CheckModifiable (vid);
	}
	new_vid = narrow (VersionID, Where ()->NewOID ());
	if (vid == 0) {
	    RootPart rp=>New (new_vid, self, ClassCopyKind::Original);

	    cv = rp;
	} else {
	    Object o;

	    o = LookupAsUpperPart (vid)->NewLowerVersion (new_vid, kind);
	    cv = narrow (ClassVersion, o);
	}
	fops.MakeDirectory (cv->GetClassFileDirectory ());
	AddToClassTable (cv);
	AddToOriginals (new_vid);
	if (vid != 0) {
	    AddAsNewLowerVersion (vid, new_vid);
	}
	return new_vid;
    }

    global VersionID CreateNewPart (global VersionID vid) : global {
	return CreateNewLowerPart (vid, KindOfClassPart::anOrdinaryClass);
    }

    global VersionID CreateNewRecord (global VersionID vid) : global {
	return CreateNewLowerPart (vid, KindOfClassPart::aRecord);
    }

    global VersionID CreateNewShared (global VersionID vid) : global {
	return CreateNewLowerPart (vid, KindOfClassPart::aShared);
    }

    global VersionID CreateNewStaticClass (global VersionID vid) : global {
	return CreateNewLowerPart (vid, KindOfClassPart::aStaticClass);
    }

    char CreateNewVersion (global VersionID vid)[] : global {
	CheckModifiable (vid);
	{
	    LowerPart lp = LookupAsLowerPart (vid);
	    ClassVersion cv = LookupAsClassVersion (vid);
	    global VersionID upper = lp->GetUpperPart ();
	    VersionString vs = SearchClass (upper)->MakeItVisible (upper, vid);

	    cv->SetVersionString (vs);
	    Logger->LogSetVersionString (vid, vs);
	    PropagateToMirrors (vid, MirrorModificationMode::OnlyObject);
	    return vs->Content ();
	}
    }

    void DelegateAll (global Class c) : global {
	global ClassID cids [] = ClassTable->SetOfKeys ();
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    try {
		DelegateClass (cids [i], c);
	    } except {
	      ClassExceptions::UnknownClass (cid) {
		  /* never mind if someone steels time and remove a class while
		     delegating all classes */
	      }
	    }
	}
    }

    void DelegateClassAsOriginal (global ClassID cid, global Class c): global {
	/* under construction */
    }

    void DelegateClass (global ClassID cid, global Class c) : global {
	ArchitectureID aid=>Any ();
	ClassPart cp = GetClassPart (cid);
	char dir [] = GetClassDirectoryPath ();
	String dir_str;
	String cid_str;
	String tar_file_str;
	FileOperators fops;

	dir_str=>NewFromArrayOfChar (dir);
	cid_str=>OIDtoHexa (cid);
	dir_str = dir_str->ConcatenateWithArrayOfChar ("/")
	                     ->Concatenate (cid_str);
	tar_file_str = dir_str->ConcatenateWithArrayOfChar (".tar");
	dir_str = dir_str->ConcatenateWithArrayOfChar ("/..");
	fops.Tar (dir_str, tar_file_str, cid_str);
	c->LoadClassPart (cid, aid, oid, GetClassDirectoryPath (), cp);
    }

    /*
     * Decision of whether to distribute or not should be made according to the
     * copy type and architecture.  Return 1 if replied, otherwise 0.
     */
    int Distribute (global ClassID cid, global ObjectManager requester,
		    ArchitectureID arch)
      : global {
	  FileOperators fops;



	  inline "C" {
	      _oz_debug_flag = 1;
	  }
	  debug (0, "Class::Distribute: ClassID = %O\n", cid);


	  if ((LookupClass (cid) != 0) && IsDistributable (cid)) {
	      ClassPart cp = GetClassPart (cid);

	      if (arch->Get () == -1 || ! cp->IsImplementationPart () ||
		  narrow (ImplementationPart, cp)->IsAvailableOn (arch)) {
		  char dir [] = GetClassDirectoryPath ();

		  String dir_str;
		  String cid_str;
		  String tar_file_str;

		  dir_str=>NewFromArrayOfChar (dir);
		  cid_str=>OIDtoHexa (cid);
		  dir_str
		    = dir_str
		        ->ConcatenateWithArrayOfChar ("/")
			    ->Concatenate (cid_str);
		  tar_file_str = dir_str->ConcatenateWithArrayOfChar (".tar");
		  dir_str = dir_str->ConcatenateWithArrayOfChar ("/..");

		  fops.Tar (dir_str, tar_file_str, cid_str);
		  requester->ReplyOfClassBroadcast (cid, oid, dir, cp);
		  return 1;
	      }
	  }
	  return 0;
      }

    void Do (WorkingObjectInClass worker) : global {worker->Start (self);}

    void Dump () : global {
	Logger=>New (DumpPath, 0);
	/* under construction */
    }

    global VersionID GeneralizedVersionOf (global VersionID vid) : global {
	return GetUpperPart (vid);
    }

    char GetClassDirectoryPath ()[] : global {
	return ClassDirectoryPath;
    }

    char GetClassFileDirectory (global ClassID cid)[] : global {
	return LookupAsClassPart (cid)->GetClassFileDirectory ()->Content ();
    }

    char GetClassInformations (global ClassID cid)[] : global {
	ClassPart cp = LookupAsClassPart (cid);

	if (length (cp->GetProperties ()) != 0) {
	    return cp->GetClassFileDirectory ()->Content ();
	} else {
	    return 0;
	}
    }

    /*
     * Under implementation.
     * While cutting the class link of the ClassPart, other thread
     * should be blocked to access the ClassPart.
     */
    ClassPart GetClassPart (global ClassID cid) : global {
	ClassPart cp = LookupAsClassPart (cid), copy;

	copy = oid->CopyClassPart (cp->CutClassLink ());
	cp->SetClassLink (self);
	return copy;
    }

    global VersionID GetImplementationPart (global VersionID vid) :
      global {
	  return LookupAsClassVersion (vid)->GetImplementationPart ();
      }

    global VersionID GetImplementationParts (global ConfiguredClassID ccid)[]
      : global {
	  return LookupAsConfiguredClass (ccid)->GetImplementationParts ();
      }

    String GetProperties (global ClassID cid)[] : global {
	return LookupAsClassPart (cid)->GetProperties ();
    }

    char GetPropertyPath (global ClassID cid, char name [])[] : global {
	String s;
	ClassPart cp = LookupAsClassPart (cid);

	/*
	 * 梅プランでは、 LookupProperty せずに path だけ計算して返す。
	 */
	s = cp->GetClassFileDirectory ()
	  ->ConcatenateWithArrayOfChar ("/")
	    ->ConcatenateWithArrayOfChar (name);
	return s->Content ();

    }

    String GetPropertiesOfArchitecture (global ClassID cid,
					ArchitectureID arch)[]
      : global {
	  return
	    LookupAsImplementationPart (cid)
	      ->GetPropertiesOfArchitecture (arch);
      }

    global VersionID GetProtectedPart (global VersionID vid) : global {
	return LookupAsClassVersion (vid)->GetProtectedPart ();
    }

    global VersionID GetPublicPart (global VersionID vid) : global {
	return LookupAsClassVersion (vid)->GetPublicPart ();
    }

    global VersionID GetRootPart (global VersionID vid) : global {
	return LookupAsClassVersion (vid)->GetRootPart ();
    }

    char GetRuntimeClassInformation (global ClassID cid)[] : global {
	return GetPropertyPath (cid, "private.r");
    }

    global VersionID GetDefaultVersionID (global ClassID cid) : global {
	return LookupAsUpperPart (cid)->GetDefaultLowerVersionID ();
    }

    global VersionID GetUpperPart (global VersionID vid) : global {
	return LookupAsLowerPart (vid)->GetUpperPart ();
    }

    global VersionID GetVisibleLowerVersions (global ClassID cid)[]
      : global {
	  return LookupAsUpperPart (cid)->GetVisibleLowerVersions ();
      }

    void Install (char class_list_file []) : global {
	InstallImpl (class_list_file, 1);
    }

    void InstallImpl (char new_class_list_file [], int log_flag) {
	String s=>NewFromArrayOfChar (new_class_list_file);
	NewClassListFileReader nclfr;
	unsigned int i = 0;
	ArchitectureID aid = Where ()->MyArchitecture ();

	try {
	    nclfr=>New (s);
	    while (! nclfr->IsEndOfToken ()) {
		i++;
		InstallOneRecord (nclfr, aid, log_flag);
	    }
	    ClassListFile = 0;


	    inline "C" {
		OzDebugf ("Class::InstallImpl: "
			  "Reading class file complete.\n");
	    }


	} except {
	  FileReaderExceptions::CannotOpenFile (file) {
	      inline "C" {
		  OzDebugf ("Class::InstallImpl: "
			    "cannot open class list file \"%S\"\n", file);
	      }
	  }
	}
    }

    void InstallOneRecord (NewClassListFileReader nclfr,
			   ArchitectureID aid, int log_flag) {
	global VersionID root_vid, pub_vid, prot_vid, impl_vid;
	global ConfiguredClassID ccid;
	unsigned int kind;
	RootPart rootp;
	PublicPart pubp;
	ProtectedPart protp;
	ImplementationPart impp;
	ConfiguredClass cc;
	UpperPart tmp;

	global VersionID impl_ids [];
	String path;

	kind = nclfr->ReadInteger ();
	if (kind != KindOfClassPart::aShared
	    && kind != KindOfClassPart::aStaticClass
	    && kind != KindOfClassPart::aRecord) {
	    kind = KindOfClassPart::anOrdinaryClass;
	}
	root_vid = narrow (VersionID, nclfr->ReadObjectID ());
	inline "C" {
	    pub_vid = root_vid + 1;
	    prot_vid = root_vid + 2;
	    impl_vid = root_vid + 3;
	    ccid = root_vid - 1;
	}
	LinkDirectories (kind, root_vid);

	rootp=>New (root_vid, self, ClassCopyKind::Boot);

	rootp->AddAsNewLowerVersion (pub_vid);
	rootp->SetDefaultLowerVersionID (pub_vid);

	pubp=>New (pub_vid, self, root_vid, kind, ClassCopyKind::Boot);
	tmp = pubp;


	if (kind == KindOfClassPart::anOrdinaryClass) {
	    protp=>New (prot_vid, self, pub_vid, ClassCopyKind::Boot);
	    pubp->AddAsNewLowerVersion (prot_vid);
	    pubp->SetDefaultLowerVersionID (prot_vid);
	    tmp = protp;


	    impp=>New (impl_vid, self, prot_vid, ClassCopyKind::Boot);
	    impp->AddArchitecture (aid);
	    protp->AddAsNewLowerVersion (impl_vid);
	    protp->SetDefaultLowerVersionID (impl_vid);




	    cc=>New (self, ccid, pub_vid, ClassCopyKind::Boot);
	    pubp->AddAsNewConfiguration (ccid);
	    pubp->SetDefaultConfiguredClassID (ccid);

	    cc->ReadPrivateDotsFile ();
	    if (log_flag) {
		Logger
		  ->LogSetImplementationParts (ccid,
					       cc->GetImplementationParts ());
	    }
	}

	AddToClassTableImpl (rootp, log_flag);
	BootClasses->Add (root_vid);
	tmp = pubp;
	AddToClassTableImpl (tmp, log_flag);
	BootClasses->Add (pub_vid);
	if (kind == KindOfClassPart::anOrdinaryClass) {
	    tmp = protp;
	    AddToClassTableImpl (tmp, log_flag);
	    BootClasses->Add (prot_vid);
	    AddToClassTableImpl (impp, log_flag);
	    BootClasses->Add (impl_vid);
	    AddToClassTableImpl (cc, log_flag);
	    BootClasses->Add (ccid);
	}
    }

    void InternProperties (ClassPart cp) {

    }

    int IsAvailableOn (global ClassID cid, ArchitectureID aid) : global {
	return LookupAsClassPart (cid)->IsAvailableOn (aid);
    }

    int IsDistributable (global ClassID cid) {
	return LookupAsClassPart (cid)->IsDistributable ();
    }

    void LinkDirectories (unsigned int kind, global ClassID cid) {
	String cidstr, from, to;
	FileOperators fops;
	int i, f, t;

	from=>NewFromArrayOfChar ("../OZROOT/lib/boot-class/");
	to=>NewFromArrayOfChar (GetClassDirectoryPath ());
	to = to->ConcatenateWithArrayOfChar ("/");

	if (kind == KindOfClassPart::anOrdinaryClass) {
	    f = -1, t = 4;
	} else {
	    f = 0, t = 2;
	}
	for (i = f; i < t; i ++) {
	    global ClassID v;

	    inline "C" {
		v = cid + i;
	    }
	    cidstr=>OIDtoHexa (v);
	    try {
		fops.Symlink (from->Concatenate (cidstr),
			      to->Concatenate (cidstr));
	    } except {
		default {
		    if (! fops.IsExists (to->Concatenate (cidstr))) {
			raise;
		    }
		}
	    }
	}
    }

    ClassPart LookupAsClassPart (global ClassID cid) {
	return ClassPartInClassTable (cid);
    }

    ClassVersion LookupAsClassVersion (global ClassID cid) {
	return narrow (ClassVersion, ClassPartInClassTable (cid));
    }

    ConfiguredClass LookupAsConfiguredClass (global ClassID cid) {
	return narrow (ConfiguredClass, ClassPartInClassTable (cid));
    }

    ImplementationPart LookupAsImplementationPart (global ClassID cid) {
	return narrow (ImplementationPart, ClassPartInClassTable (cid));
    }

    LowerPart LookupAsLowerPart (global ClassID cid) {
	Object o = ClassPartInClassTable (cid);

	return narrow (LowerPart, o);
    }

    ProtectedPart LookupAsProtectedPart (global ClassID cid) {
	return narrow (ProtectedPart, ClassPartInClassTable (cid));
    }

    PublicPart LookupAsPublicPart (global ClassID cid) {
	return narrow (PublicPart, ClassPartInClassTable (cid));
    }

    RootPart LookupAsRootPart (global ClassID cid) {
	return narrow (RootPart, ClassPartInClassTable (cid));
    }

    UpperPart LookupAsUpperPart (global ClassID cid) {
	Object o = ClassPartInClassTable (cid);

	return narrow (UpperPart, o);
    }

    VersionString MakeItVisible (global VersionID upper, global VersionID vid)
      : global {
	  VersionString ret;

	  CheckModifiable (upper);
	  CheckModifiable (vid);
	  ret = LookupAsUpperPart (upper)->GetNewVersionString (vid);
	  Logger->LogMakeItVisible (upper, vid);
	  PropagateToMirrors (upper, MirrorModificationMode::OnlyObject);
	  PropagateToMirrors (vid, MirrorModificationMode::OnlyObject);
	  return ret;
      }

    VersionString DefaultVersionString (global ClassID cid) : global {
	global VersionID vid = GetDefaultVersionID (cid);

	return SearchClass (vid)->GetVersionString (vid);
    }

    char GetCode (global ClassID cid, ArchitectureID aid)[] : global {
	if (LookupAsClassPart (cid)->IsAvailableOn (aid)) {
	    return GetPropertyPath (cid, "private.o");
	} else {
	    raise ClassExceptions::NotAvailableArchitecture (aid);
	}
    }

    global ConfiguredClassID GetDefaultConfiguredClassID (global ClassID cid)
      : global {
	  return
	    LookupAsPublicPart (cid)->GetDefaultConfiguredClassID ();
      }

    char GetLayout (global ClassID cid, ArchitectureID aid)[] : global {
	if (LookupAsClassPart (cid)->IsAvailableOn (aid)) {
	    return GetPropertyPath (cid, "private.l");
	} else {
	    raise ClassExceptions::NotAvailableArchitecture (aid);
	}
    }

    global VersionID GetLowerVersions (global VersionID vid)[] : global {
	return LookupAsUpperPart (vid)->GetLowerVersions ();
    }

    global VersionID GetParents (global ClassID cid)[] : global {
	return LookupAsClassVersion (cid)->GetParents ();
    }

    VersionString GetVersionString (global ClassID cid) : global {
	return LookupAsClassVersion (cid)->GetVersionString ();
    }

    InheritanceHierarchyNode
      InheritanceHierarchy (global ConfiguredClassID ccid)[] {
	  /* under implementation */
      }

    void KeepAlive () : global {


	inline "C" {
	    OzDebugf ("Class::KeepAlive\n");
	}


    }

    global ClassID ListClassID ()[] : global {return ClassTable->SetOfKeys ();}

    void LoadClassPart (global ClassID cid, ArchitectureID arch,
			global Class from, char dir [], ClassPart cp)
      : global {
	  FileOperators fops;
	  String from_dir, to_dir, from_file, to_file, cid_path;
	  char local_dir [] = GetClassDirectoryPath ();
	  String local_dir_str;
	  int result;
	  int local_distribution = 0;
	  unsigned int i;

	  cid_path=>OIDtoHexa (cid);
	  from_dir = from_dir=>NewFromArrayOfChar (dir)
	                         ->ConcatenateWithArrayOfChar ("/")
				     ->Concatenate (cid_path);
	  to_dir = to_dir=>NewFromArrayOfChar (local_dir)
	                     ->ConcatenateWithArrayOfChar ("/")
			         ->Concatenate (cid_path);
	  fops.MakeDirectory (to_dir);
	  /* tentative version:
	   * from_file should be deleted after distribution. */
	  from_file = from_dir->ConcatenateWithArrayOfChar (".tar");
	  to_file = to_dir->ConcatenateWithArrayOfChar (".tar");
	  local_dir_str=>NewFromArrayOfChar (local_dir);
	  do {
	      result = Where ()->TransferFile (from, from_file->Content (),
					       to_file->Content ());
	      switch (result) {
		case 0:
		  fops.Untar (local_dir_str, to_file);
		  fops.Remove (to_file);
		  break;
		case -2:
/*
		  fops.Untar (local_dir_str, from_file);
*/
		  fops.CopyDirectoryElement (from_dir, to_dir);
		  result = 0;
		  break;
		default:


		  inline "C" {
		      OzDebugf ("Class::LoadClassPart: "
				"OzFileTransfer returned %d. "
				"retrying ...\n",
				result);
		  }


		  break;
	      }
	  } while (result != 0);
	  cp->SetClassLink (self);
	  if (cp->IsImplementationPart () &&
	      length narrow (ImplementationPart, cp)->Architectures () > 1) {
	      ImplementationPart ip = narrow (ImplementationPart, cp);


	      ip->ClearArchitectures ();
	      ip->AddArchitecture (arch);
	  } else if (cp->IsPublicPart ()) {
	      global ConfiguredClassID ccid;

	      ccid = narrow (PublicPart, cp)->GetDefaultConfiguredClassID ();
	      if (ccid != 0) {
		  Where ()->ChangeConfigurationCache (narrow (VersionID, cid),
						      ccid);
	      }
	  }
	  cp->ChangeCopyKind (ClassCopyKind::Snapshot);
	  AddToClassTable (cp);
	  AddToSnapshots (cid);
      }

    global Class LookupClass (global ClassID cid) : global {
	debug (0, "Class::LookupClass: cid = %O\n", cid);
	if (ClassTable->IncludesKey (cid)) {
	    debug (0, "Class::LookupClass: oid returned for %O\n", cid);
	    return oid;
	} else {
	    return 0;
	}
    }

    char LookupProperty (global ClassID cid, char name [])[] : global {
	ClassPart cp = LookupAsClassPart (cid);
	String s;

	if ((s = cp->LookupProperty (name)) != 0) {
	    return s->Content ();
	} else {
	    return 0;
	}
    }

    void Purge (global ClassID cid) : global {
	CheckModifiable (cid);
	LookupAsClassVersion (cid)->Purge ();
	PropagateToMirrors (cid, MirrorModificationMode::OnlyObject);
    }

    void Read (char class_list_file []) : global {
	InstallImpl (class_list_file, 1);
    }



    void RegisterClassInformations (global ClassID cid) : global {
	ClassPart cp;
	unsigned int len, i;
	FileOperators fops;
	char files [][];

	CheckModifiable (cid);
	cp = LookupAsClassPart (cid);

	if (cp->WhichPart () == ClassPartName::aConfiguredClass) {
	    ConfiguredClass cc = narrow (ConfiguredClass, cp);

	    cc->ReadPrivateDotsFile ();
	    Logger->LogSetImplementationParts (narrow (ConfiguredClassID, cid),
					       cc->GetImplementationParts ());
	}
	PropagateToMirrors (cid, MirrorModificationMode::WithClassFiles);
    }

    void RemoveClass (global ClassID cid) : global {
	global ClassPackageID cpids [];
	global ClassID cids [];
	unsigned int i, len;
	ClassPart cp = LookupAsClassPart (cid);

	switch (cp->WhichKindOfCopy ()) {
	  case ClassCopyKind::Original:
	    Originals->RemoveKey (cid);
	    break;
	  case ClassCopyKind::Mirror:
	    raise ClassExceptions::NotModifiableCopy (cid);
	    break;
	  case ClassCopyKind::Snapshot:
	    Snapshots->RemoveKey (cid);
	    break;
	  case ClassCopyKind::Private:
	    Privates->Remove (cid);
	    break;
	  case ClassCopyKind::Boot:

	    BootClasses->Remove (cid);

	    break;
	}
	RemoveClassImpl (cid);
	length cids = 1;
	cids [0] = cid;
	cpids = GetBelongingOriginalClassPackages (cid);
	len = length cpids;
	for (i = 0; i < len; i ++) {
	    DeleteFromClassPackage (cpids [i], cids);
	}
    }

    void RemoveClassImpl (global ClassID cid) {
	ClassPart cp = ClassTable->RemoveKey (cid);
	FileOperators fops;

	fops.RemoveDirectory (cp->GetClassFileDirectory ());
	Logger->LogRemoveClass (cid);
    }

    void RemoveClassVersion (global VersionID vid) : global {
	CheckModifiable (vid);
	LookupAsClassVersion (vid)->Eliminate ();
	RemoveClass (vid);
    }

    void RemoveConfiguredClass (global ConfiguredClassID ccid) {
	CheckModifiable (ccid);
	{
	    ConfiguredClass cc = LookupAsConfiguredClass (ccid);
	    global VersionID pub = cc->GetPublicPart ();

	    CheckModifiable (pub);
	    if (LookupClass (pub)) {
		RemoveConfiguredClassImpl (pub, ccid);
		RemoveClass (ccid);
	    }
	}
    }

    void RemoveConfiguredClassImpl (global VersionID pub,
				    global ConfiguredClassID ccid) {
	PublicPart pp = LookupAsPublicPart (pub);
	pp->RemoveConfiguredClass (ccid);
	Logger->LogRemoveConfiguredClass (pub, ccid);
    }

    void RemoveLowerVersion (global VersionID lvid) {
	CheckModifiable (lvid);
	{
	    LowerPart lp = LookupAsLowerPart (lvid);
	    global VersionID uvid = lp->GetUpperPart ();

	    CheckModifiable (uvid);
	    if (LookupClass (uvid)) {
		RemoveLowerVersionImpl (uvid, lvid);
		RemoveClassVersion (lvid);
	    }
	}
    }

    void RemoveLowerVersionImpl (global VersionID uvid, global VersionID lvid){
	UpperPart up = LookupAsUpperPart (uvid);

	up->RemoveLowerVersion (lvid);
	Logger->LogRemoveLowerVersion (uvid, lvid);
    }

    void RemoveProperty (global ClassID cid, char name []) : global {
	ClassPart cp;

	CheckModifiable (cid);
	cp = LookupAsClassPart (cid);
	cp->RemoveProperty (name);

    }

    void Removing () : global {
	String path=>NewFromArrayOfChar (GetClassDirectoryPath ());
	FileOperators fops;

	Stop ();
	fops.RemoveDirectory (path);
    }

    void Restore () : global {Logger->Apply (self, DumpPath);}

    global Class SearchClass (global ClassID cid) : global {
	global Class c;

	if ((c = LookupClass (cid)) != 0) {
	    return c;
	} else {
	    ArchitectureID aid=>Any ();

	    return Where ()->SearchClass (cid, aid);
	}
    }

    void SetDefaultConfiguredClassID (global ClassID cid,
				      global ConfiguredClassID ccid)
      : global {
	  CheckModifiable (cid);
	  LookupAsPublicPart (cid)->SetDefaultConfiguredClassID (ccid);
	  Where ()->ChangeConfigurationCache (narrow (VersionID, cid), ccid);
	  Logger->LogSetDefaultConfiguredClassID (cid, ccid);
	  PropagateToMirrors (cid, MirrorModificationMode::OnlyObject);
      }

    void SetDefaultLowerVersionID (global ClassID cid, global VersionID vid)
      : global {
	  CheckModifiable (cid);
	  LookupAsUpperPart (cid)->SetDefaultLowerVersionID (vid);
	  Logger->LogSetDefaultLowerVersionID (cid, vid);
	  PropagateToMirrors (cid, MirrorModificationMode::OnlyObject);
      }

    void SetItAsDefaultConfiguredClass (global ConfiguredClassID ccid): global{
	global VersionID vid;

	vid = LookupAsConfiguredClass (ccid)->GetPublicPart ();
	SearchClass (vid)->SetDefaultConfiguredClassID (vid, ccid);
    }

    void SetItAsDefaultLowerVersion (global VersionID vid) : global {
	global ClassID cid;

	cid = LookupAsLowerPart (vid)->GetUpperPart ();
	SearchClass (vid)->SetDefaultLowerVersionID (cid, vid);
    }

    void SetImplementationParts (global ConfiguredClassID ccid,
				 global VersionID impl_ids [])
      : global {
	  CheckModifiable (ccid);
	  LookupAsConfiguredClass (ccid)->SetImplementationParts (impl_ids);
	  Logger->LogSetImplementationParts (ccid, impl_ids);
	  PropagateToMirrors (ccid, MirrorModificationMode::OnlyObject);
      }

    void SetParents (global ClassID cid, global VersionID parents []) : global{
	debug (0, "Class::SetParents cid = %O\n", cid);
	CheckModifiable (cid);
	LookupAsClassVersion (cid)->SetParents (parents);
	Logger->LogSetParents (cid, parents);
	PropagateToMirrors (cid, MirrorModificationMode::OnlyObject);
    }

    void SetVersionString (global VersionID vid, VersionString vs) {
	CheckModifiable (vid);
	LookupAsClassVersion (vid)->SetVersionString (vs);
	Logger->LogSetVersionString (vid, vs);
	PropagateToMirrors (vid, MirrorModificationMode::OnlyObject);
    }

    char UsedClassTable (global VersionID vid)[] : global {
	return LookupAsClassVersion (vid)->UsedClassTable ();
    }

    global VersionID
      VersionIDFromConfiguredClassID (global ConfiguredClassID ccid)
	: global {
	    return LookupAsConfiguredClass (ccid)->GetPublicPart ();
	}

    global VersionID VersionIDFromVersionString (global ClassID cid,
						 VersionString vs)
      : global {
	  return LookupAsClassVersion (cid)->VersionIDFromVersionString (vs);
      }

    unsigned int WhichKind (global ClassID cid) : global {
	return LookupAsPublicPart (cid)->WhichKind ();
    }

    unsigned int WhichPart (global ClassID cid) : global {
	return LookupAsClassPart (cid)->WhichPart ();
    }

/* for copy management */
    int AddMirrorMember (global ClassPackageID cpid, global ClassID cids [])
      : global {
	  /* return 1 if successful */
	  if (Mirrors->IncludesKey (cpid)) {
	      MirroredClassPackage mcp = Mirrors->AtKey (cpid);
	      global Class from = mcp->GetOriginal ();
	      unsigned int i, len = length cids;

	      CheckMirrorable (cids);
	      for (i = 0; i < len; i ++) {
		  if (LookupClass (cids [i])) {
		      switch (WhichKindOfCopy (cids [i])) {
			case ClassCopyKind::Mirror:
			case ClassCopyKind::Private:
			  break;
			case ClassCopyKind::Snapshot:
			  RemoveClassImpl (cids [i]);
			  LoadaClassPartAsaMirror (cids [i], from);
			  break;
		      }
		  } else {
		      LoadaClassPartAsaMirror (cids [i], from);
		  }
		  mcp->Add (cids [i]);
	      }
	      Logger->LogAddMirrorMember (cpid, cids);
	      return 1;
	  } else {
	      return 0;
	  }
      }

    void AddToClassPackage (global ClassPackageID cpid, global ClassID cids [])
      : global {
	  GetOriginalClassPackage (cpid)->AddAndPropagate (cids);
	  Logger->LogAddToClassPackage (cpid, cids);
      }

    void AddToOriginalPackages (global ClassPackageID cpid,
				OriginalClassPackage package) {
	OriginalPackages->Add (cpid, package);
	Logger->LogAddToOriginalPackages (cpid, package);
    }

    void AddToOriginals (global ClassID cid) {
	Date current=>Current ();

	Originals->Add (cid, current);
	Logger->LogAddToOriginals (cid);
    }

    void AddToSnapshots (global ClassID cid) {
	AddToSnapshotsWithoutLog (cid);
	Logger->LogAddToSnapshots (cid);
    }

    void AddToSnapshotsWithoutLog (global ClassID cid) {
	Date current=>Current ();

	Snapshots->Add (cid, current);
    }

    void ChangeCopyKind (global ClassID cid, int copy_kind) {
	LookupAsClassPart (cid)->ChangeCopyKind (copy_kind);
	Logger->LogChangeCopyKind (cid, copy_kind);
    }

    void ChangeMirrorMode (global ClassPackageID cpid, int new_mode) : global {
	MirroredClassPackage mcp = GetMirroredClassPackage (cpid);
	int old_mode = mcp->GetMirrorMode ();

	if (old_mode != new_mode) {
	    mcp->SetMirrorMode (new_mode);
	    if (new_mode == MirrorMode::Polling) {
		/* under implementation
		   global invocation should be protected */
		mcp->GetOriginal ()->UnregisterMirror (oid, cpid);
	    } else if (new_mode != MirrorMode::Polling &&
		       old_mode == MirrorMode::Polling) {
		/* under implementation
		   global invocation should be protected */
		mcp->GetOriginal ()->RegisterMirror (oid, cpid, new_mode);
	    } else {
		/* under implementation
		   global invocation should be protected */
		mcp->GetOriginal ()->ChangeMirrorSetting (oid, cpid, new_mode);
	    }
	}
	Logger->LogChangeMirrorMode (cpid, new_mode);
    }

    void ChangeMirrorSetting (global Class to, global ClassPackageID cpid,
			      int new_mode)
      : global {
	  OriginalClassPackage ocp = GetOriginalClassPackage (cpid);

	  if (ocp->IncludesMirror (to)) {
	      ocp->RemoveFrom (to);
	      ocp->AddMirror (to, new_mode);
	      Logger->LogChangeMirrorSetting (to, cpid, new_mode);
	  } else {
	      raise ClassExceptions::UnknownClassPackage (cpid);
	  }
      }

    void CheckMirrorable (global ClassID cids []) {
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    if (LookupClass (cids [i])) {
		switch (WhichKindOfCopy (cids [i])) {
		  case ClassCopyKind::Original:
		  case ClassCopyKind::Boot:
		    raise ClassExceptions::NotMirrorableCopy (cids [i]);
		    break;
		  case ClassCopyKind::Private:
		  case ClassCopyKind::Snapshot:
		  case ClassCopyKind::Mirror:
		    break;
		}
	    }
	}
    }

    void DeleteFromClassPackage (global ClassPackageID cpid,
				 global ClassID cids [])
      : global {
	  OriginalClassPackage ocp = GetOriginalClassPackage (cpid);

	  ocp->RemoveAndPropagate (cids);
	  Logger->LogDeleteFromClassPackage (cpid, cids);
      }

    int DeleteMirrorMember (global ClassPackageID cpid, global ClassID cids [])
      : global {
	  /* return 1 if successful */
	  if (Mirrors->IncludesKey (cpid)) {
	      unsigned int i, len = length cids;
	      int ret;

	      if (DeleteMirrorMemberImpl (cpid, cids)) {
		  for (i = 0; i < len; i ++) {
		      ClassPart cp = LookupAsClassPart (cids [i]);

		      switch (cp->WhichKindOfCopy ()) {
			case ClassCopyKind::Mirror:
			  cp->ChangeCopyKind (ClassCopyKind::Snapshot);
			  AddToSnapshotsWithoutLog (cids [i]);
			  break;
			case ClassCopyKind::Private:
			  break;
			case ClassCopyKind::Original:
			case ClassCopyKind::Boot:
			case ClassCopyKind::Snapshot:
			  detach fork UnsetMirror (cpid);
			  return 0;
		      }
		  }
		  ret = 1;
	      } else {
		  ret = 0;
	      }
	      Logger->LogDeleteMirrorMember (cpid, cids);
	      return ret;
	  } else {
	      return 0;
	  }
      }

    int DeleteMirrorMemberImpl (global ClassPackageID cpid,
				global ClassID cids []) {
	MirroredClassPackage mcp = Mirrors->AtKey (cpid);
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    if (mcp->Includes (cids [i])) {
		mcp->Remove (cids [i]);
	    } else {
		detach fork UnsetMirror (cpid);
		return 0;
	    }
	}
	return 1;
    }

    void DestroyClassPackage (global ClassPackageID cpid) : global {
	OriginalClassPackage ocp;

	if (OriginalPackages->IncludesKey (cpid)) {
	    ocp = OriginalPackages->RemoveKey (cpid);
	    ocp->Destroy ();
	    Logger->LogDestroyClassPackage (cpid);
	} else {
	    raise ClassExceptions::UnknownClassPackage (cpid);
	}
    }

    global ClassPackageID GetBelongingMirrors (global ClassID cid)[] : global {
	/* under implementation */
	/* listing mirrors and searching by atkey must not be */
	/* separated */
	global ClassPackageID set [] = ListMirrors ();
	unsigned int i, len = length set;
	SimpleArray <global ClassPackageID> cpids=>New ();

	for (i = 0; i < len; i ++) {
	    if (Mirrors->AtKey (set [i])->Includes (cid)) {
		cpids->Add (set [i]);
	    }
	}
	return cpids->Content ();
    }

    global ClassPackageID
      GetBelongingOriginalClassPackages (global ClassID cid)[]
	: global {
	    /* under implementation */
	    /* listing original class packages and searching by atkey */
	    /* must not be separated */
	    global ClassPackageID set [] = ListOriginalClassPackages ();
	    unsigned int i, len = length set;
	    SimpleArray <global ClassPackageID> cpids=>New ();

	    for (i = 0; i < len; i ++) {
		if (OriginalPackages->AtKey (set [i])->Includes (cid)) {
		    cpids->Add (set [i]);
		}
	    }
	    return cpids->Content ();
	}

    MirroredClassPackage GetMirroredClassPackage (global ClassPackageID cpid)
      : global {
	  try {
	      return Mirrors->AtKey (cpid);
	  } except {
	      CollectionExceptions <global ClassPackageID>::UnknownKey (key) {
		  if (key == cpid) {
		      raise ClassExceptions::UnknownClassPackage (cpid);
		  } else {
		      raise;
		  }
	      }
	  }
      }

    OriginalClassPackage GetOriginalClassPackage (global ClassPackageID cpid)
      : global {
	  try {
	      return OriginalPackages->AtKey (cpid);
	  } except {
	      CollectionExceptions <global ClassPackageID>::UnknownKey (key) {
		  if (key == cpid) {
		      raise ClassExceptions::UnknownClassPackage (cpid);
		  } else {
		      raise;
		  }
	      }
	  }
      }

    void InitializeClassPackages () {
	global ClassPackageID cpids [] = OriginalPackages->SetOfKeys ();
	unsigned int i, len = length cpids;

	for (i = 0; i < len; i ++) {
	    OriginalPackages->AtKey (cpids [i])->Start ();
	}
    }

    int IsBootClass (global ClassID cid) : global {
	return BootClasses->Includes (cid);
    }

    int IsMirror (global ClassID cid) : global {
	return length GetBelongingMirrors (cid) != 0;
    }

    int IsMirroredClassPackage (global ClassPackageID cpid) : global {
	return Mirrors->IncludesKey (cpid);
    }

    int IsOriginal (global ClassID cid) : global {
	return Originals->IncludesKey (cid);
    }

    int IsOriginalClassPackage (global ClassPackageID cpid) : global {
	return OriginalPackages->IncludesKey (cpid);
    }

    int IsPrivate (global ClassID cid) : global {
	return Privates->Includes (cid);
    }

    int IsSnapshot (global ClassID cid) : global {
	return Snapshots->IncludesKey (cid);
    }

    global ClassID ListBootClasses ()[] : global {
	return BootClasses->SetOfContents ();
    }

    global ClassPackageID ListMirrors ()[] : global {
	return Mirrors->SetOfKeys ();
    }

    global ClassID ListOriginals ()[] : global {
	return Originals->SetOfKeys ();
    }

    global ClassPackageID ListOriginalClassPackages ()[] : global {
	return OriginalPackages->SetOfKeys ();
    }

    global ClassID ListPrivates ()[] : global {
	return Privates->SetOfContents ();
    }

    global ClassID ListSnapshots ()[] : global {
	return Snapshots->SetOfKeys ();
    }

    void LoadaClassPartAsaMirror (global ClassID cid, global Class from) {
	/* under implementation
	   remote invocation must be protected */
	from->DelegateClass (cid, oid);
	LookupAsClassPart (cid)->ChangeCopyKind (ClassCopyKind::Mirror);
	Logger->LogChangeCopyKind (cid, ClassCopyKind::Mirror);
    }

    void Privatize (global ClassID cid) : global {
	ClassPart cp;

	switch (WhichKindOfCopy (cid)) {
	  case ClassCopyKind::Boot:
	    raise ClassExceptions::NotModifiableCopy (cid);
	    break;
	  case ClassCopyKind::Private:
	    return;
	  case ClassCopyKind::Original:
	    Originals->RemoveKey (cid);
	    break;
	  case ClassCopyKind::Snapshot:
	    Snapshots->RemoveKey (cid);
	    break;
	  case ClassCopyKind::Mirror:
	    break;
	}
	cp = LookupAsClassPart (cid);
	cp->ChangeCopyKind (ClassCopyKind::Private);
	cp->SetDistributability (0);
	Privates->Add (cid);
	Logger->LogPrivatize (cid);
	PropagateToMirrors (cid, MirrorModificationMode::OnlyObject);
    }

    void PropagateToMirrors (global ClassID cid, int mode) {
	/* mode is the mirror modification mode */
	global ClassPackageID cpids []
	  = GetBelongingOriginalClassPackages (cid);
	global ClassID cids [];
	unsigned int i, len = length cpids;

	length cids = 1;
	cids [0] = cid;
	for (i = 0; i < len; i ++) {
	    detach
	      fork OriginalPackages->AtKey (cpids [i])->Modify (cids, mode);
	}
    }

    void RefreshObjectAsaMirror (global ClassID cid, global Class from) {
	ClassPart cp;

	/* under implementation
	   remote invocation must be protected */
	cp = from->GetClassPart (cid);
	cp->SetClassLink (self);
	cp->ChangeCopyKind (ClassCopyKind::Mirror);
	if (cp->IsPublicPart ()) {
	    global ConfiguredClassID ccid;

	    ccid = narrow (PublicPart, cp)->GetDefaultConfiguredClassID ();
	    if (ccid != 0) {
		Where ()->ChangeConfigurationCache (narrow (VersionID, cid),
						    ccid);
	    }
	}
	AddToClassTable (cp);
	PropagateToMirrors (cid, MirrorModificationMode::OnlyObject);
    }

    global ClassPackageID RegisterClassPackage (ClassPackage cp) : global {
	/* No need to check the copy class. */
	/* All kind of copies can be mirrored. */
	global ClassPackageID id;
	OriginalClassPackage package=>New ();
	global ClassID cids [] = cp->SetOfContents ();
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    if (LookupClass (cids [i]) == 0) {
		raise ClassExceptions::UnknownClass (cids [i]);
	    } else {
		package->Add (cids [i]);
	    }
	}
	id = package->GetID ();
	AddToOriginalPackages (id, package);
	return id;
    }

    MirroredClassPackage RegisterMirror (global Class to,
					 global ClassPackageID cpid, int mode)
      : global {
	  OriginalClassPackage ocp = GetOriginalClassPackage (cpid);
	  MirroredClassPackage mcp=>Mirror (oid, ocp, mode);
	  if (mode != MirrorMode::Polling) {
	      ocp->AddMirror (to, mode);
	      Logger->LogRegisterMirror (to, cpid, mode);
	  }
	  return mcp;
      }

    void SetMirror (global Class from, global ClassPackageID cpid,
		    unsigned int mode)
      : global {
	  /* under implementation
	     global invocation should be protected from block */
	  MirroredClassPackage mcp = from->RegisterMirror (oid, cpid, mode);
	  global ClassID cids [] = mcp->SetOfContents ();
	  unsigned int i, len = length cids;

	  CheckMirrorable (cids);
	  for (i = 0; i < len; i ++) {
	      if (LookupClass (cids [i])) {
		  switch (WhichKindOfCopy (cids [i])) {
		    case ClassCopyKind::Mirror:
		    case ClassCopyKind::Private:
		      break;
		    case ClassCopyKind::Snapshot:
		      RemoveClassImpl (cids [i]);
		      LoadaClassPartAsaMirror (cids [i], from);
		      break;
		  }
	      } else {
		  LoadaClassPartAsaMirror (cids [i], from);
	      }
	  }
	  SetMirrorImplementation (from, cpid, mcp, mode);
      }

    void SetMirrorImplementation (global Class from,global ClassPackageID cpid,
				  MirroredClassPackage mcp, unsigned int mode){
	Mirrors->Add (cpid, mcp);
	Logger->LogSetMirror (cpid, from, mode, mcp->SetOfContents ());
    }

    void UnregisterMirror (global Class mirror, global ClassPackageID cpid)
      : global {
	  OriginalClassPackage ocp = GetOriginalClassPackage (cpid);
	  if (ocp->IncludesMirror (mirror)) {
	      ocp->RemoveFrom (mirror);
	  }
      }

    void UnsetMirror (global ClassPackageID cpid) : global {
	MirroredClassPackage mcp = GetMirroredClassPackage (cpid);
	global Class from = mcp->GetOriginal ();

	/* under implementation
	   global invocation should be protected */
	try {
	    from->UnregisterMirror (oid, cpid);
	} except {
	    default {}
	}
	UnsetMirrorImplementation (cpid);
    }

    void UnsetMirrorImplementation (global ClassPackageID cpid) : global {
	MirroredClassPackage mcp = Mirrors->RemoveKey (cpid);
	global ClassID cids [] = mcp->SetOfContents ();
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    switch (WhichKindOfCopy (cids [i])) {
	      case ClassCopyKind::Mirror:
		LookupAsClassPart (cids [i])
		  ->ChangeCopyKind (ClassCopyKind::Snapshot);
		AddToSnapshotsWithoutLog (cids [i]);
		break;
	      case ClassCopyKind::Private:
		break;
	      case ClassCopyKind::Original:
	      case ClassCopyKind::Boot:
	      case ClassCopyKind::Snapshot:
		inline "C" {
		    OzDebugf ("Class::UnsetMirror: Something wrong. "
			      "Class %O is left as it is.\n", cids [i]);
		}
		break;
	    }
	}
	Logger->LogUnsetMirror (cpid);
    }

    int CheckAllExistAndAreMemberOf (global ClassID cids [],
				     MirroredClassPackage mcp) {
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    if (LookupClass (cids [i]) == 0 || ! mcp->Includes (cids [i])) {
		global ClassPackageID cpid = mcp->GetID ();

		detach fork UnsetMirror (cpid);
		inline "C" {
		    OzDebugf ("Class::CheckAllExistAndAreMemberOf: "
			      "Something wrong.  Unsetting mirror %O.\n",
			      cpid);
		}
		return 0;
	    }
	}
	return 1;
    }

    void UpdateCopyOnWriteMirror (global ClassID cids [],
				  MirroredClassPackage mcp, int mode) {
	global Class from = mcp->GetOriginal ();
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    ClassPart cp = LookupAsClassPart (cids [i]);

	    if (cp->WhichKindOfCopy () == ClassCopyKind::Mirror) {
		switch (mode) {
		  case MirrorModificationMode::OnlyObject:
		    RefreshObjectAsaMirror (cids [i], from);
		    break;
		  case MirrorModificationMode::WithClassFiles:
		    RemoveClassImpl (cids [i]);
		    LoadaClassPartAsaMirror (cids [i], from);
		    break;
		}
	    }
	}
    }

    int UpdateMirror (global ClassPackageID cpid,
		      global ClassID cids [], int mode)
      : global {
	  /* return 1 if successful */
	  /* mode is the mirror modification mode */
	  if (Mirrors->IncludesKey (cpid)) {
	      MirroredClassPackage mcp = Mirrors->AtKey (cpid);
	      int mirror_mode = mcp->GetMirrorMode ();

	      switch (mirror_mode) {
		case MirrorMode::Polling:
		  /* under implementation
		     coerce the mirror mode at original to polling */
		  break;
		case MirrorMode::CopyOnWrite:
		  if (CheckAllExistAndAreMemberOf (cids, mcp)) {
		      UpdateCopyOnWriteMirror (cids, mcp, mode);
		  } else {
		      return 0;
		  }
		  break;
		case MirrorMode::WriteInvalidate:
		  if (CheckAllExistAndAreMemberOf (cids, mcp)) {
		      UpdateWriteInvalidateMirror (cids, mcp, mode);
		  } else {
		      return 0;
		  }
		  break;
	      }
	      return 1;
	  } else {
	      return 0;
	  }
      }

    void UpdateWriteInvalidateMirror (global ClassID cids [],
				      MirroredClassPackage mcp, int mode) {
	unsigned int i, len = length cids;

	for (i = 0; i < len; i ++) {
	    ClassPart cp = LookupAsClassPart (cids [i]);

	    if (cp->WhichKindOfCopy () == ClassCopyKind::Mirror){
		cp->Invalidate (mode, mcp->GetID ());
	    }
	}
    }

    int WhichKindOfCopy (global ClassID cid) : global {
	return LookupAsClassPart (cid)->WhichKindOfCopy ();
    }
}
