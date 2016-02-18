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
 * otentry.oz
 *
 * Object Table Entry
 */

inline "C" {
#include <oz++/object-type.h>
}

class ObjectTableEntry {
  constructor: New;
  public:
    Destroy, FlushIt, Initialize, InitialStatus, IsPermanent,
    IsSuspended, Load, Permanentize, QueuedInvocation, Remove, Restore,
    Resume, SetStatus, Shutdown, Suspend, Status, StopIt, Transientize,
    WasSafelyShutdown;

  protected:
    GoAndMelt, CellIn, ForkGoAndMelt, ForkWaitThread, ForkStop, ForkRemoving,
    ForkWaitMelted, WaitGoAndMelt, WaitMelted;


/* instance variables */
  protected:
    O, anExecutor, MyStatus, Permanent, Restoring, SafelyShutdowned,
    ShutdownSign, SomeoneFlushing, SomeoneRemoving, Suspending, CelledIn,
    Flushed, Loaded, Melted, Restored, Resumed, Suspension;

    global Object O;
    Executor anExecutor;
    int MyStatus;
    int Permanent, Restoring;
    int SafelyShutdowned, ShutdownSign;
    int SomeoneFlushing, SomeoneRemoving, Suspending;
    condition CelledIn, Flushed, Loaded, Melted, Restored, Resumed;
    SuspensionStateTransition Suspension;

/* method implementations */

    void New (global Object o, Executor e, int status) {

	Suspension=>New ();

	anExecutor = e;

	MyStatus = status;
	O = o;
	Permanent = 0;
	Restoring = 0;
	SafelyShutdowned = 0;
	ShutdownSign = 0;
	SomeoneFlushing = 0;
	SomeoneRemoving = 0;
	Suspending = 0;
    }

    void CellIn () {

	anExecutor->OzObjectTableCellIn (O);

	Signal (CelledIn);
    }

    void ChangeStatusInOT (int status) {

	anExecutor->ObjectTableChangeStatus (O, status);

    }

    void Destroy () {
	ObjectTableEntry ote = self;


	anExecutor = 0;

	inline "C" {
	    OzExecFree ((OZ_Pointer)ote);
	}
    }

    /*
     * Running and OrderStopped are flushable statuses.
     * If Frozen or Closed, no need to flush.
     * If in any other status listed above, wait for flushable
     * status.
     */
    void FlushIt () : locked {
	int flush, old_flag;

	if (! Permanent) {
	    raise ObjectManagerExceptions::NotPermanent (O);
	}

	if (SomeoneFlushing) {
	    wait Flushed;
	    return;
	}

	SomeoneFlushing = 1;
	switch (MyStatus) {
	  case ObjectStatus::Frozen:
	  case ObjectStatus::Closed:
	    SomeoneFlushing = 0;
	    signalall Flushed;
	    return;
	    break;
	  case ObjectStatus::Running:
	  case ObjectStatus::OrderStopped:
	    break;
	  case ObjectStatus::Melting:
	  case ObjectStatus::MeltingToStop:
	    wait Melted;
	    break;
	  case ObjectStatus::CellingIn:
	  case ObjectStatus::CellingInToStop:
	    wait CelledIn;
	    break;
	  case ObjectStatus::SwappedOut:
	    /* Cell-outed object should be loaded before */
	    /* flushing. Should be implemented in Beta version */
	    break;
	  case ObjectStatus::Removed:
	    raise ObjectManagerExceptions::UnknownObject (O);
	  default:
	    raise
	      ObjectManagerExceptions::FatalError("ObjectTableEntry::FlushIt");
	}
	debug (0, " Flushing %O....\n", O);

	anExecutor->OzObjectTableFlush (O);

	SomeoneFlushing = 0;
	signalall Flushed;
    }

    void ForkGoAndMelt (Waiter w) {
	ShutdownSign = 0;
	GoAndMelt ();
	w->Done ();
    }

    void ForkRemoving (Waiter w) {
	/* this method is guaranteed to be alone */
	O->Removing ();
	w->Done ();
    }

