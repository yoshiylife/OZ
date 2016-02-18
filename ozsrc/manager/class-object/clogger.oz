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
 * clogger.oz
 *
 * Transaction logger of class object.
 */

inline "C" {
#include <fcntl.h>
}

class ClassLogger {
/* method interface */
  constructor: New;
  public:
    Apply, Close,
    LogAddArchitecture, LogAddAsNewConfiguration, LogAddAsNewLowerVersion,
    LogAddProperty, LogAddToClassTable, LogClearProperties, LogMakeItVisible,
    LogRemoveClass, LogRemoveConfiguredClass, LogRemoveLowerVersion,
    LogRemoveProperty, LogSetDefaultConfiguredClassID,
    LogSetDefaultLowerVersionID, LogSetImplementationParts, LogSetParents,
    LogSetVersionString,
    Open, Start;

    /* for copy management */
  public:
    LogAddMirrorMember, LogAddToClassPackage, LogAddToOriginalPackages,
    LogAddToOriginals, LogAddToSnapshots, LogChangeCopyKind,
    LogChangeMirrorMode, LogChangeMirrorSetting, LogDeleteFromClassPackage,
    LogDeleteMirrorMember, LogDestroyClassPackage, LogPrivatize,
    LogRegisterMirror, LogSetMirror, LogUnsetMirror;

  protected: SetThreshold;

/* instance variables */
    String LogFilePath;
    String RecoveringLogFilePath;
    String DeadLogFilePath;
    Stream LogFile;
    Stream DeadLogFile;
    unsigned int Count, Threshold;

/* method implementations */
    void New (String logfile_path, unsigned int threshold) {
	LogFilePath = logfile_path;
	RecoveringLogFilePath
	  = logfile_path->ConcatenateWithArrayOfChar (".rcv");
	DeadLogFilePath = logfile_path->ConcatenateWithArrayOfChar (".ded");
	SetThreshold (threshold);
	Open ();
    }

    int Apply (Class c, String path) {
	FileOperators fops;
	ClassLogFileReader clfr;
	unsigned int line = 0;
	int finished = 0, ret = 1;



	inline "C" {
	    _oz_debug_flag = 1;
	}


	clfr=>New (path);
	while (! finished) {
	    try {
		if (clfr->ReadDefault ('(')) {
		    line ++;
		    if (! ApplyaRecord (clfr, c)) {
			ret = 0;
		    }
		} else {
		    finished = 1;
		}
	    } except {
	      FileReaderExceptions::SyntaxError (t) {
		  debug (0,
			 "ClassLogger::Apply: "
			 "syntax error in log file, line = %d.\n", line);
		  OpenDeadLogFile ();
		  DeadLogFile->PutStr ("(");
		  DeadLogFile->PutStr (t->Print ()->Content ());
		  DeadLogFile->PutStr (clfr
				       ->DiscardUntilRightParent ()
				       ->Content ());
		  DeadLogFile->PutStr ("\n");
		  ret = 0;
	      }
	      FileReaderExceptions::UnexpectedEOFInString {
		  debug (0,
			 "ClassLogger::Apply: "
			 "unexpected EOF in log file, line = %d.\n", line);
		  ret = 0;
	      }
		default {
		    CloseDeadLogFile ();
		    raise;
		}
	    }
	}
	CloseDeadLogFile ();
	return ret;
    }

