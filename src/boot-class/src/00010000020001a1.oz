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
 * fops.oz
 *
 * File operators.
 */

inline "C" {
#include <oz++/object-type.h>
}

record FileOperators {
/* interface */
  /* operators */
/*
  public:
    Copy, CopyDirectoryElement, IsExists, List, MakeDirectory, Move,
    Remove, RemoveDirectory, Symlink, Tar, Touch, Untar;
*/
  /* no members */

/* operator implementations */
    void Copy (String from, String to) {

	char from_p [] = from->Content ();
	char to_p [] = to->Content ();
	int ret;


	from_p = PrependOZHOME (from_p);
	to_p = PrependOZHOME (to_p);

	inline "C" {
	    ret = OzCopy (OZ_ArrayElement (from_p, char),
			  OZ_ArrayElement (to_p, char));
	}
	if (ret < 0) {
	    String command;

	    command=>NewFromArrayOfChar ("cp ");
	    command
	      = command->ConcatenateWithArrayOfChar (from_p)
		->ConcatenateWithArrayOfChar (" ")
		  ->ConcatenateWithArrayOfChar (to_p);
	    raise FileExceptions::CommandFailed (command->Content ());
	}

    }

    void CopyDirectoryElement (String from_dir, String to_dir) {

	char from_dir_p [];
	char to_dir_p [];
	int ret;
	unsigned int i, len;
	char files [][];
	ArrayOfCharOperators acops;


	from_dir_p = from_dir->ConcatenateWithArrayOfChar ("/")->Content ();
	to_dir_p = to_dir->ConcatenateWithArrayOfChar ("/")->Content ();

	from_dir_p = PrependOZHOME (from_dir_p);
	to_dir_p = PrependOZHOME (to_dir_p);

	files = List (from_dir);
	len = length files;
	for (i = 0; i < len; i ++) {
	    char from_p [], to_p [];


	    from_p = acops.Concatenate (from_dir_p, files [i]);
	    to_p = acops.Concatenate (to_dir_p, files [i]);

	    inline "C" {
		ret = OzCopy (OZ_ArrayElement (from_p, char),
			      OZ_ArrayElement (to_p, char));
	    }
	    if (ret < 0) {
		String command;

		command=>NewFromArrayOfChar ("cp ");
		command
		  = command
		    ->ConcatenateWithArrayOfChar (from_p)
		      ->ConcatenateWithArrayOfChar (" ")
			->ConcatenateWithArrayOfChar (to_p);
		raise FileExceptions::CommandFailed (command->Content ());
	    }
	}

    }

    String Execute (String command) {
	UnixCommand uc=>New ();
	String result=>New ();
	int status;



	status = uc->Execute (command, result, 0);
	/* 0 means no-verbose mode */


	if (status != 0) {
	    raise FileExceptions::CommandFailed (command->Content ());
	}
	return result;
    }

    int IsExists (String path_name) {
	char p [] = path_name->Content ();
	int res;


	p = PrependOZHOME (p);

	inline "C" {
	    res = OzAccess (OZ_ArrayElement (p, char), F_OK);
	}
	return res == 0;
    }

    int IsPlainFile (String path_name) {
	char p [] = path_name->Content ();
	int res;


	p = PrependOZHOME (p);

	inline "C" {
	    struct stat s;
	    res = ((OzStat (OZ_ArrayElement (p, char), &s) == 0)
		   && S_ISREG (s.st_mode));
	}
	return res;
    }

