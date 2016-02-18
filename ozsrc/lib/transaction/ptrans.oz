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
 * ptrans.oz
 *
 * Pessimistic transaction
 * 2 phase locking, 2 phase commitment
 * Should be created as a global object.
 */

/*
 * TransactionResource should have following interface:
 *   void Abort (global PTransaction);
 *   void Commit (global PTransaction);
 *   void IsReadyToCommit (global PTransaction);
 *   void Lock (global PTransaction);
 *   void Unlock (global PTransaction);
 *
 * PTransaction doesn't use strict 2 phase locking protocol.  Thus, unlocked
 * TransactionResource should be able to be locked and operated before
 * commition.  (It will be very difficult to implement...)
 * Committing or aborting transaction should automatically unlock resource.
 * TransactionResource::{Abort,Commit} should unlock itself if locked.
 */

class PTransaction {
  constructor: New, NewAndLock;
  public:
    Abort, ChangeLockingPhase, Commit, GetLockedResources,
    GetResourcesToCommit, GetWaitingResources, Lock, Unlock;
  protected: Initialize;
  protected:
    LockedResources, LockingPhase, ResourcesToCommit, WaitingResources;

    OIDSet <global TransactionResource> LockedResources;
    OIDSet <global TransactionResource> WaitingResources;
    OIDSet <global TransactionResource> ResourcesToCommit;
    char LockingPhase; /* 'l' for locking, 'u' for unlocking */

    void New () : global {Initialize ();}

    void NewAndLock (global TransactionResource resources []) : global {
	Initialize ();
	Lock (resources);
    }

    void Initialize () {
	LockedResources=>NewWithSize (2);
	ResourcesToCommit=>NewWithSize (2);
	WaitingResources=>NewWithSize (2);
	LockingPhase = 'l';
    }

    void Abort () : global, locked {
	/* naive inplementation:
	 *   should be protected from exceptions.
	 *   should be in parallel */
	global TransactionResource toabort [];
	unsigned int i, len;

	if (LockingPhase == 'l') {
	    LockingPhase = 'u';
	}
	toabort = ResourcesToCommit->SetOfContents ();
	len = length toabort;
	for (i = 0; i < len; i ++) {
	    toabort [i]->Abort (oid);
	}
	Where ()->RemoveMe (oid);
    }

    void ChangeLockingPhase () : global, locked {
	/*
	 * Because aborting and committing a transaction and unlocking a
	 * resource change the locking phase automatically, there is no need to
	 * call this method explicitly.  This method is simply for ease of
	 * debugging.  Programming to call this method can detect some extra
	 * locking caused by a bug at last stage of locking phase.
	 */
	if (LockingPhase == 'l') {
	    LockingPhase = 'u';
	} else {
	    raise TransactionProtocolExceptions::PhaseError (oid);
	}
    }

    void Commit () : global, locked {
	/* naive inplementation:
	 *   should be protected from exceptions.
	 *   should be in parallel */
	global TransactionResource tocommit [];
	unsigned int i, len;

	if (LockingPhase == 'l') {
	    LockingPhase = 'u';
	}
	tocommit = ResourcesToCommit->SetOfContents ();
	len = length tocommit;
	for (i = 0; i < len; i ++) {
	    if (! tocommit [i]->IsReadyToCommit (oid)) {
		detach fork Abort ();
		return;
	    }
	}
	for (i = 0; i < len; i ++) {
	    tocommit [i]->Commit (oid);
	}
	Where ()->RemoveMe (oid);
    }

    OIDSet <global TransactionResource> GetLockedResources () : global {
	return LockedResources;
    }

    OIDSet <global TransactionResource> GetResourcesToCommit () : global {
	return ResourcesToCommit;
    }

    OIDSet <global TransactionResource> GetWaitingResources () : global {
	return WaitingResources;
    }

    void Lock (global TransactionResource tolock []) : global, locked {
	/* naive inplementation:
	 *   should be protected from exceptions.
	 *   should be in parallel */

	if (LockingPhase == 'l') {
	    unsigned int i, len = length tolock;

	    for (i = 0; i < len; i ++) {
		global TransactionResource r = tolock [i];

		if (! LockedResources->Includes (r)) {
		    WaitingResources->Add (r);
		    r->Lock (oid);
		    ResourcesToCommit->Add (r);
		    LockedResources->Add (r);
		    WaitingResources->Remove (r);
		}
	    }
	} else {
	    raise TransactionProtocolExceptions::PhaseError (oid);
	}
    }

    void Unlock (global TransactionResource tounlock []) : global, locked {
	/* naive inplementation:
	 *   should be protected from exceptions.
	 *   should be in parallel */
	unsigned int i, len = length tounlock;

	if (LockingPhase == 'l') {
	    LockingPhase = 'u';
	}
	for (i = 0; i < len; i ++) {
	    global TransactionResource r = tounlock [i];

	    if (LockedResources->Includes (r)) {
		r->Unlock (oid);
		LockedResources->Remove (r);
	    }
	}
    }
}
