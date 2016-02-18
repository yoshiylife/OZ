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

class SimpleTable <String, TValue> {
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

    String KeyTable []; // Table size must be power of 2.
    TValue Table [];
    unsigned int Nbits;
    unsigned int NumberOfElement;

/* method implementations */
    void New () {
	Initialize (DefaultExpansionFactor (), DefaultInitialTableSize ());
    }

    void NewWithSize (unsigned int size) {
	Initialize (DefaultExpansionFactor (), size);
    }

    TValue Add (String k, TValue v) : locked {
	TValue ret;
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

    TValue AtKey (String k) : locked {
	unsigned int index = FindIndexOf (k);

	if (KeyTable [index] == 0) {
	    raise CollectionExceptions <String>::UnknownKey (k);
	} else {
	    return Table [index];
	}
    }

    TValue At (unsigned int i) : locked {
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

	String tmp_key_table [] = KeyTable;
	TValue tmp_table [] = Table;

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

    unsigned int FindIndexOf (String k) {
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
	raise CollectionExceptions <String>::InternalError (k);
    }

    int IncludesKey (String k) : locked {
	unsigned int i = FindIndexOf (k);

	if (length KeyTable <= i) {
	    debug {
		inline "C" {
		    OzDebugf ("SimpleTable::IncludesKey: index error."
			      " Table = %x, i = %d\n", k, i);
		}
	    }
	    raise CollectionExceptions <String>::InternalError (k);
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

    String KeyAt (unsigned int i) : locked {return KeyTable [i];}

    TValue RemoveKey (String k) : locked {
	unsigned int index = FindIndexOf (k);

	if (KeyTable [index] == 0) {
	    raise CollectionExceptions <String>::UnknownKey (k);
	} else {
	    unsigned int size = length KeyTable;
	    unsigned int from = (index + 1) % size, to = index;
	    TValue ret = Table [index];

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

    String SetOfKeys ()[] : locked {
	String set [];
	unsigned int i, p;

	length set = NumberOfElement;
	for (i = 0, p = 0; p < NumberOfElement; i ++) {
	    String k = KeyTable [i];

	    if (k != 0) {
		set [p++] = k;
	    }
	}
	return set;
    }

    unsigned int Size () : locked {return NumberOfElement;}
}
