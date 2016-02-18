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
 * resolver.oz
 *
 * Resolver
 */

class Resolver : ResolvableObject (rename New SuperNew;) {
  public: Go, Stop;
  constructor: NewWithDelimiter, NewWithArrayOfCharDelimiter;

  public:
    AddObject, AddObjectToResponsibleResolver,
    AddObjectWithArrayOfChar, AddResolver,
    AddResolverToResponsibleResolver, ChangeInLocal, ChangeObject,
    ChangeObjectWithArrayOfChar, Delimiter, GetResolverResponsibility,
    IsEmpty, IsEmptyWithCheckList, IsRegisteredResolver, ListAllNames,
    ListAllResolverNames, RemoveFromLocal, RemoveObject,
    RemoveObjectWithName, RemoveObjectWithNameWithArrayOfChar,
    RemoveResolver, RemoveResolverFromTable, RemoveResolverWithName,
    Resolve, ResolveLocally, ResolveWithArrayOfChar,
    ResponsibleResolver;

  protected:
    IsAllResolverEmpty;

/* instance variables */
    Dictionary <String, global ResolvableObject> ObjectTable;
    Dictionary <String, global Resolver> ResolverTable;
    String DelimiterString;

/* method implementations */
    void NewWithDelimiter (String delimiter) : global {
	SuperNew ();
	ObjectTable=>New ();
	ResolverTable=>New ();
	DelimiterString = delimiter;
    }

    void NewWithArrayOfCharDelimiter (char delimiter []) : global {
	SuperNew ();
	ObjectTable=>New ();
	ResolverTable=>New ();
	DelimiterString=>NewFromArrayOfChar (delimiter);
    }

    global Resolver AddObject (String name, global ResolvableObject object)
      : global {
	  ResolverResponsibility rr = GetResolverResponsibility (name);

	  rr->GetResponsible ()
	    ->AddObjectToResponsibleResolver (rr->GetName (), object);

	  return oid;
      }

    global Resolver AddObjectWithArrayOfChar (char s [],
					      global ResolvableObject object)
      : global {
	  String name=>NewFromArrayOfChar (s);
	  return AddObject (name, object);
      }

    void AddObjectToResponsibleResolver (String name,
					 global ResolvableObject o)
      : global, locked {
	  ObjectTable->AddAssoc (name, o);
	  Flush ();
      }

    global Resolver AddResolver (String name, global Resolver resolver)
      : global {
	  ResolverResponsibility rr = GetResolverResponsibility (name);

	  rr->GetResponsible ()
	    ->AddResolverToResponsibleResolver (rr->GetName (), resolver);

	  return oid;
      }

    void AddResolverToResponsibleResolver (String name,
					   global Resolver resolver)
      : global, locked {
	  ResolverTable->AddAssoc (name, resolver);
	  Flush ();
      }

    global ResolvableObject
      ChangeInLocal (String name, global ResolvableObject object)
	: global, locked {
	    try {
		global ResolvableObject ro;
		ro = ObjectTable->SetAtKey (name, object);
		Flush ();
		return ro;
	    } except {
		CollectionExceptions<String>::UnknownKey (name) {
		    raise ResolverExceptions::UnknownName (name);
		}
	    }
	}

    global ResolvableObject ChangeObject (String name,
					  global ResolvableObject object)
      : global {
	  ResolverResponsibility rr = GetResolverResponsibility (name);

	  return rr->GetResponsible ()->ChangeInLocal (rr->GetName (), object);

      }

    global ResolvableObject
      ChangeObjectWithArrayOfChar (char s [], global ResolvableObject object)
	: global {
	    String name=>NewFromArrayOfChar (s);
	    return ChangeObject (name, object);
	}

    String Delimiter () : global, locked {return DelimiterString;}

    int IsEmpty () : global {
	Set <OIDAsKey <global Resolver>> s;

	s=>New ();
	return IsEmptyWithCheckList (s);
    }

    int IsRegisteredResolver (String name) : global, locked {
	return ResolverTable->IncludesKey (name);
    }

    Set <String> ListAllNames () : global, locked {
	Set <String> s;
	Iterator <Assoc <String, global ResolvableObject>> i;
	Assoc <String, global ResolvableObject> assoc;

	for (s=>New (), i=>New (ObjectTable);
	     (assoc = i->PostIncrement ()) != 0;) {
	    s->Add (assoc->Key ());
	}
	i->Finish ();
	return s;
    }

    Set <String> ListAllResolverNames () : global, locked {
	Set <String> s;
	Iterator <Assoc <String, global Resolver>> i;
	Assoc <String, global Resolver> assoc;

	for (s=>New (), i=>New (ResolverTable);
	     assoc = i->PostIncrement ();) {
	    s->Add (assoc->Key ());
	}
	i->Finish ();
	return s;
    }

    global ResolvableObject RemoveFromLocal (String name)
      : global, locked {
	  try {
	      global ResolvableObject ro;
	      ro = ObjectTable->RemoveKey (name)->Value ();
	      Flush ();
	      return ro;
	  } except {
	      CollectionExceptions<String>::UnknownKey (name) {
		  raise ResolverExceptions::UnknownName (name);
	      }
	  }
      }

