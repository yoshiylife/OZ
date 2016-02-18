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

/*
 * oidset.oz
 *
 * Simple set of OID.
 * Generic class.
 */

/* TYPE PARAMETERS: TContent */

inline "C" {
#include <oz++/object-type.h>
}

class OIDSet <global ClassID> {
/* interface */
  constructor: New, NewWithSize;
  public:
    Add, AddArray, At, Capacity, Clear, Includes, Remove, RemoveArray,
    SetOfContents, Size;
  protected:
    AddImplementation, DefaultExpansionFactor, DefaultInitialTableSize,
    Expand, FindIndexOf, Initialize, RemoveImplementation;

/* instance variables */
  protected:
    ExpansionFactor, InitialTableSize, Nbits, NumberOfElement, Table;

    unsigned int ExpansionFactor; /* = 2; */
    unsigned int InitialTableSize; /* = 16; */

    unsigned int Nbits;
    unsigned int NumberOfElement;
    global ClassID Table []; // The table size must be power of 2

/* method implementations */
    void New () {
	Initialize (DefaultExpansionFactor (), DefaultInitialTableSize ());
    }

    void NewWithSize (unsigned int size) {
	Initialize (DefaultExpansionFactor (), size);
    }

    global ClassID Add (global ClassID v) : locked {
	return AddImplementation (v);
    }

    void AddArray (global ClassID array []) : locked {
	unsigned int i, len = length array;

	for (i = 0; i < len; i ++) {
	    AddImplementation (array [i]);
	}
    }

    global ClassID AddImplementation (global ClassID v) {
	unsigned int index = FindIndexOf (v);
	global ClassID ret = Table [index];

	if (ret == 0) {
	    NumberOfElement ++;
	}
	Table [index] = v;
	return ret;
    }

    global ClassID At (unsigned int i) : locked {return Table [i];}

    void Clear () : locked {
	unsigned int i, size = length Table;
	global ClassID tmp_table [] = Table;

	length Table = 0;
	length Table = size;
	inline "C" {
	    OzExecFree ((OZ_Pointer)tmp_table);
	}
    }

    unsigned int DefaultExpansionFactor () {return 2;}
    unsigned int DefaultInitialTableSize () {return 16;}

    void Expand () {
	unsigned int capacity = length Table;
	unsigned int new_capacity = capacity * ExpansionFactor;
	unsigned int i;
	global ClassID tmp_table [] = Table;

	length Table = 0;
	length Table = new_capacity;
	for (Nbits = 0, -- new_capacity;
	     new_capacity != 0; new_capacity >>= 1) {
	    Nbits ++;
	}
	for (i = 0; i < capacity; i++) {
	    if (tmp_table [i] != 0) {
		unsigned int index = FindIndexOf (tmp_table [i]);

		Table [index] = tmp_table [i];
		tmp_table [i] = 0;
	    }
	}
	inline "C" {
	    OzExecFree ((OZ_Pointer)tmp_table);
	}
    }

    unsigned int Capacity () : locked {return length Table;}

    unsigned int FindIndexOf (global ClassID k) {
	unsigned int i, mod, size = length Table, n;

	if (NumberOfElement > size / ExpansionFactor) {
	    Expand ();
	    size = length Table;
	}
	n = Nbits;
	inline "C" {
	    mod = ((0x9E3779B9 * (unsigned int) k) >> (32 - n)) & (size - 1);
	}
	for (i = mod; i != mod - 1 ; (++i == size) && (i = 0)) {
	    if (Table [i] == 0 || Table [i] == k) {
		return i;
	    }
	}
	if (Table [i] == 0 || Table [i] == k) {
	    return i;
	} else {
	    raise CollectionExceptions <global ClassID>::InternalError (k);
	}
    }

    int Includes (global ClassID k) : locked {
	unsigned int i = FindIndexOf (k);

	if (length Table <= i) {
	    debug {
		inline "C" {
		    OzDebugf ("OIDSet::Includes: index error."
			      " Table = %x, i = %d\n", k, i);
		}
	    }
	    raise CollectionExceptions<global ClassID>::InternalError (k);
	}
	return Table [i] != 0;
    }

    void Initialize (unsigned int expansion_factor,
		     unsigned int initial_table_size) {
	unsigned int size;

	ExpansionFactor = expansion_factor;
	for (size = 2; size < initial_table_size; size = size << 1)
	  ;
	InitialTableSize = size;
	length Table = size;
	for (Nbits = 0, -- size; size != 0; size >>= 1) {
	    Nbits ++;
	}
	NumberOfElement = 0;
    }

    global ClassID Remove (global ClassID v) : locked {
	unsigned int index = FindIndexOf (v);

	if (Table [index] == 0) {
	    raise CollectionExceptions <global ClassID>::UnknownKey (v);
	} else {
	    return RemoveImplementation (v, length Table, index);
	}
    }

    void RemoveArray (global ClassID array []) : locked {
	unsigned int i, len = length array;
	unsigned int size = length Table;

	for (i = 0; i < len; i ++) {
	    global ClassID c = array [i];
	    unsigned int index = FindIndexOf (c);

	    if (Table [index] != c) {
		raise CollectionExceptions <global ClassID>::UnknownKey (c);
	    }
	}
	for (i = 0; i < len; i ++) {
	    RemoveImplementation (array [i], size, FindIndexOf (array [i]));
	}
    }

    global ClassID RemoveImplementation (global ClassID v, unsigned int size,
				   unsigned int index) {
	unsigned int from = (index + 1) % size, to = index;
	global ClassID ret = Table [index];

	Table [to] = 0;
	while (Table [from] != 0) {
	    unsigned int index2;

	    index2 = FindIndexOf (Table [from]);
	    if (index2 == to) {
		Table [to] = Table [from];
		to = from;
		Table [to] = 0;
	    }
	    from = (from + 1) % size;
	}
	-- NumberOfElement;
	return ret;
    }

    global ClassID SetOfContents ()[] : locked {
	global ClassID set [];
	unsigned int i, p;

	length set = NumberOfElement;
	for (i = 0, p = 0; p < NumberOfElement; i ++) {
	    global ClassID k = Table [i];

	    if (k != 0) {
		set [p++] = k;
	    }
	}
	return set;
    }

    unsigned int Size () : locked {return NumberOfElement;}
}
