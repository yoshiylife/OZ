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
