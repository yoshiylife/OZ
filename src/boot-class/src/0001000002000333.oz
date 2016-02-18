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
 * range.oz
 *
 * Integer range.
 */

class Range {
  constructor: New, NewWithRange;
  public:
    Assign, CheckValidity, FirstIndex, Hash, IsEqual, IsIncluded,
    IsNotEqual, LastIndex, Length, SetFirstIndex, SetLastIndex,
    SetLength;

  protected: First, Len;

/* instance variables */
    int First, Len;

/* method implementations */
    void New () {First = 0, Len = -1;}

    void NewWithRange (int f, int l) {First = f, Len = l;}

    void Assign (Range r) {
	First = r->FirstIndex ();
	Len = r->Length ();
    }

    int CheckValidity () {return Len >= 0;}

    int FirstIndex () {return First;}

    unsigned int Hash () {return First ^ Len;}

    int IsEqual (Range r) {
	return ((First == r->FirstIndex ()) && (Len == r->Length ()));
    }

    int IsIncluded (Range r) {
	return ((First >= r->FirstIndex ())
		&& (First + Len <= r->FirstIndex () + r->Length ()));
    }

    int IsNotEqual (Range r) {return ! IsEqual (r);}

    int LastIndex () {return First + Len - 1;}

    int Length () {return Len;}

    int SetFirstIndex (int f) {return First = f;}

    int SetLastIndex (int i) {Len = i - First + 1; return i;}

    int SetLength (int l) {return Len = l;}
}
