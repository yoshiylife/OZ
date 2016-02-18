/*
COPYRIGHT AND LICENSE NOTICE

Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan (IPA)

This software and documentation is a result of the Open Fundamental Software
Technology Project of Information-technology Promotion Agency, Japan (IPA).

Permission to use, copy, modify and distribute this software and
documentation for any purpose and without fee is hereby granted in
perpetuity, provided that this COPYRIGHT AND LICENSE NOTICE appears in its
entirety in all copies of the software and supporting documentation.
Other software contained in this distribution package, terms and conditions
of each license notice of the software shall be observed.

IPA MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE SUIT ABILITY OF THE
SOFTWARE OR DOCUMENTATION FOR ANY PURPOSE.  THEY ARE PROVIDED "AS IS"
WITHOUT EXPRESS OR IMPLIED WARRANTY OF ANY KIND INCLUDING BUT NOT LIMITED
TO FUNCTION, PERFORMANCE, AND BUG-FREE.  IPA DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE AND DOCUMENTATION,INCLUDING THE WARRANTIES OF
MERCHANTABILITY, DESIGN, FITNESS FOR A PARTICULAR PURPOSE AND NON
INFRINGEMENT OF THIRD PARTY RIGHTS.  IN NO EVENT SHALL IPA BE LIABLE FOR ANY
SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA, OR PROFITS, WHETHER IN ACTION
ARISING OUT OF CONTRACT, NEGLIGENCE, PRODUCT LIABILITY, OR OTHER TORTIOUS
ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
SOFTWARE OR DOCUMENTATION.

This COPYRIGHT AND LICENSE NOTICE shall be subject to the Japanese version
(language), the laws of Japan (governing law), and the Tokyo District Court
shall have exclusive primary jurisdiction.
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


// we distribute class not by tar'ed directory


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


// we have no str[fp]time


// boot classes are modifiable


// when object manager is started, its configuration cache won't be cleared
//#define CLEARCONFIGURATIONCACHEATSTART

// the executor doesn't expect a class cannot be found


// now, creating Feb.1 sources

/*
 * school.oz
 *
 * School
 */

inline "C" {
#include <fcntl.h>
}

class School : SimpleTable <char [], SchoolValue> {
/* interface from super class */
  constructor: Load, New;
  public: Size;
  protected:
    Capacity, DefaultExpansionFactor, DefaultInitialTableSize, Expand,
    Initialize;
  protected:
    ExpansionFactor, InitialTableSize, KeyTable, Nbits, NumberOfElement, Table;

/* interface of this class */
  public:
    ChangeValue, ImplementationIDOf, Includes, IsEqual, IsSubSchoolOf,
    IsSuperSchoolOf, KindOf, ListNames, NewEntry, PrintIt, ProtectedIDOf,
    PublicIDOf, Remove;

/* for compatibilty of old version */
  public: Change, Register, VersionIDOf;

/* no instance variables */

/* method implementations */
    void Load (String path) {
	Stream file=>New (path);

	Initialize (DefaultExpansionFactor (), DefaultInitialTableSize ());
	while (! file->IsEndOfFile ()) {
	    int kind = file->GetC () - '0';
	    char name [] = ReadTillNewLine (file);
	    global VersionID pubid, protid, implid;
	    SchoolValue v;

	    pubid = ReadVID (file);
	    if (kind == KindOfClassPart::anOrdinaryClass ||
		kind == KindOfClassPart::anAbstractClass) {
		protid = ReadVID (file);
		implid = ReadVID (file);
	    }
	    SkipNewLine (file);
	    v.Set (kind, pubid, protid, implid);
	    Add (name, v);
	}
	file->Close ();
    }

    void SkipNewLine (Stream file) {
	int c;

	while ((c = file->GetC ()) != StreamConstants::EOF) {
	    if (c != ' ' && c != '\t') {
		break;
	    }
	}
	if (c != '\n') {
	    DefaultToken token=>New (c);
	    raise FileReaderExceptions::SyntaxError (token);
	}
    }

