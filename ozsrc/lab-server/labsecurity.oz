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
 * labsecurity.oz
 *
 * LaboratorySecurity
 */

class LaboratorySecurity {
  constructor: New;
  public: CheckString, IsSecureInvocation, ReloadKey, SecurityException;

    /* instance variables */

    long StringID;
    long SubStringID;
    long CredentialID;
    String KeyFile;
    String Key;

    /* method implementations */

    void New() {
	String exid = GetExIDString();
	String st=>NewFromArrayOfChar("images/");
	SubString sst=>NewFromString(st, 0, 0);
	Credential cred=>New(st);

	StringID = GetCCID(st);
	SubStringID = GetCCID(sst);
	CredentialID = GetCCID(cred);

	/* Key file is named as `labo-key'. */
	st = st->Concatenate(exid);
	KeyFile = st->ConcatenateWithArrayOfChar("/labo-key");
    }

    String GetExIDString() {
	global ObjectManager om = Where();
	char buf[];
	String exidstr;
	length buf = 7; /* executor part length of OID is 6 in hexa-decimal */
	inline "C" {
	    OzSprintf(OZ_ArrayElement(buf, char), "%06x",
		      (om >> 24) & 0xffffffLL);
	}
	exidstr=>NewFromArrayOfChar(buf);
	return exidstr;
    }

    /* Checks if r/w permissions to group/other users are denied. */
    void CheckFileStatus() {
	FileOperators fops;

	if (! fops.IsPlainFile(KeyFile) || ! fops.IsSecureFile(KeyFile)) {
	    String message=>NewFromArrayOfChar("Insecure key file: ");
	    message = message->Concatenate(KeyFile);
	    SecurityException(message);
	}
    }

    String ReadKeyFile() {
	Stream keyFile=>New(KeyFile);
	String st=>NewFromArrayOfChar(keyFile->GetS());
	keyFile->Close ();
	return st;
    }

    String GetKey() {
	CheckFileStatus();
	Key = ReadKeyFile();
    }

    String ReloadKey() : global {
	Key = GetKey();
    }

    long GetCCID(Object o) {
	long id;
	inline "C" {
	    OZ_ObjectAll all = OzExecGetObjectTop(o);
	    id = all->head[0].a;
	}
	return id;
    }

    void InsecureObject(char name[], long id) {
	ArrayOfCharOperators acops;
	String message=>NewFromArrayOfChar("Insecure ");
	String d=>NewFromArrayOfChar(acops.ItoA(id >> 32));
	d = d->ConcatenateWithArrayOfChar(acops.ItoA(id & 0xffffffff));
	message = message->ConcatenateWithArrayOfChar(name);
	message = message->ConcatenateWithArrayOfChar(" object(");
	message = message->Concatenate(d);
	message = message->ConcatenateWithArrayOfChar(")");
	SecurityException(message);
    }

    void CheckCredential(Credential cred) {
	long id = GetCCID(cred);
	if (id != CredentialID) {
	    InsecureObject("Credential", id);
	}
    }

    void CheckString(String st) {
	long id = GetCCID(st);
	if (id == StringID) {
	    return;
	} else if (id == SubStringID) {
	    CheckString(narrow(SubString, st)->WholeString());
	    return;
	}
	InsecureObject("String", id);
    }

    int IsSecureInvocation(Credential cred) {
	String key;
	CheckCredential(cred);
	key = cred->GetKey();
	return key->IsEqualTo(Key);
    }

    void SecurityException(String message) {
	raise SecurityExceptions::PermissionDenied(message);
    }
}