    /*
     * checks if the file cannot read/write other than the owner.
     */
    int IsSecureFile (String path_name) {
	char p [] = path_name->Content();
	int res;


	p = PrependOZHOME (p);

	inline "C" {
	    struct stat s;
	    res = ((OzStat (OZ_ArrayElement (p, char), &s) == 0)
		   && ((s.st_mode & (S_IRWXG | S_IRWXO)) == 0));
	}
	return res;
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


    char List (String path_name)[][] {
	unsigned int initial_res_len = 10;
	char p [] = path_name->Content ();
	char res [][] = 0, tmp [][];
	int i, len;
	/* DIR* */ char dirp [];


	p = PrependOZHOME (p);

	inline "C" {
	    (DIR*)dirp = OzOpendir (OZ_ArrayElement (p, char));
	}
	if (dirp == 0) {
	    raise FileExceptions::CannotOpenDirectory (p);
	} else {
	    for (i = 0; ; i ++) {
		/* struct dirent* */ char buf [];

		inline "C" {
		    (struct dirent*)buf = OzReaddir ((DIR*)dirp);
		}
		if (buf == 0) {
		    inline "C" {
			OzClosedir ((DIR*)dirp);
		    }
		    break;
		} else {
		    int c;

		    debug {
			inline "C" {
			    OzDebugf (((struct dirent*)buf)->d_name);
			}
		    }
		    inline "C" {
			c = ((struct dirent*)buf)->d_name [0];
		    }
		    if (c == '.') {
			--i;
		    } else {
			if (i % initial_res_len == 0) {
			    res = ResizeArray (res, initial_res_len);
			}
			inline "C" {
			    len = OzStrlen (((struct dirent*)buf)->d_name);
			}
			length res [i] = len + 1;
			inline "C" {
			    /* strcpy (res [i], buf->d_name) */
			    OzStrcpy ((char*)(((OZ_Array*)(res->mem))[i]->mem),
				      ((struct dirent*)buf)->d_name);
			}
		    }
		}
	    }
	}
	len = length res;
	if (i < len) {
	    res = ResizeArray (res, i - len);
	}
	return res;
    }

    void MakeDirectory (String path) {
	char p [] = path->Content ();
	int ret;


	p = PrependOZHOME (p);

	inline "C" {
	    ret = OzMkdir (OZ_ArrayElement (p, char),
			   S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
	}

	if (ret == -1) {
	    String command=>NewFromArrayOfChar ("mkdir ");

	    command = command->ConcatenateWithArrayOfChar (p);
	    raise FileExceptions::CommandFailed (command->Content ());
	}
/*
  String command;

  Execute (command=>NewFromArrayOfChar ("mkdir ")->Concatenate (path));
*/
    }

    void Move (String from, String to) {
	char from_p [] = from->Content ();
	char to_p [] = to->Content ();
	int ret;


	from_p = PrependOZHOME (from_p);
	to_p = PrependOZHOME (to_p);


	inline "C" {
	    ret = OzLink (OZ_ArrayElement (from_p, char),
			  OZ_ArrayElement (to_p, char));
	    if (ret == 0) {
		ret = OzUnlink (OZ_ArrayElement (from_p, char));
	    }
	}

	if (ret < 0) {
	    String command=>NewFromArrayOfChar ("mv ");

	    command = command->ConcatenateWithArrayOfChar (from_p)
	                         ->ConcatenateWithArrayOfChar (" ")
				     ->ConcatenateWithArrayOfChar (to_p);
	    raise FileExceptions::CommandFailed (command->Content ());
	}
    }

    void Remove (String path) {
	char p [] = path->Content ();
	int ret;


	p = PrependOZHOME (p);

	inline "C" {
	    ret = OzUnlink (OZ_ArrayElement (p, char));
	}
	if (ret == -1) {
	    String command=>NewFromArrayOfChar ("rm -f ");

	    command = command->ConcatenateWithArrayOfChar (p);
	    raise FileExceptions::CommandFailed (command->Content ());
	}
/*
  String command;

  Execute (command=>NewFromArrayOfChar ("rm -f ")->Concatenate (path));
*/
    }

    void RemoveDirectory (String path) {
	String command;

	Execute (command=>NewFromArrayOfChar ("rm -rf ")->Concatenate (path));
    }

    char ResizeArray (char a [][], unsigned int l)[][] {
	unsigned int old_len = length a;
	char tmp [][] = a;
	unsigned int i;

	length a += l;
	for (i = 0; i < old_len; i ++) {
	    tmp [i] = 0;
	}
	inline "C" {
	    if (tmp != 0)
	      OzExecFree ((OZ_Pointer)tmp);
	}
	return a;
    }

    void Symlink (String from, String to) {
	char from_p [] = from->Content ();
	char to_p [] = to->Content ();
	int ret;


	from_p = PrependOZHOME (from_p);
	to_p = PrependOZHOME (to_p);

	inline "C" {
	    ret = OzSymlink (OZ_ArrayElement (from_p, char),
			     OZ_ArrayElement (to_p, char));
	}
	if (ret < 0) {
	    String command;

	    command=>NewFromArrayOfChar ("ln -s ");
	    command
	      = command->ConcatenateWithArrayOfChar (from_p)
		->ConcatenateWithArrayOfChar (" ")
		  ->ConcatenateWithArrayOfChar (to_p);
	    raise FileExceptions::CommandFailed (command->Content ());
	}
    }

    void Tar (String dir, String tar_file, String files) {
	String command;
	char dir_p [] = dir->Content ();
	char tar_file_p [] = tar_file->Content ();


	dir_p = PrependOZHOME (dir_p);
	tar_file_p = PrependOZHOME (tar_file_p);


	Execute (command
		 =>NewFromArrayOfChar ("cd ")
		 ->ConcatenateWithArrayOfChar (dir_p)
		 ->ConcatenateWithArrayOfChar ("; tar cf ")
		 ->ConcatenateWithArrayOfChar (tar_file_p)
		 ->ConcatenateWithArrayOfChar (" ")
		 ->Concatenate (files));
    }

    void Touch (String path) {
	char p [] = path->Content ();
	int fd;


	p = PrependOZHOME (p);

	inline "C" {
	    fd = OzCreat (OZ_ArrayElement (p, char),
			  S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH);
	}
	if (fd == -1) {
	    String command=>NewFromArrayOfChar ("touch ");

	    command->ConcatenateWithArrayOfChar (p);
	    raise FileExceptions::CommandFailed (command->Content ());
	} else {
	    inline "C" {
		OzClose (fd);
	    }
	}
    }

    void Untar (String dir, String tar_file) {
	String command;
	char dir_p [] = dir->Content (), tar_file_p [] = tar_file->Content ();


	dir_p = PrependOZHOME (dir_p);
	tar_file_p = PrependOZHOME (tar_file_p);

	Execute (command
		 =>NewFromArrayOfChar ("cd ")
		 ->ConcatenateWithArrayOfChar (dir_p)
		 ->ConcatenateWithArrayOfChar ("; tar xf ")
		 ->ConcatenateWithArrayOfChar (tar_file_p));
    }
}
