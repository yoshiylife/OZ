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


// we distribute class not by tar'ed directory


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

/*
 * classwn.oz
 *
 * Class with distribution notifer window object
 */

class ClassWithNotifier : Class (rename New SuperNew;
				 alias Initialize SuperInitialize;
				 alias Stop SuperStop;
				 alias LoadClassPart SuperLoadClassPart;) {
/* programmer interface */
  constructor: New;

  public:
    Architectures, ConfiguredClassIDs, CreateNewConfiguredClass,
    CreateNewGenericClass, CreateNewPart, CreateNewVersion,
    DefaultVersionString, DelegateClass, Do, GeneralizedVersionOf,
    GetClassDirectoryPath, GetClassInformations, GetCode,
    GetDefaultConfiguredClassID, GetDefaultVersionID,
    GetImplementationPart, GetLayout, GetLowerVersions, GetParents,
    GetProperties, GetProtectedPart, GetPublicPart, GetRootPart,
    GetRuntimeClassInformation, GetUpperPart, GetVersionString,
    GetVisibleLowerVersions, InheritanceHierarchy, IsAvailableOn,
    KeepAlive, LoadClassPart, LookupClass, MakeItVisible, Purge, Read,
    RegisterClassInformations, RemoveClass, SearchClass,
    SetDefaultLowerVersionID, SetParents, UsedClassTable,
    VersionIDFromConfiguredClassID, VersionIDFromVersionString;

  protected: Initialize;

/* instance variables */
  protected: ClassDirectoryPath, ClassListFile, Names, ClassTable;
  protected: aNotifierWindow;

    NotifierWindow aNotifierWindow;

/* method implementations */
    void New (char directory_path []) : global {
	SuperNew (directory_path);
	aNotifierWindow=>New ();
    }

    void Initialize () {
	aNotifierWindow->Spawn ();
	SuperInitialize ();


	inline "C" {
	    OzDebugf ("ClassWithNotifier::Initialize: Complete.\n");
	}


    }

    void Stop () : global {
	SuperStop ();
	aNotifierWindow->Quit ();


	inline "C" {
	    OzDebugf ("ClassWithNotifier::Stop: Complete.\n");
	}


    }

    void LoadClassPart (global ClassID cid, ArchitectureID arch,
			global Class from, char dir [], ClassPart cp)
      : global {
	  aNotifierWindow->Mawaru ();
	  aNotifierWindow->ID (cid);
	  try {
	      SuperLoadClassPart (cid, arch, from, dir, cp);
	  } except {
	      default {}
	  }
	  aNotifierWindow->Tomaru ();
      }
}
