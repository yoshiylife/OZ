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

// we flush objects
//#define NOFLUSH

// we don't test flush
//#define FLUSHTESTATSTARTING

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


// we distribute class not by tar'ed directory


// we have a bug in class StreamBuffer


// we have no support for getting executor ID


// we use Object::GetPropertyPathName
//#define NOGETPROPERTYPATHNAME

// we have a bug in reference counter treatment when forking private thread
//#define NOFORKBUG

// we have a bug in OzOmObjectTableRemove
//#define NOBUGINOZOMOBJECTTABLEREMOVE

// we have no account directory


// we have no str[fp]time


// boot classes are modifiable


// we don't expire configuration cache
//#define EXPIRECONFIGURATIONCACHE
/*
 * oidextractor.oz
 *
 * Object Identifier extractor
 * Dependent to ASCII character set.
 * No support for internationalization.
 */

class OIDExtractor : TokenExtractor (rename New SuperNew;) {
  constructor: New;
  public: Extract;
  protected: IsDigit, IsHexaDigit;

/* instance variables */
    char Buffer [];

/* method implementations */
    void New () {
	length Buffer = 16;
    }

    Token Extract (Stream file) {
	int c;

	debug (0, "OIDExtractor::Extract\n");
	if (IsHexaDigit (c = file->GetC ())) {
	    return ExtractOID (c, file);
	} else if (c == StreamConstants::EOF) {
	    EOFToken eof;
	    return eof=>New ();
	} else {
	    file->UngetC (c);
	    return 0;
	}
    }

    OIDToken ExtractOID (int first, Stream file) {
	OIDToken token;
	long res;
	int i, c = first;

	debug (0, "OIDExtractor::ExtractOID\n");
	for (res = 0, i = 0; i < 16; i ++, c = file->GetC ()) {
	    Buffer [i] = c;
	    res <<= 4;
	    if (c >= '0' && c <= '9') {
		res += c - '0';
	    } else if (c >= 'a' && c <= 'f') {
		res += c - 'a' + 10;
	    } else if (c >= 'A' && c <= 'F') {
		res += c - 'A' + 10;
	    } else {
		/* Too short */
		for (; i >=0; -- i) {
		    file->UngetC (Buffer [i]);
		}
		return 0;
	    }
	}
	if (IsHexaDigit (c)) {
	    /* Too long */
	    file->UngetC (c);
	    for (i = 15; i >=0; -- i) {
		file->UngetC (Buffer [i]);
	    }
	    return 0;
	} else {
	    file->UngetC (c);
	    debug (0, "OIDExtractor::ExtractOID: OID %lx\n", res);
	    return token=>New (res);
	}
    }
}
