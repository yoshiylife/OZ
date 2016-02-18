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

/*
 * textractor.oz
 *
 * Token extractor
 * Dependent to ASCII character set
 * No support for internationalization
 */

abstract class TokenExtractor {
  constructor: New;
  public: Extract;
  protected: IsAlphanumeric, IsDigit, IsHexaDigit, IsLetter, IsSpace;

/* no instance variable */

/* abstract methods */
    Token Extract (Stream file) : abstract;

/* method implementations */
    void New () {} /* used as constructor in subclasses */

    /* Tentative version. Not efficient. */
    int IsAlphanumeric (int c) {
	return IsDigit (c) || IsLetter (c);
    }

    int IsDigit (int c) {
	return c >= '0' && c <= '9';
    }

    int IsHexaDigit (int c) {
	debug (0, "TokenExtractor::IsHexaDigit: c = %d\n", c);
	return
	  IsDigit (c) || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F';
    }

    int IsLetter (int c) {
	return
	  c == '_' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z';
    }

    int IsSpace (int c) {return c == ' ' || c == '\t' || c == '\n';}
}
