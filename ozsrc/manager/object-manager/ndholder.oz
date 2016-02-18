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
 * ndholder.oz
 *
 * holder of name directory
 */

class NameDirectoryHolder : Exclusive (rename New SuperNew;), Alarmable {
  constructor: New;
  public:
    Capture, ChangeDomain, Get, Init, Peek, Reply, Set, SetDomainName,
    WhichDomain;
  protected: IsReady, MakeSure;
  public: Lock, Unlock;
  public: Alarm, Hash, IsEqual;

/* instance variables */
  protected:
    AlreadyCaptured, BroadcastManager, DomainName, DomainPath, aNameDirectory,
    Searching, aTimer;

    global NameDirectory aNameDirectory;
    NameDirectoryBroadcastManager BroadcastManager;
    condition Captured;
    int AlreadyCaptured;
    char DomainName [];
    char DomainPath [];
    Timer aTimer;
    unsigned int Interval;
    int Searching;

/* method implementations */

    void New (global NameDirectory nd, Executor e) {
	SuperNew ();
	aNameDirectory = nd;
	Init (e);
    }


    void Capture (Timer timer) : locked {
	Executor anExecutor;





	anExecutor=>New ();

	if (BroadcastManager == 0) {

	    BroadcastManager=>New (anExecutor);

	}
	AlreadyCaptured = 0;
	aTimer = timer;
	Interval = 1;		/* alarmed once per 1 * 10 seconds */
	aTimer->Add (Interval, self);
	if (aNameDirectory != 0) {
	    detach fork MakeSure (aNameDirectory);
	} else {
	    detach fork Alarm (1);
	}
	wait Captured;

	anExecutor->OzBroadcastReady ();

	debug (0, "NameDirectoryHolder::Capture: "
	       "the NameDirectory of domain %S was captured.\n",
	       DomainName);
    }

    char ChangeDomain (char new_domain [])[] : locked {
	ArrayOfCharOperators acops;

	DomainName = new_domain;
	if (new_domain == 0) {
	    DomainPath = 0;
	} else {
	    DomainPath = acops.Concatenate ("::", new_domain);
	    DomainPath = acops.Concatenate (DomainPath, ":name");
	}
	if (AlreadyCaptured) {
	    AlreadyCaptured = 0;
	    detach fork Capture (aTimer);
	}
	wait Captured;
	return DomainName;
    }

    global NameDirectory Get () : locked {
	if (! AlreadyCaptured) {
	    wait Captured;
	}
	return aNameDirectory;
    }


    void Init (Executor e) : locked {
	AlreadyCaptured = 0;
	Searching = 0;
	BroadcastManager=>New (e);
    }


    global NameDirectory IsReady (global NameDirectory nd, Waiter w) {
	while (nd != 0) {
	    try {
		nd->IsReady ();
	    } except {
		default {
		    w->Abort ();
		    return 0;
		}
	    }
	    if (DomainName != 0) {
		if (nd->WhichDomain ()->IsEqualToArrayOfChar (DomainName)) {
		    w->Done ();
		    return nd;
		} else {
		    nd = narrow (NameDirectory,
				 nd->ResolveWithArrayOfChar (DomainPath));
		}
	    } else {
		SetDomainName (nd->WhichDomain ()->Content ());
		w->Done ();
		return nd;
	    }
	}
	/* the name directory is not registrated to the DNS resolver */
	w->Done ();
	return 0;
    }

    void MakeSure (global NameDirectory nd) {
	Waiter w;
	global NameDirectory@ p;


	inline "C" {
	    _oz_debug_flag = 1;
	}

	if (TestAndSetSearching ()) {
	    try {
		w=>New ();
		p = fork IsReady (nd, w);
		detach fork w->Timer (30);
		/* wait 30 seconds if no response */
		if (w->WaitAndTest ()) {
		    global NameDirectory nd = join p;

		    if (nd != 0) {
			Lock ();
			try {
			    SignalCaptured (nd);
			    debug (0,
				   "NameDirectoryHolder: "
				   "name directory is ready (%O).\n", nd);
			} except {
			    default {
				Unlock ();
				raise;
			    }
			}
			Unlock ();
		    }
		} else {
		    debug (0,
			   "NameDirectoryHolder:: Couldn't capture "
			   "the NameDirectory of domain %S (%O).  "
			   "Continuing ...\n",
			   DomainName, nd);
		    kill p;
		    detach p;
		}
	    } except {
		default {
		    ResetSearching ();
		    raise;
		}
	    }
	    ResetSearching ();
	}
    }

    global NameDirectory Peek () : locked {
	if (AlreadyCaptured) {
	    return aNameDirectory;
	} else {
	    return 0;
	}
    }

    void Reply (global NameDirectory nd) {BroadcastManager->Reply (nd);}

    void ResetSearching () : locked {Searching = 0;}

    void Set (global NameDirectory nd) {
	Lock ();
	aNameDirectory = nd;
	Capture (aTimer);
	Unlock ();
    }

    void SetDomainName (char new_domain []) {
	ArrayOfCharOperators acops;

	Lock ();
	DomainName = new_domain;
	if (new_domain == 0) {
	    DomainPath = 0;
	} else {
	    DomainPath = acops.Concatenate ("::", new_domain);
	    DomainPath = acops.Concatenate (DomainPath, ":name");
	}
	Unlock ();
    }

    int TestAndSetSearching () : locked {
	if (Searching) {
	    return 0;
	} else {
	    Searching = 1;
	    return 1;
	}
    }

    char WhichDomain ()[] {return DomainName;}

    void SignalCaptured (global NameDirectory nd) : locked {
	AlreadyCaptured = 1;
	aNameDirectory = nd;
	signalall Captured;
    }

    void Alarm (unsigned int tick) {

	inline "C" {
	    _oz_debug_flag = 1;
	}

	if (AlreadyCaptured) {
	    aTimer->Delete (self);
	} else {
	    global NameDirectory nd;

	    debug (0, "NameDirectoryHolder: Searching NameDirectory of "
		   "domain %S\n", DomainName);
	    if (aNameDirectory != 0) {
		MakeSure (aNameDirectory);
	    }
	    nd = BroadcastManager->Broadcast (Where ());
	    if (nd != 0) {
		MakeSure (nd);
	    }
	    if (Interval < 4320) {
		if (tick > Interval * 6) {
		    aTimer->Delete (self);
		    Interval *= 6;
		    if (Interval > 4320) {
			Interval = 4320;
		    }
		    /* Interval never exceed a half of a day */
		    aTimer->Add (Interval, self);
		}
	    }
	}
    }

    unsigned int Hash () {return 0;}
    int IsEqual (Alarmable another) {return another == self;}
}
