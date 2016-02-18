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

// we have a bug in gen-spec-src


// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// we have no str[fp]time


// boot classes are modifiable

/*
 * orderedcltn.oz
 *
 * Ordered collection.
 */

/* TYPE PARAMETERS: TContent */

class OrderedCollection <TContent>
  : SequencedCollection <TContent> (rename New SuperNew;)
{
  constructor: New, NewWithCollection;

  public:
    Add, AddAfter, AddAllLast, AddBefore, AddContentsTo, AddLast,
    After, AsArray, At, AtAllPut, Before, Capacity, DoFinish, DoNext,
    DoReset, First, Hash, IndexOf, IsEmpty, IsEqual, Last, OccurrencesOf,
    Remove, RemoveAll, RemoveAllContent, RemoveFirst, RemoveID,
    RemoveLast, ReplaceFrom, ReSize, Size, Sort;

  protected: AddAtIndex, RemoveAtIndex;

  protected: Contents, DefaultCapacity, ExpansionFactor, ExpansionIncrement;

/* instance variables */
    int EndIndex;
    TContent Contents [];

/* method implementations */
    void New () {
	SuperNew ();
	EndIndex = 0;
	length Contents = DefaultCapacity;
    }

    TContent Add (TContent o) {return AddAtIndex (EndIndex, o);}

    TContent AddAfter (TContent o, TContent new) {
	return AddAtIndex (IndexOf (o) + 1, new);
    }

    OrderedCollection <TContent>
      AddAllLast (OrderedCollection <TContent> c) {
	  unsigned int csize = c->Size ();
	  unsigned int i;

	  if (EndIndex + csize >= length Contents) {
	      length Contents = EndIndex + csize + ExpansionIncrement;
	  }
	  for (i = 0; i < csize; i ++) {
	      Contents [EndIndex ++] = c->At (i);
	  }
	  return c;
      }

    TContent AddAtIndex (unsigned int i, TContent o) {
	unsigned int j;

	if (EndIndex == length Contents) {
	    length Contents = length Contents + ExpansionIncrement;
	}
	for (j = EndIndex; j > i; j --) {
	    Contents [j] = Contents [j - 1];
	}
	Contents [i] = o;
	EndIndex ++;
	return o;
    }

    TContent AddBefore (TContent o, TContent new) {
	return AddAtIndex (IndexOf (o), new);
    }

    Collection <TContent> AddContentsTo (Collection <TContent> c) {
	unsigned int i, size = Size ();

	for (i = 0; i < size; i ++) {
	    c->Add (Contents [i]);
	}
	return c;
    }

    TContent AddLast (TContent o) {return Add (o);}

    TContent After (TContent o) {
	unsigned int i = IndexOf (o);

	return At (i + 1);
    }

    TContent AsArray ()[] {
	TContent array [];
	unsigned int i, j, size = Size ();

	length array = Size ();
	for (i = 0, j = 0; i < size; i ++, j++) {
	    array [j] = Contents [i];
	}
	return array;
    }

    TContent At (unsigned int i) {
	if (i >= 0 && i < Size ()) {
	    return Contents [i];
	} else {
	    raise CollectionExceptions <TContent>::InvalidIntParameter (i);
	}
    }

    void AtAllPut (TContent o) {
	unsigned int i, len = Size ();

	for (i = 0; i < len; i ++) {
	    Contents [i] = o;
	}
    }

    TContent Before (TContent o) {
	unsigned int i = IndexOf (o);

	return At (i - 1);
    }

    unsigned int Capacity () {return length Contents;}

    TContent First () {
	if (IsEmpty ()) {
	    raise CollectionExceptions <TContent>::Empty;
	} else {
	    return At (0);
	}
    }

    unsigned int Hash () {
	unsigned int i = Size ();
	unsigned int h;

	while (i --) {
	    h ^= Contents [i]->Hash ();
	}
	return h;
    }

    int IndexOf (TContent o) {
	unsigned int i, len = Size ();

	for (i = 0; i < len; i ++) {
	    if (Contents [i]->IsEqual (o)) {
		return i;
	    }
	}
	raise CollectionExceptions <TContent>::ElementNotFound (o);
    }

    int IsEmpty () {return Size () == 0;}

    int IsEqual (Collection <TContent> collection) {
	unsigned int i;
	Iterator <TContent> j;
	TContent q;
	int ret = 1;

	if (Size () != collection->Size ()) {
	    return 0;
	}
	for (i = 0, j=>New (collection); q = j->PostIncrement (); i++) {
	    if (! Contents [i]->IsEqual (q)) {
		ret = 0;
		break;
	    }
	}
	j->Finish ();
	return ret;
    }

    TContent Last () {
	if (IsEmpty ()) {
	    raise CollectionExceptions<TContent>::Empty;
	} else {
	    return At (Size () - 1);
	}
    }

    unsigned int OccurrencesOf (TContent o) {
	unsigned int i, len = Size (), n = 0;

	for (i = 0; i < len; i ++) {
	    if (Contents [i]->IsEqual (o)) {
		n ++;
	    }
	}
	return n;
    }

    TContent Remove (TContent o) {
	unsigned int i, len = Size ();

	for (i = 0; i < len; i ++) {
	    if (At (i)->IsEqual (o)) {
		return RemoveAtIndex (i);
	    }
	}
	raise CollectionExceptions <TContent>::ElementNotFound (o);
    }

    void RemoveAllContent () {
	unsigned int i;

	for (i = 0; i < EndIndex; ++ i) {
	    Contents [i] = 0;
	}
	EndIndex = 0;
    }

    TContent RemoveAtIndex (unsigned int i) {
	TContent o = Contents [i];
	unsigned int j;

	for (j = i + 1; j < EndIndex; j ++) {
	    Contents [j - 1] = Contents [j];
	}
	Contents [-- EndIndex] = 0;
	return o;
    }

    TContent RemoveFirst () {
	if (IsEmpty ()) {
	    raise CollectionExceptions <TContent>::Empty;
	} else {
	    return RemoveAtIndex (0);
	}
    }

    TContent RemoveID (TContent o) {
	unsigned int i;

	for (i = 0; i < EndIndex; i ++) {
	    if (Contents [i] == o) {
		return RemoveAtIndex (i);
	    }
	}
	raise CollectionExceptions <TContent>::ElementNotFound (o);
    }

    TContent RemoveLast () {
	if (IsEmpty ()) {
	    raise CollectionExceptions <TContent>::Empty;
	} else {
	    return RemoveAtIndex (EndIndex - 1);
	}
    }

    void ReSize (unsigned int new_size) {
	if (new_size > length Contents) {
	    length Contents = new_size;
	}
    }

    void ReplaceFrom (unsigned int start, unsigned int stop,
		      SequencedCollection <TContent> replacement,
		      unsigned int start_at) {
	unsigned int i, j = start_at;

	if (start >= 0 && stop < Size ()) {
	    for (i = start; i <= stop; i++, j++) {
		Contents [i] = replacement->At (j);
	    }
	    return;
	}
	if (0 > start) {
	    raise CollectionExceptions <TContent>::InvalidIntParameter (start);
	} else {
	    raise CollectionExceptions <TContent>::InvalidIntParameter (stop);
	}
    }

    unsigned int Size () {return EndIndex;}

    void Sort () {
	/* under implementation */
    }
}
