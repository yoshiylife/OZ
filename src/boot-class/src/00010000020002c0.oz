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


// we don't use Object::GetPropertyPathName


// we have a bug in gen-spec-src

/*
 * oorderedcltn.oz
 *
 * Ordered collection whose key is an object ID.
 */

/* TYPE PARAMETERS: TContent */

class OIDOrderedCollection <TContent>
  : OrderedCollection <OIDAsKey <TContent>>
  (rename Add SuperAdd;
   rename AddAfter SuperAddAfter;
   rename AddBefore SuperAddBefore;
   rename AddLast SuperAddLast;
   rename After SuperAfter;
   rename AsArray SuperAsArray;
   rename At SuperAt;
   rename AtAllPut SuperAtAllPut;
   rename Before SuperBefore;
   rename First SuperFirst;
   rename IndexOf SuperIndexOf;
   rename Last SuperLast;
   rename OccurrencesOf SuperOccurrencesOf;
   rename Remove SuperRemove;
   rename RemoveAtIndex SuperRemoveAtIndex;
   rename RemoveFirst SuperRemoveFirst;
   rename RemoveLast SuperRemoveLast;) {
    constructor:
      New, NewWithCollection;

    public:
      Add, AddAfter, AddAllLast, AddBefore, AddContentsTo, AddLast,
      After, AsArray, At, AtAllPut, Before, Capacity, DoFinish, DoNext,
      DoReset, First, Hash, IndexOf, IsEmpty, IsEqual, Last, OccurrencesOf,
      Remove, RemoveAll, RemoveAllContent, RemoveFirst, RemoveID,
      RemoveLast, ReplaceFrom, ReSize, Size, Sort;

    protected: AddAtIndex, RemoveAtIndex;

    protected: Contents, DefaultCapacity, ExpansionFactor, ExpansionIncrement;

/* no instance variable */

/* method implementations */
      TContent Add (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  return SuperAdd (key)->Get ();
      }

      TContent AddAfter (TContent o, TContent new) {
	  OIDAsKey <TContent> key=>New (o), key_new=>New (new);
	  return SuperAddAfter (key, key_new)->Get ();
      }

      TContent AddBefore (TContent o, TContent new) {
	  OIDAsKey <TContent> key=>New (o), key_new=>New (new);
	  return SuperAddBefore (key, key_new)->Get ();
      }

      TContent AddLast (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  return SuperAddLast (key)->Get ();
      }

      TContent After (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  return SuperAfter (key)->Get ();
      }

      TContent AsArray ()[] {
	  TContent array [];
	  unsigned int i, j, size = Size ();

	  length array = Size ();
	  for (i = 0, j = 0; i < size; i ++, j++)
	    array [j] = Contents [i]->Get ();
	  return array;
      }

      TContent At (unsigned int index) {return SuperAt (index)->Get ();}

      void AtAllPut (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  SuperAtAllPut (key);
      }

      TContent Before (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  return SuperBefore (key)->Get ();
      }

      TContent First () {return SuperFirst ()->Get ();}

      int IndexOf (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  return SuperIndexOf (key);
      }

      TContent Last () {return SuperLast ()->Get ();}

      unsigned int OccurrencesOf (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  return SuperOccurrencesOf (key);
      }

      TContent Remove (TContent o) {
	  OIDAsKey <TContent> key=>New (o);
	  return SuperRemove (key)->Get ();
      }

      TContent RemoveAtIndex (unsigned int i) {
	  return SuperRemoveAtIndex (i)->Get ();
      }

      TContent RemoveFirst () {return SuperRemoveFirst ()->Get ();}

      TContent RemoveLast () {return SuperRemoveLast ()->Get ();}
  }
