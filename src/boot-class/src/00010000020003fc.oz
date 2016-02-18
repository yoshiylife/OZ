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

class UnixCommand  {
  constructor: New;
  public: Execute;

    UnixIO Unix;

    void New () {}

    int Execute (String commands, String result, int verbose) {
	char args [][];
	UnixIO debugp;
	String s, buf=>New (), tmp;
	unsigned int i;
	int status;


	String cd=>NewFromArrayOfChar ("cd $OZROOT; ");


	if (result == 0) {
	    result=>New ();
	}

	length args = 2;
	args [0] = "unix";

	args [1] = cd->Concatenate (commands)->Content ();

	if (verbose) {
	    debugp=>New ()->PutStr (args [1])->PutReturn ();
	}

	Unix=>Spawn (args);
	while ((s = Unix->ReadString (256)) != 0) {
	    if (verbose) {
		debugp->PutString (s)->PutReturn ();
	    }
	    tmp = buf;
	    buf = buf->Concatenate (s);
	    inline "C" {
		OzExecFree ((OZ_Pointer) tmp);
	    }
	}

/*	if ((s = Unix->ReadString (256)) != 0) {
	    do {
		if (verbose) {
		    debugp->PutString (s)->PutReturn ();
		}
		tmp = buf;
		buf = buf->Concatenate (s);
		inline "C" {
		    OzExecFree (tmp);
		}
	    } while (s = Unix->ReadString (256));
	} */

	result->Assign (buf);

	if (result->Length () == 0) {
	    debugp->PutStr ("UnixCommand::Execute: no response from\n");
	    debugp->PutStr ("  ")->PutStr (args [1])->PutReturn ();
	}

	Unix->Close ();
	status = result->At ((i = result->Length () - 1)) - '0';

	result->SetAt (i, 0);

	return status;
    }
}
