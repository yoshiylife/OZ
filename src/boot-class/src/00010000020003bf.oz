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
 * string.oz
 *
 * Mutable string class.
 * Instance variable is the length of the string and the string
 * contents.
 * String contents is implemented by an array of char.
 * The size of the array is equal to the length + 1.
 * Dependent to ASCII character set.
 * No support for internationalization.
 */

/*
  under implementation:
  Content must be NULL terminated.
*/

inline "C" {
#include <oz++/object-type.h>
}

class String {
  constructor: New, NewFromArrayOfChar, OIDtoHexa;

  public:
    Append, Assign, AssignFromArrayOfChar, At, AtoI, Capacity,
    Compare, CompareToArrayOfChar,
    Concatenate, ConcatenateWithArrayOfChar,
    Content, Duplicate, GetSubString, GetSubStringByRange, Hash,
    IsEqual, IsEqualTo, IsEqualToArrayOfChar, IsGreaterThan,
    IsGreaterThanArrayOfChar, IsGreaterThanOrEqualTo,
    IsGreaterThanOrEqualToArrayOfChar, IsLessThan, IsLessThanArrayOfChar,
    IsLessThanOrEqualTo, IsLessThanOrEqualToArrayOfChar, IsNotEqualTo,
    IsNotEqualToArrayOfChar,
    Length, NCompare, NCompareToArrayOfChar, SetAt, SetCapacity,
    ToLower, ToUpper,

    Str2OID,

    StrChr, StrRChr, DebugPrint;

/* instance variables */
  protected: ACO, Len, Str;

    ArrayOfCharOperators ACO;
    unsigned int Len;
    char Str [];

/* constructors */
    /* Assign "" to new String */
    void New () {

	AssignFromArrayOfChar ("");
    }

    /* Assign array-of-char argument to new String */
    void NewFromArrayOfChar (char s []) {

	AssignFromArrayOfChar (s);
    }

    /* Assign hexa-decimal digit string to new String */
    void OIDtoHexa (global Object o) {
	char buf[];

	length buf = 17; /* length of hexa-decimal long long expression */

	inline "C" {
	    OzSprintf (OZ_ArrayElement(buf, char), "%08x%08x",
		       (unsigned int)(o >> 32), (int)(o & 0xffffffff));
	}
	AssignFromArrayOfChar (buf);
    }

/* method implementations */
    String Append (String string) {
	char c;
	unsigned int i = 0, len = string->Length ();

	SetCapacity (Len + len);
	do {
	    c = string->At (i ++);
	    SetAt (Len ++, c);
	} while (c);
	return self;
    }

    String Assign (String s) {
	return AssignSub (s->Content (), s->Length ());
    }

    String AssignFromArrayOfChar (char s []) {

	return AssignSub (ACO.Duplicate (s), ACO.Length (s));

    }

    String AssignSub (char s [], unsigned int len) {
	char tmp [] = Str;

	Len = len;
	Str = s;
	if (tmp != 0) {
	    inline "C" {
		OzExecFree ((OZ_Pointer)tmp);
	    }
	}
	return self;
    }

    char At (unsigned int index) {
	if (index < Len)
	  return Str [index];
	else
	  raise StringExceptions::OutOfRange (index);
    }


    int AtoI () {return ACO.AtoI (Content ());}


    unsigned int Capacity () {return length Str - 1;}

    int Compare (String s) {
	unsigned int slen;
	unsigned int l;
	unsigned int i;
	int r;

	if (self == s)
	  return 0;

	slen = s->Length ();
	l = Len < slen ? Len : slen ;
	for (i = 0; i < l; i ++) {
	    if (r = At (i) - s->At (i))
	      return r;
	}
	if (Len == slen)
	  return 0;
	else if (Len < slen)
	  return - s->At (i);
	else
	  return At (i);
    }

    int CompareToArrayOfChar (char s []) {
	unsigned int i;
	int r;

	for (i = 0; i < Len; i ++) {
	    if (r = At (i) - s [i])
	      return r;
	}
	return - s [i];
    }

    String Concatenate (String st) {
	return ConcatenateWithArrayOfChar (st->Content ());
    }

