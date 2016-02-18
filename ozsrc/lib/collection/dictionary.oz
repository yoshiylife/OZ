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
 * dictionary.oz
 *
 * Keyed set.
 */

/* TYPE PARAMETERS: TKey,TValue */

class Dictionary <TKey, TValue> : Set <Assoc <TKey, TValue>>
  (rename FindIndexOf FindIndexOfInSet;
   rename FindObjectWithKey FindObjectWithKeyInSet;
   rename OccurrencesOf OccurrencesOfInSet;) {
    constructor: New, NewWithSize;
    public:
      AddAssoc, AssocAt, AtKey, DoFinish, DoNext, DoReset,
      IncludesKey, IsEmpty, IsEqual, RemoveKey, SetAtKey, SetOfKeies, Size;

    protected:
      Add, FindIndexOf, FindIndexOfInSet, FindObjectWithKey,
      FindObjectWithKeyInSet, H, OccurrencesOf, OccurrencesOfInSet;

    protected: Contents, Mask;

/* no instance variable */

/* method implementations */
      Assoc <TKey, TValue> AddAssoc (TKey key, TValue value) {
	  Assoc <TKey, TValue> a=>New (key, value);
	  Assoc <TKey, TValue> b = Add (a);

	  debug {
	      inline "C" {
		  OzDebugf ("Dictionary::AddAssoc: key = %x, value = %p\n",
			    key, value);
	      }
	  }
	  if (a != b)
	    raise CollectionExceptions<TKey>::RedefinitionOfKey (key);
	  return b;
      }

      Assoc <TKey, TValue> AssocAt (TKey key) {return FindObjectWithKey (key);}

      TValue AtKey (TKey key) {
	  Assoc <TKey, TValue> assoc = FindObjectWithKey (key);

	  if (assoc == 0) {
	      raise CollectionExceptions<TKey>::UnknownKey (key);
	  } else {
	      return assoc->Value ();
	  }
      }

      int FindIndexOf (TKey key) {
	  int i;

	  for (i = H (key->Hash ()); Contents [i] != 0;
	       i = (i-1) & Mask) {
	      if (Contents [i]->Key ()->IsEqual (key))
		break;
	  }

	  debug {
	      inline "C" {
		  OzDebugf ("Dictionary::FindIndexOf: returning %d for %p\n",
			    i, key);
	      }
	  }
	  return i;
      }

      Assoc <TKey, TValue> FindObjectWithKey (TKey key) {
	  return Contents [FindIndexOf (key)];
      }

      int IncludesKey (TKey key) {
	  return FindObjectWithKey (key) != 0;
      }

      unsigned int OccurrencesOf (TKey key) {
	  return (FindObjectWithKey (key) != 0) ? 1 : 0;
      }

      Assoc <TKey, TValue> RemoveKey (TKey key) {
	  Assoc <TKey, TValue> assoc = FindObjectWithKey (key);

	  if (assoc == 0) {
	      raise CollectionExceptions<TKey>::UnknownKey (key);
	  } else {
	      return Remove (assoc);
	  }
      }

      TValue SetAtKey (TKey key, TValue data) {
	  Assoc <TKey, TValue> assoc = FindObjectWithKey (key);

	  if (assoc == 0) {
	      raise CollectionExceptions<TKey>::UnknownKey (key);
	  } else {
	      return assoc->SetValue (data);
	  }
      }

      Set <TKey> SetOfKeies () {
	  Set <TKey> s=>New ();
	  Iterator <Assoc <TKey, TValue>> i;
	  Assoc <TKey, TValue> assoc;

	  for (i=>New (self);
	       (assoc = i->PostIncrement ()) != 0;) {
	      s->Add (assoc->Key ());
	  }
	  return s;
      }
  }
