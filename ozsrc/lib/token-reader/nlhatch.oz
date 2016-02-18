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
 * nlhatch.oz
 *
 * New line and hatched comment disposer
 */

class NewLineAndHatchedCommentDisposer : TokenExtractor {
  constructor: New;
  public: Extract;

/* no instance variable */

/* method implementations */
    Token Extract (Stream file) {
	int c;

	debug (0, "NewLineAndHatchedCommentDisposer:: Extract: start\n");

	while ((c = file->GetC ()) == '\t' || c == ' ') {
	    debug {
		char cc = c;
		debug (0, "NewLineAndHatchedCommentDisposer::Extract: ");
		debug (0, "white space c = %c\n", cc);
	    }
	}
	debug {
	    char cc = c;
	    debug (0, " c = %c.\n", cc);
	}

	if (c == StreamConstants::EOF) {
	    return ReturnEOF ();
	} else if (c == '\n') {
	    debug (0, " NewLine detected.\n");
	    while (1) {
		c = file->GetC ();
		debug {
		    char cc = c;
		    debug (0, " next character c = %c\n", cc);
		}
		switch (c) {
		  case '#':
		    debug (0, " # detected.\n");
		    while ((c = file->GetC ()) != '\n') {
			debug {
			    char cc = c;
			    debug (0, " next char c = %c\n", cc);
			}
		    }
		    break;
		  case '\n':
		    break;
		  case StreamConstants::EOF:
		    return ReturnEOF ();
		    break;
		  default:
		    debug {
			char cc = c;
			debug (0, "Ungetting '%c'\n", cc);
		    }
		    file->UngetC (c);
		    return Extract (file);
		}
	    }
	} else {
	    debug {
		char cc = c;
		debug (0, "Ungetting '%c'\n", cc);
	    }
	    file->UngetC (c);
	    return 0;
	}
    }

    Token ReturnEOF () {
	EOFToken eof;
	return eof=>New ();
    }
}
