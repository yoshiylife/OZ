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
 * ozcgi.oz
 *
 * OZ++ CGI
 */

class OZCGI : ResolvableObject (alias New SuperNew;) {
  constructor: New;
  public: GetRequest, IsReady, PutResult;
  protected: EventLoop, SendResult, UnderConstruction;

/* instance variables */
    SimpleStringTable <WaitingNumber> DaemonTable;
    SimpleStringTable <FIFO <HTMLMessage>> RequestTable;
    SimpleTable <int, String> ResultTable;
    condition RandezvouPoint [][];
    int InUse [][];
    int RandezvouPointer;
    int RandezvouBlockSize;
    int Active;
    String Key;
    UnixDomainStreamSocket Socket;

/* method implementations */
    void New () : global {
	SuperNew ();
	AddName (OZCGIConstants::CGIName);
	Key=>NewFromArrayOfChar (OZCGIConstants::KeyforFormName);
	Go ();
    }

    void Go () : global {
	DaemonTable=>New ();
	RequestTable=>New ();
	RandezvouBlockSize = 128;
	length RandezvouPoint = 1;
	length InUse = 1;
	length RandezvouPoint [0] = RandezvouBlockSize;
	length InUse [0] = RandezvouBlockSize;
	RandezvouPointer = 0;
	ResultTable=>NewWithSize (8);

	ListenPort ();
	RegisterToNameDirectory ();
	detach fork EventLoop ();
    }

    void Removing () : global {
	String path;
	FileOperators fops;

	Active = 0;
	UnRegisterFromNameDirectory ();
	Socket->Close ();
	path=>NewFromArrayOfChar (OZCGIConstants::PathName);
	fops.Remove (path);
	FlushRequestTable ();
	FlushDaemonTable ();
    }

    void Stop () : global {
	Removing ();
	length RandezvouPoint = 0;
	length InUse = 0;
	ResultTable = 0;
    }

    void EventLoop () {
	Active = 1;
	try {
	    while (1) {
		try {
		    ConnectedStreamSocket s = Socket->Accept ();
		    char str [] = s->Receive ();
		    HTMLMessage message=>NewFromArrayOfChar (str);
		    int p = NewRequest (message);

		    if (p >= 0) {
			detach fork SendResult (s, p);
		    } else {
			detach fork UnderConstruction (s);
		    }
		} except {
		    default {
			if (Active) {
			    Socket->Close ();
			    ListenPort ();
			} else {
			    return;
			}
		    }
		}
	    }
	} except {
	    default {
		Active = 0;
	    }
	}
    }

    void FlushDaemonTable () : locked {
	int i, capa = DaemonTable->Capacity ();

	for (i = 0; i < capa; i ++) {
	    String form = DaemonTable->KeyAt (i);

	    if (form != 0) {
		signalall
		  Randezvou (DaemonTable->AtKey (form)->RandezvouPoint ());
	    }
	}
	DaemonTable = 0;
	RequestTable = 0;
    }

    void FlushRequestTable () : locked {
	int i, p, capa = RequestTable->Capacity ();
	String key=>NewFromArrayOfChar (OZCGIConstants::KeyforRequestID);
	String sorry;
	char s [];

	length s = 140;
	inline "C" {
	    OzStrcpy (OZ_ArrayElement (s, char),
"<head><title>Server Shutdown</title></head>\n"
"<body>\n"
"We are very sorry for that the server is going to shutdown...\n"
"</body>\n"
		      );
	}
	sorry=>NewFromArrayOfChar (s);
	for (i = 0; i < capa; i ++) {
	    String form = RequestTable->KeyAt (i);
	    FIFO <HTMLMessage> queue = RequestTable->AtKey (form);
	    while (! queue->IsEmpty ()) {
		HTMLMessage m = queue->Get ();
		int rp = m->AtKey (key)->RemoveAny ()->AtoI ();

		ResultTable->Add (rp, sorry);
		signal Randezvou (rp);
		NotInUse (rp);
	    }
	}
    }

    int GetRandezvouPoint () {
	int first = RandezvouPointer;
	int p = first;
	int size = length RandezvouPoint * RandezvouBlockSize;

	do {
	    if (! InUse [p / RandezvouBlockSize][p % RandezvouBlockSize]) {
		InUse [p / RandezvouBlockSize][p % RandezvouBlockSize] = 1;
		RandezvouPointer = p;
		return p;
	    }
	    p ++;
	    if (p == size) {
		p = 0;
	    }
	} while (p != first);
	length RandezvouPoint += 1;
	length InUse += 1;
	length RandezvouPoint [length RandezvouPoint - 1] = RandezvouBlockSize;
	length InUse [length InUse - 1] = RandezvouBlockSize;
	RandezvouPointer = size;
	return size;
    }

