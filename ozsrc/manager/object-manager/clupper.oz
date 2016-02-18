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
 * clupper.oz
 *
 * Class Lookupper
 * Lookupper for classes on local executor.
 */

inline "C" {
#include <oz++/object-type.h>
}

class ClassLookupper : Exclusive (rename New SuperNew;), Alarmable {
/* interface from super classes*/
  /* methods */
  public: Lock, Unlock;
  protected: SuperNew;

  public: Alarm, Hash, IsEqual;

  /* instance variables */
  protected: LockCondition, Locking;

/* interface from this class */
  constructor: New;
  public:
    AddRemoteClassName, Init, Distribute, LoadClassPart, Lookup,
    RegisterAsLocalClass, RegisterClass, Shutdown, UnregisterClass,
    WaitClassEmployment;
  protected:
    NextClass, NextLocalClass,
    DefaultInitialCapacityOfClassTable,
    DefaultInitialCapacityOfLocalClassTable,
    DefaultInitialCapacityOfPendingCalls,
    DefaultInitialCapacityOfRemoteClassNames;


  protected: EmployRemoteClasses, EmployRemoteClassEach, LoadIt;


/* instance variables */
  protected: /* constants */
    InitialCapacityOfClassTable, InitialCapacityOfLocalClassTable,
    InitialCapacityOfPendingCalls, InitialCapacityOfRemoteClassNames;

  protected:
    ClassTable, LocalClassTable, PendingCallCount, PendingCalls,
    PendingCallTimeouts, RemoteClassNames, aTimer;

    unsigned int InitialCapacityOfClassTable; /* = 16 */
    unsigned int InitialCapacityOfLocalClassTable; /* = 8 */
    unsigned int InitialCapacityOfPendingCalls; /* = 4 */
    unsigned int InitialCapacityOfRemoteClassNames; /* = 4 */

    SimpleArray <global Class> ClassTable;
    SimpleArray <global Class> LocalClassTable;
    global ClassID PendingCalls [];
    unsigned int PendingCallTimeouts [];
    unsigned int PendingCallCount;
    condition Loaded [][];
    StringArray RemoteClassNames;
    condition ClassHasCome;
    Timer aTimer;

/* method implementations */
    void New (Timer timer) {
	SuperNew ();
	InitialCapacityOfClassTable = DefaultInitialCapacityOfClassTable ();
	InitialCapacityOfLocalClassTable
	  = DefaultInitialCapacityOfLocalClassTable ();
	InitialCapacityOfPendingCalls =DefaultInitialCapacityOfPendingCalls ();
	InitialCapacityOfRemoteClassNames
	  = DefaultInitialCapacityOfRemoteClassNames ();
	ClassTable=>NewWithSize (InitialCapacityOfClassTable);
	LocalClassTable=>NewWithSize (InitialCapacityOfLocalClassTable);
	RemoteClassNames=>NewWithSize (InitialCapacityOfRemoteClassNames);
	Init (timer);
    }

    void Init (Timer timer) : locked {
	aTimer = timer;
	ClassTable->Clear ();
	LocalClassTable->Clear ();
	PendingCallCount = 0;
	length PendingCalls = InitialCapacityOfPendingCalls;
	length PendingCallTimeouts = InitialCapacityOfPendingCalls;
	length Loaded = 1;
	length Loaded [0] = InitialCapacityOfPendingCalls;
	detach fork EmployRemoteClasses ();
    }

    ClassLookupper AddRemoteClassName (char name []) {
	Lock ();
	if (! RemoteClassNames->Includes (name)) {
	    RemoteClassNames->Add (name);
	}
	Unlock ();
	return self;
    }

    void Alarm (unsigned int tick) : locked {
	unsigned int i, len = length PendingCalls;

	for (i = 0; i < len; i ++) {
	    if (PendingCalls [i] != 0) {
		if (-- PendingCallTimeouts [i] == 0) {
		    unsigned int l = InitialCapacityOfPendingCalls;

		    RemoveImpl (i);
		    signal Loaded [i / l] [i % l];
		}
	    }
	}
    }

    unsigned int DefaultInitialCapacityOfClassTable () {return 16;}
    unsigned int DefaultInitialCapacityOfLocalClassTable () {return 8;}
    unsigned int DefaultInitialCapacityOfPendingCalls () {return 4;}
    unsigned int DefaultInitialCapacityOfRemoteClassNames () {return 4;}

    void Distribute (global ClassID cid, global ObjectManager requester,
		     ArchitectureID arch) {
	global Class c;

	for (c = 0; (c = NextLocalClass (c)) != 0; ) {
	    if (c->Distribute (cid, requester, arch)) {
		break;
	    }
	}
    }

    void EmployRemoteClassEach (global NameDirectory nd, char name []) {
	global Class c = 0;

	while (c == 0) {
	    Sleep (5); /* 5 seconds */
	    c = narrow (Class, nd->ResolveWithArrayOfChar (name));
	}
	RegisterClass (c);
    }

    void EmployRemoteClasses () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	unsigned int i, size = RemoteClassNames->Size ();

