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
 * stream.oz
 *
 * Character stream
 */

inline "C" {
#include <fcntl.h>
}

class Stream {
  constructor: New, NewWithFlag;
  public:
    Close, GetC, GetS, GetTillaChar, IsEndOfFile, PutC, PutInt, PutOID, PutStr,
    UngetC;
  protected: Open, SetBufferCapacity, SetInitialUngottenBufferCapacity;

/* instance variables */
  protected: FileDescriptor, Buffer, Size, Pointer, Ungotten, RunOut;

    int BufferCapacity; /* = 4096; */
    int InitialUngottenBufferCapacity; /* = 16; */

    unsigned int FileDescriptor;
    char Buffer [];
    unsigned int Size, Pointer;
    int Ungotten [];
    unsigned int UngottenSize;
    int RunOut;

/* method implementations */
    void New (String path) {
	int mode;

	inline "C" {
	    mode = O_RDONLY;
	}
	Open (path, mode);
    }

    void NewWithFlag (String path, unsigned int flag) {
	Open (path, flag);
    }

    void Open (String path, unsigned int flag) {
	char path_name [] = path->Content ();
	int fd;

	SetBufferCapacity ();
	SetInitialUngottenBufferCapacity ();
	try {
	    char p [];

	    if (path->At (0) == '/') {
		/* Temporary. Absolute path should be interpreted as if */
		/* $OZHOME is the root directory. */
		p = path_name;
	    } else {

		p = PrependOZHOME (path_name);

	    }
	    inline "C" {
		fd = OzOpen (OZ_ArrayElement (p, char), flag, 0666);
	    }
	    if (fd == -1) {
		raise FileReaderExceptions::CannotOpenFile (path_name);
	    }
	} except {
	    default {
		raise FileReaderExceptions::CannotOpenFile (path_name);
	    }
	}
	length Buffer = BufferCapacity;
	Pointer = Size = 0;
	length Ungotten = InitialUngottenBufferCapacity;
	UngottenSize = 0;
	RunOut = 0;
	FileDescriptor = fd;
    }

    void Close () {
	unsigned int fd = FileDescriptor;

	inline "C" {
	    if (fd != -1) {
		OzClose (fd);
	    }
	}
	RunOut = 1;
	FileDescriptor = -1;
    }

    int GetC () {
	int res;

	if (UngottenSize > 0) {
	    res = Ungotten [-- UngottenSize];
	    Ungotten [UngottenSize] = 0;
	} else {
	    if (Pointer < Size) {
		res = Buffer [Pointer ++];
	    } else {
		if (! RunOut) {
		    ReadaPage ();
		}
		if (Pointer < Size) {
		    res = Buffer [Pointer ++];
		} else {
		    res = StreamConstants::EOF;
		}
	    }
	}
	debug {
	    char c = res;
	    debug (0, "Stream::GetC: returnd '%c'\n", c);
	}
	return res;
    }

    char GetS ()[] {return GetTillaChar ("\n");}

    char GetTillaChar (char stopper [])[] {
	char buf [];
	unsigned int bufmax = 8, bufp = 0, i;
	int c;

	length buf = bufmax;
	while (1) {
	    if (UngottenSize > 0) {
		c = Ungotten [-- UngottenSize];
		Ungotten [UngottenSize] = 0;
	    } else {
		if (Pointer < Size) {
		    c = Buffer [Pointer ++];
		} else {
		    if (! RunOut) {
			ReadaPage ();
		    }
		    if (Pointer < Size) {
			c = Buffer [Pointer ++];
		    } else {
			c = StreamConstants::EOF;
		    }
		}
	    }
	    if (c == StreamConstants::EOF) {
		length buf = bufp + 1;
		return buf;
	    }
	    buf [bufp ++] = c;
	    for (i = 0; stopper [i] != 0; i ++) {
		if (c == stopper [i]) {
		    length buf = bufp + 1;
		    return buf;
		}
	    }
	    if (bufp == bufmax) {
		bufmax *= 2;
		length buf = bufmax;
	    }
	}
    }

    int IsEndOfFile () {
	return RunOut && UngottenSize == 0 && Pointer == Size;
    }


    char PrependOZHOME (char p [])[] {
	if (p [0] == '/') {
	    return p;
	} else {
	    char home []; /* char* */
	    unsigned int len, s = 0;
	    char path [] = 0;

	    inline "C" {
		(char*)home = OzGetenv ("OZROOT");
		len = OzStrlen ((char*)home);
		if (((char*)home) [len - 1] != '/') {
		    s = 1;
		}
	    }
	    length path = len + s + length p + 1;
	    inline "C" {
		OzStrcpy (OZ_ArrayElement (path, char), (char*)home);
	    }
	    if (s == 1) {
		path [len] = '/';
		path [len + 1] = 0;
	    }
	    inline "C" {
		OzStrcat (OZ_ArrayElement (path, char),
			  OZ_ArrayElement (p, char));
	    }
	    return path;
	}
    }


    void PutC (char c) {
	char buf [];

	length buf = 1;
	buf [0] = c;
	PutStr (buf);
    }

    void PutInt (int i) {
	ArrayOfCharOperators acops;


	PutStr (acops.ItoA (i));

    }

    void PutOID (global Object o) {
	String st=>OIDtoHexa (o);

	PutStr (st->Content ());
    }

    void PutStr (char s []) {
	unsigned int fd = FileDescriptor, len = length s, i;
	int res;

	for (i = 0; i < len; i ++) {
	    if (s [i] == '\0') {
		break;
	    }
	}
	inline "C" {
	    res = OzWrite (fd, OZ_ArrayElement (s, char), i);
	}
	if (res == -1) {
	    int err;

	    inline "C" {
		err = errno;
	    }
	    raise FileReaderExceptions::CannotWrite (err);
	}
    }

    void ReadaPage () {
	int n, err;
	unsigned int fd = FileDescriptor;
	char buf [] = Buffer;
	unsigned int capa = BufferCapacity;

	inline "C" {
	    int nn;




	    n = OzRead (fd, OZ_ArrayElement (buf, char), capa);
	    if (n != -1) {
		while (n < capa) {
		    nn = OzRead (fd, OZ_ArrayElement (buf, char) + n,capa - n);
		    if (nn == 0) {
			break;
		    } else if (nn == -1) {
			n = -1;
			break;
		    } else {
			n += nn;
		    }
		}
	    }
	}
	if (n == -1) {
	    inline "C" {
		err = errno;
	    }
	    raise FileReaderExceptions::CannotRead (err);
	} else {
	    Size = n;
	    Pointer = 0;
	    if (Size < BufferCapacity) {
		Close ();
		debug (0, "Stream::ReadaPage: closed\n");
	    }
	}
	debug (0, "Stream::ReadaPage: size %d, \"%S\"\n", n, buf);
    }

    void SetBufferCapacity () {BufferCapacity = 4096;}

    void SetInitialUngottenBufferCapacity () {
	InitialUngottenBufferCapacity = 16;
    }

    void UngetC (int c) {
	if (UngottenSize == length Ungotten) {
	    length Ungotten += InitialUngottenBufferCapacity;
	}
	Ungotten [UngottenSize ++] = c;
    }
}
