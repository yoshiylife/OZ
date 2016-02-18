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
 * sptrans.oz
 *
 * Strict pessimistic transaction
 * strict 2 phase locking, 2 phase commitment
 * Should be created as a global object.
 */

/*
 * StrictTransactionResource should have following interface:
 *   void Abort (global StrictPTransaction);
 *   void IsReadyToCommit (global StrictPTransaction);
 *   void Commit (global StrictPTransaction);
 *   void Lock (global StrictPTransaction);
 *
 * StrictPTransaction use strict 2 phase locking protocol.  Thus, explicit
 * unlock operation is not taken for StrictTransactionResource.  Instead, 
 * committing or aborting transaction should automatically unlock resource.
 * StrictTransactionResource::{Abort,Commit} should unlock itself.
 */

class StrictPTransaction : PTransaction {
  constructor: New, NewAndLock;
  public:
    Abort, ChangeLockingPhase, Commit, GetLockedResources,
    GetResourcesToCommit, GetWaitingResources, Lock;
  protected: Initialize;
  protected: Unlock;
  protected: LockedResources, LockingPhase, ResourcesToCommit,WaitingResources;

    void Unlock (global TransactionResource tounlock []) : global {
	raise TransactionProtocolExceptions::ProtocolError (oid);
    }
}
