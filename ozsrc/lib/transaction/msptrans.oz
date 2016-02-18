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
 * msptrans.oz
 *
 * Moded strict pessimistic transaction
 * strict 2 phase locking, 2 phase commitment,
 * 2 locking mode (shared/exclusive)
 * Should be created as a global object.
 */

/*
 * ModedStrictTransactionResource should have following interface:
 *   void Abort (global PTransaction);
 *   void Commit (global PTransaction);
 *   void IsReadyToCommit (global PTransaction);
 *   void Lock (global PTransaction);
 *   void SharedLock (global PTransaction);
 *
 * ModedStrictPTransaction use strict 2 phase locking protocol.  Thus, explicit
 * unlock operation is not taken for ModedStrictTransactionResource.  Instead,
 * committing or aborting transaction should automatically unlock resource.
 * ModedTransactionResource::{Abort,Commit} should unlock itself.
 * It should be possible to change lock mode.  That is,
 * StrictModedTransactionResources should be able to be exclusively locked by
 * a ModedPTransaction which already has a shared lock to the resource.
 */

class ModedStrictPTransaction :
  ModedPTransaction (rename Unlock RenamedUnlock;),
  StrictPTransaction (rename New RenamedNew;
		      rename NewAndLock RenamedNewAndLock;
		      rename Initialize RenamedInitialize;
		      rename Abort RenamedAbort;
		      rename ChangeLockingPhase RenamedChangeLockingPhase;
		      rename Commit RenamedCommit;
		      rename GetResourcesToCommit RenamedGetResourcesToCommit;
		      rename GetWaitingResources RenamedGetWaitingResources;
		      rename Lock RenamedLock;
		      rename ResourcesToCommit RenamedResourcesToCommit;
		      rename WaitingResources RenamedWaitingResources;
		      rename LockingPhase RenamedLockingPhase;)
{
  constructor: New, NewAndLock;
  public:
    Abort, Commit, ExclusiveLock, GetExclusivelyLockedResources,
    GetResourcesToCommit, GetWaitingResources, SharedLock;
  protected: Initialize;
  protected: Unlock;
  protected:
    ExclusivelyLockedResources, LockingPhase, SharedLockedResources,
    ResourcesToCommit, WaitingResources;

    void RenamedNew () : global {Initialize ();}
    void RenamedNewAndLock (global TransactionResource resources []) : global {
	Initialize ();
	ExclusiveLock (resources);
    }
    void RenamedInitialize () {Initialize ();}
    void RenamedAbort () : global {Abort ();}
    void RenamedChangeLockingPhase () : global {ChangeLockingPhase ();}
    void RenamedCommit () : global {Commit ();}
    OIDSet <global TransactionResource> GetLockedResources () : global {
	return GetExclusivelyLockedResources ();
    }
    OIDSet <global TransactionResource> RenamedGetResourcesToCommit ():global {
	return ResourcesToCommit;
    }
    OIDSet <global TransactionResource> RenamedGetWaitingResources () :global {
	return WaitingResources;
    }
    void RenamedLock (global TransactionResource tolock []) : global {
	ExclusiveLock (tolock);
    }
    void RenamedUnlock (global TransactionResource tounlock []) : global {
	Unlock (tounlock);
    }
}
