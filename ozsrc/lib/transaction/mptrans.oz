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
 * mptrans.oz
 *
 * Moded pessimistic transaction
 * 2 phase locking, 2 phase commitment, 2 locking mode (shared/exclusive)
 * Should be created as a global object.
 */

/*
 * ModedTransactionResource should have following interface:
 *   void Abort (global PTransaction);
 *   void Commit (global PTransaction);
 *   void IsReadyToCommit (global PTransaction);
 *   void Lock (global PTransaction);
 *   void SharedLock (global PTransaction);
 *   void Unlock (global PTransaction);
 *
 * ModedPTransaction doesn't use strict 2 phase locking protocol.  Thus,
 * unlocked TransactionResource should be able to be locked and operated before
 * commition.  (It will be very difficult to implement...)
 * Committing or aborting transaction should automatically unlock resource.
 * ModedTransactionResource::{Abort,Commit} should unlock itself if locked.
 * It should be possible to change lock mode.  That is,
 * ModedTransactionResources should be able to be exclusively locked by
 * a ModedPTransaction which already has a shared lock to the resource.
 */

class ModedPTransaction
  : PTransaction (alias Initialize SuperInitialize;
		  rename GetLockedResources GetExclusivelyLockedResources;
		  rename Lock ExclusiveLock;
		  rename LockedResources ExclusivelyLockedResources;)
{
  constructor: New, NewAndLock;
  public:
    Abort, ChangeLockingPhase, Commit, ExclusiveLock,
    GetExclusivelyLockedResources, GetResourcesToCommit, GetWaitingResources,
    SharedLock, Unlock;
  protected: Initialize;
  protected:
    ExclusivelyLockedResources, LockingPhase, ResourcesToCommit,
    SharedLockedResources, WaitingResources;

    OIDSet <global ModedTransactionResource> SharedLockedResources;

    void Initialize () {
	SuperInitialize ();
	SharedLockedResources=>NewWithSize (2);
    }

    void SharedLock (global ModedTransactionResource tolock []) : global {
	/* naive inplementation:
	 *   should be protected from exceptions.
	 *   should be in parallel */
	if (LockingPhase == 'l') {
	    unsigned int i, len = length tolock;

	    for (i = 0; i < len; i ++) {
		global ModedTransactionResource r = tolock [i];

		if (! ExclusivelyLockedResources->Includes (r) &&
		    ! SharedLockedResources->Includes (r)) {
		    WaitingResources->Add (r);
		    r->SharedLock (oid);
		    ResourcesToCommit->Add (r);
		    SharedLockedResources->Add (r);
		    WaitingResources->Remove (r);
		}
	    }
	} else {
	    raise TransactionProtocolExceptions::PhaseError (oid);
	}
    }

    void Unlock (global TransactionResource tounlock []) : global,locked {
	/* naive inplementation:
	 *   should be protected from exceptions.
	 *   should be in parallel */
	unsigned int i, len = length tounlock;

	if (LockingPhase == 'l') {
	    LockingPhase = 'u';
	}
	for (i = 0; i < len; i ++) {
	    global TransactionResource r = tounlock [i];

	    if (ExclusivelyLockedResources->Includes (r)) {
		r->Unlock (oid);
		ExclusivelyLockedResources->Remove (r);
	    } else {
		global ModedTransactionResource mr;

		mr = narrow (ModedTransactionResource, r);
		if (SharedLockedResources->Includes (mr)) {
		    mr->Unlock (oid);
		    SharedLockedResources->Remove (mr);
		}
	    }
	}
    }
}
