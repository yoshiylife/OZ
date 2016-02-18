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

//#define NORECORDACOPS

// we use broadcast
//#define NOBROADCAST

// we flush objects
//#define NOFLUSH

// we don't test flush
//#define FLUSHTESTATSTARTING

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

// we have bug in alias


// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we distribute class not by tar'ed directory


// we have a bug in class StreamBuffer


// we have no support for getting executor ID


// we use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in gen-spec-src


// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we use the new ObjectManager::NewObject
//#define NONEWNEWOBJECT

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have two typos in executor::file.c
//#define NOBUGINFILEC
/*
 * waiter.oz
 *
 * Wait something
 */

class Waiter {
  constructor: New;
  public: Abort, Done, Timer, WaitAndTest;

/* instance variables */
  protected: Aborted, Finished, Lock;

    int Aborted;
    int Finished;
    condition Lock;

/* method implementations */
    void New () {Aborted = 0; Finished = 0;}
    void Abort () : locked {
	if (! Finished) {
	    Aborted = 1;
	    signalall Lock;
	}
    }
    void Done () : locked {Finished = 1; signalall Lock;}
    void Timer (unsigned int interval) {
	inline "C" {
	    OzSleep (interval);
	}
	Abort ();
    }
    int WaitAndTest () : locked {
	if (! Aborted && ! Finished) {
	    wait Lock;
	}
	return Finished;
    }
}