	for (i = 0; i < size; i ++) {
	    detach fork EmployRemoteClassEach (nd, RemoteClassNames->At (i));
	}
    }

    void Expand () {
	length PendingCalls += InitialCapacityOfPendingCalls;
	length PendingCallTimeouts += InitialCapacityOfPendingCalls;
	length Loaded += 1;
    }

    global Class LoadClassPart (global ClassID cid, ArchitectureID arch,
				global Class from, char dir [], ClassPart cp) {
	global Class c;




	debug (0, "ClassLookupper::LoadClassPart: loading %O ...\n", cid);
	for (c = 0; (c = NextClass (c)) != 0;) {
	    try {
		if ((c = LoadClassPartImpl (c, cid, arch, from, dir, cp))!=0) {
		    debug (0, "ClassLookupper::LoadClassPart: "
			   "loading %O has finished.\n", cid);
		    return c;
		}
	    } except {
		ChildAborted {
		    debug (0, "ClassLookupper::LoadClassPart: "
			   "loading %O has failed.\n", cid);
		}
	    }
	}
	return 0;
    }

    global Class LoadClassPartImpl (global Class c, global ClassID cid,
				    ArchitectureID arch, global Class from,
				    char dir [], ClassPart cp)
      : locked {
	  unsigned int count = PendingCallCount ++;
	  unsigned int l = InitialCapacityOfPendingCalls;
	  void @p;

	  if (count == 0) {
	      aTimer->Add (6, self);  /* alarmed once per 60 seconds */
	  }
	  if (count == length PendingCalls) {
	      Expand ();
	  }
	  p = fork LoadIt (c, cid, arch, from, dir, cp, count);
	  PendingCalls [count] = cid;
	  detach p;
	  wait Loaded [count / l] [count % l];
	  if (PendingCalls [count] == cid) {
	      RemoveImpl (count);
	      return c;
	  } else {
	      kill p;
	      return 0;		/* continue */
	  }
      }

    void LoadIt (global Class c, global ClassID cid, ArchitectureID arch,
		 global Class from, char dir [], ClassPart cp,
		 unsigned int count) {
	try {
	    if (c->LookupClass (cid) == 0) {
		c->LoadClassPart (cid, arch, from, dir, cp);
		Signal (count);
	    } else {
		Remove (cid, count);
	    }
	} except {
	    default {
		Remove (cid, count);
	    }
	}
    }

    global Class Lookup (global ClassID cid, ArchitectureID arch) {
	global Class c;

	for (c = 0; (c = NextClass (c)) != 0;) {
	    if (c->LookupClass (cid) != 0) {
		if (arch->Get () == -1 ||
		    c->IsAvailableOn (cid, arch)) {
		    break;
		}
	    }
	}
	debug {
	    if (c != 0) {
		debug (0, "ClassLookupper::Lookup: returning %O\n", c);
	    }
	}
	return c;
    }

    global Class NextClass (global Class c) : locked {
	int size = ClassTable->Size ();
	unsigned int index;

	if (c == 0) {
	    if (size > 0) {
		return ClassTable->At (0);
	    } else {
		return 0;
	    }
	}
	index = ClassTable->Lookup (c);
	if (index < size - 1) {
	    return ClassTable->At (index + 1);
	} else {
	    return 0;
	}
    }

    global Class NextLocalClass (global Class c) : locked {
	int size = LocalClassTable->Size ();
	unsigned int index;

	if (size == 0) {
	    return 0;
	} else {
	    if (c == 0) {
		return LocalClassTable->At (0);
	    } else {
		index = LocalClassTable->Lookup(c);
		if (index < size - 1) {
		    return LocalClassTable->At (index + 1);
		} else {
		    return 0;
		}
	    }
	}
    }

    void RegisterAsLocalClass (global Class c) {
	global ObjectManager om = Where ();
	int res;

	Lock ();
	if (om->LookupObject (c) == 0) {
	    Unlock ();
	    raise ObjectManagerExceptions::NotLocal (c);
	}
	RegisterClassSub (c);
	RegisterAsLocalClassSub (c);
	Unlock ();
    }

    void RegisterAsLocalClassSub (global Class c) : locked {
	if (LocalClassTable->Includes (c)) {
	    return;
	}
	LocalClassTable->Add (c);
    }

    void RegisterClass (global Class c) {
	Lock ();



	RegisterClassSub (c);
	Unlock ();
    }

    void RegisterClassSub (global Class c) : locked {
	if (ClassTable->Includes (c)) {
	    return;
	}
	ClassTable->Add (c);
	signalall ClassHasCome;
    }

    void Remove (global ClassID cid, unsigned int count) : locked {
	unsigned int l = InitialCapacityOfPendingCalls;

	if (PendingCalls [count] == cid) {
	    RemoveImpl (count);
	    signal Loaded [count / l] [count % l];
	}
    }

    void RemoveImpl (unsigned int count) {
	PendingCalls [count] = 0;
	if (-- PendingCallCount == 0) {
	    aTimer->Delete (self);
	}
    }

    void Shutdown () {
	PendingCalls = 0;
	PendingCallTimeouts = 0;
	Loaded = 0;
    }

    void Signal (unsigned int count) : locked {
	unsigned int l = InitialCapacityOfPendingCalls;

	signal Loaded [count / l] [count % l];
    }

    void Sleep (unsigned int interval) {
	inline "C" {
	    OzSleep (interval);
	}
    }

    void UnregisterClass (global Class c) {
	Lock ();
	try {
	    ClassTable->Remove (c);
	    if (LocalClassTable->Includes (c)) {
		LocalClassTable->Remove (c);
	    }
	} except {
	    CollectionExceptions <global Class>::ElementNotFound (c) {
		Unlock ();
		raise ObjectManagerExceptions::UnknownObject (c);
	    }
	}
	Unlock ();
    }

    void WaitClassEmployment () : locked {
	if (ClassTable->Size () == 0) {
	    wait ClassHasCome;
	}
    }

    unsigned int Hash () {return 0;}
    int IsEqual (Alarmable another) {return another == self;}
}