    void ForkStop (Waiter w) {
	/* this method is guaranteed to be alone */
	O->Stop ();
	w->Done ();
    }

    void ForkWaitMelted (Waiter w) : locked {
	wait Melted;
	w->Done ();
    }

    void ForkWaitThread (Waiter w) {
	/* this method is guaranteed to be alone */

	anExecutor->OzSchedulerWaitThread (O);

	w->Done ();
    }

    void GoAndMelt () {
	O->Go ();
	Melt ();
    }

    void Initialize () : locked {
	MyStatus = ObjectStatus::Frozen;
	SafelyShutdowned = ShutdownSign;
    }

    int InitialStatus () {return OTObjectStatus::OTQueue;}

    int IsPermanent () : locked {return Permanent;}

    int IsSuspended () : locked {return Suspension->IsSuspended ();}

    void Load () : locked {
	if (MyStatus == ObjectStatus::Frozen) {
	    MyStatus = ObjectStatus::Melting;

	    anExecutor->OzObjectTableLoad (O);

	    debug (0, "ObjectTableEntry::Load:loaded O = %O\n", O);
	    ShutdownSign = 0;
	    signalall Loaded;
	    detach fork GoAndMelt ();
	} else {
	    raise ObjectManagerExceptions::ObjectAlreadyLoaded (O);
	}
    }

    void Melt () : locked {
	debug (0, "ObjectTableEntry::Melt: O = %O\n", O);
	if (Suspending)
	  wait Resumed;
	MyStatus = ObjectStatus::Running;
	ChangeStatusInOT (OTObjectStatus::OTReady);
	debug (0, " Status Changed to Run: o = %O\n", O);
	signalall Melted;
    }

    int OrderStop (int removing) : locked {
	int ret;

	debug (0, "ObjectTableEntry::OrderStop: O = %O, Status = %d\n",
	       O, MyStatus);
	if (Suspending)
	  wait Resumed;
	SomeoneRemoving |= removing;
	switch (MyStatus) {
	  case ObjectStatus::Frozen:
	    if (SomeoneRemoving) {
		Waiter w=>New ();

		ret = 1;
		MyStatus = ObjectStatus::MeltingToStop;

		anExecutor->OzObjectTableLoad (O);

		debug (0, "ObjectTableEntry::OrderStop: ");
		debug (0, "frozen object was loaded.  O = %O\n", O);
		signalall Loaded;
		detach fork WaitGoAndMelt ();
		wait Melted;
		MyStatus = ObjectStatus::OrderStopped;
		ChangeStatusInOT (OTObjectStatus::OTStop);
	    } else {
		ret = 0;
		MyStatus = ObjectStatus::Closed;
		ChangeStatusInOT (OTObjectStatus::OTStop);
	    }
	    break;
	  case ObjectStatus::Melting:
	    ret = 1;
	    MyStatus = ObjectStatus::MeltingToStop;
	    detach fork WaitMelted ();
	    wait Melted;
	    MyStatus = ObjectStatus::OrderStopped;
	    ChangeStatusInOT (OTObjectStatus::OTStop);
	    break;
	  case ObjectStatus::MeltingToStop:
	    ret = 0;
	    wait Melted;
	    break;
	  case ObjectStatus::CellingIn:
	    ret = 1;
	    MyStatus = ObjectStatus::CellingInToStop;
	    wait CelledIn;
	    MyStatus = ObjectStatus::OrderStopped;
	    ChangeStatusInOT (OTObjectStatus::OTStop);
	    break;
	  case ObjectStatus::CellingInToStop:
	    ret = 0;
	    wait CelledIn;
	    break;
	  case ObjectStatus::Running:
	    ret = 1;
	    MyStatus = ObjectStatus::OrderStopped;
	    ChangeStatusInOT (OTObjectStatus::OTStop);
	    break;
	  case ObjectStatus::SwappedOut:
	    ret = 1;
	    MyStatus = ObjectStatus::CellingInToStop;
	    ChangeStatusInOT (OTObjectStatus::OTStop);
	    detach fork CellIn ();
	    wait CelledIn;
	    MyStatus = ObjectStatus::OrderStopped;
	    break;
	  case ObjectStatus::OrderStopped:
	  case ObjectStatus::Closed:
	    if (removing) {
		raise ObjectManagerExceptions::ClosedObject (O);
	    }
	    ret = 0;
	    break;
	  case ObjectStatus::Removed:
	    raise ObjectManagerExceptions::UnknownObject (O);
	    break;
	  default:
	    /* illegal object status; fatal */
	    raise
	      ObjectManagerExceptions
		::FatalError ("ObjectTableEntry::OrderStopped");
	    break;
	}
	return ret;
    }

