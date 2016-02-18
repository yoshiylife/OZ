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


// we have no str[fp]time


// boot classes are modifiable


// when object manager is started, its configuration cache won't be cleared
//#define CLEARCONFIGURATIONCACHEATSTART

// the executor doesn't expect a class cannot be found

/*
 * resolvable.oz
 *
 * Resolvable object
 */

abstract class ResolvableObject {
  public: Go, Removing, Stop, Flush, Where;
  constructor: New;
  public: AddName, RemoveName;
  protected:
    RegisterToNameDirectory, UnRegisterFromNameDirectory,
    SetInitialLengthOfNames;

/* instance variables */
  protected: Names;

    unsigned int InitialLengthOfNames; /* = 4; */

    StringArray Names;

/* method implementations */
    void New () : global {
	SetInitialLengthOfNames ();
	Names=>NewWithSize (InitialLengthOfNames);
    }

    void AddName (char name []) : global {Names->Add (name);}

    void RegisterToNameDirectory () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	unsigned int size = Names->Size (), i;

	for (i = 0; i < size; i ++) {
	    global ResolvableObject c;

	    c = nd->ResolveWithArrayOfChar (Names->At (i));
	    if (c == 0) {
		nd->AddObjectWithArrayOfChar (Names->At (i), oid);
	    } else if (c != oid) {
		String s=>NewFromArrayOfChar (Names->At (i));

		raise ResolverExceptions::DuplicateRegistration (s);
	    }
	}
    }

    void RemoveName (char name []) : global {Names->Remove (name);}

    void SetInitialLengthOfNames () {InitialLengthOfNames = 4;}

    void UnRegisterFromNameDirectory () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	unsigned int size = Names->Size (), i;

	for (i = 0; i < size; i ++) {
	    global ResolvableObject c;

	    c = nd->ResolveWithArrayOfChar (Names->At (i));
	    if (c == oid) {
		nd->RemoveObjectWithNameWithArrayOfChar (Names->At (i));
	    }
	}
    }
}
