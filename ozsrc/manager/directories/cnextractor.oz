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
 * cnextractor.oz
 *
 * Class name extractor
 */

class ClassNameExtractor : TokenExtractor {
  constructor: New;
  public: Extract;

/* instance variables */

/* method implementations */
    Token Extract (Stream file) {
	int c;

	if ((c = file->GetC ()) == StreamConstants::EOF) {
	    EOFToken eof;
	    return eof=>New ();
	} else if (IsLetter (c)) {
	    return ExtractClassName (c, file);
	} else {
	    file->UngetC (c);
	    return 0;
	}
    }

    StringToken ExtractClassName (int c, Stream file) {
	char buffer [];
	unsigned int bufferp = 0;
	int state = 0, spaced = 0, angle = 0;

	length buffer = 32;

	/* state
	 *  0 ... initial
	 *  1 ... in a first identifier
	 *  2 ... after a collon
	 *  3 ... after a double collon
	 *  4 ... in a second identifier
	 *  5 ... after a left angle
	 *  6 ... after right angle(s)
	 *  7 ... after a left bracket
	 *  8 ... after a bracket pair
	 *  9 ... after a comma
	 * 10 ... after an asterisk
	 * 99 ... error
	 */

	while (1) {
	    switch (c) {
	      case ':':
		if (state == 1) {
		    state = 2;
		} else if (state = 2) {
		    state = 3;
		} else {
		    state = 99;
		}
		break;
	      case '<':
		if (state == 1 || state == 4) {
		    ++ angle;
		    state = 5;
		} else {
		    state = 99;
		}
		break;
	      case '*':
		if (state == 5 || state == 9) {
		    state = 10;
		} else {
		    state = 99;
		}
		break;
	      case ',':
		if (angle > 0 &&
		    (state == 1 || state == 4 || state == 6 || state == 8 ||
		     state == 10)) {
		    state = 9;
		} else {
		    state = 99;
		}
		break;
	      case '>':
		if (angle > 0 &&
		    (state == 1 || state == 4 || state == 6 || state == 8 ||
		     state == 10)) {
		    -- angle;
		    state = 6;
		} else {
		    state = 99;
		}
		break;
	      case '[':
		if (state == 1 || state == 4 || state == 6 || state == 8) {
		    if (spaced) {
			buffer [bufferp ++] = ' ';
			if (bufferp == length buffer) {
			    length buffer = length buffer + 32;
			}
		    }
		    state = 7;
		} else {
		    state = 99;
		}
		break;
	      case ']':
		state = ((state == 7) ? 8 : 99);
		break;
	      case '\n':
		if (angle == 0 && (state == 1 || state == 4 || state == 6)) {
		    StringToken token=>New (buffer);

		    return token;
		} else {
		    state = 99;
		}
		break;
	      case ' ':
	      case '\t':
		if (state == 1 || state == 4) {
		    if (angle == 0) {
			StringToken token=>New (buffer);

			return token;
		    } else {
			spaced = 1;
			c = 0;
		    }
		} else if (state == 8) {
		    if (angle == 0) {
			state = 99;
		    } else {
			spaced = 1;
			c = 0;
		    }
		} else if (! (state == 0 || state == 3 || state == 5 ||
			      state == 6 || state == 9 || state == 10)) {
		    state = 99;
		}
		break;
	      default:
		if (IsLetter (c)) {
		    if (state == 0) {
			spaced = 0;
			state = 1;
		    } else if (state == 1) {
			if (spaced) {
			    buffer [bufferp ++] = ' ';
			    if (bufferp == length buffer) {
				length buffer = length buffer + 32;
			    }
			}
		    } else if (state == 3) {
			state = 4;
		    } else if (state == 4) {
			state = 4;
		    } else if (state == 5) {
			state = 1;
		    } else if (state == 9) {
			state = 1;
		    } else {
			state = 99;
		    }
		} else if (IsDigit (c)) {
		    if (state == 1 || state == 4) {
			;
		    } else {
			state = 99;
		    }
		} else {
		    state = 99;
		}
		break;
	    }
	    if (state == 99) {
		Rewind (file, c, buffer, bufferp);
		return 0;
	    } else {
		if (c != 0) {
		    buffer [bufferp ++] = c;
		    if (bufferp == length buffer) {
			length buffer = length buffer + 32;
		    }
		}
		c = file->GetC ();
	    }
	}
    }

    void Rewind (Stream file, int c, char buffer [], int bufferp) {
	file->UngetC (c);
	for (; -- bufferp >= 0;) {
	    file->UngetC (buffer [bufferp]);
	}
    }
}
