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
 * secure.oz
 *
 * Secure object
 * Currently, user group is not supported.
 */

/* implement Bye, AddCategory */

abstract class SecureObject {
  protected: New; /* constructor */
  public: Authenticate;
  protected:
    AddCategory, Bye, ChangeCategory, CheckValid, Decrypt, Encrypt, Iam,
    RemoveCategory;

/* instance variables */
  protected: AccessControlList, SessionTable, OutofDateLimit, OwnerOnly;
    String AccessControlList [][];
    SimpleTable <global SessionID, Session> SessionTable;
    Time OutofDateLimit;

    int OwnerOnly;

/* method implementations */
    void New () {
	length AccessControlList = 1;
	SessionTable=>New ();
	OutofDateLimit=>NewFromTime (0, 0, 30);
	SetOwnerOnly ();
    }

    void SetOwnerOnly () {
	OwnerOnly = 0;
	length AccessControlList [0];
	AccessControlList [0][0]->NewFromArrayOfChar (Where ()->GetOwner ());
    }

    String Authenticate (String credential) : global {
	String s []
	  = Seperate (Decrypt (credential, Where ()->GetPassword ()), ',', 4);
	String from = s [CredentialStructure::SenderName];
	global SessionID session_id
	  = narrow (SessionID,s [CredentialStructure::aSessionID]->Str2OID ());
	String session_key = s [CredentialStructure::SessionKey];
	Date current_time=>NewFromString (s[CredentialStructure::CurrentTime]);

	if (OutOfDate (current_time)) {
	    raise AuthenticationExceptions::OutOfDate (current_time);
	} else {
	    Session session=>New (session_id, session_key, from);

	    SessionTable->Add (session_id, session);
	    return session_id;
	}
    }

    void CheckExpiration (Session session) {
	if (IsExpired (session)) {
	    Expire (session->GetSessionID ());
	    raise AuthenticationExceptions::SessionExpired (session_id);
	}
    }

    void CheckPermission (Session session, int category) {
	/* incomplete implementation --
	   cannot handle user group */
	unsigned int i, len;
	String sender = session->GetPeer ();

	if (category >= length AccessControlList) {
	    raise AuthenticationExceptions::InvalidCategory (category);
	}
	len = length AccessControlList [category];
	for (i = 0; i < len; i ++) {
	    if (AccessControlList [category][i]->IsEqualTo (sender)) {
		return;
	    }
	}
	raise AuthenticationExceptions::PermissionDenied;
    }

    void CheckRequestNumber (session, encrypted_req_num) {
	if (session->GetRequestNumber->IsEqualTo (encrypted_req_num)) {
	    session->DecrementRequestNumber ();
	    raise
	      AuthenticationExceptions
		::InValidRequestNumber (session->GetSessionID ());
	}
    }

    void CheckValid (global SessionID session_id, String encrypted_req_num,
		     int category) {
	Session session;

	try {
	    session = SessionTable->AtKey (session_id);
	} except {
	  CollectionExceptions <global SessionID>::UnknownKey (key) {
	      raise AuthenticationExceptions::UnknownSession (session_id);
	  }
	}
	CheckRequestNumber (session, encrypted_req_num);
	CheckPermission (session, category);
	CheckExpiration (session);
    }

    String Decrypt (String data, String key) {
	/* under implementation */
	return data;
    }

    String Encrypt (String data, String key) {
	/* under implementation */
	return data;
    }

    void Expire (global SessionID session_id){
	SessionTable->RemoveKey (session_id);
	debug (0, "SecureObject::Expire: session %O expired.\n", session_id);
    }

    int IsExpired (Session session) {
	Date current=>Current ();

	return session->GetExpirationDate ()->IsEarlierThan (current);
    }

    global AccountDirectory GetAccountDirectory () {
	/* under implementation --
	   health check must be made for account directory. */

	return narrow (AccountDirectory,
		       Where ()
		       ->GetNameDirectory ()
		       ->ResolveWithArrayOfChar ("account"));
    }

    global SessionID Iam (global SecureObject o) {
	String nonce = GetNonce ();
	String sender=>NewFromArrayOfChar (Where ()->GetOwner ());
	String receiver=>NewFromArrayOfChar (o->Where ()->GetOwner ());
	global AccountDirectory auth = GetAccountDirectory ();
	String credential = auth->GetCredential (sender, receiver, nonce);
	String s []
	  = Seperate (Decrypt (credential, Where ()->GetPassword ()), ',', 7);
	global SessionID session_id
	  = narrow (SessionID,s [CredentialStructure::aSessionID]->Str2OID ());
	String session_key = s [CredentialStructure::SessionKey];
	String expiration_time
	  = s [CredentialStructure::ExpirationTime]->AtoI ();
	String for_receiver = s [CredentialStructure::ReceiverData];

	if (s [CredentialStructure::SenderName]->IsNotEqualTo (sender)
	    || s [CredentialStructure::Nonce]->IsNotEqualTo (nonce)) {
	    raise AuthenticationExceptions::FakeAuthenticationServer (auth);
	} else {
	    if (o->Authenticate (for_receiver)->IsNotEqualTo (session_id)) {
		raise AuthenticationExceptions::FakePeer (o);
	    } else {
		Session session=>New (session_id, session_key,
				      receiver, expiration_time);

		SessionTable->Add (session_id, session);
		return session_id;
	    }
	}
    }

    int OutOfDate (Date date) {
	Date current=>Current ();

	return
	  current->Difference (date)->SetSign (1)->Compare(OutofDateLimit) > 0;
    }

    String Seperate (String data, char delimiter, int parts)[] {
	unsigned int i, s, n;
	char c;
	String result [];

	length result = parts;
	n = 0;

	if (parts == 1) {
	    result [n ++] = data;
	} else {
	    for (i = 0, s = 0; (c = data->At (i)) != 0; i ++) {
		if (c == delimiter) {
		    result [n ++] = data->GetSubString (s, i - s);
		    s = i + 1;
		    if (n + 1 == parts) {
			break;
		    }
		}
	    }
	    result [n ++] = data->GetSubString (s, 0);
	}
	if (n < parts) {
	    length result = n;
	}
	return result;
    }
}
