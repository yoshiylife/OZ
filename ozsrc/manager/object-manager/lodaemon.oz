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
 * lodaemon.oz
 *
 * Layout information fault daemon.
 */

class LayoutFaultDaemon : DaemonForClass {
  constructor: New;
  public: GetNumberOfProcesses, SetNumberOfProcesses, Start;
  protected: DaemonProcess, SearchClass, ProcessLayoutFault;

  protected: AID, ClassDirectoryPath, NumberOfProcesses, OM, StandAlone;

  protected: anExecutor;


/* no instance variable */

/* method implementations */
    void DaemonProcess () {
	global VersionID vid;
	global Class c;
	char file_name [];

	while (1) {
	    try {

		vid = anExecutor->OzLayoutFault ();

		debug (0,
		       "LayoutFaultDaemon::DaemonProcess"
		       " layout fault is occurred.  vid = %O\n", vid);

		file_name = ProcessLayoutFault (vid);

		anExecutor->OzLoadLayout (vid, file_name);

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

    char ProcessLayoutFault(global VersionID vid)[] {
	if (StandAlone) {
	    /* If stand alone, lookup the class directory at first. */
	    String path = ClassPropertyPath(vid, "private.l");
	    FileOperators fops;
	    if (fops.IsExists(path)) {
		return path->Content();
	    }
	}

	try {
	    return SearchClass (vid)->GetLayout (vid, AID);
	} except {
	  ClassExceptions::UnknownClass (vid) {
	      debug (0,
		     "LayoutFaultDaemon::DaemonProcess: %O: "
		     "class not found\n", vid);
	  }
	  ClassExceptions::UnknownProperty (p) {
	      debug (0,
		     "LayoutFaultDaemon::DaemonProcess: %O: "
		     "property %S is not found.\n", vid, p);
	  }
	  default {
	  }
	}
	return 0;
    }
}
