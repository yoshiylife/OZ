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
 * daemonfc.oz
 *
 * Common interface for class daemon process initializer.
 * Abstract class.
 */

abstract class DaemonForClass : Daemon(rename New SuperNew;) {
  public: GetNumberOfProcesses, SetNumberOfProcesses, Start;
  protected: ClassPropertyPath, DaemonProcess, New, SearchClass;

/* instance variables */
  protected: AID, ClassDirectoryPath, NumberOfProcesses, OM, StandAlone;

  protected: anExecutor;


    ArchitectureID AID;
    int StandAlone;
    String ClassDirectoryPath;

/* method implementations */

    void New(Executor e, unsigned int n, int stand_alone) {
	SuperNew(e, n);
	AID=>New(anExecutor->OzMyArchitecture());
	StandAlone = stand_alone;
	if (StandAlone) {
	    InitializeClassDirectoryPath();
	}
    }


    global Class SearchClass(global ClassID cid) {
	return OM->SearchClassImpl(cid, AID);
    }

    void InitializeClassDirectoryPath() {
	/* Prepares a path name of the class directory.
	   "images/<EXID>/classes" */
	String exid=>OIDtoHexa(Where());
	ClassDirectoryPath=>NewFromArrayOfChar("images/");
	ClassDirectoryPath
	  = ClassDirectoryPath->Concatenate(exid->GetSubString(4, 6))
	    ->ConcatenateWithArrayOfChar("/classes/");
    }

    String ClassPropertyPath(global ClassID vid, char propertyName[]) {
	String vidstr=>OIDtoHexa(vid);
	return
	  ClassDirectoryPath
	    ->Concatenate(vidstr)
	      ->ConcatenateWithArrayOfChar("/")
		->ConcatenateWithArrayOfChar(propertyName);
    }
}
