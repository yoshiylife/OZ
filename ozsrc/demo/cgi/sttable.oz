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

/*
 * sttable.oz
 *
 * Simple table whose key is a String.
 * Generic class
 */

/* TYPE PARAMETERS: TKey,TValue */

class SimpleStringTable <TValue> : SimpleTable <String, TValue> {
/* interface from superclasses */
  constructor: New, NewWithSize;
  public:
    Add, At, AtKey, Capacity, Clear, IncludesKey, KeyAt, RemoveKey,
    SetOfKeys, Size;
  protected:
    Expand, DefaultExpansionFactor, DefaultInitialTableSize, FindIndexOf,
    Initialize;

  /* instance variables */
  protected:
    ExpansionFactor, InitialTableSize, KeyTable, Nbits, NumberOfElement, Table;

/* no interface from this class */

/* no instance variable */

/* method implementations */
    unsigned int FindIndexOf (String k) {
	unsigned int i, h = k->Hash (), mod, size = length KeyTable, n = Nbits;

	if (NumberOfElement > size / ExpansionFactor) {
	    Expand ();
	    h = k->Hash ();
	    size = length KeyTable;
	    n = Nbits;
	}
	inline "C" {
	    mod = ((0x9E3779B9 * h) >> (32 - n)) % size;
	}
	for (i = mod; i != mod - 1 ; (++i == size) && (i = 0)) {
	    if (KeyTable [i] == 0 || KeyTable [i]->IsEqual (k)) {
		return i;
	    }
	}
	raise CollectionExceptions <String>::InternalError (k);
    }

    unsigned int DefaultInitialTableSize () {return 32;}
}