    String ConcatenateWithArrayOfChar (char s []) {
	char concat [];
	String new;


	concat = ACO.Concatenate (Content (), s);

	debug (0, "String::ConcatenateWithArrayOfChar: concat = %S\n", concat);
	return new=>NewFromArrayOfChar (concat);
    }


    char Content ()[] {return ACO.Duplicate (Str);}


    String Duplicate () {
	String new=>New ();

	return new->Assign (self);
    }

    SubString GetSubString (unsigned int start_pos, unsigned int len) {
	SubString ss;

	if (len == 0) {
	    len = Len - start_pos;
	}
	ss=>NewFromString (self, start_pos, len);
	return ss;
    }

    SubString GetSubStringByRange (Range r) {
	r->CheckValidity ();
	return GetSubString (r->FirstIndex (), r->Length ());
    }

    unsigned int Hash () {

	return ACO.Hash (Content ());

    }

    int IsEqual (String s) {return IsEqualTo (s);}
    int IsEqualTo (String s) {return Compare (s) == 0;}
    int IsGreaterThan (String s) {return Compare (s) > 0;}
    int IsGreaterThanOrEqualTo (String s) {return Compare (s) >= 0;}
    int IsLessThan (String s) {return Compare (s) < 0;}
    int IsLessThanOrEqualTo (String s) {return Compare (s) <= 0;}
    int IsNotEqualTo (String s) {return Compare (s) != 0;}

    int IsEqualToArrayOfChar (char s []) {
	return CompareToArrayOfChar (s) == 0;
    }
    int IsGreaterThanArrayOfChar (char s []) {
	return CompareToArrayOfChar (s) > 0;
    }
    int IsGreaterThanOrEqualToArrayOfChar (char s []) {
	return CompareToArrayOfChar (s) >= 0;
    }
    int IsLessThanArrayOfChar (char s []) {
	return CompareToArrayOfChar (s) < 0;
    }
    int IsLessThanOrEqualToArrayOfChar (char s []) {
	return CompareToArrayOfChar (s) <= 0;
    }
    int IsNotEqualToArrayOfChar (char s []) {
	return CompareToArrayOfChar (s) != 0;
    }

    unsigned int Length () {return Len;}

    int NCompare (String s, unsigned int n) {
	if (self == s)
	  return 0;

	if (Len < n || s->Length () < n) {
	    return Compare (s);
	} else {
	    unsigned int i;
	    int r;

	    for (i = 0; i < n; i ++) {
		if (r = At (i) - s->At (i))
		  return r;
	    }
	    return 0;
	}
    }

    int NCompareToArrayOfChar (char s [], unsigned int n) {
	if (Str == s)
	  return 0;

	if (Len < n) {
	    return CompareToArrayOfChar (s);
	} else {
	    unsigned int i;
	    int r;

	    for (i = 0; i < n; i ++) {
		if (r = At (i) - s [i])
		  return r;
	    }
	    return 0;
	}
    }

    void SetAt (unsigned int at, char c) {
	if (at < Len) {
	    Str [at] = c;
	} else {
	    raise StringExceptions::OutOfRange (at);
	}
    }

    void SetCapacity (unsigned int new_capacity) {
	if (new_capacity >= length Str) {
	    char tmp [] = Str;

	    length Str = new_capacity + 1;
	    inline "C" {
		OzExecFree ((OZ_Pointer)tmp);
	    }
	}
    }



    global Object Str2OID () {return ACO.Str2OID (Content ());}

    int StrChr (char c) {return ACO.StrChr (Content (), c);}
    int StrRChr (char c) {return ACO.StrRChr (Content (), c);}


    String ToLower () {
	unsigned int i;
	char c;

	for (i = 0; i < Len; i ++) {
	    c = At (i);
	    if (c >= 'A' && c <= 'Z') {
		SetAt (i, c - ('A' - 'a'));
	    }
	}
	return self;
    }

    String ToUpper () {
	unsigned int i;
	char c;

	for (i = 0; i < Len; i ++) {
	    c = At (i);
	    if (c >= 'a' && c <= 'z') {
		SetAt (i, c + ('A' + 'a'));
	    }
	}
	return self;
    }

    String DebugPrint(){
	char s [] = Content ();
	int len = Length ();

	inline "C" {
	    OzDebugf ("String (%d): %S\n", len, s);
	}
	return self;
    }
}
