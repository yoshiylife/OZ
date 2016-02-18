/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

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
 * iterator.oz
 *
 * Iteration Place Holder.
 */

/* TYPE PARAMETERS: TContent */

class Iterator <Assoc<String,Command>> {
  constructor: New;
  public:
    Finish, GetIndex, GetNum, Hash, PostIncrement, Reset,
    Restart, SetIndex;

  protected: aCollection, Index, Num;

/* instance variables */
    Collection <Assoc<String,Command>> aCollection;
    int Index;
    unsigned int Num;

/* method implementations */
    void New (Collection <Assoc<String,Command>> collection) {
	aCollection = collection;
	Index = 0;
	Num = 0;
	aCollection->DoReset (self);
    }

    void Finish () {
	aCollection->DoFinish (self);
	aCollection = 0;
    }

    unsigned int GetIndex () {return Index;}

    unsigned int GetNum () {return Num;}

    unsigned int Hash () {
	unsigned int h = Index;

	return h;
    }

    Assoc<String,Command> PostIncrement () {return aCollection->DoNext (self);}

    void Reset () {aCollection->DoReset (self);}

    void Restart () {
	Index = 0;
	Num = 0;
    }

    void SetIndex (unsigned int index) {Index = index;}
}
