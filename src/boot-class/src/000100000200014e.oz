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
 * debdaemon.oz
 *
 * Class distribution daemon for debugger.
 */

inline "C" {
#include <executor/debug.h>
}

class DebuggerClassRequestDaemon : DaemonForClass(alias New SuperNew;) {
  constructor: New;
  public: GetNumberOfProcesses, SetNumberOfProcesses, Start;
  protected: DaemonProcess;

  protected: AID, ClassDirectoryPath, NumberOfProcesses, OM, StandAlone;


/* no instance variable */

/* method implementations */

    void New(Executor e, unsigned int n, int stand_alone) {
	SuperNew(e, n, stand_alone);
	AID=>Any();
    }


    void DaemonProcess() {
	global ClassID cid;
	Object req;

	debug (0, "DebuggerClassRequestDaemon: Start\n");
	while (1) {
	    try {

		req = anExecutor->OzDmClassRequest();

		if (req != 0) {
		    inline "C" {
			cid = ((OZ_DmClassRequest)req)->cid;
		    }
		    debug (default,
			   "DebuggerClassRequestDaemon::DaemonProcess: ");
		    debug (default, "class fault occurred. cid = %O\n", cid);

		    if (! StandAlone) {
			SearchClass(cid);
		    }

		    anExecutor->OzDmClassRequestReply(0, req);

		}
	    } except {
		default {
		    /* catch all exceptions and restart daemon process */

		    anExecutor->OzDmClassRequestReply(-1, req);

		    debug (default,
			   "DebuggerClassRequestDaemon::DaemonProcess: ");
		    debug (default, "class not found. cid = %O.\n", cid);
		}
	    }
	}
    }
}
