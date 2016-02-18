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


// we use exceptions with parameters
//#define NOEXCEPTIONPARAMETER

// we use broadcast
//#define NOBROADCAST

// we flush objects
//#define NOFLUSH

// we don't test flush
//#define FLUSHTESTATSTARTING

// we are debugging
//#define NDEBUG

// we have a bug in remote instantiation


// we lookup configuration table for configured class ID


// we don't list directory by unix 'ls' command, but opendir library
//#define LISTBYLS

// we need change directory to $OZHOME before OzRead and OzSpawn


// we don't use OzRemoveCode
//#define USEOZREMOVECODE

// we don't read parents version IDs from private.i.
//#define READPARENTSFROMPRIVATEDOTI

// we have bug in alias
//#define NOALIASBUG

// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we distribute class not by tar'ed directory


// we have bug in StreamBuffer


// we have no support for getting executor ID


// we don't use Object::GetPropertyPathName

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