    global ResolvableObject RemoveObject (String name,
					  global ResolvableObject object)
      : global {
	  try {
	      global ResolvableObject ro;

	      if (Resolve (name) == object)
		ro = RemoveObjectWithName (name);
	      else
		ro = 0;
	      return ro;
	  } except {
	      CollectionExceptions<String>::UnknownKey (name) {
		  return 0;
	      }
	  }
      }

    global ResolvableObject RemoveObjectWithName (String name) : global {
	ResolverResponsibility rr = GetResolverResponsibility (name);

	return rr->GetResponsible ()->RemoveFromLocal (rr->GetName ());

    }

    global ResolvableObject
      RemoveObjectWithNameWithArrayOfChar (char s []) : global {
	  String name=>NewFromArrayOfChar (s);

	  return RemoveObjectWithName (name);
      }

    global Resolver RemoveResolver (String name, global Resolver resolver)
      : global {
	  try {
	      ResolverResponsibility rr
		= GetResolverResponsibility (name);
	      if (

		  rr->GetResponsible ()->IsRegisteredResolver (rr->GetName ())

		  == resolver) {
		  return RemoveResolverWithName (name);
	      } else {
		  return 0;
	      }
	  } except {
	      CollectionExceptions<String>::UnknownKey (name) {
		  return 0;
	      }
	  }
      }

    global Resolver RemoveResolverFromTable (String name)
      : global, locked {
	  try {
	      global Resolver r;
	      r = ResolverTable->RemoveKey (name)->Value ();
	      Flush ();
	      return r;
	  } except {
	      CollectionExceptions<String>::UnknownKey (name) {
		  raise ResolverExceptions::UnknownResolverName (name);
	      }
	  }
      }

    global Resolver RemoveResolverWithName (String name) : global {
	ResolverResponsibility rr = GetResolverResponsibility (name);


	return
	  rr->GetResponsible ()->RemoveResolverFromTable (rr->GetName ());

    }

    global ResolvableObject Resolve (String name) : global {
	ResolverResponsibility rr = GetResolverResponsibility (name);

	return rr->GetResponsible ()->ResolveLocally (rr->GetName ());

    }

    global ResolvableObject ResolveLocally (String name) : locked, global {
	if (ObjectTable->IncludesKey (name)) {
	    return ObjectTable->AtKey (name);
	} else {
	    return 0;
	}
    }

    global ResolvableObject ResolveWithArrayOfChar (char name []) : global {
	String s;

	return Resolve (s=>NewFromArrayOfChar (name));
    }

    global Resolver ResponsibleResolver (String name) {

	return GetResolverResponsibility (name)->GetResponsible ();

    }

/* protected method implementations */
    String AfterPath (String whole, unsigned int max) {
	return whole->GetSubString (max + DelimiterString->Length (), 0);
    }

    int ForePath (String whole, String part) {
	String fore;
	unsigned int fore_len;

	fore=>New ()->Assign (part)->Concatenate (DelimiterString);
	fore_len = fore->Length ();

	return
	  whole->Length () > fore_len && whole->NCompare (fore, fore_len) == 0;
    }

    ResolverResponsibility GetResolverResponsibility (String name) : global {
	ResolverResponsibility rr;

	if (ObjectTable->IncludesKey (name)) {

	    rr=>New (name, oid);

	    return rr;
	} else {
	    Iterator <Assoc <String, global Resolver>> i;
	    Assoc <String, global Resolver> assoc;

	    unsigned int max = 0;
	    global Resolver resolver;
	    for (i=>New (ResolverTable);
		 assoc = i->PostIncrement ();) {
		unsigned int len = assoc->Key ()->Length ();

		if (len > max && ForePath (name, assoc->Key ())) {
		    resolver = assoc->Value ();
		    max = len;
		}
	    }
	    i->Finish ();
	    if (max > 0) {
		return
		  resolver->GetResolverResponsibility (AfterPath (name, max));
	    } else {

		rr=>New (name, oid);

		return rr;
	    }
	}
    }

    /*
     * naive implementation.
     * monitor lock should be release while accessing remote
     * resolvers.
     */
    int IsAllResolverEmpty (Set <OIDAsKey <global Resolver>> s) : locked {
	Iterator <Assoc <String, global Resolver>> i;
	Assoc <String, global Resolver> assoc;

	int answer = 1;

	for (i=>New (ResolverTable); (assoc = i->PostIncrement ()) != 0;) {
	    if (! assoc->Value ()->IsEmptyWithCheckList (s)) {
		answer = 0;
		break;
	    }
	}
	i->Finish ();
	return answer;
    }

    int IsEmptyWithCheckList (Set <OIDAsKey <global Resolver>> s) : global {
	OIDAsKey <global Resolver> key=>New (oid);

	if (s->Includes (key)) {
	    return 1;
	} else {
	    s->Add (key);
	    return ObjectTable->IsEmpty () & IsAllResolverEmpty (s);
	}
    }
}
