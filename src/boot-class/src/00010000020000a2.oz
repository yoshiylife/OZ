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


// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we distribute class not by tar'ed directory


// we have bug in StreamBuffer


// we have no support for getting executor ID


// we don't use Object::GetPropertyPathName


// we have a bug in gen-spec-src


// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG
/*
 * cnote.oz
 *
 * Notifier window for class distribution
 */

class NotifierWindow {
  constructor: New;
  public: ID, Mawaru, Quit, Spawn, Tomaru;

  protected: TomaruImpl, IDImpl, MawaruImpl;


/* instance variables */
    UnixIO Command;
    int Idle;
    int WaitingID;
    condition Done;

    UnixIO Debug;


/* method implementations */
    void New () {}

    void ID (global ClassID cid) {detach fork IDImpl (cid);}

    void IDImpl (global ClassID cid) : locked {
	while (! WaitingID) {
	    signal Done;
	    wait Done;
	}
	Command->PutStr ("ID ")->PutOID (cid)->PutReturn ();

	Debug->PutStr ("ID ")->PutOID (cid)->PutReturn ();

	WaitingID = 0;
	signal Done;
    }

    void Mawaru () {detach fork MawaruImpl ();}

    void MawaruImpl () : locked {
	while (! Idle) {
	    signal Done;
	    wait Done;
	}
	Command->PutStr ("mawaru\n");
	Idle = 0;
	WaitingID = 1;
	signal Done;
    }

    void Quit () {Command->PutStr ("quit\n")->Close ();}

    void Spawn () {
	char argv [][];

	Idle = 1;
	WaitingID = 0;
	length argv = 1;
	argv [0] = "kurukuru";
	Command=>Spawn (argv);

	Debug=>New ();

    }

    void Tomaru () {detach fork TomaruImpl ();}

    void TomaruImpl () : locked {
	while (Idle || WaitingID) {
	    signal Done;
	    wait Done;
	}
	Command->PutStr ("tomaru\n");
	Idle = 1;
	signal Done;
    }
}