    global VersionID ReadVID (Stream file) {
	char buf [];
	unsigned int i;
	int c;
	ArrayOfCharOperators acops;

	length buf = 17;
	while ((c = file->GetC ()) != StreamConstants::EOF) {
	    if (c != ' ' && c != '\t') {
		break;
	    }
	}
	file->UngetC (c);
	buf = file->GetTillaChar (" \t\n");
	file->UngetC (buf [length buf - 2]);
	buf [length buf - 2] = 0;
	return narrow (VersionID, acops.Str2OID (buf));
    }

    char ReadTillNewLine (Stream file)[] {
	char buf [];
	int c;

	while ((c = file->GetC ()) != StreamConstants::EOF) {
	    if (c != ' ' && c != '\t')
	      break;
	}
	file->UngetC (c);
	buf = file->GetS ();
	if (buf [length buf - 2] == '\n') {
	    buf [length buf - 2] = 0;
	}
	return buf;
    }

    void Change (String key, unsigned int kind, global VersionID pubid) {
	global VersionID protid, implid;
	ArchitectureID any;

	if (kind == 0 || kind == 8) {    /* ordinary class or abstract class */
	    protid
	      = Where ()
		->SearchClass (pubid, any=>Any ())->GetProtectedPart (pubid);
	    implid
	      = Where ()
		->SearchClass (protid, any)->GetImplementationPart (protid);
	} else {
	    protid = 0;
	    implid = 0;
	}
	ChangeValue (key, kind, pubid, protid, implid);
    }

    void ChangeValue (String key, unsigned int kind, global VersionID pubid,
		      global VersionID protid, global VersionID implid) {
	char k [] = key->Content ();
	SchoolValue v;

	v.Set (kind, pubid, protid, implid);
	if (IncludesKey (k)) {
	    Add (k, v);
	} else {
	    raise CollectionExceptions <String>::UnknownKey (key);
	}
    }

    unsigned int FindIndexOf (char k []) {
	unsigned int h, i, mod, capacity = length KeyTable, n = Nbits;
	ArrayOfCharOperators acops;


	if (NumberOfElement > capacity / ExpansionFactor) {
	    Expand ();
	    capacity = length KeyTable;
	    n = Nbits;
	}

	h = acops.Hash (k);

	inline "C" {
	    mod = ((0x9e3779b9 * h) >> (32 - n)) % capacity;
	}
	for (i = mod; i != mod - 1 ; (++i == capacity) && (i = 0)) {
	    if (KeyTable [i] == 0

		|| acops.IsEqual (KeyTable [i], k)

		) {
		return i;
	    }
	}
	{
	    String key=>NewFromArrayOfChar (k);
	    raise CollectionExceptions <String>::InternalError (key);
	}
    }

    global VersionID ImplementationIDOf (String key) {
	return AtKey (key->Content ()).ImplementationVID;
    }

    int Includes (String key) {return IncludesKey (key->Content ());}

    int IsEqual (School s) {
	return IsSubSchoolOf (s) && IsSuperSchoolOf (s);
    }

    int IsSubSchoolOf (School s) {
	unsigned int i, capacity = length KeyTable;

	for (i = 0; i < capacity; i ++) {
	    char k [] = KeyAt (i);

	    if (k != 0) {
		String key=>NewFromArrayOfChar (k);

		if (! s->Includes (key)
		    || AtKey (k).Kind != s->KindOf (key)
		    || AtKey (k).PublicVID != s->PublicIDOf (key)
		    || AtKey (k).ProtectedVID != s->ProtectedIDOf (key)
		    || AtKey (k).ImplementationVID
		         != s->ImplementationIDOf (key))
		  return 0;
	    }
	}
	return 1;
    }

    int IsSuperSchoolOf (School s) {return s->IsSubSchoolOf (self);}

    unsigned int KindOf (String key) {
	return AtKey (key->Content ()).Kind;
    }

    Set <String> ListNames () {
	unsigned int i, capacity = length KeyTable;
	Set <String> set=>NewWithSize (NumberOfElement);

	for (i = 0; i < capacity; i ++) {
	    char k [] = KeyAt (i);

	    if (k != 0) {
		String key=>NewFromArrayOfChar (k);

		set->Add (key);
	    }
	}
	return set;
    }

