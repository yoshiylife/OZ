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
 * starray.oz
 *
 * Cheap array of array of char.
 */

class StringArray : SimpleArray <char []> {
/* interface */
  constructor: New, NewWithConstants, NewWithSize;
  public:
    Add, AsArray, At, Capacity, Clear, Content, Includes, Lookup, Remove,
    RemoveAt, Set, Size;
  protected:
    DefaultExpansionFactor, DefaultInitialTableSize,
    DefaultShrinkFactor, DefaultShrinkThreshold,
    Expand, Initialize, Shrink;

/* instance variables */
  protected:
    ExpansionFactor, InitialTableSize, NumberOfElement,
    ShrinkFactor, ShrinkThreshold, Table;

/* method implementations */
    int Includes (char c []) {
	ArrayOfCharOperators acops;
	unsigned int i;


	for (i = 0; i < NumberOfElement; i ++) {

	    if (acops.IsEqual (Table [i], c)) {
		return 1;
	    }

	}
	return 0;
    }

    unsigned int Lookup (char c []) {
	ArrayOfCharOperators acops;
	unsigned int i;


	for (i = 0; i < NumberOfElement; i ++) {
	    if (

		acops.IsEqual (Table [i], c)

		) {
		return i;
	    }
	}
	return i;
    }

    char Remove (char c [])[] {
	ArrayOfCharOperators acops;
	unsigned int index = Lookup (c);


	if (index != length Table

	    && acops.IsEqual (Table [index], c)

	    ) {
	    return RemoveAt (index);
	} else {
	    raise CollectionExceptions <char []>::ElementNotFound (c);
	}
    }
}


