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
 * classpart.oz
 *
 * A class part: a managing unit of class.
 * Abstract class
 */

abstract class ClassPart {
/* method interface */
  constructor: New;
  public:
    CutClassLink, IsAvailableOn, IsConfiguredClass, IsImplementationPart,
    IsProtectedPart, IsPublicPart, IsRootPart, WhichPart;
    /* for copy management */
  public: IsExpirable, IsPackable, IsModifiable;
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

/* instance variables */

    Class ClassObject;
    global ClassID ID;

    int CopyKind;
    int Distributable;
    int Dirty;
    global ClassPackageID InvalidatedSource;

/* abstract methods */
    int IsConfiguredClass () : abstract;
    int IsImplementationPart () : abstract;
    int IsProtectedPart () : abstract;
    int IsPublicPart () : abstract;
    int IsRootPart () : abstract;
    unsigned int WhichPart () : abstract;

/* method implementations */
    void New (global ClassID cid, Class class_object, int copy_kind) {


	ID = cid;

	ClassObject = class_object;

	CopyKind = copy_kind;
	Dirty = MirrorModificationMode::DoNothing;
	InvalidatedSource = 0;
	Distributable = (copy_kind != ClassCopyKind::Private);
    }

    ClassPart CutClassLink () {
	SetClassLink (0);
	return self;
    }

    int DoesFileExist (char path_name []) {
	String st=>NewFromArrayOfChar (path_name);
	FileOperators fops;
	return fops.IsExists (st);
    }

/* accessor methods */
    void AddProperty (char property []) : locked {

    }

    void ClearProperties () : locked {

    }

    String GetClassFileDirectory () : locked {
	String s=>NewFromArrayOfChar (ClassObject->GetClassDirectoryPath ());


	String id=>OIDtoHexa (ID);
	return s->ConcatenateWithArrayOfChar ("/")->Concatenate (id);

    }

    Class GetClassLink () {return ClassObject;}

    global ClassID GetID () {return ID;}

    /*
     * Returns array of file names (not path names) in the class directory.
     */
    String GetProperties ()[] : locked {
	String res [];
	unsigned int i;

	/*
	 * クラスディレクトリの list を取って返します。
	 */
	String s=>NewFromArrayOfChar (ClassObject->GetClassDirectoryPath ());
	String id=>OIDtoHexa (ID);
	String path = s->ConcatenateWithArrayOfChar ("/")->Concatenate (id);
	FileOperators fops;
	char list [][] = fops.List (path);
	unsigned int len = length list;
	length res = len;
	for (i = 0; i < len; i ++) {
	    res [i]=>NewFromArrayOfChar (list [i]);
	}
	return res;

    }

    int IsAvailableOn (ArchitectureID aid) {return 1;}


    String LookupProperty (char property []) {

	unsigned int i;

	/*
	 * 梅プランでは、毎回ファイルを見に行く。
	 * 実行時に private.o や private.r を探しに行くのに
	 * そういう方法では遅い、かもしれないが、
	 * その用途には Class#GetPropertyPath を使ってもらう。
	 * Class#GetPropertyPath は、ファイルを見ずに path を計算して返す。
	 */
	String properties [] = GetProperties ();
	unsigned int len = length properties;

	for (i = 0; i < len; i ++) {
	    if (properties [i]->IsEqualToArrayOfChar (property)) {
		String id=>OIDtoHexa(ID);
		char cdp [] = ClassObject->GetClassDirectoryPath ();
		String s=>NewFromArrayOfChar (cdp);
		return
		  s->ConcatenateWithArrayOfChar ("/")
		    ->Concatenate (id)
		      ->ConcatenateWithArrayOfChar ("/")
			->ConcatenateWithArrayOfChar (property);
	    }
	}
	return 0;

    }


    void RemoveProperty (char property []) {


	String path = LookupProperty (property);

	if (path == 0) {
	    raise ClassExceptions::UnknownProperty (property);
	} else {
	    try {
		FileOperators fops;
		fops.Remove (path);
	    } except {
	      default {}
	    }
	}

    }

    void SetInitialLengthOfPropertyTable () {

    }

    void SetClassLink (Class class_object) {ClassObject = class_object;}

    /* for copy management */
    void ChangeCopyKind (int copy_kind) {CopyKind = copy_kind;}

    global ClassPackageID GetInvalidatedSource () {return InvalidatedSource;}

    void Invalidate (int mode, global ClassPackageID cpid) {
	Dirty = mode;
	InvalidatedSource = cpid;
    }

    int IsDirty () {return Dirty;}
    int IsDistributable () {return Distributable;}
    int IsExpirable () {return WhichKindOfCopy () == ClassCopyKind::Snapshot;}
    int IsPackable () {return ! IsExpirable ();}

    int IsModifiable () {
	switch (WhichKindOfCopy ()) {
	  case ClassCopyKind::Original:
	  case ClassCopyKind::Private:

	  case ClassCopyKind::Boot:

	    return 1;
	  case ClassCopyKind::Mirror:
	  case ClassCopyKind::Snapshot:

	    return 0;
	    break;
	}
    }

    void SetDistributability (int d) {Distributable = d;}
    int WhichKindOfCopy () {return CopyKind;}
}
