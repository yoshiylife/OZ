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
 * directory.oz
 *
 * Directory used in DirectoryServer <Directory <TEnt>, TEnt>
 */

/* TYPE PARAMETERS: TEnt */

class Directory <TEnt> {
  constructor: New;
  public:
    AddDirectory, AddEntry, Includes, IncludesEntry, IncludesSubdirectory,
    List, ListDirectory, ListEntry, Remove, RemoveDirectory, RemoveEntry,
    Retrieve, RetrieveDirectory, Update;

/* instance variables */
  protected: Entries, Subdirectories;

  protected: Debug;


    Dictionary <String, Directory <TEnt>> Subdirectories;
    Dictionary <String, TEnt> Entries;

    UnixIO Debug;


/* method implementations */
    void New () {
	Subdirectories=>New ();
	Entries=>New ();

	Debug=>New ();

    }

    void AddDirectory (String name, Directory <TEnt> d) {
	Subdirectories->AddAssoc (name, d);
    }

    void AddEntry (String name, TEnt e) {
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

    Directory <TEnt> RemoveDirectory (String name) {
	return Subdirectories->RemoveKey (name)->Value ();
    }

    TEnt RemoveEntry (String name) {



	return Entries->RemoveKey (name)->Value ();
    }

    TEnt Retrieve (String name) {
	return Entries->AtKey (name);
    }

    Directory <TEnt> RetrieveDirectory (String name) {
	return Subdirectories->AtKey (name);
    }

    TEnt Update (String name, TEnt new) {
	return Entries->SetAtKey (name, new);
    }
}
