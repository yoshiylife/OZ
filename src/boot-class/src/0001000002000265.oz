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
 * ndbcmng.oz
 *
 * BroadcastManager for name directory
 * should be implemented in Beta version
 */

class NameDirectoryBroadcastManager {
  constructor: New;
  public: Broadcast, Reply;
  protected: Status, NumberOfReaders, Written, Value, anExecutor;

  protected: Waker;


/* instance variables */
    int Status; /* 0 ... no session, 1 ... waiting reply, */
                /* 2 ... already replied */
    unsigned int NumberOfReaders;
    condition Written;
    global NameDirectory Value;
    Executor anExecutor;

/* method implementations */

    void New (Executor e) {
	anExecutor = e;
	NumberOfReaders = 0;
	Status = 0;
    }


    /* send broadcast message */
    global NameDirectory Broadcast (global ObjectManager sender) : locked {




	if (Status == 0) {
	    Status = 1;
	    NumberOfReaders = 0;

	    anExecutor->Broadcast (sender, 0, 0, 0);

	    detach fork Waker (Written, 2); /* 2 seconds */
	}
	if (Status == 1) {
	    ++ NumberOfReaders;
	    debug (0,
		   "NameDirectoryBroadcastManager::Broadcast: "
		   "++NumberOfReaders == %d.\n", NumberOfReaders);
	    wait Written;
	    if (-- NumberOfReaders == 0)
	      Status = 0;
	    debug (0,
		   "NameDirectoryBroadcastManager::Broadcast: "
		   "--NumberOfReaders == %d.\n", NumberOfReaders);
	}
	return Value;
    }

    /* reply of broadcast */
    void Reply (global NameDirectory nd) : locked {
	if (Status == 1) {
	    Value = nd;
	    Status = 2;
	    signalall Written;
	} /* else -- someone else has already written */
    }

    void Waker (condition Written, unsigned int interval) {
	inline "C" {
	    OzSleep (interval);
	}
	Reply (0);
    }
}
