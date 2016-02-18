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
 * ocpackage.oz
 *
 * OriginalClassPackage
 */

class OriginalClassPackage
  : ClassPackage (alias Initialize SuperInitialize;)
{
  constructor: New, NewWithSize;
  public: Add, Capacity, Includes, Remove, SetOfContents, Size, Start;
  public: GetID, SetID;
  public:
    AddAndPropagate, AddMirror, Destroy, IncludesMirror, ListDeadList,
    ListToBePropagated, Modify, RemoveAndPropagate, RemoveFrom,
    RevisitDeadList, WhichMirrorMode;

  protected: DoFunction, FindIndexOf, Initialize;

/* instance variables */
    /* constants */
    int Content; // = 0;
    int Addition; // = 1;
    int Deletion; // = 2;
    Time PropagationLimit; // = 1 week;

    SimpleTable <global Class, int> ToBePropagated;
    SimpleTable <global Class, FIFO <MirrorOperation>> DeadList;
    int Propagating;
    condition PropagationEnd;

/* method implementations */

    void Initialize () {
	SuperInitialize ();
	Content = 0;
	Addition = 1;
	Deletion = 2;
	PropagationLimit=>NewFromTime (168, 0, 0); /* 1 week */
	ToBePropagated=>New ();
	DeadList=>New ();
	Propagating = 0;
    }

    void AddAndPropagate (global ClassID cids []) {
	SimpleTable <global Class, Waiter> wait_list;

	AddArray (cids);
	wait_list = Propagate (ToBePropagated->SetOfKeys (), Addition,
			       cids, MirrorModificationMode::DoNothing);
	Wait (wait_list, Addition, cids, MirrorModificationMode::DoNothing);
    }

    void AddMirror (global Class c, int mode) {ToBePropagated->Add (c, mode);}

    void AddToDeadList (global Class c, FIFO <MirrorOperation> queue) : locked{
	DeadList->Add (c, queue);
    }

    void CheckDeadList (global Class c, int operation,
			global ClassID argument [], int mode)
      : locked {
	  MirrorOperation mo;

	  if (DeadList->IncludesKey (c)) {
	      if (IsExpired (c)) {
		  Expire (c);
		  return;
	      }
	  } else {
	      FIFO <MirrorOperation> queue=>New ();

	      DeadList->Add (c, queue);
	  }
	  mo=>New (operation, argument, mode);
	  DeadList->AtKey (c)->Put (mo);
      }

    void CheckExpire (global Class c) : locked {
	if (IsExpired (c)) {
	    Expire (c);
	}
    }

    void Destroy () {
	global Class set [] = ToBePropagated->SetOfKeys ();
	unsigned int i, len = length set;

	for (i = 0; i < len; i ++) {
	    detach fork set [i]->UnsetMirrorImplementation (ID);
	}
    }

    void DoFunction (global Class c, Waiter w, int operation,
		     global ClassID arg [], int mode) {
	try {
	    switch (operation) {
	      case 0: // Content
		if (! c->UpdateMirror (ID, arg, mode)) {
		    RemoveFrom (c);
		}
		break;
	      case 1: // Addition
		c->AddMirrorMember (ID, arg);
		break;
	      case 2: // Deletion
		c->DeleteMirrorMember (ID, arg);
		break;
	    }
	} except {
	    default {
		w->Abort ();
		return;
	    }
	}
	w->Done ();
    }

    void Expire (global Class c) {
	if (ToBePropagated->IncludesKey (c)) {
	    ToBePropagated->RemoveKey (c);
	}
	DeadList->RemoveKey (c);
    }

    int IncludesMirror (global Class c) {
	return ToBePropagated->IncludesKey (c);
    }

    int IsExpired (global Class c) {
	Date current=>Current ();
	Time t =current->Difference (DeadList->AtKey (c)->Peek ()->GetDate ());

	return t->Compare (PropagationLimit) > 0;
    }

    global Class ListDeadList ()[] {return DeadList->SetOfKeys ();}

    global Class ListToBePropagated ()[] {return ToBePropagated->SetOfKeys ();}

    void FinishPropagation () : locked {
	Propagating = 0;
	signal PropagationEnd;
    }

    Waiter ForkMirrorFunction (global Class c, int operation,
			       global ClassID arg [], int mode) {
	Waiter w=>New ();

	detach fork DoFunction (c, w, operation, arg, mode);
	detach fork w->Timer (20); /* 20 seconds */
	return w;
    }

    void Modify (global ClassID cids [], int mode) {
	/* mode is the mirror modification mode */
	global Class set [] = ToBePropagated->SetOfKeys ();
	SimpleTable <global Class, Waiter> wait_list;

	wait_list = Propagate (set, Content, cids, mode);
	Wait (wait_list, Content, cids, mode);
    }

    SimpleTable <global Class, Waiter>
      Propagate (global Class set [], int operation,
		 global ClassID arg [], int mode) {
	  SimpleTable <global Class, Waiter> wait_list=>New ();
	  unsigned int i, len = length set;

	  StartPropagation ();
	  for (i = 0; i < len; i ++) {
	      Waiter w;

	      try {
		  w = ForkMirrorFunction (set [i], operation, arg, mode);
	      } except {
		  default {
		      CheckDeadList (set [i], operation, arg, mode);
		      w = 0;
		  }
	      }
	      if (w != 0) {
		  wait_list->Add (set [i], w);
	      }
	  }
	  FinishPropagation ();
	  return wait_list;
      }

    void RemoveAndPropagate (global ClassID cids []) {
	SimpleTable <global Class, Waiter> wait_list;

	RemoveArray (cids);
	wait_list = Propagate (ToBePropagated->SetOfKeys (), Deletion,
			       cids, MirrorModificationMode::DoNothing);
	Wait (wait_list, Deletion, cids, MirrorModificationMode::DoNothing);
    }

    FIFO <MirrorOperation> RemoveFromDeadList (global Class c) : locked {
	if (DeadList->IncludesKey (c)) {
	    return DeadList->RemoveKey (c);
	}
    }

    void RemoveFrom (global Class c) : locked {
	if (ToBePropagated->IncludesKey (c)) {
	    ToBePropagated->RemoveKey (c);
	    if (DeadList->IncludesKey (c)) {
		DeadList->RemoveKey (c);
	    }
	} else {
	    raise ClassExceptions::UnknownClassObject (c);
	}
    }

    void RevisitDeadList () {
	global Class classes [] = DeadList->SetOfKeys ();
	unsigned int i, len = length classes;

	for (i = 0; i < len; i ++) {
	    RevisitEach (classes [i]);
	}
    }

    void RevisitEach (global Class c) {
	FIFO <MirrorOperation> queue = RemoveFromDeadList (c);

	while (! queue->IsEmpty ()) {
	    MirrorOperation mo = queue->Peek ();
	    Waiter w;

	    StartPropagation ();
	    w = ForkMirrorFunction (c, mo->GetOperation (), mo->GetArgument (),
				    mo->GetModificationMode ());
	    FinishPropagation ();
	    if (w->WaitAndTest ()) {
		queue->Get ();
	    } else {
		CheckExpire (c);
		break;
	    }
	}
	if (! queue->IsEmpty ()) {
	    AddToDeadList (c, queue);
	}
    }

    void Start () : locked {Propagating = 0;}

    void StartPropagation () : locked {
	if (Propagating) {
	    wait PropagationEnd;
	}
	Propagating = 1;
    }

    void Wait (SimpleTable <global Class, Waiter> wait_list,
	       int operation, global ClassID arg [], int mode) {
	global Class set [] = wait_list->SetOfKeys ();
	unsigned int i, len = length set;

	for (i = 0; i < len ; i ++) {
	    Waiter w = wait_list->AtKey (set [i]);

	    if (w->WaitAndTest ()) {
		RemoveFromDeadList (set [i]);
	    } else {
		CheckDeadList (set [i], operation, arg, mode);
	    }
	}
    }

    int WhichMirrorMode (global Class c) : locked {
	if (ToBePropagated->IncludesKey (c)) {
	    return ToBePropagated->AtKey (c);
	} else {
	    raise ClassExceptions::UnknownClassObject (c);
	}
    }
}
