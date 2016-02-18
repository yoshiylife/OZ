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
 * lockset.oz
 *
 * Set of objects to be locked
 */

/* TYPE PARAMETERS: TContent */

/*
  TContent must respond to
  TestAndLock (global Object id); and
  UnLock (global Object id);
  */

/*
  naive implementation.
  Lock should distinguish simple Locking and TestAndLock.
  */

class LockSet <global DirectoryServer<Package>>
  : Set <OIDAsKey <global DirectoryServer<Package>>> (rename New SuperNew;
			       rename Add SuperAdd;
			       rename Includes SuperIncludes;
			       rename Remove SuperRemove;)
{
  constructor: New;

  public: Add, Commit, Includes, Lock, Remove, RemoveAllContent, UnLock;

/* instance variables */
  protected: Locked, ID;

    Set <OIDAsKey <global DirectoryServer<Package>>> Locked;
    global LockID ID;

/* method implementations */

    void New () {
	SuperNew ();
	Locked=>New ();
	ID = narrow (LockID, Where ()->NewOID ());
    }

    global DirectoryServer<Package> Add (global DirectoryServer<Package> t) {
	OIDAsKey <global DirectoryServer<Package>> key=>New (t);

	key = SuperAdd (key);
	if (key == 0) {
	    return 0;
	} else {
	    return key->Get ();
	}
    }

    int Commit () {
	Iterator <OIDAsKey <global DirectoryServer<Package>>> i;
	OIDAsKey <global DirectoryServer<Package>> k;

	for (i=>New (Locked); (k = i->PostIncrement ()) != 0;) {
	    k->Get ()->FlushImpl ();
	}
	/* Critical! Failure of this method is fatal. */
    }

    int Includes (global DirectoryServer<Package> t) {
	OIDAsKey <global DirectoryServer<Package>> key=>New (t);

	return SuperIncludes (key);
    }

    int Lock () {
	Iterator <OIDAsKey <global DirectoryServer<Package>>> i;
	OIDAsKey <global DirectoryServer<Package>> k;
	int finished = 0;
	int res = 1;

	for (i=>New (self); ! finished && (k = i->PostIncrement ()) != 0;) {
	    try {
		if (! k->Get ()->TestAndLock (ID)) {
		    UnLock ();
		    Sleep (1); /* sleep 1 second */
		    finished = 1;
		    res = 0;
		} else {
		    Locked->Add (k);
		    /* continue iteration */
		}
	    } except {
		default {
		    UnLock ();
		    Sleep (1);
		    finished = 1;
		    res = 0;
		}
	    }
	}
	return res;
    }

    global DirectoryServer<Package> Remove (global DirectoryServer<Package> t) {
	OIDAsKey <global DirectoryServer<Package>> key=>New (t);

	key = SuperRemove (key);
	if (key == 0) {
	    return 0;
	} else {
	    return key->Get ();
	}
    }

    void Sleep (unsigned int interval) {
	inline "C" {
	    OzSleep (interval);
	}
    }

    void UnLock () {
	Iterator <OIDAsKey <global DirectoryServer<Package>>> i;
	OIDAsKey <global DirectoryServer<Package>> k;

	for (i=>New (Locked); (k = i->PostIncrement ()) != 0;) {
	    k->Get ()->UnLock (ID);
	}
	Locked->RemoveAllContent ();
    }
}