    void Remove () {
	if (OrderStop (1)) {
	    Wait ();
	}
    }

    void QueuedInvocation () : locked {
	if (Suspending) {
	    wait Resumed;
	} else {
	    switch (MyStatus) {
	      case ObjectStatus::Frozen:
		detach fork Load ();
		wait Loaded;
		break;
	      case ObjectStatus::Melting:
	      case ObjectStatus::MeltingToStop:
		break;
	      case ObjectStatus::SwappedOut:
		MyStatus = ObjectStatus::CellingIn;
		detach fork CellIn ();
		wait CelledIn;
		break;
	      case ObjectStatus::CellingIn:
	      case ObjectStatus::CellingInToStop:
		wait CelledIn;
		break;
	      default:
		/* status was already changed to non-queue */
		break;
	    }
	}
    }

    void Permanentize () : locked {Permanent = 1;}

    void RemoveObjectImageFile () {
	FileOperators fops;
	String path, exid;

	path=>NewFromArrayOfChar ("images/");
	exid=>OIDtoHexa (O);
	path = path->Concatenate (exid->GetSubString (4, 6));
	path = path->ConcatenateWithArrayOfChar ("/objects/");
	path = path->Concatenate (exid->GetSubString (11, 6));
	if (fops.IsExists (path)) {
	    fops.Remove (path);
	}
    }

    void Restore () : locked {
	if (Restoring) {
	    wait Restored;
	} else {
	    Restoring = 1;
	    StopIt ();
	    Restoring = 0;
	    MyStatus = ObjectStatus::Frozen;
	    detach fork Load ();
	    wait Loaded;
	    signalall Restored;
	}
    }

    void Resume () : locked {
	int ret;

	Suspension->ResumeStart ();
	switch (MyStatus) {
	  case ObjectStatus::Frozen:
	  case ObjectStatus::SwappedOut:
	  case ObjectStatus::CellingIn:
	  case ObjectStatus::CellingInToStop:
	  case ObjectStatus::Closed:
	  case ObjectStatus::Removed:
	    raise
	      ObjectManagerExceptions::FatalError ("Illegal Status");
	    break;
	  case ObjectStatus::Melting:
	  case ObjectStatus::MeltingToStop:
	  case ObjectStatus::OrderStopped:
	    break;
	  case ObjectStatus::Running:
	    break;
	  default:
	    raise ObjectManagerExceptions::FatalError ("Invalid Status");
	}
	switch (

		ret = anExecutor->OzObjectTableResume (O)

		) {
	  case 0:
	    Suspension->Resumed ();
	    Suspending = 0;
	    signalall Resumed;
	    break;
	  case -1:
	    raise ObjectManagerExceptions::UnknownObject (O);
	    break;
	  default:
	    if (ret > 0) {
		raise
		ObjectManagerExceptions::FatalError ("Double Resumption");
	    } else {
		raise
		ObjectManagerExceptions::FatalError ("Not a Defined Error");
	    }
	    break;
	}
    }

    void SetStatus (int s) : locked {MyStatus = s;}

    void Shutdown () {
	debug (0, "ObjectTableEntry::Shutdown.\n");
	if (OrderStop (0)) {
	    Wait ();
	}
    }

    void Signal (condition c) : locked {signal c;}

    void Sleep (unsigned int interval) {
	inline "C" {
	    OzSleep (interval);
	}
    }

