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
 * classdaemon.oz
 *
 * Runtime class information fault daemon.
 */

class ClassRequestDaemon : DaemonForClass (alias New SuperNew;) {
  constructor: New;
  public: GetNumberOfProcesses, SetNumberOfProcesses, Start;
  protected: DaemonProcess;

  protected: AID, ClassDirectoryPath, NumberOfProcesses, OM, StandAlone;

  protected: anExecutor;


/* no instance variable */

/* method implementations */

    void New (Executor e, unsigned int n, int stand_alone) {
	SuperNew (e, n, stand_alone);
	AID=>Any ();
    }


    void DaemonProcess () {
	global ConfiguredClassID ccid;
	char file_name [];



	inline "C" {
	    _oz_debug_flag = 0;
	}


	while (1) {
	    try {

		ccid = anExecutor->OzClassRequest ();

		debug (0, "ClassRequestDaemon::DaemonProcess: "
		       "class fault occurred. ccid = %O\n", ccid);

		file_name = ProcessClassFault (ccid);


		anExecutor->OzLoadClass (ccid, file_name);

		inline "C" {
		    OzExecFree ((OZ_Pointer)file_name);
		}
	    } except {
		default {
		    /* catch all exceptions and restart daemon process */
		}
	    }
	}
    }

    char ProcessClassFault (global ConfiguredClassID ccid)[] {
	if (StandAlone) {
	    /* If stand alone, lookup the class directory at first. */
	    String path = ClassPropertyPath(ccid, "private.r");
	    FileOperators fops;
	    if (fops.IsExists(path)) {
		return path->Content();
	    }
	}

	try {
	    global Class c = SearchClass (ccid);
	    debug (0, "ClassRequestDaemon::DaemonProcess "
		   " a class is returned. ccid = %O\n", c);
	    return c->GetRuntimeClassInformation (ccid);
	} except {
	  ClassExceptions::UnknownClass (ccid) {
	      debug (0,
		     "ClassRequestDaemon::DaemonProcess: %O: "
		     "class not found\n", ccid);

	      raise;

	  }
	  ClassExceptions::UnknownProperty (p) {
	      debug (0,
		     "ClassRequestDaemon::DaemonProcess: %O: "
		     "property %S is not found.\n", ccid, p);

	      raise;

	  }
	  default {

	      raise;

	  }
	}
	return 0;
    }
}
