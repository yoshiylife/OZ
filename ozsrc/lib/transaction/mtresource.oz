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
 * mtresource.oz
 *
 * Moded pessimistic transaction resoruce
 * Should be inherited by a global object.
 */

abstract class ModedTransactionResource
  : TransactionResource (alias Initialize SuperInitialize;)
{
  public:
    Abort, Commit, GetLockMode, GetLockingTransaction, IsReadyToCommit, Lock,
    SharedLock, Unlock;
  protected: Initialize;
  protected: LockHook, SharedLockHook, UnlockHook;
  protected: ResetLock;
  protected: LockingTransaction, SharedLockingTransactions, Unlocked;

    OIDSet <global ModedPTransaction> SharedLockingTransactions;

    void SharedLockHook (global ModedPTransaction t) : abstract;

    void Initialize () {
	SuperInitialize ();
	SharedLockingTransactions=>NewWithSize (2);
    }

    /* GetLockMode -- 0 for no lock : 1 for exclusive : 2 for shared */
    int GetLockMode () : global, locked {
	if (LockingTransaction != 0) {
	    return 1;
	} else if (SharedLockingTransactions->Size () > 0) {
	    return 2;
	} else {
	    return 0;
	}
    }

    void Lock (global PTransaction t) : global, locked {
	if (LockingTransaction != t) {
	    global ModedPTransaction mt;

	    mt = narrow (ModedPTransaction, t);
	    while (! (LockingTransaction == 0 &&
		      (SharedLockingTransactions->Size () == 0||
		       (SharedLockingTransactions->Size () == 1 &&
			SharedLockingTransactions->Includes (mt))))) {
		wait Unlocked;
	    }
	    LockHook (t);
	    if (SharedLockingTransactions->Includes (mt)) {
		SharedLockingTransactions->Remove (mt);
	    }
	    LockingTransaction = t;
	}
    }

    /* This method is for error recovery. */
    void ResetLock () : global, locked {
	if (LockingTransaction != 0) {
	    UnlockHook (LockingTransaction);
	    detach fork Abort (LockingTransaction);
	    LockingTransaction = 0;
	}
	if (SharedLockingTransactions->Size () > 0) {
	    global ModedPTransaction tounlock []
	      = SharedLockingTransactions->SetOfContents ();
	    unsigned int i, len = length tounlock;

	    for (i = 0; i < len; i ++) {
		UnlockHook (tounlock [i]);
		detach fork Abort (tounlock [i]);
	    }
	    SharedLockingTransactions->Clear ();
	}
	signalall Unlocked;
    }

    void SharedLock (global ModedPTransaction t) : global, locked {
	if (! SharedLockingTransactions->Includes (t)) {
	    while (LockingTransaction != 0) {
		wait Unlocked;
	    }
	    SharedLockHook (t);
	    SharedLockingTransactions->Add (t);
	}
    }

    void Unlock (global PTransaction t) : global, locked {
	if (LockingTransaction == t) {
	    UnlockHook (t);
	    LockingTransaction = 0;
	    signalall Unlocked;
	} else {
	    global ModedPTransaction mt;

	    mt = narrow (ModedPTransaction, t);
	    if (SharedLockingTransactions->Includes (mt)) {
		UnlockHook (mt);
		SharedLockingTransactions->Remove (mt);
		if (SharedLockingTransactions->Size () == 0) {
		    signalall Unlocked;
		}
	    }
	}
    }
}
/*
  Followings are still abstract:
  void Abort (global PTransaction t) : abstract;
  void Commit (global PTransaction t) : abstract;
  int IsReadyToCommit (global PTransaction t) : abstract;
  void LockHook (global PTransaction t) : abstract;
  void UnlockHook (global PTransaction t) : abstract;
*/
