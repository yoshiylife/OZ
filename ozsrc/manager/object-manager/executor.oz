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
 * executor.oz
 *
 * Executor runtime routine caller.
 * This class should be a record.
 */

inline "C" {
#include <executor/class-table.h>
#include <executor/config-req.h>
#include <executor/memory.h>
#include <executor/ncl-if.h>
#include <executor/object-table.h>
#include <executor/code-layout.h>
#include <executor/debug.h>
#include <executor/remote-file-if.h>
}

class Executor {
  constructor: New;
  public:
    SenderOfThisMessage,
    OzShutdownExecutor,
    ShutdownRequest, WaitShutdownRequest,
    ObjectTableDownLoad, ObjectTableChangeStatus,
    ObjectTableChangeStatusToREADY,
    ObjectTableChangeStatusToQUEUE, 
    ObjectTableChangeStatusToSTOP, 
    OzObjectTableCellIn, OzObjectTableRemove, OzObjectTableLoad,
    OzObjectTableFlush, OzObjectTableSuspend, OzObjectTableResume,
    OzSchedulerWaitThread,
    OzAllocateCell,
    Broadcast, ReceiveBroadcast,
    OzBroadcastReady,
    OzMyArchitecture,
    OzCodeFault, OzLayoutFault, OzClassRequest,
    OzQueuedInvocation,
    OzConfiguration,
    OzLoadCode, OzLoadLayout, OzLoadClass,
    OzConfigurationReply,
    OzDmClassRequest, OzDmClassRequestReply,
    ExecutorUptime, ExecutorLoadAverage, MemoryShortageOccurrence,
    GlobalObjectGCOccurrence, GlobalObjectCellOutOccurrence,
    TransferFile;

/* no member */

/* operators */
    void New () {}

    char SenderOfThisMessage ()[] {return Where ()->GetOwner ();}

    void OzShutdownExecutor () {
	inline "C" {
	    OzOmShutdownExecutor ();
	}
    }

    int ShutdownRequest () {
	int ret;

	inline "C" {
	    ret = OzOmShutdownRequest ();
	}
	return ret;
    }

    int WaitShutdownRequest () {
	int ret;

	inline "C" {
	    ret = OzOmWaitShutdownRequest ();
	}
	return ret;
    }

    void ObjectTableDownLoad (global Object o, int status) {
	switch (status) {
	  case OTObjectStatus::OTReady:
	    inline "C" {
		OzOmObjectTableDownLoad (o, OT_READY);
	    }
	    break;
	  case OTObjectStatus::OTQueue:
	    inline "C" {
		OzOmObjectTableDownLoad (o, OT_QUEUE);
	    }
	    break;
	  case OTObjectStatus::OTStop:
	    inline "C" {
		OzOmObjectTableDownLoad (o, OT_STOP);
	    }
	    break;
	}
    }

    void ObjectTableChangeStatus (global Object o, int status) {
	switch (status) {
	  case OTObjectStatus::OTReady:
	    ObjectTableChangeStatusToREADY (o);
	    break;
	  case OTObjectStatus::OTQueue:
	    ObjectTableChangeStatusToQUEUE (o);
	    break;
	  case OTObjectStatus::OTStop:
	    ObjectTableChangeStatusToSTOP (o);
	    break;
	}
    }

    void ObjectTableChangeStatusToREADY (global Object o) {
	inline "C" {
	    OzOmObjectTableChangeStatus (o, OT_READY);
	}
    }

    void ObjectTableChangeStatusToQUEUE (global Object o) {
	inline "C" {
	    OzOmObjectTableChangeStatus (o, OT_QUEUE);
	}
    }

    void ObjectTableChangeStatusToSTOP (global Object o) {
	inline "C" {
	    OzOmObjectTableChangeStatus (o, OT_STOP);
	}
    }

    void OzObjectTableCellIn (global Object o) {
	inline "C" {
	    OzOmObjectTableCellIn (o);
	}
    }


