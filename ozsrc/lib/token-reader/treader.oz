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
 * treader.oz
 *
 * token reader.
 */

abstract class TokenReader {
  constructor: New;
  public: IsEndOfToken, Next;
  protected:
    ExtractorInit, GetATokenFromBuffer, IsEOF, Lex, PeekATokenAtBuffer,
    PutATokenToBuffer, ReadATokenFromFile, SetEOF, WaitSignal;

/* instance variables */
  protected:
    Buffer, EOF, ExtractorTable, aTokenIsReady;

    FIFO <Token> Buffer;
    condition aTokenIsReady;
    int EOF;
    TokenExtractor ExtractorTable [];

/* abstract methods */
    void ExtractorInit () : abstract;

/* method implementations */
    void New (String path) {
	Stream file;

	Buffer=>New ();
	ExtractorInit ();
	file=>New (path);
	detach fork Lex (file);
    }

    Token GetATokenFromBuffer () : locked {
	if (Buffer->IsEmpty ())
	  return 0;
	else
	  return Buffer->Get ();
    }

    int IsEndOfToken () {
	Token token;

	while ((token = PeekATokenAtBuffer ()) == 0) {
	    /* in case of buffer empty */
	    if (IsEOF ()) {
		return 1;
	    } else {
		WaitSignal ();
	    }
	}
	return token->Type () == TokenType::EOFType;
    }

    int IsEOF () : locked {return EOF;}

    void Lex (Stream file) {
	Token t;

	debug (0, "TokenReader::Lex: started.\n");
	while ((t = ReadATokenFromFile (file)) != 0) {
	    PutATokenToBuffer (t);
	}
    }

    Token Next () {
	Token token;




	debug (0, "TokenReader::Next: reading a token from buffer...\n");
	while ((token = GetATokenFromBuffer ()) == 0){
	    /* in case of buffer empty */
	    if (IsEOF ()) {
		EOFToken eof=>New ();
		return eof;
	    } else {
		debug (0, "TokenReader::Next: waiting to get\n");
		WaitSignal ();
	    }
	}
	debug (0, "TokenReader::Next: get a token. \"%S\"\n",
	       token->Print ()->Content ());
	return token;
    }

    Token PeekATokenAtBuffer () : locked {
	if (Buffer->IsEmpty ())
	  return 0;
	else
	  return Buffer->Peek ();
    }

    void PutATokenToBuffer (Token t) : locked {
	Buffer->Put (t);
	signal aTokenIsReady;
    }

    Token ReadATokenFromFile (Stream file) {



	while (! file->IsEndOfFile ()) {
	    unsigned int i, len = length ExtractorTable;

	    for (i = 0; i < len; i ++) {
		Token token;

		token = ExtractorTable [i]->Extract (file);
		if (token != 0) {



		    return token;
		    break;
		}
	    }
	}
	debug (0, "TokenReader::ReadaToken: EOF detected\n");
	SetEOF ();
	return 0;
    }

    void SetEOF () : locked {
	EOF = 1;
	signalall aTokenIsReady;
    }

    void WaitSignal () : locked {
	while (Buffer->IsEmpty () && ! EOF) {
	    wait aTokenIsReady;
	}
    }
}
