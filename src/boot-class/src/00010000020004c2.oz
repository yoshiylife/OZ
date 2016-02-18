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


// we distribute class not by tar'ed directory


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

/*
 * sarray.oz
 *
 * Cheap array of '==' comparable entities.
 * Generic class.
 */

/* TYPE PARAMETERS: TContent */

inline "C" {
#include <oz++/object-type.h>
}

class SimpleArray <global ConfiguredClassID> {
/* interface */
  constructor: New, NewWithConstants, NewWithSize;
  public:
    Add, AddArray, AsArray, At, Capacity, Clear, Content, Includes, Lookup,
    Remove, RemoveAt, Set, Size;
  protected:
    DefaultExpansionFactor, DefaultInitialTableSize,
    DefaultShrinkFactor, DefaultShrinkThreshold,
    Expand, Initialize, Shrink;

/* instance variables */
  protected:
    ExpansionFactor, InitialTableSize, NumberOfElement,
    ShrinkFactor, ShrinkThreshold, Table;

    unsigned int ExpansionFactor; /* = 2; */
    unsigned int InitialTableSize; /* = 16; */
    int ShrinkFactor; /* = 2; */
    int ShrinkThreshold; /* = 4; */

    global ConfiguredClassID Table [];
    unsigned int NumberOfElement;

/* method implementations */
    void New () {
	Initialize (DefaultExpansionFactor (), DefaultInitialTableSize (),
		    DefaultShrinkFactor (), DefaultShrinkThreshold ());
    }

    void NewWithSize (unsigned int size) {
	Initialize (DefaultExpansionFactor (), size,
		    DefaultShrinkFactor (), DefaultShrinkThreshold ());
    }

    void NewWithConstants (unsigned int expansion_factor,
			   unsigned int initial_table_size,
			   unsigned int shrink_factor,
			   unsigned int shrink_threshold) {
	if (shrink_factor > shrink_threshold) {
	    raise
	      CollectionExceptions <global ConfiguredClassID>
		::InvalidIntParameter (shrink_threshold);
	}
	Initialize (expansion_factor, initial_table_size,
		    shrink_factor, shrink_threshold);
    }

    void Add (global ConfiguredClassID c) : locked {
	AddImpl (c);
    }

    void AddImpl (global ConfiguredClassID c) {
	unsigned int i = LookupImpl (c);

	if (i == length Table) {
	    Expand ();
	}
	if (Table [i] == 0) {
	    Table [i] = c;
	    NumberOfElement ++;
	}
    }

    void AddArray (global ConfiguredClassID a []) : locked {
	unsigned int i, len = length a;

	for (i = 0; i < len; i ++) {
	    AddImpl (a [i]);
	}
    }

    global ConfiguredClassID AsArray ()[] : locked {
	global ConfiguredClassID table [] = Table;

	length table = NumberOfElement;
	return table;
    }

    global ConfiguredClassID At (unsigned int i) : locked {
	if (i < NumberOfElement) {
	    return Table [i];
	} else {
	    raise CollectionExceptions <global ConfiguredClassID>::InvalidIntParameter (i);
	}
    }

    unsigned int Capacity () : locked {return length Table;}

    void Clear () : locked {
	unsigned int i, size = length Table;

	for (i = 0; i < size; i++) {
	    Table [i] = 0;
	}
	NumberOfElement = 0;
    }

    global ConfiguredClassID Content ()[] : locked {
	global ConfiguredClassID content [] = Table;

	length content = NumberOfElement;
	return content;
    }

    unsigned int DefaultExpansionFactor () {return 2;}
    unsigned int DefaultInitialTableSize () {return 16;}
    unsigned int DefaultShrinkFactor () {return 2;}
    unsigned int DefaultShrinkThreshold () {return 4;}

    void Expand () {
	unsigned int capacity = length Table;
	unsigned int new_capacity, i;
	global ConfiguredClassID tmp_table [] = Table;

	if (capacity == 0) {
	    length Table = InitialTableSize;
	} else {
	    length Table = capacity * ExpansionFactor;
	}
	for (i = 0; i < capacity; i ++) {
	    tmp_table [i] = 0;
	}
    }

    int Includes (global ConfiguredClassID c) : locked {
	unsigned int i;

	for (i = 0; i < NumberOfElement; i ++) {
	    if (Table [i] == c) {
		return 1;
	    }
	}
	return 0;
    }

    void Initialize (unsigned int expansion_factor,
		     unsigned int initial_table_size,
		     unsigned int shrink_factor,
		     unsigned int shrink_threshold) : locked {
	ExpansionFactor = expansion_factor;
	InitialTableSize = initial_table_size;
	ShrinkFactor = shrink_factor;
	ShrinkThreshold = shrink_threshold;
	length Table = InitialTableSize;
	NumberOfElement = 0;
    }

    unsigned int Lookup (global ConfiguredClassID c) : locked {return LookupImpl (c);}

    unsigned int LookupImpl (global ConfiguredClassID c) {
	unsigned int i;

	for (i = 0; i < NumberOfElement; i ++) {
	    if (Table [i] == c) {
		return i;
	    }
	}
	return i;
    }

    global ConfiguredClassID Remove (global ConfiguredClassID c) : locked {
	unsigned int index = LookupImpl (c);

	if (index != length Table && Table [index] == c) {
	    return RemoveAtImpl (index);
	} else {
	    raise CollectionExceptions <global ConfiguredClassID>::ElementNotFound (c);
	}
    }

    global ConfiguredClassID RemoveAt (unsigned int index) : locked {
	if (0 <= index && index < NumberOfElement) {
	    return RemoveAtImpl (index);
	} else {
	    raise CollectionExceptions <global ConfiguredClassID>::InvalidIntParameter (index);
	}
    }

    global ConfiguredClassID RemoveAtImpl (unsigned int index) {
	global ConfiguredClassID ret = Table [index];
	unsigned int i;

	for (i = index; i < NumberOfElement - 1; i++) {
	    Table [i] = Table [i + 1];
	}
	Table [i] = 0;
	-- NumberOfElement;
	if (NumberOfElement <= length Table / ShrinkThreshold) {
	    Shrink ();
	}
	return ret;
    }

    void Set (global ConfiguredClassID elements []) : locked {
	global ConfiguredClassID tmp [] = Table;
	unsigned int i, len;

	if (elements != 0) {
	    Table = elements;
	    NumberOfElement = length elements;
	    len = InitialTableSize;
	    while (len < NumberOfElement) {
		len *= ExpansionFactor;
	    }
	    length Table = len;
	} else {
	    raise CollectionExceptions <global ConfiguredClassID>::InvalidParameter;
	}
    }

    void Shrink () {
	global ConfiguredClassID tmp_table [];
	unsigned int i;
	unsigned int capacity = length Table;
	unsigned int new_capacity = capacity / ShrinkFactor;

	tmp_table = Table;
	length Table = new_capacity;
	for (i = 0; i < NumberOfElement; i ++) {
	    tmp_table [i] = 0;
	}
	inline "C" {
	    OzExecFree ((OZ_Pointer)tmp_table);
	}
    }

    unsigned int Size () : locked {return NumberOfElement;}
}