    int OzObjectTableRemove (global Object o) {
	debug (0, "Executor::OzObjectTableRemove: o = %O\n", o);
	try {
	    inline "C" {
		OzOmObjectTableRemove (o);
	    }
	} except {
	    ObjectNotFound {}
	}
	debug (0, "Executor::OzObjectTableRemove:complete. o = %O\n", o);
	return 1;
    }


    void OzObjectTableLoad (global Object o) {
	inline "C" {
	    OzOmObjectTableLoad (o);
	}
    }

    void OzObjectTableFlush (global Object o) {
	inline "C" {


	    OzDebugf ("Executor::OzObjectTableFlush: o = %O\n", o);



	    OzOmObjectTableFlush (o);

	}
	debug (0, "Executor::OzObjectTableFlush: complete. o = %O\n", o);
    }

    int OzObjectTableSuspend (global Object o) {
	int ret;

	inline "C" {


	    OzDebugf ("Executor::OzObjectTableSuspend: o = %O\n", o);


	    ret = OzOmObjectTableSuspend (o);
	}
	return ret;
    }

    int OzObjectTableResume (global Object o) {
	int ret;

	inline "C" {


	    OzDebugf ("Executor::OzObjectTableResume: o = %O\n", o);


	    ret = OzOmObjectTableResume (o);
	}
	return ret;
    }

    void OzSchedulerWaitThread (global Object o) {
	debug (0, "Executor::OzSchedulerWaitThread: o = %O\n", o);
	inline "C" {
	    OzOmSchedulerWaitThread (o);
	}
	debug (0, "Executor::OzSchedulerWaitThread: complete. o = %O", o);
    }

    /* allocate new cell for global object */
    global Object OzAllocateCell (global ClassID cid) {
	global Object o;
	inline "C" {
	    o = OzOmAllocateCell (cid);
	}
	return o;
    }

    /* broadcast */
    void Broadcast (global ObjectManager sender, unsigned int i,
		    global ClassID cid, ArchitectureID aid) {
	global ObjectManager Sender = sender;
	int ID = i;
	global ClassID Param1 = cid;
	int Param2;

	if (cid != 0) { /* in case of broadcasting for class */
	    Param2 = aid->Get ();
	} else {
	    Param2 = 0;
	}

        debug (0, "Executor::Broadcast: cid = %O\n", cid);
	inline "C" {
	    OZ_BroadcastParameterRec bp_rec;

	    bp_rec.sender = Sender;
	    bp_rec.id = ID;
	    bp_rec.param1 = Param1;
	    bp_rec.param2 = Param2;
	    OzOmBroadcast (bp_rec);
	}
    }

    /* receive broadcast message */
    BroadcastParameter ReceiveBroadcast () {
	BroadcastParameter bp;
	global ObjectManager Sender;
	int ID;
	global ClassID Param1;
	int Param2;
	ArchitectureID aid;
	/*
	 * Tentative version.
	 * Should be rewritten to directly assign members of
	 * bp_rec to members of bp.
	 */
	inline "C" {
	    OZ_BroadcastParameterRec bp_rec;
	    bp_rec = OzOmReceiveBroadcast ();
	    Sender = bp_rec.sender;
	    ID = bp_rec.id;
	    Param1 = bp_rec.param1;
	    Param2 = bp_rec.param2;
	}

	aid=>New (Param2);
	bp=>New (Sender, ID, Param1, aid);

	return bp;
    }

    /* inform executor receiving broadcast is ready */
    void OzBroadcastReady () {
	inline "C" {
	    OzOmBroadcastReady ();
	}
    }

    /* architecture ID */
    int OzMyArchitecture () {
	int arch;

	inline "C" {
	    arch = OzOmMyArchitecture ();
	}
	return arch;
    }

    /* executable code fault */
    global VersionID OzCodeFault () {
	global VersionID vid;

	inline "C" {
	    vid = OzOmCodeFault ();
	}
	return vid;
    }

    /* layout information fault */
    global VersionID OzLayoutFault () {
	global VersionID vid;

	inline "C" {
	    vid = OzOmLayoutFault ();
	}
	return vid;
    }

