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
 * suspendstoz
 *
 * State transition machine of suspension
 */

class SuspensionStateTransition {
  constructor: New;
  public:
    IsSuspended, Resumed, ResumeStart, Suspended, SuspendFailed,
    SuspendStart, WaitResumeIfSuspended;
  protected: Status, SuspensionComplete, ResumptionComplete;

/* instance variables */
    int Status;
    condition SuspensionComplete, ResumptionComplete;

/* method implementations */
    void New () {Status = ObjectSuspensionStatus::NotSuspend;}

    int IsSuspended () : locked {
	return
	  Status == ObjectSuspensionStatus::Suspending
	    || Status == ObjectSuspensionStatus::Suspend;
    }

    void Resumed () : locked {
	if (Status == ObjectSuspensionStatus::Resuming) {
	    Status = ObjectSuspensionStatus::NotSuspend;
	    signalall ResumptionComplete;
	} else {
	    raise ObjectManagerExceptions::FatalError
	            ("Resumed not resuming global object.");
	}
    }

    void ResumeStart () : locked {
	if (Status == ObjectSuspensionStatus::Suspending)
	  wait SuspensionComplete;
	if (Status != ObjectSuspensionStatus::Suspend)
	  raise ObjectManagerExceptions::ThereIsAnotherResumption;
	Status = ObjectSuspensionStatus::Resuming;
    }

    void Suspended () : locked {
	if (Status == ObjectSuspensionStatus::Suspending) {
	    Status = ObjectSuspensionStatus::Suspend;
	    signalall SuspensionComplete;
	} else {
	    raise ObjectManagerExceptions::FatalError
	            ("Suspended not suspending global object.");
	}
    }

    void SuspendFailed () : locked {
	if (Status == ObjectSuspensionStatus::Suspending) {
	    Status = ObjectSuspensionStatus::NotSuspend;
	    signalall SuspensionComplete;
	} else {
	    raise ObjectManagerExceptions::FatalError
	            ("Suspended not suspending global object.");
	}
    }

    void SuspendStart () : locked {
	if (Status == ObjectSuspensionStatus::Resuming)
	  wait ResumptionComplete;
	if (Status != ObjectSuspensionStatus::NotSuspend)
	  raise ObjectManagerExceptions::ThereIsAnotherSuspension;
	Status = ObjectSuspensionStatus::Suspending;
    }

    void WaitResumeIfSuspended () : locked {
	if (Status == ObjectSuspensionStatus::Suspending
	    || Status == ObjectSuspensionStatus::Suspend) {
	    wait ResumptionComplete;
	}
    }
}
