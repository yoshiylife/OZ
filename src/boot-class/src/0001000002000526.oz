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


// we have no support for getting executor ID

/*
 * sequencedcltn.oz
 *
 * Sequenced collection.
 */

/* TYPE PARAMETERS: TContent */

abstract class SequencedCollection <Token> : Collection <Token> {
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
    Token At (unsigned int index) : abstract;
    void AtAllPut (Token o) : abstract;
    void ReplaceFrom (unsigned int start, unsigned int stop,
		      SequencedCollection <Token> replacement,
		      unsigned int start_at) : abstract;

/* method implementations */
    Token DoNext (Iterator <Token> i) {
	unsigned int index = i->GetIndex ();

	if (index < Size ()) {
	    i->SetIndex (index + 1);
	    return At (index);
	} else {
	    return 0;
	}
    }

    Token First () {return At (0);}

    unsigned int Hash () {
	unsigned int h = Size ();
	Iterator <Token> i;
	Token p;

	for (i=>New (self); p = i->PostIncrement ();) {
	    h ^= p->Hash ();
	}
	i->Finish ();
	return h;
    }

    int IsEqual (Collection <Token> collection) {
	Iterator <Token> i, j;
	Token p;
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

    int IndexOf (Token o) {
	Iterator <Token> i;
	Token p;
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

    Token Last () {
	if (IsEmpty ())
	  raise CollectionExceptions<Token>::Empty;
	else
	  return At (Size () - 1);
    }

    unsigned int OccurrencesOf (Token o) {
	Iterator <Token> i;
	Token p;
	unsigned int n = 0;

	for (i=>New (self); (p = i->PostIncrement ()) != 0;) {
	    if (p->IsEqual (o))
	      n ++;
	}
	i->Finish ();
	return n;
    }
}
