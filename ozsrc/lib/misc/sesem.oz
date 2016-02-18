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
 * sesem.oz
 *
 * Semaphore which has both Shared and Exclusive operations
 */

class SharedAndExclusiveSemaphore {
  constructor: New;
  public: ExclusiveEnter, ExclusiveExit, Reset, SharedEnter, SharedExit;

/* instance variables */
  protected: Accessing, NumberOfAccessor;

    condition Lock;
    int Accessing;
    int NumberOfAccessor;

/* method implementations */
    void New () {Reset ();}

    void ExclusiveEnter () : locked {
	while (Accessing || NumberOfAccessor)
	  wait Lock;
	Accessing = 1;
	/*
	  Another possible implementation:

	  while (Accessing)
	    wait Lock;
	    Accessing = 1;
	  while (NumberOfAccessor)
	    wait Lock;

	  which one is useful?
	  */
    }

    void ExclusiveExit () : locked {
	Accessing = 0;
	signal Lock;
    }

    void Reset () : locked {
	Accessing = 0;
	NumberOfAccessor = 0;
    }

    void SharedEnter () : locked {
	while (Accessing)
	  wait Lock;
	NumberOfAccessor ++;
    }

    void SharedExit () : locked {
	-- NumberOfAccessor;
	signal Lock;
    }
}
