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


// we use exceptions with parameters
//#define NOEXCEPTIONPARAMETER

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
//#define NOALIASBUG

// we have no executor who recognize relative path from OZHOME


// we have OzCopy
//#define NOOZCOPY

// we distribute class not by tar'ed directory


// we have bug in StreamBuffer


// we have no support for getting executor ID


// we don't use Object::GetPropertyPathName


// we have a bug in gen-spec-src

/*
 * pitreader.oz
 *
 * protected.i file token reader.
 */

class PrivateDotiTokenReader : TokenReader {
/* interface from superclasses */
  /* methods */
  constructor: New;
  public: Next;
  protected:
    ExtractorInit, GetATokenFromBuffer, IsEOF, Lex, PutATokenToBuffer,
    ReadATokenFromFile, SetEOF, WaitSignal;

  /* instance variables */
  protected:
    Buffer, EOF, ExtractorTable, aTokenIsReady;

/* no instance variable */

/* method implementations */
    void ExtractorInit () {
	TokenExtractor e [];
	NewLineDisposer nl=>New ();
	OIDExtractor oe=>New ();
	IntegerExtractor ie=>New ();
	LexicalError le=>New ();

	length e = 4;
	e [0] = nl;
	e [1] = oe;
	e [2] = ie;
	e [3] = le;
	ExtractorTable = e;
    }
}
