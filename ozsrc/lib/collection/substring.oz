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
 * substring.oz
 *
 * Mutable substring class.
 * Each SubString instance points some part of a String instance.
 * Instance variable is the start point and length of the substring in
 * the original string.
 */

class SubString : String {
  constructor: NewCopy, NewFromArrayOfChar, NewFromString;

  public:
    New,
    Assign, AssignFromArrayOfChar, At, AtoI,
    Capacity, Compare, CompareToArrayOfChar, Concatenate,
    ConcatenateWithArrayOfChar,
    Content,
    GetSubString, GetSubStringByRange,
    IsEqualTo, IsEqualToArrayOfChar,
    IsGreaterThan, IsGreaterThanArrayOfChar,
    IsGreaterThanOrEqualTo, IsGreaterThanOrEqualToArrayOfChar,
    IsLessThan, IsLessThanArrayOfChar,
    IsLessThanOrEqualTo, IsLessThanOrEqualToArrayOfChar,
    IsNotEqualTo, IsNotEqualToArrayOfChar,
    Length, Replace, ReplaceWithArrayOfChar, SetAt,
    SetCapacity,

    Str2OID, StrChr, StrRChr,

    ToLower, ToUpper, Position, WholeString, DebugPrint;
  protected:
    CheckSubString;

  protected: ACO, Len, OriginalString, Pos;
    /* Str in parent class is not used */

/* instance variables */
    String OriginalString;	/* String this is a SubString of */
    unsigned int Pos;	/* Starting index in OriginalString */

/* method implementations */
    void NewCopy (SubString ss) {
	New ();
	Pos = ss->Position ();
	Len = ss->Length ();
	OriginalString = ss->WholeString ();
    }

    void NewFromString (String st, unsigned int pos, unsigned int len) {
	New ();
	Pos = pos;
	Len = len;
	OriginalString = st;
	CheckSubString ();
    }

    String Assign (String st) {
	Pos = 0;
	Len = st->Length ();
	OriginalString = st;
	return self;
    }

    String AssignFromArrayOfChar (char s []) {
	String st=>NewFromArrayOfChar (s);
	return Assign (st);
    }

    char At (unsigned int index) {
	if (index < Len)
	  return OriginalString->At (Pos + index);
	else
	  raise StringExceptions::OutOfRange (index);
    }

    unsigned int Capacity () {return Len;}

    /* check if valid SubString */
    void CheckSubString () {
	if (Position () + Len > OriginalString->Length ())
	  raise StringExceptions::InvalidSubString (self);
    }

    char Content ()[] {
	char s [];
	unsigned int i;

	length s = Len + 1;
	for (i = 0; i < Len; i ++) {
	    s [i] = At (i);
	}
	s [i] = '\0';
	return s;
    }

    SubString GetSubString (unsigned int start_pos, unsigned int len) {
	SubString ss;
	if( len == 0 )
	  len = Len - start_pos;
	ss=>NewFromString (OriginalString, Pos + start_pos, len);
	return ss;
    }

    SubString GetSubStringByRange (Range r) {
	r->CheckValidity ();
	return GetSubString (r->FirstIndex (), r->Length ());
    }

    unsigned int Position () {return Pos;}

    /* replace the substring with the argument string */
    void Replace (String st, unsigned int ln) {
	ReplaceWithArrayOfChar (st->Content (), ln);
    }

    void ReplaceWithArrayOfChar (char s [], unsigned int len) {
	/* under implementation */
    }

    void SetAt (unsigned int at, char c) {
	if (at < Len)
	  OriginalString->SetAt (Pos + at, c);
	else
	  raise StringExceptions::OutOfRange (at);
    }

    void SetCapacity (unsigned int capacity) {
	int diff = capacity - Len;

	if (diff > 0) {
	    int olen = OriginalString->Length ();
	    unsigned int i;

	    if (olen + diff > OriginalString->Capacity ()) {
		OriginalString->SetCapacity (olen + diff);
	    }
	    for (i = olen; -- i >= Pos + Len;) {
		OriginalString->SetAt (i + diff, OriginalString->At (i));
	    }
	    Len = capacity;
	}
    }

    String WholeString () {return OriginalString;}
}
