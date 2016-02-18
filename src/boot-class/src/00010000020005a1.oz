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
 * assoc.oz
 *
 * Association of key and value.
 * Element of dictionary as set.
 */

/* TYPE PARAMETERS: TKey,TValue */

class Assoc <String, global DirectoryServer<T>> {
  constructor: New;
  public: Compare, Hash, IsEqual, Key, SetKey, Value, SetValue;

/* instance variables */
    String aKey;
    global DirectoryServer<T> aValue;

/* method implementations */
    void New (String key, global DirectoryServer<T> value) {
	aKey = key;
	aValue = value;
    }

    int Compare (Assoc <String, global DirectoryServer<T>> assoc) {
	return aKey->Compare (assoc->Key ());
    }

    unsigned int Hash () {return aKey->Hash ();}

    int IsEqual (Assoc <String, global DirectoryServer<T>> assoc) {
	return aKey->IsEqual (assoc->Key ());
    }

    String Key () {return aKey;}

    String SetKey (String new_key) {
	String temp = aKey;

	aKey = new_key;
	return temp;
    }

    global DirectoryServer<T> Value () {return aValue;}

    global DirectoryServer<T> SetValue (global DirectoryServer<T> new_value) {
	global DirectoryServer<T> tmp = aValue;
	aValue = new_value;
	return tmp;
    }
}
