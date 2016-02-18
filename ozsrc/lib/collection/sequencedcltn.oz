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
 * sequencedcltn.oz
 *
 * Sequenced collection.
 */

/* TYPE PARAMETERS: TContent */

abstract class SequencedCollection <TContent> : Collection <TContent> {
  protected: /* for the constructor of subclasses */
    New, NewWithCollection;

  public:
    At, AtAllPut, DoNext, First, Hash, IsEqual, IndexOf,
    Last, OccurrencesOf, ReplaceFrom;

  public: /* inherited from Collection */
    Add, AddAll, AddContentsTo, AsArray, DoFinish, DoReset,
    Includes, IsEmpty, Remove, RemoveAllContent, RemoveAll, Size;

  protected: DefaultCapacity, ExpansionFactor, ExpansionIncrement;

/* no instance variable */

/* abstract methods */
    TContent At (unsigned int index) : abstract;
    void AtAllPut (TContent o) : abstract;
    void ReplaceFrom (unsigned int start, unsigned int stop,
		      SequencedCollection <TContent> replacement,
		      unsigned int start_at) : abstract;

/* method implementations */
    TContent DoNext (Iterator <TContent> i) {
	unsigned int index = i->GetIndex ();

	if (index < Size ()) {
	    i->SetIndex (index + 1);
	    return At (index);
	} else {
	    return 0;
	}
    }

    TContent First () {return At (0);}

    unsigned int Hash () {
	unsigned int h = Size ();
	Iterator <TContent> i;
	TContent p;

	for (i=>New (self); p = i->PostIncrement ();) {
	    h ^= p->Hash ();
	}
	i->Finish ();
	return h;
    }

    int IsEqual (Collection <TContent> collection) {
	Iterator <TContent> i, j;
	TContent p;
	int ret = 1;

	if (Size () != collection->Size ())
	  return 0;

	for (i=>New (self), j=>New (collection);
	     p = i->PostIncrement ();) {
	    if (! p->IsEqual (j->PostIncrement ())) {
		ret = 0;
		break;
	    }
	}
	i->Finish ();
	j->Finish ();
	return ret;
    }

    int IndexOf (TContent o) {
	Iterator <TContent> i;
	TContent p;
	int ret = -1;

	for (i=>New (self); p = i->PostIncrement ();) {
	    if (p->IsEqual (o)) {
		ret = i->GetIndex ();
		break;
	    }
	}
	i->Finish ();
	return ret;
    }

    TContent Last () {
	if (IsEmpty ())
	  raise CollectionExceptions<TContent>::Empty;
	else
	  return At (Size () - 1);
    }

    unsigned int OccurrencesOf (TContent o) {
	Iterator <TContent> i;
	TContent p;
	unsigned int n = 0;

	for (i=>New (self); (p = i->PostIncrement ()) != 0;) {
	    if (p->IsEqual (o))
	      n ++;
	}
	i->Finish ();
	return n;
    }
}