    void Suspend () : locked {
	int ret;

	Suspension->SuspendStart ();
	switch (MyStatus) {
	  case ObjectStatus::Frozen:
	    detach fork Load ();
	    wait Loaded;
	    break;
	  case ObjectStatus::Melting:
	  case ObjectStatus::MeltingToStop:
	  case ObjectStatus::Running:
	    break;
	  case ObjectStatus::SwappedOut:
	    detach fork CellIn ();
	    wait CelledIn;
	    break;
	  case ObjectStatus::CellingIn:
	  case ObjectStatus::CellingInToStop:
	    wait CelledIn;
	    break;
	  case ObjectStatus::OrderStopped:
	    break;
	  case ObjectStatus::Closed:
	    Suspension->SuspendFailed ();
	    raise ObjectManagerExceptions::ClosedObject (O);
	    break;
	  case ObjectStatus::Removed:
	    Suspension->SuspendFailed ();
	    raise ObjectManagerExceptions::UnknownObject (O);
	    break;
	}
	switch (

		ret = anExecutor->OzObjectTableSuspend (O)

		) {
	  case 0:
	    Suspension->Suspended ();
	    Suspending = 1;
	    break;
	  case -1:
	    Suspension->SuspendFailed ();
	    raise ObjectManagerExceptions::UnknownObject (O);
	    break;
	  case -2:
	    Suspension->SuspendFailed ();
	    raise ObjectManagerExceptions::FatalError ("Not Loaded");
	    break;
	  default:
	    if (ret > 1) {
		raise
		ObjectManagerExceptions::FatalError ("Double Suspension");
	    } else {
		raise ObjectManagerExceptions::FatalError ("Nazono error");
	    }
	    break;
	}
    }

    int Status () : locked {return MyStatus;}

    void StopIt () {
	Shutdown ();
	SetStatus (ObjectStatus::Frozen);
	ChangeStatusInOT (OTObjectStatus::OTQueue);
    }

    void Transientize () : locked {Permanent = 0;}

    void Wait () {
	/* this method is guaranteed to be alone */
	int flag = 1;

	flag &= WaitThread ();
	SetStatus (ObjectStatus::Removed);
	if (SomeoneRemoving || ! (Permanent || Restoring)) {
	    flag &= WaitRemoving ();
	    if (!

		anExecutor->OzObjectTableRemove (O)

		) {
		RemoveObjectImageFile ();
	    }
	} else {
	    flag &= WaitStop ();
	    SetStatus (ObjectStatus::Closed);
	    if (! Restoring && flag) {

		anExecutor->OzObjectTableFlush (O);

	    }
	}
	ShutdownSign = flag && (MyStatus == ObjectStatus::Closed
				|| MyStatus == ObjectStatus::Removed);
    }

    int Wait20 (void@ p, Waiter w) {
	int res;

	detach fork w->Timer (20); /* 20 seconds */
	res = w->WaitAndTest ();
	try {
	    if (res) {
		join p;
	    } else {
		kill p;
		detach p;
	    }
	} except {
	    default {}
	}
	return res;
    }

    void WaitGoAndMelt () {
	void@ p;
	Waiter w=>New ();

	p = fork ForkGoAndMelt (w);
	if (! Wait20 (p, w)) {
	    Melt ();
	}
    }

    void WaitMelted () {
	void@ p;
	Waiter w=>New ();

	p = fork ForkWaitMelted (w);
	if (! Wait20 (p, w)) {
	    Melt ();
	}
    }

    int WaitRemoving () {
	/* this method is guaranteed to be alone */
	void@ p;
	Waiter w=>New ();

	p = fork ForkRemoving (w);
	return Wait20 (p, w);
    }

    int WaitStop () {
	/* this method is guaranteed to be alone */
	void@ p;
	Waiter w=>New ();

	p = fork ForkStop (w);
	return Wait20 (p, w);
    }

    int WaitThread () {
	/* this method is guaranteed to be alone */
	void@ p;
	Waiter w=>New ();

	p = fork ForkWaitThread (w);
	return Wait20 (p, w);
    }

    int WasSafelyShutdown () {return SafelyShutdowned;}
}
