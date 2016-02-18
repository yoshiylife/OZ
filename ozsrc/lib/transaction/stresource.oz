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
 * stresource.oz
 *
 * Strict pessimistic transaction resoruce
 * Should be inherited by a global object.
 */

abstract class StrictTransactionResource : TransactionResource {
  public: Abort, Commit, GetLockingTransaction, IsReadyToCommit, Lock;
  protected: Initialize;
  protected: LockHook, UnlockHook;
  protected: ResetLock, Unlock;
  protected: LockingTransaction, Unlocked;

    void Abort (global PTransaction t) : global, locked {
	if (LockingTransaction == t) {
	    UnlockHook (t);
	    detach fork Where ()->RestoreObject (oid);
	} else {
	    raise TransactionProtocolExceptions::ProtocolError (t);
	}
    }

    void Commit (global PTransaction t) : global, locked {
	if (LockingTransaction == t) {
	    UnlockHook (t);
	    LockingTransaction = 0;
	    Flush ();
	    signal Unlocked;
	} else {
	    raise TransactionProtocolExceptions::ProtocolError (t);
	}
    }

    int IsReadyToCommit (global PTransaction t) : global, locked {
	if (LockingTransaction == t) {
	    return 1;
	} else {
	    raise TransactionProtocolExceptions::ProtocolError (t);
	}
    }

    void Unlock (global PTransaction t) : global, locked {
	raise TransactionProtocolExceptions::ProtocolError (t);
    }
}
