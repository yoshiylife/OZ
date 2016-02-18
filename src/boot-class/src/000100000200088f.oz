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
 * orderedcltn.oz
 *
 * Ordered collection.
 */

/* TYPE PARAMETERS: TContent */

class OrderedCollection <MirrorOperation>
  : SequencedCollection <MirrorOperation> (rename New SuperNew;) {
    constructor: New, NewWithCollection;

    public:
      Add, AddAfter, AddAllLast, AddBefore, AddContentsTo, AddLast,
      After, AsArray, At, AtAllPut, Before, Capacity,
      DoFinish, DoNext, DoReset, First, Hash, IndexOf, IsEmpty,
      IsEqual, Last, OccurrencesOf, Remove, RemoveAll,
      RemoveAllContent, RemoveFirst, RemoveID, RemoveLast,
      ReplaceFrom, ReSize, Size, Sort;

    protected: AddAtIndex, RemoveAtIndex;

    protected: Contents, DefaultCapacity, ExpansionFactor, ExpansionIncrement;

/* instance variables */
      int EndIndex;
      MirrorOperation Contents [];

/* method implementations */
      void New () {
	  SuperNew ();
	  EndIndex = 0;
	  length Contents = DefaultCapacity;
      }

      MirrorOperation Add (MirrorOperation o) {return AddAtIndex (EndIndex, o);}

      MirrorOperation AddAfter (MirrorOperation o, MirrorOperation new) {
	  return AddAtIndex (IndexOf (o) + 1, new);
      }

      OrderedCollection <MirrorOperation>
	AddAllLast (OrderedCollection <MirrorOperation> c) {
	    unsigned int csize = c->Size ();
	    unsigned int i;

	    if (EndIndex + csize >= Capacity ())
	      length Contents = EndIndex + csize + ExpansionIncrement;
	    for (i = 0; i < csize; i ++) {
		Contents [EndIndex++] = c->At (i);
	    }
	    return c;
	}

      MirrorOperation AddAtIndex (unsigned int i, MirrorOperation o) {
	  unsigned int j;

	  if (EndIndex == Capacity ())
	    length Contents = Capacity () + ExpansionIncrement;
	  for (j = EndIndex; j > i; j --)
	    Contents [j] = Contents [j - 1];
	  Contents [i] = o;
	  EndIndex ++;
	  return o;
      }

      MirrorOperation AddBefore (MirrorOperation o, MirrorOperation new) {
	  return AddAtIndex (IndexOf (o), new);
      }

      Collection <MirrorOperation> AddContentsTo (Collection <MirrorOperation> c) {
	  unsigned int i, size = Size ();

	  for (i = 0; i < size; i ++)
	    c->Add (Contents [i]);
	  return c;
      }

      MirrorOperation AddLast (MirrorOperation o) {return Add (o);}

      MirrorOperation After (MirrorOperation o) {
	  unsigned int i = IndexOf (o);

	  if (++i == EndIndex)
	    return 0;
	  else
	    return Contents [i];
      }

      MirrorOperation AsArray ()[] {
	  MirrorOperation array [];
	  unsigned int i, j, size = Size ();

	  length array = Size ();
	  for (i = 0, j = 0; i < size; i ++, j++)
	    array [j] = Contents [i];
	  return array;
      }

      MirrorOperation At (unsigned int index) {return Contents [index];}

      void AtAllPut (MirrorOperation o) {
	  unsigned int i;

	  for (i = 0; i < EndIndex; i ++)
	    Contents [i] = o;
      }

      MirrorOperation Before (MirrorOperation o) {
	  unsigned int i = IndexOf (o);

	  if (--i < 0) return 0;
	  return Contents [i];
      }

      unsigned int Capacity () {return length Contents;}

      MirrorOperation First () {
	  if (EndIndex == 0)
	    raise CollectionExceptions<MirrorOperation>::Empty;
	  else
	    return Contents [0];
      }

      unsigned int Hash () {
	  unsigned int i = EndIndex;
	  unsigned int h;

	  while (i--)
	    h ^= Contents [i]->Hash ();
	  return h;
      }

      int IndexOf (MirrorOperation o) {
	  unsigned int i;

	  for (i = 0; i < EndIndex; i ++) {
	      if (Contents [i]->IsEqual (o))
		return i;
	  }
	  raise CollectionExceptions<MirrorOperation>::ElementNotFound (o);
      }

      int IsEmpty () {return EndIndex == 0;}

      int IsEqual (Collection <MirrorOperation> collection) {
	  unsigned int i;
	  Iterator <MirrorOperation> j;
	  MirrorOperation q;
	  int ret = 1;

	  if (Size () != collection->Size ())
	    return 0;
	  for (i = 0, j=>New (collection);
	       q = j->PostIncrement (); i++) {
	      if (! Contents [i]->IsEqual (q)) {
		  ret = 0;
		  break;
	      }
	  }
	  j->Finish ();
	  return ret;
      }

      MirrorOperation Last () {
	  if (EndIndex == 0)
	    raise CollectionExceptions<MirrorOperation>::Empty;
	  else
	    return Contents [EndIndex - 1];
      }

      unsigned int OccurrencesOf (MirrorOperation o) {
	  unsigned int i, n = 0;

	  for (i = 0; i < EndIndex; i ++) {
	      if (Contents [i]->IsEqual (o))
		n ++;
	  }
	  return n;
      }

      MirrorOperation Remove (MirrorOperation o) {
	  unsigned int i;

	  for (i = 0; i < EndIndex; i ++) {
	      if (Contents [i]->IsEqual (o)) {
		  return RemoveAtIndex (i);
	      }
	  }
	  raise CollectionExceptions<MirrorOperation>::ElementNotFound (o);
      }

      void RemoveAllContent () {
	  unsigned int i, size = Size ();

	  EndIndex = 0;
	  for (i = 0; i < size; ++ i)
	    Contents [i] = 0;
      }

      MirrorOperation RemoveAtIndex (unsigned int i) {
	  MirrorOperation o = Contents [i];
	  unsigned int j;

	  for (j = i + 1; j < EndIndex; j ++) {
	      Contents [j - 1] = Contents [j];
	  }
	  Contents [-- EndIndex] = 0;
	  return o;
      }

      MirrorOperation RemoveFirst () {
	  if (EndIndex == 0)
	    raise CollectionExceptions<MirrorOperation>::Empty;
	  else
	    return RemoveAtIndex (0);
      }

      MirrorOperation RemoveID (MirrorOperation o) {
	  unsigned int i;

	  for (i = 0; i < EndIndex; i ++) {
	      if (Contents [i] == o)
		return RemoveAtIndex (i);
	  }
	  raise CollectionExceptions<MirrorOperation>::ElementNotFound (o);
      }

      MirrorOperation RemoveLast () {
	  if (EndIndex == 0)
	    raise CollectionExceptions<MirrorOperation>::Empty;
	  else
	    return RemoveAtIndex (EndIndex - 1);
      }

      void ReSize (unsigned int new_size) {
	  if (new_size > Size ())
	    length Contents = new_size;
      }

      void ReplaceFrom (unsigned int start, unsigned int stop,
			SequencedCollection <MirrorOperation> replacement,
			unsigned int start_at) {
	  unsigned int i, j = start_at;

	  for (i = start; i <= stop; i++, j++) {
	      Contents [i] = replacement->At (j);
	  }
      }

      unsigned int Size () {return EndIndex;}

      void Sort () {
	  /* under implementation */
      }
}