    void NewEntry (char key [], unsigned int kind, global VersionID pubid,
		   global VersionID protid, global VersionID implid) {
	SchoolValue v;

	v.Set (kind, pubid, protid, implid);
	if (! IncludesKey (key)) {
	    Add (key, v);
	} else {
	    raise CollectionExceptions <char []>::RedefinitionOfKey (key);
	}
    }

    void PrintIt (String path) {
	unsigned int i, capacity = length KeyTable;
	int flag;
	Stream file;
	ArchitectureID any=>Any ();

	inline "C" {
	    flag = O_WRONLY | O_CREAT | O_TRUNC;
	}
	file=>NewWithFlag (path, flag);
	for (i = 0; i < capacity; i ++) {
	    char k [] = KeyAt (i);

	    if (k != 0) {
		String key=>NewFromArrayOfChar (k);
		unsigned int kind = AtKey (k).Kind;
		global VersionID pub = AtKey (k).PublicVID;
		global VersionID prot;
		global VersionID impl;

		switch (kind) {
		  case 0: /* ordinary class */
		  case 8: /* abstract class */
		    prot = AtKey (k).ProtectedVID;
		    impl = AtKey (k).ImplementationVID;
		    file->PutInt (kind);
		    file->PutStr (" ");
		    file->PutStr (k);
		    file->PutStr ("\n\t");
		    file->PutOID (pub);
		    file->PutStr ("\t");
		    file->PutOID (prot);
		    file->PutStr ("\t");
		    file->PutOID (impl);
		    file->PutStr ("\n");
		    break;
		  case 5: /* shared */
		  case 6: /* static class */
		  case 7: /* record */
		    file->PutInt (kind);
		    file->PutStr (" ");
		    file->PutStr (k);
		    file->PutStr ("\n\t");
		    file->PutOID (pub);
		    file->PutStr ("\n");
		    break;
		}
	    }
	}
    }

    global VersionID ProtectedIDOf (String key) {
	return AtKey (key->Content ()).ProtectedVID;
    }

    global VersionID PublicIDOf (String key) {
	return AtKey (key->Content ()).PublicVID;
    }

    void Register (String key, unsigned int kind, global VersionID vid) {
	char k [] = key->Content ();
	SchoolValue v;
	global VersionID protid, implid;
	ArchitectureID any;

	if (kind == 0 || kind == 8) { /* ordinary class or abstract class */
	    protid
	     = Where ()->SearchClass (vid,any=>Any ())->GetProtectedPart (vid);
	    implid
	      = Where ()
		->SearchClass (protid, any)->GetImplementationPart (protid);
	} else {
	    protid = 0;
	    implid = 0;
	}
	v.Set (kind, vid, protid, implid);
	if (IncludesKey (k)) {
	    raise CollectionExceptions <String>::RedefinitionOfKey (key);
	} else {
	    Add (k, v);
	}
    }

    void Remove (String key) {RemoveKey (key->Content ());}

    unsigned int DefaultInitialTableSize () {return 8;}

    global VersionID VersionIDOf (String key) {return PublicIDOf (key);}

/*
    // An obsolete implementation of Load.  This is too slow...
    void Load (String path) {
	SchoolFileReader sfr=>New (path);

	Initialize (DefaultExpansionFactor (), DefaultInitialTableSize ());
	while (! sfr->IsEndOfToken ()) {
	    LoadaRecord (sfr);
	}
    }

    void LoadaRecord (SchoolFileReader sfr) {
	int kind = sfr->ReadInteger ();
	char key [] = sfr->ReadClassName ()->Content ();
	global VersionID pubid = narrow (VersionID, sfr->ReadObjectID ());
	global VersionID protid = 0, implid = 0;
	SchoolValue v;

	if (kind == KindOfClassPart::anOrdinaryClass ||
	    kind == KindOfClassPart::anAbstractClass) {
	    protid = narrow (VersionID, sfr->ReadObjectID ());
	    implid = narrow (VersionID, sfr->ReadObjectID ());
	}
	v.Set (kind, pubid, protid, implid);
	Add (key, v);
    }
*/
}
