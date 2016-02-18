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
 * fcontent.oz
 *
 * FileContent - byte array read from a file
 */

inline "C" {
#include <fcntl.h>
}

class FileContent {
  constructor: New;
  public: Get;

/* instance variables */
    char Content [];
    int Length;

/* method implementations */
    void New (String path_name) {
	int fd = Open (path_name);

	Read (fd);
	Close (fd);
    }

    void Close (int fd) {
	inline "C" {
	    OzClose (fd);
	}
    }

    String Get () {
	String st=>NewFromArrayOfChar (Content);

	return st;
    }

    int Open (String path_name) {
	char cont [] = path_name->Content ();
	int fd;

	try {
	    char p [];
	    int len;
	    int flag;

	    inline "C" {
		flag = O_RDONLY;
	    }
	    if (cont [0] == '/') {
		/* Temporary. Absolute path name should be interpreted */
		/* as if $OZHOME is the root directory. */
		p = cont;
	    } else {

		p = PrependOZHOME (cont);

	    }
	    inline "C" {
		struct stat buf;
		char *path = OZ_ArrayElement (p, char);
		int res;

		res = OzStat (path, &buf);
		len = buf.st_size;
		if (res == 0) {
		    fd = OzOpen (path, flag, 0666);
		} else {
		    fd = -1;
		}
	    }
	    if (fd == -1) {
		raise FileReaderExceptions::CannotOpenFile (cont);
	    } else {
		Length = len;
	    }
	} except {
	    default {
		raise FileReaderExceptions::CannotOpenFile (cont);
	    }
	}
	return fd;
    }


    char PrependOZHOME (char p [])[] {
	if (p [0] == '/' || p [0] == '.') {
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
	    length path = len + length p + s + 1;
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


    void Read (int fd) {
	char c [];
	int len = Length;
	int res;

	length Content = Length + 1;
	c = Content;
	inline "C" {
	    res = OzRead (fd, OZ_ArrayElement (c, char), len);
	}
	if (res == -1) {
	    raise FileReaderExceptions::CannotRead;
	}
    }
}
