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
 * bcreceiver.oz
 *
 * Broadcast receiving daemon.
 */

class BroadcastReceiver : Daemon (rename New SuperNew;) {
  constructor: New;
  public: GetNumberOfProcesses, SetNumberOfProcesses, Start;
  protected: DaemonProcess;

/* instance variables */
    ClassLookupper aClassLookupper;

/* method implementations */

    void New (Executor e, unsigned int n, ClassLookupper cl) {
	SuperNew (e, n);

	aClassLookupper = cl;
    }

    void DaemonProcess () {

	int site_id = 0;





	while (1) {
	    try {

		int res;


		BroadcastParameter bp = anExecutor->ReceiveBroadcast ();
		global ClassID cid = bp->GetParam1 ();





		  if (cid == 0) {
		      /* Name Directory Lookup */
		      global NameDirectory nd = OM->PeekNameDirectory ();

		      if (nd != 0) {

			  detach fork
			    bp->GetSender ()
			      ->ReplyOfNameDirectoryBroadcast (bp->GetID(),nd);

		      }
		  } else {
		      /* Class Lookup */

		      ArchitectureID architecture = bp->GetParam2 ();

		      aClassLookupper->Distribute (cid, 

						   bp->GetSender (),

						   architecture);
		  }
	    } except {
		default {
		    /* catch all exceptions and restart daemon process */
		}
	    }
	}
    }
}
