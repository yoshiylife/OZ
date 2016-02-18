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

class EasyCompiler {
  constructor: New;
  public: Compile;

    String SchoolFile;

    void New (String school_file_path) {
	SchoolFile = CopySchoolFile (school_file_path);
    }

    global ConfiguredClassID Compile (global ConfiguredClassID ccid,
				      char path [])
      : locked {
	  global Class c = SearchClass ();
	  global VersionID pubp = c->VersionIDFromConfiguredClassID (ccid);
	  global VersionID protp = GetProtected (c, pubp, ccid);
	  global VersionID new_vid = c->CreateNewPart (protp);
	  global ConfiguredClassID new_ccid;
	  UnixIO CFED = SpawnCfed (c);
	  String class_name = ReadClassName (CFED, protp);

	  char cls [] = class_name->Content ();
	  inline "C" {
	      OzDebugf ("class name is %S\n", cls);
	  }
	  ChangeImplementationPart (CFED, class_name, new_vid);
	  CompilePrivate (CFED, path);
	  new_ccid = c->CreateNewConfiguredClass (pubp);
	  ChangeConfiguredClass (CFED, class_name, new_ccid);
	  Configure (CFED, class_name);
	  CFED->PutStr ("quit\n");
	  return new_ccid;
      }

    void ChangeConfiguredClass (UnixIO CFED, String class_name,
				global ConfiguredClassID new_ccid) {
	CFED->PutStr ("sb ")->PutString (class_name)
	  ->PutStr (" 9 ")->PutOID (new_ccid)->PutReturn ();
    }

    void ChangeImplementationPart (UnixIO CFED, String class_name,
				   global VersionID new_vid) {
	CFED->PutStr ("sb ")->PutString (class_name)
	  ->PutStr (" 10 0 ")->PutOID (new_vid)->PutReturn ();
    }

    void CompilePrivate (UnixIO CFED, char path []) {
	CFED->PutStr ("compile ")->PutStr (path)->PutStr (" private\n");
    }

    void Configure (UnixIO CFED, String class_name) {
	CFED->PutStr ("config ")->PutString (class_name)->PutReturn ();
    }

    global VersionID GetProtected (global Class c,
				   global VersionID public_part,
				   global ConfiguredClassID ccid) {
	global VersionID impl_ids [] = c->GetImplementationParts (ccid);
	unsigned int i, len = length impl_ids;

	for (i = 0; i < len; i ++) {
	    if (c->GetPublicPart (impl_ids [i]) == public_part) {
		return c->GetProtectedPart (impl_ids [i]);
	    }
	}
	/* Something wrong in the class management system */
	/* The designated configured class does not include any */
	/* implementation part whose public part is as same as the */
	/* public part of the configured class. */
	raise ClassExceptions::InternalError;
    }

    String CopySchoolFile (String from) {
	String to, to_dir=>NewFromArrayOfChar ("images/"), o;
	long l;
	global Object executorID;
	FileOperators fops;

	l = Where ()->ExecutorID ();
	inline "C" {
	    executorID = l;
	}
	o=>OIDtoHexa (executorID);
	to_dir = to_dir->Concatenate (o->GetSubString (4, 6));
	to_dir = to_dir->ConcatenateWithArrayOfChar ("/easy-compiler");
	to = to_dir->ConcatenateWithArrayOfChar ("/");
	to = to->Concatenate (o=>OIDtoHexa (cell));
	if (! fops.IsExists (to_dir)) {
	    fops.MakeDirectory (to_dir);
	}
	fops.Copy (from, to);
	return to;
    }

    String ReadClassName (UnixIO CFED, global VersionID vid) {
	String class_name;

	CFED->PutStr ("sb ")->PutOID (vid)->PutStr (" 7\n");
	class_name = CFED->ReadString (128);
	/* chop terminating \n */
	return class_name->GetSubString (0, class_name->Length () - 1);
    }

    global Class SearchClass () {
	global ConfiguredClassID ccid;
	ArchitectureID aid=>Any ();

	inline "C" {
	    ccid = OzExecGetObjectTop (self)->head [0].a;
	}
	return Where ()->SearchClass (ccid, aid);
    }

    UnixIO SpawnCfed (global Class c) {
	UnixIO CFED;
	char argv [][];

	length argv = 6;
	argv [0] = "cfed";
	argv [1] = "-a";
	argv [2] = "-c";
	argv [3] = c->GetClassDirectoryPath ();
	argv [4] = "-s";
	argv [5] = SchoolFile->Content ();
	CFED=>Spawn (argv);
	return CFED;
    }
}
