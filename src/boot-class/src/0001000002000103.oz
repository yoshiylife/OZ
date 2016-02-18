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

// we have a bug in gen-spec-src


// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// we have no str[fp]time


// boot classes are modifiable

/*
 * confclass.oz
 *
 * Configured class
 */

class ConfiguredClass : ClassPart (rename New SuperNew;) {
/* interface from super classes */
  /* method interface */
  public:
    CutClassLink, IsAvailableOn, IsConfiguredClass, IsImplementationPart,
    IsProtectedPart, IsPublicPart, IsRootPart, WhichPart;
  protected: DoesFileExist, SuperNew;

  /* accessor methods */
  public:
    AddProperty, ClearProperties,
    GetClassFileDirectory, GetClassLink, GetID, GetProperties,
    LookupProperty, RemoveProperty, SetClassLink;
    /* for copy management */
  public:
    ChangeCopyKind, GetInvalidatedSource, Invalidate, IsDirty, IsDistributable,
    SetDistributability, WhichKindOfCopy;

  protected: SetInitialLengthOfPropertyTable;

/* interface from this class */
  constructor: New;
  public:
    GetImplementationParts, GetPublicPart, ReadPrivateDotsFile,
    SetImplementationParts;

  protected: SetInitialLengthOfImplementationParts;

/* instance variables */
  protected: VersionIDOfPublicPart;

    unsigned int InitialLengthOfImplementationParts; /* = 2; */

    global VersionID VersionIDOfPublicPart;
    SimpleArray <global VersionID> ImplementationParts;

/* method implementatins */
    void New (Class class_object, global ConfiguredClassID cid,
	      global VersionID public_part, int copy_kind) {
	SuperNew (cid, class_object, copy_kind);
	VersionIDOfPublicPart = public_part;
	SetInitialLengthOfImplementationParts ();
	ImplementationParts=>NewWithSize (InitialLengthOfImplementationParts);
    }

    global VersionID GetImplementationParts ()[] {
	return ImplementationParts->Content ();
    }

    global VersionID GetPublicPart () {return VersionIDOfPublicPart;}

    int IsConfiguredClass () {return 1;}
    int IsImplementationPart () {return 0;}
    int IsProtectedPart () {return 0;}
    int IsPublicPart () {return 0;}
    int IsRootPart () {return 0;}

    void ReadPrivateDotsFile () {
	String path = LookupProperty ("private.s");
	if (path == 0) {


	    global ClassID cid = GetID ();

	    inline "C" {
		OzDebugf ("ConfiguredClass::ReadPrivateDotsFile: "
			  "property \"private.s\" is not found in %O.\n",
			  cid);
	    }


	} else {
	    try {
		PrivateDotsFileReader fr;
		SimpleArray <global VersionID> a=>New ();

		fr=>New (path);
		while (! fr->IsEndOfToken ()) {
		    try {
			a->Add (narrow (VersionID, fr->ReadObjectID ()));
		    } except {
		      FileReaderExceptions::SyntaxError (t) {
			  if (t->Type () == TokenType::EOFType) {
			      break;
			  }
		      }
			default {


			    inline "C" {
				OzDebugf ("ConfiguredClass::"
					  "ReadPrivateDotsFile: "
					  "something wrong.\n");
			    }


			}
		    }
		}
		SetImplementationParts (a->Content ());
	    } except {
	      FileReaderExceptions::CannotOpenFile (fn) {


		  global ClassID cid = GetID ();
		  inline "C" {
		      OzDebugf ("ConfiguredClass::ReadPrivateDotsFile: "
				"cannot open private.s file %S\n", fn);
		  }


	      }
	      FileReaderExceptions::SyntaxError (t) {


		  global ClassID cid = GetID ();
		  inline "C" {
		      OzDebugf ("ConfiguredClass::ReadPrivateDotsFile: "
				"syntax error in private.s file in %O, "
				"token = %p\n", cid, t);
		  }


	      }
		default {


		    global ClassID cid = GetID ();
		    inline "C" {
			OzDebugf ("ConfiguredClass::ReadPrivateDotsFile: "
				  "something wrong in reading "
				  "private.s file in %O.",
				  cid);
		    }


		}
	    }
	}
    }

    void SetImplementationParts (global VersionID impl_ids []) {
	ImplementationParts->Set (impl_ids);
    }

    void SetInitialLengthOfImplementationParts () {
	InitialLengthOfImplementationParts = 2;
    }

    unsigned int WhichPart () {return ClassPartName::aConfiguredClass;}
}
