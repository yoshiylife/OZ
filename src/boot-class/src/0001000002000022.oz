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

/*
 * bcparam.oz
 *
 * Broadcast Parameter Holder
 */


class BroadcastParameter {
  constructor: New;
  public: GetSender, GetID, GetParam1, GetParam2,
          SetSender, SetID, SetParam1, SetParam2;

/* members */
    /*
      Param1: 0 for name directory lookup
              any ClassID for class lookup
      Param2: architecture ID for class lookup
      */
    global ObjectManager Sender;
    unsigned int ID;
    global ClassID Param1;
    ArchitectureID Param2;


/* method implementations */
    void New (global ObjectManager sender, unsigned int id,
	      global ClassID cid, ArchitectureID aid) {
	SetSender (sender);
	SetID (id);
	SetParam1 (cid);
	SetParam2 (aid);
    }
    global ObjectManager GetSender () {return Sender;}
    int GetID () {return ID;}
    global ClassID GetParam1 () {return Param1;}
    ArchitectureID GetParam2 () {return Param2;}
    void SetSender (global ObjectManager sender) {Sender = sender;}
    void SetID (int id) {ID = id;}
    void SetParam1 (global ClassID p1) {Param1 = p1;}
    void SetParam2 (ArchitectureID p2) {Param2 = p2;}

}
