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
 * intextractor.oz
 *
 * Integer extractor
 * Dependent to ASCII character set.
 * No support for internationalization.
 */

class IntegerExtractor : TokenExtractor {
  constructor: New;
  public: Extract;
  protected: IsDigit;

/* no instance variable */

/* method implementations */
    Token Extract (Stream file) {
	int c;

	debug (0, "IntegerExtractor::Extract\n");

	if (IsDigit (c = file->GetC ())) {
	    return ExtractInteger (c, file);
	} else if (c == '-') {
	    c = file->GetC ();
	    if (IsDigit (c)) {
		return ExtractDecimal (c, file, -1);
	    } else {
		file->UngetC(c);
		file->UngetC('-');
		return 0;
	    }
	} else if (c == StreamConstants::EOF) {
	    EOFToken eof;
	    return eof=>New ();
	} else {
	    file->UngetC (c);
	    return 0;
	}
    }

    IntegerToken ExtractHexa (int first, Stream file) {
	long res = 0;
	int c = first;

	debug (0, " start from 0x.\n");

	while (1) {
	    c = file->GetC ();
	    if (c >= '0' && c <= '9') {
		res *= 16;
		res += c - '0';
	    } else if (c >= 'a' && c <= 'f') {
		res *= 16;
		res += c - 'a' + 10;
	    } else if (c >= 'A' && c <= 'F') {
		res *= 16;
		res += c - 'A' + 10;
	    } else {
		break;
	    }
	}

	debug {
	    char cc = c;
	    debug (0, " trailer is %c.\n", cc);
	}

	c = trailing_L (file, c);
	file->UngetC (c);

	debug {
	    char cc = c;
	    debug (0, " ungetting char is '%c'.\n", cc);
	    debug (0, " returning (hexa) %lx\n", res);
	}

	{
	    IntegerToken token=>New (res);




	    return token;
	}
    }

    IntegerToken ExtractOctal (int first, Stream file) {
	IntegerToken token;
	long res = 0;
	int c = first;

	debug {
	    char cc = c;
	    debug (0, " start from 0. next = %c.\n", cc);
	}

	res = c - '0';
	for (;; c = file->GetC ()) {
	    if (c >= '0' && c <= '7') {
		res *= 8;
		res += c - '0';
	    } else {
		break;
	    }
	}

	debug {
	    char cc = c;
	    debug (0, " trailer is %c.\n", cc);
	}

	c = trailing_L (file, c);
	file->UngetC (c);

	debug {
	    char cc = c;
	    debug (0, " ungetting char is %c.\n", cc);
	    debug (0, " returning (octal) %ld\n", res);
	}
	return token=>New (res);
    }

    IntegerToken ExtractDecimal (int first, Stream file, int sign) {
	IntegerToken token;
	long res;
	int c = first;

	res = c - '0';
	while (IsDigit (c = file->GetC ())) {
	    res *= 10;
	    res += c - '0';
	}
	res *= sign;
	c = trailing_L (file, c);
	file->UngetC (c);

	debug {
	    char cc = c;
	    debug (0, " ungetting char is '%c'.\n", cc);
	    debug (0, " returning (decimal) %ld\n", res);
	}
	return token=>New (res);
    }

    IntegerToken ExtractInteger (int first, Stream file) {
	IntegerToken token;
	long res;
	int c = first;

	debug {
	    char cc = c;
	    debug (0, "IntegerExtractor::ExtractInteger: start. c = %c\n", cc);
	}

	if (c == '0') {
	    c = file->GetC ();
	    if (c == 'x' || c == 'X') {
		return ExtractHexa (c, file);
	    } else if (c >= '0' && c <= '7') {
		return ExtractOctal (c, file);
	    } else {
		file->UngetC (c);

		debug {
		    char cc = c;
		    debug (0, " ungetting char is '%c'.\n", cc);
		    debug (0, " returning 0\n");
		}
		return token=>New (0LL);
	    }
	} else {
	    return ExtractDecimal (c, file, 1);
	}
    }

    int trailing_L (Stream file, int c) {
	unsigned int i;

	for (i = 0; i < 2; i ++) {
	    if (c == 'L')
	      c = file->GetC();
	    else
	      break;
	}
	return c;
    }
}
