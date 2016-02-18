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

/*
 * directory.oz
 *
 * Directory used in DirectoryServer <Directory <TEnt>, TEnt>
 */

/* TYPE PARAMETERS: TEnt */

class Directory <global ResolvableObject> {
  constructor: New;
  public:
    AddDirectory, AddEntry, Includes, IncludesEntry,
    IncludesSubdirectory, List, ListDirectory, ListEntry, Remove,
    RemoveDirectory, RemoveEntry, Retrieve, RetrieveDirectory, Update;

/* instance variables */
  protected: Entries, Subdirectories;

  protected: Debug;


    Dictionary <String, Directory <global ResolvableObject>> Subdirectories;
    Dictionary <String, global ResolvableObject> Entries;

    UnixIO Debug;


/* method implementations */
    void New () {
	Subdirectories=>New ();
	Entries=>New ();

	Debug=>New ();

    }

    void AddDirectory (String name, Directory <global ResolvableObject> d) {
	Subdirectories->AddAssoc (name, d);
    }

    void AddEntry (String name, global ResolvableObject e) {
	Entries->AddAssoc (name, e);
    }

    int Includes (String name) {
	return IncludesEntry (name) || IncludesSubdirectory (name);
    }

    int IncludesEntry (String name) {
	return Entries->IncludesKey (name);
    }

    int IncludesSubdirectory (String name) {
	return Subdirectories->IncludesKey (name);
    }

    Set <String> List () {
	return ListDirectory ()->AddContentsTo (ListEntry ());
    }

    Set <String> ListDirectory () {return Subdirectories->SetOfKeies ();}

    Set <String> ListEntry () {return Entries->SetOfKeies ();}

    void Remove (String name) {
	if (Subdirectories->IncludesKey (name)) {
	    Subdirectories->RemoveKey (name);
	} else if (Entries->IncludesKey (name)) {
	    Entries->RemoveKey (name);
	} else {
	    raise DirectoryExceptions::UnknownEntry (name);
	}
    }

    Directory <global ResolvableObject> RemoveDirectory (String name) {
	return Subdirectories->RemoveKey (name)->Value ();
    }

    global ResolvableObject RemoveEntry (String name) {



	return Entries->RemoveKey (name)->Value ();
    }

    global ResolvableObject Retrieve (String name) {
	return Entries->AtKey (name);
    }

    Directory <global ResolvableObject> RetrieveDirectory (String name) {
	return Subdirectories->AtKey (name);
    }

    global ResolvableObject Update (String name, global ResolvableObject new) {
	return Entries->SetAtKey (name, new);
    }
}