    int ApplyaRecord (ClassLogFileReader clfr, Class c) {
	String kind = clfr->ReadIdentifier ();
	global ClassID cid;
	global VersionID vid;
	global ConfiguredClassID ccid;
	global ClassPackageID cpid;
	int res = 1;

	if (kind->IsEqualToArrayOfChar ("AddArchitecture")) {
	    ArchitectureID aid;

	    cid = ReadClassID (clfr);
	    aid=>New (clfr->ReadInteger ());
	    clfr->ReadDefault (')');
	    try {
		c->AddArchitecture (cid, aid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: cannot add architecture.\n");
		    LogAddArchitecture (cid, aid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddAsNewConfiguration")) {
	    vid = ReadVID (clfr);
	    ccid = ReadCCID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->AddAsNewConfiguration (vid, ccid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot add new configuration.\n");
		    LogAddAsNewConfiguration (vid, ccid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddAsNewLowerVersion")) {
	    global VersionID new;

	    vid = ReadVID (clfr);
	    new = ReadVID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->AddAsNewLowerVersion (vid, new);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot add new lower version.\n");
		    LogAddAsNewLowerVersion (vid, new);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddProperty")) {
	    String name;

	    cid = ReadClassID (clfr);
	    name = clfr->ReadString ();
	    clfr->ReadDefault (')');
	    try {
		c->AddProperty (cid, name->Content ());
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: cannot add a property.\n");
		    LogAddProperty (cid, name->Content ());
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddToClassTable")) {
	    ClassPart cp;
	    UpperPart up;
	    unsigned int part = clfr->ReadInteger ();

	    switch (part) {
	      case ClassPartName::aRootPart:
		cp = ReadRootPart (clfr, c);
		break;
	      case ClassPartName::aPublicPart:
		up = ReadPublicPart (clfr, c);
		cp = up;
		break;
	      case ClassPartName::aProtectedPart:
		up = ReadProtectedPart (clfr, c);
		cp = up;
		break;
	      case ClassPartName::anImplementationPart:
		cp = ReadImplementationPart (clfr, c);
		break;
	      case ClassPartName::aConfiguredClass:
		cp = ReadConfiguredClass (clfr, c);
		break;
	    }
	    clfr->ReadDefault (')');
	    try {
		c->AddToClassTable (cp);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: cannot add a class part.\n");
		    LogAddToClassTable (cp);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("ClearProperty")) {
	    vid = ReadVID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->ClearProperties (vid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: cannot clear property.\n");
		    LogClearProperties (vid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("MakeItVisible")) {
	    global VersionID upper = ReadVID (clfr);

	    vid = ReadVID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->MakeItVisible (upper, vid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot make a class part visible.\n");
		    LogMakeItVisible (upper, vid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("RemoveClass")) {
	    cid = ReadClassID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->RemoveClassImpl (cid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot remove a class part.\n");
		    LogRemoveClass (cid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("RemoveConfiguredClass")) {
	    vid = ReadVID (clfr);
	    ccid = ReadCCID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->RemoveConfiguredClassImpl (vid, ccid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot remove a configured class.\n");
		    LogRemoveConfiguredClass (vid, ccid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("RemoveLowerVersion")) {
	    global VersionID uvid = ReadVID (clfr);
	    global VersionID lvid = ReadVID (clfr);

	    clfr->ReadDefault (')');
	    try {
		c->RemoveLowerVersionImpl (uvid, lvid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot remove a lower version.\n");
		    LogRemoveLowerVersion (uvid, lvid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("RemoveProperty")) {
	    String name;

	    cid = ReadClassID (clfr);
	    name = clfr->ReadString ();
	    clfr->ReadDefault (')');
	    try {
		c->RemoveProperty (cid, name->Content ());
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot remove a property.\n");
		    LogRemoveProperty (cid, name->Content ());
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("SetDefaultConfiguredClassID")){
	    cid = ReadClassID (clfr);
	    ccid = ReadCCID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->SetDefaultConfiguredClassID (cid, ccid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot set default configured class.\n");
		    LogSetDefaultConfiguredClassID (cid, ccid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("SetDefaultLowerVersionID")) {
	    cid = ReadClassID (clfr);
	    vid = ReadVID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->SetDefaultLowerVersionID (cid, vid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot set default lower version ID.\n");
		    LogSetDefaultLowerVersionID (cid, vid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("SetImplementationParts")) {
	    global VersionID impl_ids [];

	    ccid = ReadCCID (clfr);
	    impl_ids = ReadVIDArray (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->SetImplementationParts (ccid, impl_ids);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot set a list of implementation parts.\n");
		    LogSetImplementationParts (ccid, impl_ids);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("SetParents")) {
	    global VersionID parents [];

	    cid = ReadClassID (clfr);
	    parents = ReadVIDArray (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->SetParents (cid, parents);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot set the parent classes.\n");
		    LogSetParents (cid, parents);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("SetVersionString")) {
	    VersionString vs;

	    vid = ReadVID (clfr);
	    vs = ReadVersionString (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->SetVersionString (vid, vs);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot set a version string.\n");
		    LogSetVersionString (vid, vs);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddMirrorMember")) {
	    global ClassPackageID cpid = ReadClassPackageID (clfr);
	    global ClassID cids [] = ReadClassIDArray (clfr);

	    clfr->ReadDefault (')');
	    try {
		c->AddMirrorMember (cpid, cids);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot add mirror members.\n");
		    LogAddMirrorMember (cpid, cids);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddToClassPackage")) {
	    global ClassPackageID cpid = ReadClassPackageID (clfr);
	    global ClassID cids [] = ReadClassIDArray (clfr);

	    clfr->ReadDefault (')');
	    try {
		c->AddToClassPackage (cpid, cids);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot add classes to a class package.\n");
		    LogAddToClassPackage (cpid, cids);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddToOriginalPackages")) {
	    unsigned int i, len;
	    OriginalClassPackage ocp;

	    cpid = ReadClassPackageID (clfr);
	    len = clfr->ReadInteger ();
	    ocp=>NewWithSize (len);
	    ocp->SetID (cpid);
	    for (i = 0; i < len; i ++) {
		ocp->Add (ReadClassID (clfr));
	    }
	    clfr->ReadDefault (')');
	    try {
		c->AddToOriginalPackages (cpid, ocp);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot add a original class package.\n");
		    LogAddToOriginalPackages (cpid, ocp);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddToOriginals")) {
	    cid = ReadClassID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->AddToOriginals (cid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot add an original class.\n");
		    LogAddToOriginals (cid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("AddToSnapshots")) {
	    cid = ReadClassID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->AddToSnapshots (cid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot add a snapshot.\n");
		    LogAddToSnapshots (cid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("ChangeCopyKind")) {
	    global ClassID cid = ReadClassID (clfr);
	    int copy_kind = clfr->ReadInteger ();

	    clfr->ReadDefault (')');
	    try {
		c->ChangeCopyKind (cid, copy_kind);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot change the copy kind of a class.\n");
		    LogChangeCopyKind (cid, copy_kind);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("ChangeMirrorMode")) {
	    global ClassPackageID cpid = ReadClassPackageID (clfr);
	    int new_mode = clfr->ReadInteger ();

	    clfr->ReadDefault (')');
	    try {
		c->ChangeMirrorMode (cpid, new_mode);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot change the mirror mode of a mirror.\n");
		    LogChangeMirrorMode (cpid, new_mode);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("ChangeMirrorSetting")) {
	    global Class to = narrow (Class, clfr->ReadObjectID ());
	    global ClassPackageID cpid = ReadClassPackageID (clfr);
	    int mode = clfr->ReadInteger ();

	    clfr->ReadDefault (')');
	    try {
		c->ChangeMirrorSetting (to, cpid, mode);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot change mirror setting of a mirror.\n");
		    LogChangeMirrorSetting (to, cpid, mode);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("DeleteFromClassPackage")) {
	    global ClassPackageID cpid = ReadClassPackageID (clfr);
	    global ClassID cids [] = ReadClassIDArray (clfr);

	    clfr->ReadDefault (')');
	    try {
		c->DeleteFromClassPackage (cpid, cids);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot delete classes from a class package.\n");
		    LogDeleteFromClassPackage (cpid, cids);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("DeleteMirrorMember")) {
	    global ClassPackageID cpid = ReadClassPackageID (clfr);
	    global ClassID cids [] = ReadClassIDArray (clfr);

	    clfr->ReadDefault (')');
	    try {
		c->DeleteMirrorMember (cpid, cids);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot delete a mirror member.\n");
		    LogDeleteMirrorMember (cpid, cids);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("DestroyClassPackage")) {
	    cpid = ReadClassPackageID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->DestroyClassPackage (cpid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot destroy a class package.\n");
		    LogDestroyClassPackage (cpid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("Privatize")) {
	    cid = ReadClassID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->Privatize (cid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot privatize a class.\n");
		    LogPrivatize (cid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("RegisterMirror")) {
	    global Class to = narrow (Class, clfr->ReadObjectID ());
	    global ClassPackageID cpid = ReadClassPackageID (clfr);
	    int mode = clfr->ReadInteger ();

	    clfr->ReadDefault (')');
	    try {
		c->RegisterMirror (to, cpid, mode);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot register a mirror to original.\n");
		    LogRegisterMirror (to, cpid, mode);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("SetMirror")) {
	    unsigned int mode, i, len;
	    MirroredClassPackage mcp;
	    global Class from;

	    cpid = ReadClassPackageID (clfr);
	    from = narrow (Class, clfr->ReadObjectID ());
	    mode = clfr->ReadInteger ();
	    len = clfr->ReadInteger ();
	    mcp=>NewWithSize (len);
	    mcp->SetID (cpid);
	    mcp->SetOriginal (from);
	    mcp->SetMirrorMode (mode);
	    for (i = 0; i < len; i ++) {
		mcp->Add (ReadClassID (clfr));
	    }
	    clfr->ReadDefault (')');
	    try {
		c->SetMirrorImplementation (from, cpid, mcp, mode);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot set a mirror.\n");
		    LogSetMirror (cpid, from, mode, mcp->SetOfContents ());
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else if (kind->IsEqualToArrayOfChar ("UnsetMirror")) {
	    cpid = ReadClassPackageID (clfr);
	    clfr->ReadDefault (')');
	    try {
		c->UnsetMirrorImplementation (cpid);
	    } except {
		default {
		    Stream tmp = LogFile;

		    OpenDeadLogFile ();
		    LogFile = DeadLogFile;
		    debug (0,"ClassLogger::Apply: "
			   "cannot unset a mirror.\n");
		    LogUnsetMirror (cpid);
		    LogFile = tmp;
		    res = 0;
		}
	    }
	} else {
	    IdentifierToken t=>New (kind->Content ());

	    raise FileReaderExceptions::SyntaxError (t);
	}
	return res;
    }

    void Close () {
	debug (0, "ClassLogger::Close:\n");
	if (LogFile != 0) {
	    LogFile->Close ();
	    LogFile = 0;
	}
	try {
	    FileOperators fops;

	    if (fops.IsExists (LogFilePath)) {
		fops.Remove (LogFilePath);
	    }
	} except {
	    default {}
	}
	Count = 0;
    }

    void CloseDeadLogFile () {
	if (DeadLogFile != 0) {
	    DeadLogFile->Close ();
	    DeadLogFile = 0;
	}
    }

    int CheckLogging () {
	int ans = (LogFile != 0);

	if (! ans) {
	    Where ()->FlushObject (cell);
	}
	return ans;
    }

    void CountUp () {
	if (++ Count >= Threshold && Threshold > 0) {
	    Where ()->FlushObject (cell);
	    Close ();
	    Open ();
	}
    }

    void PutBlank () {LogFile->PutStr (" ");}

    void PutFinishUp () {
	LogFile->PutStr (")\n");
	CountUp ();
    }

    void PutName (char name []) {
	LogFile->PutStr ("\"");
	LogFile->PutStr (name);
	LogFile->PutStr ("\"");
    }

    void LogAddArchitecture (global ClassID cid, ArchitectureID aid) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(AddArchitecture ");
	    LogFile->PutOID (cid);
	    PutBlank ();
	    LogFile->PutInt (aid->Get ());
	    PutFinishUp ();
	}
    }

    void LogAddAsNewConfiguration (global VersionID vid,
				   global ConfiguredClassID ccid)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(AddAsNewConfiguration ");
	      LogFile->PutOID (vid);
	      PutBlank ();
	      LogFile->PutOID (ccid);
	      PutFinishUp ();
	  }
      }

    void LogAddAsNewLowerVersion (global VersionID vid, global VersionID new)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(AddAsNewLowerVersion ");
	      LogFile->PutOID (vid);
	      PutBlank ();
	      LogFile->PutOID (new);
	      PutFinishUp ();
	  }
      }

    void LogAddToClassTable (ClassPart cp) : locked {
	if (CheckLogging ()) {
	    switch (cp->WhichPart ()) {
	      case ClassPartName::aRootPart:
		LogAddRootPartToClassTable (narrow (RootPart, cp));
		break;
	      case ClassPartName::aPublicPart:
		LogAddPublicPartToClassTable (narrow (PublicPart, cp));
		break;
	      case ClassPartName::aProtectedPart:
		LogAddProtectedPartToClassTable (narrow (ProtectedPart, cp));
		break;
	      case ClassPartName::anImplementationPart:
		LogAddImplementationPartToClassTable
		  (narrow (ImplementationPart, cp));
		break;
	      case ClassPartName::aConfiguredClass:
		LogAddConfiguredClassToClassTable (narrow(ConfiguredClass,cp));
		break;
	    }
	}
    }

    void LogAddConfiguredClassToClassTable (ConfiguredClass cc) {
	LogFile->PutStr ("(AddToClassTable ");
	LogFile->PutInt (ClassPartName::aConfiguredClass);
	PutBlank ();
	LogClassPart (cc);
	PutBlank ();
	LogFile->PutOID (cc->GetPublicPart ());
	PutBlank ();
	LogOIDArray (cc->GetImplementationParts ());
	PutFinishUp ();
    }

    void LogAddImplementationPartToClassTable (ImplementationPart ip) {
	LogFile->PutStr ("(AddToClassTable ");
	LogFile->PutInt (ClassPartName::anImplementationPart);
	PutBlank ();
	LogLowerPart (ip);
	PutBlank ();
	LogClassVersion (ip);
	PutBlank ();
	LogArchitectureIDArray (ip->Architectures ());
	PutFinishUp ();
    }

    void LogAddProperty (global ClassID cid, char name []) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(AddProperty ");
	    LogFile->PutOID (cid);
	    PutBlank ();
	    PutName (name);
	    PutFinishUp ();
	}
    }

    void LogAddProtectedPartToClassTable (ProtectedPart protp) {
	LogFile->PutStr ("(AddToClassTable ");
	LogFile->PutInt (ClassPartName::aProtectedPart);
	PutBlank ();
	LogLowerPart (protp);
	PutBlank ();
	LogUpperPart (protp);
	PutFinishUp ();
    }

    void LogAddPublicPartToClassTable (PublicPart pubp) {
	LogFile->PutStr ("(AddToClassTable ");
	LogFile->PutInt (ClassPartName::aPublicPart);
	PutBlank ();
	LogLowerPart (pubp);
	PutBlank ();
	LogFile->PutInt (pubp->WhichKind ());
	PutBlank ();
	LogUpperPart (pubp);
	PutBlank ();
	LogOIDArray (pubp->ConfiguredClassIDs ());
	PutBlank ();
	LogFile->PutOID (pubp->GetDefaultConfiguredClassID ());
	PutFinishUp ();
    }

    void LogAddRootPartToClassTable (RootPart rp) {
	LogFile->PutStr ("(AddToClassTable ");
	LogFile->PutInt (ClassPartName::aRootPart);
	PutBlank ();
	LogUpperPart (rp);
	PutFinishUp ();
    }

    void LogClassPart (ClassPart cp) {
	LogFile->PutOID (cp->GetID ());
	PutBlank ();
	LogFile->PutInt (cp->WhichKindOfCopy ());
	PutBlank ();
	LogFile->PutInt (cp->IsDistributable ());
	PutBlank ();
	LogStringArray (cp->GetProperties ());
    }

    void LogClassVersion (ClassVersion cv) {
	LogClassPart (cv);
	PutBlank ();
	LogVersionString (cv->GetVersionString ());
	PutBlank ();
	LogOIDArray (cv->GetParents ());
    }

    void LogClearProperties (global ClassID cid) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(ClearProperty ");
	    LogFile->PutOID (cid);
	    PutFinishUp ();
	}
    }

    void LogArchitectureIDArray (ArchitectureID aids []) {
	unsigned int i, len = length aids;

	LogFile->PutInt (len);
	for (i = 0; i < len; i ++) {
	    PutBlank ();
	    LogFile->PutInt (aids [i]->Get ());
	}
    }

    void LogLowerPart (LowerPart lp) {LogFile->PutOID (lp->GetUpperPart ());}

    void LogMakeItVisible (global VersionID upper, global VersionID vid)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(MakeItVisible ");
	      LogFile->PutOID (upper);
	      PutBlank ();
	      LogFile->PutOID (vid);
	      PutFinishUp ();
	  }
      }

    void LogOIDArray (global Object oids []) {
	unsigned int i, len = length oids;

	LogFile->PutInt (len);
	for (i = 0; i < len; i ++) {
	    PutBlank ();
	    LogFile->PutOID (oids [i]);
	}
    }

    void LogRemoveClass (global ClassID cid) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(RemoveClass ");
	    LogFile->PutOID (cid);
	    PutFinishUp ();
	}
    }

    void LogRemoveConfiguredClass (global VersionID vid,
				   global ConfiguredClassID ccid)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(RemoveConfiguredClass ");
	      LogFile->PutOID (vid);
	      PutBlank ();
	      LogFile->PutOID (ccid);
	      PutFinishUp ();
	  }
      }

    void LogRemoveLowerVersion (global VersionID uvid, global VersionID lvid)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(RemoveLowerVersion ");
	      LogFile->PutOID (uvid);
	      PutBlank ();
	      LogFile->PutOID (lvid);
	      PutFinishUp ();
	  }
      }

    void LogRemoveProperty (global ClassID cid, char name []) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(RemoveProperty ");
	    LogFile->PutOID (cid);
	    PutBlank ();
	    PutName (name);
	    PutFinishUp ();
	}
    }

    void LogSetDefaultConfiguredClassID (global ClassID cid,
					 global ConfiguredClassID ccid)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(SetDefaultConfiguredClassID ");
	      LogFile->PutOID (cid);
	      PutBlank ();
	      LogFile->PutOID (ccid);
	      PutFinishUp ();
	  }
      }

    void LogSetDefaultLowerVersionID (global ClassID cid, global VersionID vid)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(SetDefaultLowerVersionID ");
	      LogFile->PutOID (cid);
	      PutBlank ();
	      LogFile->PutOID (vid);
	      PutFinishUp ();
	  }
      }

    void LogSetImplementationParts (global ConfiguredClassID ccid,
				    global VersionID impl_ids [])
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(SetImplementationParts ");
	      LogFile->PutOID (ccid);
	      PutBlank ();
	      LogOIDArray (impl_ids);
	      PutFinishUp ();
	  }
      }

    void LogSetParents (global ClassID cid, global VersionID parents [])
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(SetParents ");
	      LogFile->PutOID (cid);
	      PutBlank ();
	      LogOIDArray (parents);
	      PutFinishUp ();
	  }
      }

    void LogSetVersionString (global VersionID vid, VersionString vs): locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(SetVersionString ");
	    LogFile->PutOID (vid);
	    PutBlank ();
	    LogVersionString (vs);
	    PutFinishUp ();
	}
    }

    void LogStringArray (String starray []) {
	unsigned int i, len = length starray;

	LogFile->PutInt (len);
	for (i = 0; i < len; i ++) {
	    LogFile->PutStr (" \"");
	    LogFile->PutStr (starray [i]->Content ());
	    LogFile->PutStr ("\"");
	}
    }

    void LogUpperPart (UpperPart up) {
	LogClassVersion (up);
	PutBlank ();
	LogOIDArray (up->GetLowerVersions ());
	PutBlank ();
	LogFile->PutOID (up->GetDefaultLowerVersionID ());
	PutBlank ();
	LogOIDArray (up->GetVisibleLowerVersions ());
    }

    void LogVersionString (VersionString vs) {
	if (vs == 0) {
	    LogFile->PutInt (-1);
	} else {
	    LogFile->PutInt (vs->GetPublicPart ());
	    PutBlank ();
	    LogFile->PutInt (vs->GetProtectedPart ());
	    PutBlank ();
	    LogFile->PutInt (vs->GetImplementationPart ());
	}
    }

    void Open () {
	int flag;

	inline "C" {
	    _oz_debug_flag = 1;
	    flag = O_SYNC | O_WRONLY | O_CREAT | O_TRUNC;
	}
	try {
	    LogFile=>NewWithFlag (LogFilePath, flag);
	} except {
	  FileReaderExceptions::CannotOpenFile (log_file) {
	      int err;

	      inline "C" {
		  err = errno;
	      }
	      debug (0,
		     "ClassLogger::Open: "
		     "cannot open class object log file %S. errno = %d\n"
		     "                   "
		     "Going into conservative mode ...\n",
		     log_file, err);
	      LogFile = 0;
	  }
	}
	Count = 0;
    }

    void OpenDeadLogFile () {
	char log_file [];

	if (DeadLogFile == 0) {
	    int flag;

	    inline "C" {
		flag = O_SYNC | O_WRONLY | O_APPEND | O_CREAT;
	    }
	    try {
		DeadLogFile=>NewWithFlag (DeadLogFilePath, flag);
	    } except {
	      FileReaderExceptions::CannotOpenFile (log_file) {
		  int err;

		  inline "C" {
		      err = errno;
		  }
		  debug (0,
			 "ClassLogger::OpenDeadLogFile: "
			 "FATAL! -- cannot open dead log file %S.  "
			 "errno = %d\n"
			 "                             "
			 "Terminating class object ...\n",
			 log_file, err);
		  raise;
	      }
	    }
	}
    }

    global ConfiguredClassID ReadCCID (ClassLogFileReader clfr) {
	return narrow (ConfiguredClassID, clfr->ReadObjectID ());
    }

    global ConfiguredClassID ReadCCIDArray (ClassLogFileReader clfr)[] {
	unsigned int i, len = clfr->ReadInteger ();
	global ConfiguredClassID ccarray [];

	length ccarray = len;
	for (i = 0; i < len; i ++) {
	    ccarray [i] = ReadCCID (clfr);
	}
	return ccarray;
    }

    global ClassID ReadClassID (ClassLogFileReader clfr) {
	return narrow (ClassID, clfr->ReadObjectID ());
    }

    global ClassID ReadClassIDArray (ClassLogFileReader clfr)[] {
	unsigned int i, len = clfr->ReadInteger ();
	global ClassID cids [];

	length cids = len;
	for (i = 0; i < len; i ++) {
	    cids [i] = ReadClassID (clfr);
	}
	return cids;
    }

    global ClassPackageID ReadClassPackageID (ClassLogFileReader clfr) {
	return narrow (ClassPackageID, clfr->ReadObjectID ());
    }

    ConfiguredClass ReadConfiguredClass (ClassLogFileReader clfr, Class c) {
	global ConfiguredClassID ccid = ReadCCID (clfr);
	int copy_kind = clfr->ReadInteger ();
	int distributability = clfr->ReadInteger ();
	String properties [] = ReadStringArray (clfr);
	global VersionID public_id = ReadVID (clfr);
	ConfiguredClass cc=>New (c, ccid, public_id, copy_kind);
	global VersionID impl_ids [] = ReadVIDArray (clfr);

	cc->SetDistributability (distributability);
	SetProperties (cc, properties);
	cc->SetImplementationParts (impl_ids);
	return cc;
    }

    Date ReadDate (ClassLogFileReader clfr) {
	String s = clfr->ReadString ();
	Date d=>NewFromString (s->GetSubString (1, s->Length () - 2));

	return d;
    }

    ImplementationPart ReadImplementationPart (ClassLogFileReader clfr,
					       Class c) {
	global VersionID upper = ReadVID (clfr);
	global VersionID vid = ReadVID (clfr);
	int copy_kind = clfr->ReadInteger ();
	int distributability = clfr->ReadInteger ();
	ImplementationPart ip=>New (vid, c, upper, copy_kind);

	ip->SetDistributability (distributability);
	SetClassVersion (ip, clfr);
	SetArchitecture (ip, clfr);
	return ip;
    }

    int ReadIntArray (ClassLogFileReader clfr)[] {
	unsigned int i, len = clfr->ReadInteger ();
	int iarray [];

	length iarray = len;
	for (i = 0; i < len; i ++) {
	    iarray [i] = clfr->ReadInteger ();
	}
	return iarray;
    }

    ProtectedPart ReadProtectedPart (ClassLogFileReader clfr, Class c) {
	global VersionID upper = ReadVID (clfr);
	global VersionID vid = ReadVID (clfr);
	int copy_kind = clfr->ReadInteger ();
	int distributability = clfr->ReadInteger ();
	ProtectedPart protp=>New (vid, c, upper, copy_kind);

	protp->SetDistributability (distributability);
	SetUpperPart (protp, clfr);
	return protp;
    }

    PublicPart ReadPublicPart (ClassLogFileReader clfr, Class c) {
	global VersionID upper = ReadVID (clfr);
	unsigned int kind = clfr->ReadInteger ();
	global VersionID vid = ReadVID (clfr);
	int copy_kind = clfr->ReadInteger ();
	int distributability = clfr->ReadInteger ();
	global ConfiguredClassID ccid;
	PublicPart pubp=>New (vid, c, upper, kind, copy_kind);

	pubp->SetDistributability (distributability);
	SetUpperPart (pubp, clfr);
	SetConfiguredClassIDList (pubp, ReadCCIDArray (clfr));
	ccid = ReadCCID (clfr);
	if (ccid != 0) {
	    pubp->SetDefaultConfiguredClassID (ccid);
	}
	return pubp;
    }

    RootPart ReadRootPart (ClassLogFileReader clfr, Class c) {
	global VersionID vid = ReadVID (clfr);
	int copy_kind = clfr->ReadInteger ();
	int distributability = clfr->ReadInteger ();
	RootPart rp=>New (vid, c, copy_kind);

	rp->SetDistributability (distributability);
	SetUpperPart (rp, clfr);
	return rp;
    }

    String ReadStringArray (ClassLogFileReader clfr)[] {
	unsigned int i, len = clfr->ReadInteger ();
	String starray [];

	length starray = len;
	for (i = 0; i < len; i ++) {
	    starray [i] = clfr->ReadString ();
	}
	return starray;
    }

    global VersionID ReadVID (ClassLogFileReader clfr) {
	return narrow (VersionID, clfr->ReadObjectID ());
    }

    global VersionID ReadVIDArray (ClassLogFileReader clfr)[] {
	unsigned int i, len = clfr->ReadInteger ();
	global VersionID varray [];

	length varray = len;
	for (i = 0; i < len; i ++) {
	    varray [i] = ReadVID (clfr);
	}
	return varray;
    }

    VersionString ReadVersionString (ClassLogFileReader clfr) {
	int pubp = clfr->ReadInteger ();
	VersionString vs;

	if (pubp == -1) {
	    return 0;
	} else {
	    int protp = clfr->ReadInteger (), implp = clfr->ReadInteger ();

	    vs=>New ();
	    vs->SetPublicPart (pubp);
	    vs->SetProtectedPart (protp);
	    vs->SetImplementationPart (implp);
	    return vs;
	}
    }

    void SetArchitecture (ImplementationPart ip, ClassLogFileReader clfr) {
	int aids [] = ReadIntArray (clfr);
	unsigned int i, len = length aids;
	ArchitectureID aid;

	for (i = 0; i < len; i ++) {
	    ip->AddArchitecture (aid=>New (aids [i]));
	}
    }

    void SetClassVersion (ClassVersion cv, ClassLogFileReader clfr) {
	VersionString vs;

	SetProperties (cv, ReadStringArray (clfr));
	vs = ReadVersionString (clfr);
	if (vs != 0) {
	    cv->SetVersionString (vs);
	}
	cv->SetParents (ReadVIDArray (clfr));
    }

    void SetConfiguredClassIDList (PublicPart pubp,
				   global ConfiguredClassID ccids []) {
	unsigned int i, len = length ccids;

	for (i = 0; i < len; i ++) {
	    pubp->AddAsNewConfiguration (ccids [i]);
	}
    }

    void SetLowerVersions (UpperPart up, global VersionID lower_versions []) {
	unsigned int i, len = length lower_versions;

	for (i = 0; i < len; i ++) {
	    up->AddAsNewLowerVersion (lower_versions [i]);
	}
    }

    void SetUpperPart (UpperPart up, ClassLogFileReader clfr) {
	global VersionID vid;

	SetClassVersion (up, clfr);
	SetLowerVersions (up, ReadVIDArray (clfr));
	vid = ReadVID (clfr);
	if (vid != 0) {
	    up->SetDefaultLowerVersionID (vid);
	}
	SetVisibleLowerVersions (up, ReadVIDArray (clfr));
    }

    void SetVisibleLowerVersions (UpperPart up,
				  global VersionID visible_lower_versions []) {
	unsigned int i, len = length visible_lower_versions;

	for (i = 0; i < len; i ++) {
	    up->AddAsNewLowerVersion (visible_lower_versions [i]);
	}
    }

    void SetProperties (ClassPart cp, String properties []) {
	unsigned int i, len = length properties;

	for (i = 0; i < len; i ++) {
	    cp->AddProperty (properties [i]->Content ());
	}
    }

    void SetThreshold (unsigned int th) {Threshold = th;}

    /*
     * if ( logfile.ded exists ) { write a warning to ozlog; }
     * if ( logfile.rcv exists ) {
     *     rm logfile;
     *     mv logfile.rcv logfile;
     * }
     * if ( logfile isn't empty ) {
     *     mv logfile logfile.rcv;
     *     redo transaction;
     *     rm logfile.rcv;
     * }
     */

    int Start (int safe_shutdown, Class c) {
	FileOperators fops;
	int to_be_flushed = 0;

	inline "C" {
	    _oz_debug_flag = 1;
	}
	if (fops.IsExists (DeadLogFilePath)) {
	    debug (0,
		   "ClassLogger: There are some aborted transactions in %S.\n"
		   "             Check and remove it if not needed.\n",
		   DeadLogFilePath->Content ());
	}
	if (safe_shutdown) {
	    Open ();
	} else {
	    if (fops.IsExists (RecoveringLogFilePath)) {
		debug (0,
		       "ClassLogger: Transaction recovering file exists.  "
		       "Previous execution seems to\n"
		       "             be aborted during redoing lost "
		       "transaction.  Trying to recover\n"
		       "             from temporary file ...\n");
		if (fops.IsExists (LogFilePath)) {
		    fops.Remove (LogFilePath);
		}
		fops.Move (RecoveringLogFilePath, LogFilePath);
	    }
	    if (fops.IsExists (LogFilePath)) {
		fops.Move (LogFilePath, RecoveringLogFilePath);
		Open ();
		if (Apply (c, RecoveringLogFilePath)) {
		    debug (0, "ClassLogger: lost transaction was redone.\n");
		} else {
		    debug (0,
			   "ClassLogger: Some error was occurred in "
			   "redoing transactions.\n"
			   "             See logfile.ded.\n");
		}
		fops.Remove (RecoveringLogFilePath);
		to_be_flushed = 1;
	    }
	}
	return to_be_flushed;
    }

/* for copy management */
    void LogAddMirrorMember (global ClassPackageID cpid,
			     global ClassID cids [])
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(AddMirrorMember ");
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogOIDArray (cids);
	      PutFinishUp ();
	  }
      }

    void LogAddToClassPackage (global ClassPackageID cpid,
			       global ClassID cids [])
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(AddToClassPackage ");
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogOIDArray (cids);
	      PutFinishUp ();
	  }
      }

    void LogAddToaCopyClass (char title [], global ClassID cid) {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(");
	    LogFile->PutStr (title);
	    PutBlank ();
	    LogFile->PutOID (cid);
	    PutFinishUp ();
	}
    }

    void LogAddToOriginalPackages (global ClassPackageID id,
				   OriginalClassPackage package)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(AddToOriginalPackages ");
	      LogFile->PutOID (id);
	      PutBlank ();
	      LogOIDArray (package->SetOfContents ());
	      PutFinishUp ();
	  }
      }

    void LogAddToOriginals (global ClassID cid) : locked {
	LogAddToaCopyClass ("AddToOriginals", cid);
    }

    void LogAddToSnapshots (global ClassID cid) : locked {
	LogAddToaCopyClass ("AddToSnapshots", cid);
    }

    void LogChangeCopyKind (global ClassID cid, int copy_kind) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(ChangeCopyKind ");
	    LogFile->PutOID (cid);
	    PutBlank ();
	    LogFile->PutInt (copy_kind);
	    PutFinishUp ();
	}
    }

    void LogChangeMirrorMode (global ClassPackageID cpid, int new_mode)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(ChangeMirrorMode ");
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogFile->PutInt (new_mode);
	      PutFinishUp ();
	  }
      }

    void LogChangeMirrorSetting (global Class to, global ClassPackageID cpid,
				 int new_mode)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(ChangeMirrorSetting ");
	      LogFile->PutOID (to);
	      PutBlank ();
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogFile->PutInt (new_mode);
	      PutFinishUp ();
	  }
      }

    void LogDeleteFromClassPackage (global ClassPackageID cpid,
				    global ClassID cids [])
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(DeleteFromClassPackage ");
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogOIDArray (cids);
	      PutFinishUp ();
	  }
      }

    void LogDeleteMirrorMember (global ClassPackageID cpid,
				global ClassID cids [])
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(DeleteMirrorMember ");
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogOIDArray (cids);
	      PutFinishUp ();
	  }
      }

    void LogDestroyClassPackage (global ClassPackageID cpid) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(DestroyClassPackage ");
	    LogFile->PutOID (cpid);
	    PutFinishUp ();
	}
    }

    void LogPrivatize (global ClassID cid) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(Privatize ");
	    LogFile->PutOID (cid);
	    PutFinishUp ();
	}
    }

    void LogRegisterMirror (global Class to,
			    global ClassPackageID cpid, int mode)
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(RegisterMirror ");
	      LogFile->PutOID (to);
	      PutBlank ();
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogFile->PutInt (mode);
	      PutFinishUp ();
	  }
      }

    void LogSetMirror (global ClassPackageID cpid, global Class from,
		       unsigned int mode, global ClassID cids [])
      : locked {
	  if (CheckLogging ()) {
	      LogFile->PutStr ("(SetMirror ");
	      LogFile->PutOID (cpid);
	      PutBlank ();
	      LogFile->PutOID (from);
	      PutBlank ();
	      LogFile->PutInt (mode);
	      PutBlank ();
	      LogOIDArray (cids);
	      PutFinishUp ();
	  }
      }

    void LogUnsetMirror (global ClassPackageID cpid) : locked {
	if (CheckLogging ()) {
	    LogFile->PutStr ("(UnsetMirror ");
	    LogFile->PutOID (cpid);
	    PutFinishUp ();
	}
    }
}
