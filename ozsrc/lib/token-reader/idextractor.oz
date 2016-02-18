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
 * idextractor.oz
 *
 * Identifier extractor
 * No support for internationalization
 */

class IdentifierExtractor : TokenExtractor (rename New SuperNew;) {
/* method interface */
  constructor: New;
  public: Extract;
  protected: IsDigit, IsLetter, SetInitialBufferSize;

/* instance variables */
    unsigned int InitialBufferSize; /* = 16; */

/* method implementations */
    void New () {
	SuperNew ();
	SetInitialBufferSize ();
    }

    Token Extract (Stream file) {
	int c;

	if (IsLetter (c = file->GetC ())) {
	    return ExtractIdentifier (c, file);
	} else if (c == StreamConstants::EOF) {
	    EOFToken eof;
	    return eof=>New ();
	} else {
	    file->UngetC (c);
	    return 0;
	}
    }

    IdentifierToken ExtractIdentifier (int first, Stream file) {
	IdentifierToken token;
	char buffer [];
	unsigned int i = 0;
	int c = first;

	length buffer = InitialBufferSize;
	do {
	    buffer [i ++] = c;
	    if (i == length buffer)
	      length buffer += InitialBufferSize;
	} while (IsLetter (c = file->GetC ()) || IsDigit (c));
	buffer [i] = 0;
	if (c != StreamConstants::EOF)
	  file->UngetC (c);
	return token=>New (buffer);
    }

    void SetInitialBufferSize () {InitialBufferSize = 16;}
}
