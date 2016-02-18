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

//#define NORECORDACOPS

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


// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we don't have OzRename


// we distribute class not by tar'ed directory
//#define DISTRIBUTEWITHTAR

// we have bug in StreamBuffer


// we have no support for getting executor ID


// we don't use Object::GetPropertyPathName


// we have a bug in gen-spec-src


// we have a bug in reference counter treatment when forking thread
//#define NOFORKBUG

// we don't have a bug in assigning 0 to a record instance

/*
 * freader.oz
 *
 * file reader.
 */

abstract class FileReader {
  constructor: New;
  public:
    IsEndOfToken, ReadDefault, ReadIdentifier, ReadInteger,
    ReadObjectID, ReadString;
  protected: InitializeTokenReader;
  protected: aTokenReader;

/* instance variables */
    TokenReader aTokenReader;

/* abstract methods */
    TokenReader InitializeTokenReader (String file_name) : abstract;

/* method implementations */
    void New (String file_name) {
	debug (0, "FileReader::New");
	aTokenReader = InitializeTokenReader (file_name);
    }

    void DebugWrite (Token t) {
	int c;
	long l;
	char s [];
	global Object o;

	switch (t->Type ()) {
	  case TokenType::DefaultType:
	    c = narrow (DefaultToken, t)->Get ();
	    inline "C" {
		OzDebugf ("Default Type '%c'\n", c);
	    }
	    break;
	  case TokenType::EOFType:
	    inline "C" {
		OzDebugf ("EOF\n");
	    }
	    break;
	  case TokenType::IdentifierType:
	    s = narrow (IdentifierToken, t)->Get ()->Content ();
	    inline "C" {
		OzDebugf ("Identifier Type \"%S\"\n", s);
	    }
	    break;
	  case TokenType::IntegerType:
	    l = narrow (IntegerToken, t)->Get ();
	    inline "C" {
		OzDebugf ("Integer Type %ld\n", l);
	    }
	    break;
	  case TokenType::NewLineType:
	    inline "C" {
		OzDebugf ("New Line\n");
	    }
	    break;
	  case TokenType::OIDType:
	    o = narrow (OIDToken, t)->Get ();
	    inline "C" {
		OzDebugf ("OID Type 0x%O\n", o);
	    }
	  case TokenType::StringType:
	    s = narrow (StringToken, t)->Get ()->Content ();
	    inline "C" {
		OzDebugf ("String Type \"%S\"\n", s);
	    }
	    break;
	}
    }

    int IsEndOfToken () {
	return aTokenReader->IsEndOfToken ();
    }

    int ReadDefault (int expected) {
	Token t = aTokenReader->Next ();

	debug {
	    char c = expected;

	    debug (0, "FileReader::ReadDefault: expected token is %c\n", c);
	    DebugWrite (t);
	}

	if (t->Type () == TokenType::EOFType) {
	    debug (0, "Token Type is EOF.\n");
	    return 0;
	} else if (t->Type () != TokenType::DefaultType) {
	    debug (0, "Token Type is not EOF.\n");
	    raise FileReaderExceptions::SyntaxError (t);
	} else {
	    int c = narrow (DefaultToken, t)->Get ();

	    debug (0, "Token type is Default. c = %d\n", c);
	    if (c == expected) {
		debug (0, "Expected token is read.\n");
		return 1;
	    } else {
		raise FileReaderExceptions::SyntaxError (t);
	    }
	}
    }

    String ReadIdentifier () {
	Token t = aTokenReader->Next ();

	debug (0, "FileReader::ReadIdentifier\n");
	debug {DebugWrite (t);}

	if (t->Type () == TokenType::IdentifierType) {
	    return narrow (IdentifierToken, t)->Get ();
	} else {
	    raise FileReaderExceptions::SyntaxError (t);
	}
    }

    long ReadInteger () {
	Token t = aTokenReader->Next ();

	debug {DebugWrite (t);}

	if (t->Type () == TokenType::IntegerType) {
	    return narrow (IntegerToken, t)->Get ();
	} else {
	    raise FileReaderExceptions::SyntaxError (t);
	}
    }

    global Object ReadObjectID () {
	Token t = aTokenReader->Next ();

	debug {DebugWrite (t);}

	if (t->Type () == TokenType::IntegerType) {
	    global Object o;
	    long ret = narrow (IntegerToken, t)->Get ();
	    inline "C" {
		o = (OID) ret;
	    }
	    return o;
	} else if (t->Type () == TokenType::OIDType) {
	    return narrow (OIDToken, t)->Get ();
	} else {
	    raise FileReaderExceptions::SyntaxError (t);
	}
    }

    String ReadString () {
	Token t = aTokenReader->Next ();

	debug {DebugWrite (t);}

	if (t->Type () != TokenType::StringType) {
	    raise FileReaderExceptions::SyntaxError (t);
	} else {
	    return narrow (StringToken, t)->Get ();
	}
    }
}
