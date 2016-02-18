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
 * conffilemaker.oz
 *
 * ConfigurationFileMaker
 * Create a configuration file used to start an application on a stand alone
 * OM.
 */

inline "C" {
#include <fcntl.h>
}

class ConfigurationFileMaker : CatalogTool {
/* no instance variables */
    String PackageName;

/* method implementations */
    String GetPackageName() {
	TypeStr("Enter the package name in the catalog: ");
	PackageName = Trim(Read());
	return PackageName;
    }

    Stream OpenOutputFile() {
	String path;
	FileOperators fops;
	Stream stream = 0;
	int flag;

	inline "C" {
	    flag = O_WRONLY | O_CREAT | O_APPEND;
	}

	while (stream == 0) {
	    char p[];

	    TypeStr("Enter configuration file name: ");
	    path = Trim(Read());
	    try {
		stream=>NewWithFlag(path, flag);
	    } except {
	      FileReaderExceptions::CannotOpenFile(p) {
		  TypeStr(p);
		  TypeStr(": cannot open file.\n");
		  stream = 0;
	      }
	    }
	}
	return stream;
    }

    void Do(School school, global Class c) {
	global ObjectManager om = Where();
	Set <String> s = school->ListNames();
	Iterator <String> i;
	String name;
	Stream stream = OpenOutputFile();

	stream->PutStr("# generated from catalog ");
	stream->PutStr(PackageName->Content());
	stream->PutStr("\n");
	for (i=>New(s); (name = i->PostIncrement()) != 0;) {
	    global VersionID public_id = school->VersionIDOf(name);
	    global ConfiguredClassID ccid;

	    TypeString(name);
	    TypeStr(": ");
	    try {
		ccid = om->GetConfiguredClassID(public_id, 0);
		if (ccid != 0) {
		    TypeOID(ccid);
		    TypeStr("\n");
		    stream->PutStr(name->Content());
		    stream->PutStr(" ");
		    stream->PutOID(public_id);
		    stream->PutStr(" ");
		    stream->PutOID(ccid);
		    stream->PutStr("\n");
		} else {
		    TypeStr("No configuration\n");
		}
	    } except {
	      ClassExceptions::UnknownClass(unknown) {
		  TypeStr("Unknown public version ID ");
		  TypeOID(public_id);
		  TypeStr(".\n");
	      }
	      default {
		  TypeStr("something wrong ...\n");
	      }
	    }
	}
	stream->Close();
    }

    String Title() {
	String title=>NewFromArrayOfChar("Configuration File Maker");

	return title;
    }
}
