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
 * cra.oz
 *
 * Class Request Agent
 */

class ClassRequestAgent :
  Class (rename New SuperNew;
	 rename Dump SuperDump;
	 rename Read SuperRead;),
  Alarmable
{
  constructor: New;
  public: AddName;  // From ResolvableObject
  public: Alarm, Hash, IsEqual;  // From Alarmable
  public: Distribute;  // Called when a broadcast is received
  public: Disable, Enable, IsReady;
  public: AddToDList, AppendToDList, ClearDList, GetDList, InsertToDList;
  public: AddToSList, AppendToSList, ClearSList, GetSList, InsertToSList;
  public: RemoveFromDList, SetDList;
  public: RemoveFromSList, SetSList;
  public: Dump, Read;

  protected: ForkDelegate, ForkDistribute;

/* instance variables */
  protected:
    Active, ClassRequestHistory, DList, DListSemaphore, ExpirationDuration,
    SList, SListSemaphore, aTimer;

    int Active;
    OrderedCollection <Set <String>> DList, SList;
    SharedAndExclusiveSemaphore DListSemaphore;
    SharedAndExclusiveSemaphore SListSemaphore;

    SimpleTable <global ClassID, FIFO <Date>> ClassRequestHistory;
    Time ExpirationDuration;

    Timer aTimer;

    /*
     * Class search limit:
     *   0 for never search abroad
     *   1 always search abroad
     *   n for search if n count of broadcast was caught in a certain duration
     */
    unsigned int ForeignClassSearchLimit;
    unsigned int LocalClassSearchLimit;
    
/* method implementations */
    void New () : global {
	SuperNew ("class-request-agent");
	AddName (ClassRequestAgentConstants::Name);
	Active = 0;
	DList=>New ();
	SList=>New ();
	DListSemaphore=>New ();
	SListSemaphore=>New ();
	ClassRequestHistory=>NewWithSize (64);
	LocalClassSearchLimit = 0; /* never search abroad for local class */
	ForeignClassSearchLimit = 2;
	ExpirationDuration=>NewFromTime (24, 0, 0);
			/* expire histories a day ago */
	Go ();
    }

    void Go () : global {
	StartTimer ();
	RegisterToNameDirectory ();
	Enable ();
    }

    void Removing () : global {
	Disable ();
	UnRegisterFromNameDirectory ();
	/* under construction */
    }

    void Stop () : global {
	Removing ();
	/* under construction */
    }

    void AddToDList (unsigned int at, Set <String> names) : global {
	DListSemaphore->ExclusiveEnter ();
	try {
	    DList->At (at)->AddAll (names);
	} except {
	    default {
		DListSemaphore->ExclusiveExit ();
	    }
	}
	DListSemaphore->ExclusiveExit ();
    }

    void AddToSList (unsigned int at, Set <String> names) : global {
	SListSemaphore->ExclusiveEnter ();
	try {
	    SList->At (at)->AddAll (names);
	} except {
	    default {
		SListSemaphore->ExclusiveExit ();
	    }
	}
	SListSemaphore->ExclusiveExit ();
    }

    void AppendToDList (Set <String> names) : global {
	DListSemaphore->ExclusiveEnter ();
	try {
	    DList->Add (names);
	} except {
	    default {
		DListSemaphore->ExclusiveExit ();
	    }
	}
	DListSemaphore->ExclusiveExit ();
    }

    void AppendToSList (Set <String> names) : global {
	SListSemaphore->ExclusiveEnter ();
	try {
	    SList->Add (names);
	} except {
	    default {
		SListSemaphore->ExclusiveExit ();
	    }
	}
	SListSemaphore->ExclusiveExit ();
    }

    void Alarm (unsigned int tick) {
	/* under construction */
	/* expiration of history */
    }

    void ClearDList () : global {
	/* under construction */
    }

    void ClearSList () : global {
	/* under construction */
    }

    int DecideIfSearchAbroad (global ClassID cid) : locked {
	unsigned int limit;

	if (IsForeignClass (cid)) {
	    limit = ForeignClassSearchLimit;
	} else {
	    limit = LocalClassSearchLimit;
	}

	if (limit > 0) {
	    Date current=>Current ();
	    FIFO <Date> item;

	    if (ClassRequestHistory->IncludesKey (cid)) {
		item = ClassRequestHistory->AtKey (cid);
	    } else {
		item=>New ();
		ClassRequestHistory->Add (cid, item);
	    }
	    item->Put (current);
	    return item->Size () >= limit;
	} else {
	    return 0;
	}
    }

    int DelegateToAbroad (global ClassID cid, global ObjectManager requester,
			  ArchitectureID arch) {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	int ret = 0;

	DListSemaphore->SharedEnter ();
	try {
	    Waiter w=>New ();
	    unsigned int i, size = DList->Size ();

	    for (i = 0; i < size; i ++) {
		Set <String> set = DList->At (i);
		String name;

		while (! w->Test () && ((name = set->RemoveAny ()) != 0)) {
		    detach
		      fork ForkDelegate (name, nd, cid, requester, arch, w);
		}
		detach fork w->Timer (10); /* 10 seconds */
		if (w->WaitAndTest ()) {
		    ret = 1;
		    break;
		}
	    }
	    if (! ret) {
		detach fork w->Timer (120); /* 2 minutes */
		if (w->WaitAndTest ()) {
		    ret = 1;
		}
	    }
	} except {
	    default {
		DListSemaphore->SharedExit ();
		raise;
	    }
	}
	DListSemaphore->SharedExit ();
	return ret;
    }

    void Disable () : global {
	Where ()->UnregisterClass (oid);
	Active = 0;
    }

    /* The ClassLookupper calls this method if a class searching */
    /* broadcast is received. */
    int Distribute (global ClassID cid, global ObjectManager requester,
		    ArchitectureID arch)
      : global {
	  if (DecideIfSearchAbroad (cid)) {
	      if (SearchAbroad (cid, requester, arch)) {
		  return 1;
	      } else {
		  return DelegateToAbroad (cid, requester, arch);
	      }
	  } else {
	      return 0;
	  }
      }

    void Dump (String file) : global {
	/* under construction */
    }

    void Enable () : global {
	Where ()->RegisterClass (oid);
	Active = 1;
    }

    void ForkDelegate (String name, global NameDirectory nd,
		       global ClassID cid, global ObjectManager request,
		       ArchitectureID arch, Waiter w) {
	global ResolvableObject ro;

	if ((ro = nd->Resolve (name)) != 0) {
	    if (narrow (ClassRequestAgent,
			ro)->Distribute (cid, request, arch)) {
		w->Done ();
	    }
	}
    }

    void ForkDistribute (String name, global NameDirectory nd,
			 global ClassID cid, global ObjectManager request,
			 ArchitectureID arch, Waiter w) {
	global ResolvableObject ro;

	if ((ro = nd->Resolve (name)) != 0) {
	    if (narrow (Class, ro)->Distribute (cid, request, arch)) {
		w->Done ();
	    }
	}
    }

    OrderedCollection <Set <String>> GetDList () : global {return DList;}
    OrderedCollection <Set <String>> GetSList () : global {return SList;}

    unsigned int Hash () {
	global Object o = oid;
	unsigned int ret;

	inline "C" {
	    ret = o & 0xffffffff;
	}
	return ret;
    }

    void InsertToDList (unsigned int at, Set <String> new_item) {
	/* under construction */
    }

    void InsertToSList (unsigned int at, Set <String> new_item) {
	/* under construction */
    }

    int IsEqual (Alarmable another) {return self == another;}

    int IsForeignClass (global ClassID cid) {
	global Object o = oid;
	int ans;

	inline "C" {
	    int here = ((o >> 48) & 0xffff);
	    int there = ((cid >> 48) & 0xffff);
	    ans = (here != there);
	}
	return ans;
    }

    int IsReady () : global {return Active;}

    void Read (String file) : global {
	/* under construction */
    }

    Set <String> RemoveFromDList (unsigned int at) : global {
	/* under construction */
    }

    Set <String> RemoveFromSList (unsigned int at) : global {
	/* under construction */
    }

    int SearchAbroad (global ClassID cid, global ObjectManager requester,
		      ArchitectureID arch) {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	int ret;

	SListSemaphore->SharedEnter ();
	try {
	    Waiter w=>New ();
	    unsigned int i, size = SList->Size ();

	    for (i = 0; i < size; i ++) {
		Set <String> set = SList->At (i);
		String name;

		while (! w->Test () && ((name = set->RemoveAny ()) != 0)) {
		    detach
		      fork ForkDistribute (name, nd, cid, requester, arch, w);
		}
		detach fork w->Timer (10); /* 10 seconds */
		if (w->WaitAndTest ()) {
		    ret = 1;
		    break;
		}
	    }
	    if (! ret) {
		detach fork w->Timer (120); /* 2 minutes */
		if (w->WaitAndTest ()) {
		    ret = 1;
		}
	    }
	} except {
	    default {
		SListSemaphore->SharedExit ();
		raise;
	    }
	}
	SListSemaphore->SharedExit ();
	return ret;
    }

    void SetDList (OrderedCollection <Set <String>> new_dlist) : global {
	/* under construction */
    }

    void SetSList (OrderedCollection <Set <String>> new_slist) : global {
	/* under construction */
    }

    void StartTimer () {
	aTimer=>New ();
	aTimer->Add (360, self);    /* alarmed once per an hour */
    }
}
