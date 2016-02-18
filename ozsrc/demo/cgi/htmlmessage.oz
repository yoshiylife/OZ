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
 * htmlmessage.oz
 *
 * Message in HTML
 */

class HTMLMessage :
  SimpleStringTable <Set <String>> (alias New SuperNew;
				    rename Initialize SuperInitialize;
				    rename Add SuperAdd;)
{
  constructor: New, NewFromArrayOfChar;
  public:
    Add, At, AtKey, Encode, Hash, IncludesKey, IsEqual, KeyAt, RemoveKey, Size;

    void New () {
	String m=>NewFromArrayOfChar ("");

	Initialize (m);
    }

    void NewFromArrayOfChar (char s []) {
	String m=>NewFromArrayOfChar (s);

	Initialize (m);
    }

    void NewFromString (String m) {
	Initialize (m);
    }

    void Add (String key, String value) {
	Set <String> set;

	if (IncludesKey (key)) {
	    set = AtKey (key);
	} else {
	    set=>New ();
	    SuperAdd (key, set);
	}
	set->Add (value);
    }

    void Initialize (String m) {
	int eq, amp;
	String key, value;
	Set <String> set;

	SuperNew ();
	while (m->Length () > 0) {
	    eq = m->StrChr ('=');
	    amp = m->StrChr ('&');
	    if (amp == -1) {
		amp = m->Length ();
	    }
	    if (eq == -1 || amp <= eq) {
		raise HTMLMessageExceptions::IllegalFormat (m);
	    }
	    key = Decode (m->GetSubString (0, eq));
	    if (amp == eq + 1) {
		value=>NewFromArrayOfChar ("");
	    } else {
		value = Decode (m->GetSubString (eq + 1, amp - eq - 1));
	    }
	    Add (key, value);
	    if (amp == m->Length ())
	      break;
	    m = m->GetSubString (amp + 1, 0);
	}
    }

    String Decode (String original) {
	unsigned int i, p, len = original->Length ();
	char from [] = original->Content ();
	char to [];
	String result;

	length to = len + 1;
	for (i = 0, p = 0; i < len; i ++, p ++) {
	    switch (from [i]) {
	      case '%':
		to [p] = HexadecimalDigitToInt (from [++ i]) * 16;
		to [p] += HexadecimalDigitToInt (from [++ i]);
		break;
	      case '+':
		to [p] = ' ';
		break;
	      default:
		to [p] = from [i];
		break;
	    }
	}
	to [p] = 0;
	length to = p + 1;
	return result=>NewFromArrayOfChar (to);
    }

    String Encode (String original) {
	unsigned int i, p, len = original->Length ();
	char from [] = original->Content ();
	char to [];
	String result;

	length to = 3 * len + 1;
	for (i = 0, p = 0; i < len; i ++, p ++) {
	    if ('0' <= from [i] && from [i] <= '9'
		|| 'a' <= from [i] && from [i] <= 'z'
		|| 'A' <= from [i] && from [i] <= 'Z'
		|| from [i] == '@'
		|| from [i] == '_'
		|| from [i] == '-'
		|| from [i] == '.') {
		to [p ++] = from [i];
	    } else if (from [i] == ' ') {
		to [p ++] = '+';
	    } else {
		to [p ++] = '%';
		to [p ++] = IntToHexadecimalDigit (from [i] / 16);
		to [p] = IntToHexadecimalDigit (from [i] % 16);
	    }
	}
	to [p] = 0;
	length to = p + 1;
	return result=>NewFromArrayOfChar (to);
    }

    unsigned int Hash () {
	unsigned int i, len = Capacity ();

	for (i = 0; i < len; i ++) {
	    String st = KeyAt (i);

	    if (st != 0) {
		return st->Hash () + len;
	    }
	}
	return len;
    }

    int HexadecimalDigitToInt (char c) {
	return ('0' <= c && c <= '9') ? c - '0' : c - 'A' + 10;
    }

    char IntToHexadecimalDigit (int i) {
	return (i < 10) ? '0' + i : 'A' + i - 10;
    }

    int IsEqual (HTMLMessage m) {
	return 0;
    }
}
