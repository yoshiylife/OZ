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
 * acd.oz
 *
 * Authentication server
 */

/*
 * structure of credential
 *
 * encrypted by sender password {
 *   0 : sender name
 *   1 : session ID
 *   2 : session key
 *   3 : current time
 *   4 : expiration time
 *   5 : nonce
 *   6 : encrypted by receiver password {
 *         6.0 : sender name
 *         6.1 : session ID
 *         6.2 : session key
 *         6.3 : current time
 *         6.4 : expiration time
 *       }
 * }
 */

class AccountDirectory : ResolvableObject, SecureObject (rename New SecureNew;)
{
  protected: Go, Removing, Stop;

  constructor: New;
  public:
    AddUser, GetCredential, GetExpirationTime, GetPassword, IsEmpty,
    ListUsers, RemoveUser, SetExpirationTime;

  protected:

/* instance variables */

/* instance variables */
    global SessionID ID;
    String ExpirationTime; /* in second */

/* method implementations */
    void NewDirectorySystem () : global {
	long exid = Where ()->ExecutorID ();
	global SessionID id;

	SuperNewDirectorySystem ();
	SecureNew ();
	inline "C" {
	    id = exid;
	}
	ID = id;
	ExpirationTime=>NewFromArrayOfChar ("60");
    }

    global DirectoryServer <String>
      CreateNewDirectoryServer (global ObjectManager where) {
	  raise DirectoryExceptions::CannotCreateDirectoryServer;
      }

    String GetDelimiter () {
	String s=>NewFromArrayOfChar ("");

	return s;
    }

    String GetExpirationTime () : global {return ExpirationTime;}

    String CreateSessionID () {
	String session_ID;
	global SessionID id = ID;

	inline "C" {
	    id ++;
	}
	ID = id;
	session_ID=>OIDtoHexa (ID);
	return session_ID;
    }

    String CreateSessionKey () {
	int s, len;
	ArrayOfCharOperators acops;
	String session_key;

	inline "C" {
	    s = OzTime (0);
	}
	session_key=>NewFromArrayOfChar (acops.ItoA (s));
	len = session_key->Length ();
	if (len > 8) {
	    return session_key->GetSubString (len - 8, 0);
	} else {
	    return session_key;
	}
    }

    String Pack (String buf [], String password) {
	String credential;
	unsigned int i, len = length buf;

	if (len > 0) {
	    credential = buf [0];
	    for (i = 1; i < len; i ++) {
		credential
		  = credential->ConcatenateWithArrayOfChar (",")
		      ->Concatenate (buf [i]);
	    }
	    return Encrypt (credential, password);
	} else {
	    return 0;
	}
    }

    String GetCredential (String sender,String receiver,String nonce): global {
	ArrayOfCharOperators acops;
	String buf [];
	Date date=>Current ();
	String for_receiver, for_sender;

	length buf = CredentialStructure::ReceiverLength;
	buf [CredentialStructure::SenderName] = sender;
	buf [CredentialStructure::aSessionID] = CreateSessionID ();
	buf [CredentialStructure::SessionKey] = CreateSessionKey ();
	buf [CredentialStructure::CurrentTime] = date->PrintIt ();
	buf [CredentialStructure::ExpirationTime] = ExpirationTime;
	buf [CredentialStructure::Nonce] = nonce;
	for_receiver = Pack (buf, GetPassword (receiver));

	length buf = CredentialStructure::SenderLength;
	buf [CredentialStructure::ReceiverData] = for_receiver;
	for_sender = Pack (buf, GetPassword (sender));

	return for_sender;
    }

    void SetExpirationTime (String expiration) : global {
	ExpirationTime = expiration;
    }
}
