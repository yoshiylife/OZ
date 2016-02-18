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
 * vstring.oz
 *
 * String representing a version of a class part.
 * Based on a mutable string class String.
 */

class VersionString {
/* interface */
  constructor: New;
  public:
    Assign, AsString, Compare, Content, Duplicate,
    GetImplementationPart, GetProtectedPart, GetPublicPart,
    IsEqual, IsEqualTo, IsGreaterThan, IsGreaterThanOrEqualTo,
    IsLessThan, IsLessThanOrEqualTo, IsNotEqualTo,
    SetImplementationPart, SetProtectedPart, SetPublicPart;

  /* instance variables */
  protected: PublicPart, ProtectedPart, ImplementationPart;

    unsigned int PublicPart;
    unsigned int ProtectedPart;
    unsigned int ImplementationPart;

/* method implementations */
    void New () {
	PublicPart = 0;
	ProtectedPart = 0;
	ImplementationPart = 0;
    }

    VersionString Assign (VersionString vs) {
	SetPublicPart (vs->GetPublicPart ());
	SetProtectedPart (vs->GetProtectedPart ());
	SetImplementationPart (vs->GetImplementationPart ());
	return self;
    }

    String AsString () {
	String s=>NewFromArrayOfChar (Content ());

	return s;
    }

    int Compare (VersionString s) {
	int r;

	if (self == s)
	  return 0;

	if (PublicPart == 0) {
	    return - s->GetPublicPart ();
	} else if ((r = PublicPart - s->GetPublicPart ()) != 0) {
	    return r;
	} else if (ProtectedPart == 0) {
	    return - s->GetProtectedPart ();
	} else if ((r = ProtectedPart - s->GetProtectedPart ()) != 0) {
	    return r;
	} else if (ImplementationPart == 0) {
	    return - s->GetImplementationPart ();
	} else if ((r = ImplementationPart - s->GetImplementationPart ())
		   != 0) {
	    return r;
	} else {
	    return 0;
	}
    }

    char Content ()[] {
	ArrayOfCharOperators acops;
	char buf [];


	if (PublicPart == 0) {

	    buf = acops.Duplicate ("*.*.*");

	} else {

	    buf = acops.ItoA (PublicPart);

	    if (ProtectedPart == 0) {

		buf = acops.Concatenate (buf, acops.Duplicate (".*.*"));

	    } else {

		buf = acops.Concatenate (buf, acops.Duplicate ("."));
		buf = acops.Concatenate (buf, acops.ItoA (ProtectedPart));

		if (ImplementationPart == 0) {

		    buf = acops.Concatenate (buf, acops.Duplicate (".*"));

		} else {

		    buf = acops.Concatenate (buf, acops.Duplicate ("."));
		    buf = acops.Concatenate (buf,
					     acops.ItoA (ImplementationPart));

		}
	    }
	}
	return buf;
    }

    VersionString Duplicate () {
	VersionString vs=>New ();

	return vs->Assign (self);
    }

    unsigned int GetPublicPart () {return PublicPart;}
    unsigned int GetProtectedPart () {return ProtectedPart;}
    unsigned int GetImplementationPart () {return ImplementationPart;}

    int IsEqual (VersionString vs) {return IsEqualTo (vs);}
    int IsEqualTo (VersionString vs) {return Compare (vs) == 0;}
    int IsGreaterThan (VersionString vs) {return Compare (vs) > 0;}
    int IsGreaterThanOrEqualTo (VersionString vs) {return Compare (vs) >= 0;}
    int IsLessThan (VersionString vs) {return Compare (vs) < 0;}
    int IsLessThanOrEqualTo (VersionString vs) {return Compare (vs) <= 0;}
    int IsNotEqualTo (VersionString vs) {return Compare (vs) != 0;}

    VersionString SetPublicPart (unsigned int n) {
	PublicPart = n;
	return self;
    }

    VersionString SetProtectedPart (unsigned int n) {
	ProtectedPart = n;
	return self;
    }

    VersionString SetImplementationPart (unsigned int n) {
	ImplementationPart = n;
	return self;
    }
}
