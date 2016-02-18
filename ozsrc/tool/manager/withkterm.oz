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
 * withkterm.oz
 *
 * launchable with kterm
 */

abstract class LaunchableWithKterm : Launchable {
  constructor: New;
  public: Go, Initialize, Launch;

  protected:
    BreakScroll, IsAlphabet, IsAlphanumeric, IsDigit, IsWhite, Read,
    ReadFromConsole, ReadObject, ReadOID, ReadOIDFromConsole, ReadYN,
    ReadYNFromConsole, SetPrompt, Start, Title, Trim, TypeChar, TypeInt,
    TypeOID, TypeReturn, TypeSpaces, TypeStr, TypeString, WriteStr;


  protected: CallStart;


/* instance variables */
    Console aConsole;

/* abstract methods */

    void Start () : abstract;
    String Title () : abstract;

/* method implementations */
    void New () : global {
	Initialize ();
	detach fork Go ();
    }

    void Go () : global {}

    void Initialize () {aConsole=>NewWithTitle (Title ());}

    void Launch () {detach fork CallStart ();}


    int BreakScroll () {
	String command;

	TypeStr ("------------<ret> to continue, q to quit------------");
	command = Read ();
	return command->Length () > 0 && command->At (0) == 'q';
    }

    void CallStart () : locked {
	aConsole->Open ();
	Start ();
	aConsole->Close ();
    }

    int IsAlphabet (int c) {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
    }

    int IsAlphanumeric (int c) {return IsAlphabet (c) || IsDigit (c);}

    int IsDigit (int c) {return c >= '0' && c <= '9';}

    int IsWhite (int c) {return (c == ' ') || (c == '\n') || (c == '\t');}

    String Read () {return aConsole->Read ();}

    String ReadFromConsole (Console dialog, String prompt) {
	dialog->Write (prompt);
	return dialog->Read ();
    }

    global Object ReadObject (char msg []) {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	global Object o;
	String name;

	while (1) {
	    TypeStr (msg);
	    name = Trim (Read ());
	    if (name->At (0) == ':' && (o = nd->Resolve (name)) != 0) {
		return o;
	    } else if ((o = name->Str2OID ()) != 0) {
		return o;
	    } else {
		TypeStr ("No such object.\n\n");
	    }
	}
    }

    global Object ReadOID () {
	String null=>NewFromArrayOfChar ("");

	return ReadOIDFromConsole (aConsole, null);
    }

    global Object ReadOIDFromConsole (Console dialog, String prompt) {
	String s;
	unsigned int i, len;
	global Object o = 0;
	unsigned long l = 0;

	while (1) {
	    dialog->Write (prompt);
	    s = dialog->Read ();
	    len = s->Length ();
	    if (len == 17) {
		for (i = 0; i < 16; i ++) {
		    int c = s->At (i);

		    if (c >= '0' && c <= '9') {
			l = l * 16 + c - '0';
		    } else if (c >= 'a' && c <= 'f') {
			l = l * 16 + c - 'a' + 10;
		    } else if (c >= 'A' && c <= 'F') {
			l = l * 16 + c - 'A' + 10;
		    } else {
			WriteStr (dialog, "Enter in 16 hexa-decimal ");
			WriteStr (dialog, "digits ([0-9a-fA-F]).\n\n");
		    }
		}
		inline "C" {
		    o = l;
		}
		break;
	    } else {
		WriteStr (dialog, "Enter in 16 hexa-decimal ");
		WriteStr (dialog, "digits ([0-9a-fA-F]).\n\n");
	    }
	}
	return o;
    }

    int ReadYN (int def) {
	String null=>NewFromArrayOfChar ("");
	return ReadYNFromConsole (def, aConsole, null);
    }

    int ReadYNFromConsole (int def, Console dialog, String prompt) {
	String answer;

	while (1) {
	    dialog->Write (prompt);
	    answer = Read ()->ToLower ();
	    if (answer->IsEqualToArrayOfChar ("y\n")
		|| answer->IsEqualToArrayOfChar ("yes\n")) {
		return 1;
	    } else if (answer->IsEqualToArrayOfChar ("n\n")
		       || answer->IsEqualToArrayOfChar ("no\n")) {
		return 0;
	    } else if (answer->IsEqualToArrayOfChar ("\n")) {
		return def;
	    } else {
		TypeStr ("Answer in `yes' or `no'.\n\n");
	    }
	}
    }

    String SetPrompt (String prompt) {return aConsole->SetPrompt (prompt);}

    String Trim (String s) {
	unsigned int i, b, e, len = s->Length ();


	for (i = 0, b = 0; i < len; i ++) {
	    if (! IsWhite (s->At (i))) {
		b = i;
		break;
	    }
	}
	if (i == len) {
	    String st=>NewFromArrayOfChar ("");
	    return st;
	}
	for (i = len, e = len; --i >= 0; ) {
	    if (! IsWhite (s->At (i))) {
		e = i;
		break;
	    }
	}
	return s->GetSubString (b, e - b + 1);
    }

    void TypeChar (int c) {
	char p [];
	String st;

	length p = 2;
	p [0] = c;
	p [1] = '\0';
	aConsole->Write (st=>NewFromArrayOfChar (p));
    }

    void TypeInt (int i) {
	ArrayOfCharOperators aco;
	String st;


	aConsole->Write (st=>NewFromArrayOfChar (aco.ItoA (i)));

    }

    void TypeOID (global Object o) {
	String st;

	aConsole->Write (st=>OIDtoHexa (o));
    }

    void TypeReturn () {
	String st;

	aConsole->Write (st=>NewFromArrayOfChar ("\n"));
    }

    void TypeSpaces (unsigned int column) {
	char buf [];
	unsigned int i;

	length buf = column + 1;
	for (i = 0; i < column; i ++) {
	    buf [i] = ' ';
	}
	buf [i] = 0;
	TypeStr (buf);
    }

    void TypeStr (char p []) {
	String st;

	aConsole->Write (st=>NewFromArrayOfChar (p));
    }

    void TypeString (String s) {aConsole->Write (s);}

    void WriteStr (Console dialog, char p []) {
	String s=>NewFromArrayOfChar (p);

	dialog->Write (s);
    }
}
