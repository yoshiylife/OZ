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
