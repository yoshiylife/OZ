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

// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we distribute class not by tar'ed directory


// we have a bug in class StreamBuffer


// we have no support for getting executor ID


// we use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// we have no str[fp]time


// boot classes are modifiable


// we don't expire configuration cache

/*
 * stable.oz
 *
 * Simple table whose key is a global object.
 * Generic class.
 */

/* TYPE PARAMETERS: TKey,TValue */

inline "C" {
#include <oz++/object-type.h>
}

class SimpleTable <global Class, int> {
/* interface */
  constructor: New, NewWithSize;
  public:
    Add, At, AtKey, Capacity, Clear, IncludesKey, KeyAt, RemoveKey, SetOfKeys,
    Size;
  protected:
    Expand, DefaultExpansionFactor, DefaultInitialTableSize, FindIndexOf,
    Initialize;

/* instance variables */
  protected:
    ExpansionFactor, InitialTableSize, KeyTable, Nbits, NumberOfElement, Table;

    unsigned int ExpansionFactor; /* = 2; */
    unsigned int InitialTableSize; /* = 128; */

    global Class KeyTable []; // Table size must be power of 2.
    int Table [];
    unsigned int Nbits;
    unsigned int NumberOfElement;

/* method implementations */
    void New () {
	Initialize (DefaultExpansionFactor (), DefaultInitialTableSize ());
    }

    void NewWithSize (unsigned int size) {
	Initialize (DefaultExpansionFactor (), size);
    }

    int Add (global Class k, int v) : locked {
	int ret;
	unsigned int index;

	index = FindIndexOf (k);
	if (KeyTable [index] != 0) {
	    ret = Table [index];
	} else {
	    ret = 0;
	    KeyTable [index] = k;
	    NumberOfElement ++;
	}
	Table [index] = v;
	return ret;
    }

    int AtKey (global Class k) : locked {
	unsigned int index = FindIndexOf (k);

	if (KeyTable [index] == 0) {
	    raise CollectionExceptions <global Class>::UnknownKey (k);
	} else {
	    return Table [index];
	}
    }

    int At (unsigned int i) : locked {
	if (KeyTable [i] == 0) {
	    return 0;
	} else {
	    return Table [i];
	}
    }

    void Clear () : locked {
	unsigned int i, size = length KeyTable;

	for (i = 0; i < size; i++) {
	    KeyTable [i] = 0;
	    Table [i] = 0;
	}
    }

    unsigned int DefaultExpansionFactor () {return 2;}
    unsigned int DefaultInitialTableSize () {return 128;}

    void Expand () {
	unsigned int capacity = length KeyTable;
	unsigned int new_capacity = capacity * ExpansionFactor;
	unsigned int i;

	global Class tmp_key_table [] = KeyTable;
	int tmp_table [] = Table;

	length KeyTable = 0;
	length KeyTable = new_capacity;
	length Table = 0;
	length Table = new_capacity;
	for (Nbits = 0, -- new_capacity;
	     new_capacity != 0; new_capacity >>= 1) {
	    Nbits ++;
	}
	for (i = 0; i < capacity; i++) {
	    if (tmp_key_table [i] != 0) {
		unsigned int index = FindIndexOf (tmp_key_table [i]);
		KeyTable [index] = tmp_key_table [i];
		Table [index] = tmp_table [i];
		tmp_key_table [i] = 0;
		tmp_table [i] = 0;
	    }
	}
	inline "C" {
	    OzExecFree ((OZ_Pointer)tmp_key_table);
	    OzExecFree ((OZ_Pointer)tmp_table);
	}
    }

    unsigned int Capacity () : locked {return length KeyTable;}

    unsigned int FindIndexOf (global Class k) {
	unsigned int i, mod, size = length KeyTable, n;

	if (NumberOfElement > size / ExpansionFactor) {
	    Expand ();
	    size = length KeyTable;
	}
	n = Nbits;
	inline "C" {
	    mod = ((0x9E3779B9 * (unsigned int) k) >> (32 - n)) & (size - 1);
	}
	for (i = mod; i != mod - 1 ; (++i == size) && (i = 0)) {
	    if (KeyTable [i] == 0 || KeyTable [i] == k) {
		return i;
	    }
	}
	raise CollectionExceptions <global Class>::InternalError (k);
    }

    int IncludesKey (global Class k) : locked {
	unsigned int i = FindIndexOf (k);

	if (length KeyTable <= i) {
	    debug {
		inline "C" {
		    OzDebugf ("SimpleTable::IncludesKey: index error."
			      " Table = %x, i = %d\n", k, i);
		}
	    }
	    raise CollectionExceptions <global Class>::InternalError (k);
	}
	return KeyTable [i] != 0;
    }

    void Initialize (unsigned int expansion_factor,
		     unsigned int initial_table_size) {
	unsigned int size;

	ExpansionFactor = expansion_factor;
	for (size = 2; size < initial_table_size; size = size << 1)
	  ;
	InitialTableSize = size;
	length KeyTable = size;
	length Table = size;
	for (Nbits = 0, -- size; size != 0; size >>= 1) {
	    Nbits ++;
	}
	NumberOfElement = 0;
    }

    global Class KeyAt (unsigned int i) : locked {return KeyTable [i];}

    int RemoveKey (global Class k) : locked {
	unsigned int index = FindIndexOf (k);

	if (KeyTable [index] == 0) {
	    raise CollectionExceptions<global Class>::UnknownKey (k);
	} else {
	    unsigned int size = length KeyTable;
	    unsigned int from = (index + 1) % size, to = index;
	    int ret = Table [index];

	    KeyTable [to] = 0;
	    Table [to] = 0;
	    while (KeyTable [from] != 0) {
		unsigned int index2;

		index2 = FindIndexOf (KeyTable [from]);
		if (index2 == to) {
		    KeyTable [to] = KeyTable [from];
		    Table [to] = Table [from];
		    to = from;
		    KeyTable [to] = 0;
		    Table [to] = 0;
		}
		from = (from + 1) % size;
	    }
	    -- NumberOfElement;
	    return ret;
	}
    }

    global Class SetOfKeys ()[] : locked {
	global Class set [];
	unsigned int i, p;

	length set = NumberOfElement;
	for (i = 0, p = 0; p < NumberOfElement; i ++) {
	    global Class k = KeyTable [i];

	    if (k != 0) {
		set [p++] = k;
	    }
	}
	return set;
    }

    unsigned int Size () : locked {return NumberOfElement;}
}