    HTMLMessage GetRequest (String form_name) : locked, global {
	FIFO <HTMLMessage> queue;
	HTMLMessage request;
	int p;

	while (1) {
	    int res;

	    try {
		res = RequestTable->IncludesKey (form_name);
	    } except {
		IllegalInvoke {
		    return 0;
		}
	    }

	    if (res) {
		break;
	    } else {
		WaitingNumber wn;

		if (DaemonTable->IncludesKey (form_name)) {
		    wn = DaemonTable->AtKey (form_name);
		    p = wn->RandezvouPoint ();
		    wn->Increment ();
		} else {
		    p = GetRandezvouPoint ();
		    wn=>New (p);
		    DaemonTable->Add (form_name, wn);
		}
		wait Randezvou (p);
	    }
	}

	queue = RequestTable->AtKey (form_name);
	request = queue->Get ();
	if (queue->IsEmpty ()) {
	    RequestTable->RemoveKey (form_name);
	} else {
	    signal Randezvou (p);
	    NotInUse (p);
	}
	return request;
    }

    int IsReady () : global {return Active;}

    void ListenPort () {
	Socket=>New (OZCGIConstants::PathName);
	try {
	    try {
		Socket->Bind ();
	    } except {
	      SocketExceptions::CantBindSocket (name) {
		  FileOperators fops;
		  String path=>NewFromArrayOfChar (name);

		  try {
		      fops.Remove (path);
		      Socket->Bind ();
		  } except {
		    FileExceptions::CommandFailed (com) {
			raise SocketExceptions::CantBindSocket (name);
		    }
		  }
	      }
	    }
	    Socket->Listen (5);
	} except {
	    default {
		Socket->Close ();
		raise;
	    }
	}
    }

    int NewRequest (HTMLMessage message) : locked {
	String form_name;

	if (message->IncludesKey (Key)) {
	    int rp = GetRandezvouPoint ();
	    ArrayOfCharOperators acops;
	    String key=>NewFromArrayOfChar (OZCGIConstants::KeyforRequestID);
	    String value=>NewFromArrayOfChar (acops.ItoA (rp));
	    FIFO <HTMLMessage> queue;

	    form_name = message->AtKey (Key)->RemoveAny ();
	    message->Add (key, value);
	    if (RequestTable->IncludesKey (form_name)) {
		queue = RequestTable->AtKey (form_name);
	    } else {
		queue=>New ();
		RequestTable->Add (form_name, queue);
	    }
	    queue->Put (message);
	    if (DaemonTable->IncludesKey (form_name)) {
		WaitingNumber wn = DaemonTable->AtKey (form_name);
		int p = wn->RandezvouPoint ();

		signal Randezvou (p);
		NotInUse (p);
		if (wn->Decrement () == 0) {
		    DaemonTable->RemoveKey (form_name);
		}
	    }
	    return rp;
	} else {
	    return -1;
	}
    }

    void NotInUse (int p) {
	InUse [p / RandezvouBlockSize][p % RandezvouBlockSize] = 0;
    }

    void PutResult (int p, String result) : locked, global {
/*
	ResultTable->Add (p, RestoreOctal (result));
*/
	ResultTable->Add (p, result);
	signal Randezvou (p);
	NotInUse (p);
    }

    condition Randezvou (int p) {
	return RandezvouPoint [p / RandezvouBlockSize][p % RandezvouBlockSize];
    }

    void SendResult (ConnectedStreamSocket socket, int p) : locked {
	String result;

	if (! ResultTable->IncludesKey (p)) {
	    wait Randezvou (p);
	}
	result = ResultTable->RemoveKey (p);


	{
	    char s [];

	    if (result->Length () > 1000) {
		s = result->GetSubString (0, 1000)->Content ();
	    } else {
		s = result->Content ();
	    }
	    inline "C" {
		OzDebugf ("OZCGI::SendResult: sending [%S].\n", s);
	    }
	}


	socket->Send (result->Content ());
	socket->Close ();


	{
	    inline "C" {
		OzDebugf ("OZCGI::SendResult: connection closed.\n");
	    }
	}


    }

    void UnderConstruction (ConnectedStreamSocket socket) {
	char sorry [];

	length sorry = 150;
	inline "C" {
	    OzStrcpy (OZ_ArrayElement (sorry, char),
"<head><title>Under construction</title><head>\n"
"<body>\n"
"We are very sorry for that this page is under construction.\n"
"</body>\n"
		  );
	}
	socket->Send (sorry);
	socket->Close ();
    }

  String RestoreOctal (String result)
    {
      char orig[], conv[];
      int i, j, len;
      char c1, c2;
      String converted;

      orig = result->Content ();
      len = length orig;
      length conv = len;

      for (i = 0, j = 0; i < len; i++)
	{
	  if (orig[i] == '%')
	    {
	      c1 = orig[++i];
	      c2 = orig[++i];

	      c1 = c1 >= 'A' ? c1 - 'A' + 10 : c1 - '0';
	      c2 = c2 >= 'A' ? c2 - 'A' + 10 : c2 - '0';
	      conv[j++] = ((c1 << 4) & 0xf0) | (c2 & 0x0f);
	    }
	  else
	    conv[j++] = orig[i];
	}

      length conv = j;

      converted=>NewFromArrayOfChar (conv);
      return converted;
    }
}