    /* runtime class information fault */
    global ConfiguredClassID OzClassRequest () {
	global ConfiguredClassID ccid;

	inline "C" {
	    ccid = OzOmClassRequest ();
	}
	return ccid;
    }

    /* method invocation of an object in QUEUE status */
    global Object OzQueuedInvocation () {
	global Object o;

	inline "C" {
	    o = OzOmQueuedInvocation ();
	}
	return o;
    }

    Object OzConfiguration () {
	Object cr;

	inline "C" {
	    cr = (OZ_Object)OzOmConfiguration ();



	}
	return cr;
    }

    Object OzDmClassRequest () {
	Object cr;

	inline "C" {
	    OID cid;

	    cr = (OZ_Object)OzDmClassRequest ();


	    cid = ((OZ_DmClassRequest)cr)->cid;
	    OzDebugf ("Executor::OzConfiguration: cr = %p, cid = %O\n",
		      cr, cid);


	}
	return cr;
    }

    /* load executable code */
    void OzLoadCode (global VersionID vid, char file_name []) {

	file_name = PrependOZHOME (file_name);

	inline "C" {
	    OzOmLoadCode (vid, OZ_ArrayElement (file_name, char));
	}
    }

    /* load layout information */
    void OzLoadLayout (global VersionID vid, char file_name []) {

	file_name = PrependOZHOME (file_name);

	inline "C" {
	    OzOmLoadLayout (vid, OZ_ArrayElement (file_name, char));
	}
    }

    /* load runtime class information */
    void OzLoadClass (global ConfiguredClassID ccid, char file_name []) {

	file_name = PrependOZHOME (file_name);

	inline "C" {
	    OzOmLoadClass (ccid, OZ_ArrayElement (file_name, char));
	}
    }


    char PrependOZHOME (char p [])[] {
	if (p != 0 && length p > 0 && p [0] == '/') {
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
	    if (p != 0) {
		inline "C" {
		    OzStrcat (OZ_ArrayElement (path, char),
			      OZ_ArrayElement (p, char));
		}
	    }
	    return path;
	}
    }


    void OzConfigurationReply (global ConfiguredClassID ccid, Object req) {
	inline "C" {
	    OZ_ConfigurationRequest ecr = (OZ_ConfigurationRequest) req;




	    OzOmConfigurationReply (ccid, ecr);
	}
    }

    void OzDmClassRequestReply (int ret, Object req) {
	inline "C" {
	    OZ_DmClassRequest dcr = (OZ_DmClassRequest) req;


	    OzDebugf ("Executor::OzDmClassRequestReply ");
	    OzDebugf ("dcr->cid = %O, ret = %d\n", dcr->cid, ret);


	    OzDmClassRequestReply (ret, dcr);
	}
    }

    /* returns uptime of the executor */
    Time ExecutorUptime () {
	/* Low implementation prioirty */
    }

    /* returns number of ready threads in the executor */
    unsigned int ExecutorLoadAverage () {
	/* Low implementation prioirty */
    }

    /* returns number of occurrences of memory shortage upcall */
    unsigned int MemoryShortageOccurrence () {
	/* Low implementation prioirty */
    }

    /* returns number of occurrences of global object GC */
    unsigned int GlobalObjectGCOccurrence () {
	/* Low implementation prioirty */
    }

    /* returns number of occurrences of global object swapping out */
    unsigned int GlobalObjectCellOutOccurrence () {
	/* Low implementation prioirty */
    }

    int TransferFile (global Class remote, char from_file [], char to_file [])
      : global {
	  /* under implementation: error result code should raised */
	  int result;

	  inline "C" {
	      result = OzOmFileTransfer (remote,
					 OZ_ArrayElement (from_file, char),
					 OZ_ArrayElement (to_file, char));
	  }
	  debug (0,
		 "Executor::TransferFile: OzFileTransfer (%O, %S, %S) = %d;\n",
		 remote, from_file, to_file, result);
	  return result;
      }
}
