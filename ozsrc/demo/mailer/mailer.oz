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
 * mailer.oz
 *
 * Mailer - mail sender and receiver
 * Mailer sends a mail by forking SMTP agent (/usr/lib/sendmail) and
 * receives mails by forking telnet to talk with POP server.
 */

class Mailer {
  constructor: New;
  public: ChangeSMTPAgent, ChangePOPServer, Send, Receive;

    String SMTPAgent;
    String POPServer;
    char Buffer [];
    unsigned int BufferStart, BufferEnd;

/* method implementations */
    void New () {
	SMTPAgent=>NewFromArrayOfChar ("/usr/lib/sendmail");
	POPServer=>NewFromArrayOfChar ("localhost");
	length Buffer = 256;
	Buffer [0] = '\0';
    }

    void ChangeSMTPAgent (String smtp_agent) {
	SMTPAgent = smtp_agent;
    }

    void ChangePOPServer (String pop_server) {
	POPServer = pop_server;
    }

    void SendCommand (UnixIO telnet, char command [], String arg) {
	String com=>NewFromArrayOfChar (command);

	if (arg != 0) {
	    com = com->ConcatenateWithArrayOfChar (" ");
	    com = com->Concatenate (arg);
	}
	com = com->ConcatenateWithArrayOfChar ("\n");
	telnet->PutString (com);



    }

    int SearchChar (char c) {
	unsigned int i;

	for (i = BufferStart; i < BufferEnd; i ++) {
	    if (Buffer [i] == c) {
		return i;
	    }
	}
	return -1;
    }

    void PutToBuffer (char s []) {
	ArrayOfCharOperators acops;
	unsigned int i, len = acops.Length (s);

	if (BufferEnd + len >= length Buffer) {
	    length Buffer += len + 256;
	}
	for (i = 0; i < len; i ++) {
	    Buffer [BufferEnd ++] = s [i];
	}
	Buffer [BufferEnd] = '\0';
    }

    String CutString (int pos) {
	char s [];
	char buffer [] = Buffer;
	char c;
	unsigned int i, start = BufferStart;
	String result;




	length s = pos - BufferStart + 1;
	c = Buffer [pos];
	Buffer [pos] = '\0';
	inline "C" {
	    OzStrcpy (OZ_ArrayElement (s, char),
		      OZ_ArrayElement (buffer, char) + start);
	}
	BufferStart = pos;
	Buffer [pos] = c;
	if (BufferEnd == BufferStart) {
	    BufferStart = BufferEnd = 0;
	    Buffer [0] = '\0';
	}
	return result=>NewFromArrayOfChar (s);
    }

    String ReadUntillNewLine (UnixIO telnet) {
	int pos;
	char answer [];

	while ((pos = SearchChar ('\n')) == -1) {
	    answer = telnet->Read (256);



	    if (answer != 0) {
		PutToBuffer (answer);
	    } else {
		inline "C" {
		    OzSleep (1);
		}
	    }
	}
	return CutString (pos + 1);
    }

    int IsOK (String answer) {
	return answer->NCompareToArrayOfChar ("+OK", 3) == 0;
    }

    void SkipHello (UnixIO telnet) {
	String answer;




	do {
	    answer = ReadUntillNewLine (telnet);
	} while (! IsOK (answer));
    }

    void SetUser (UnixIO telnet, String user) {
	String answer;




	SendCommand (telnet, "USER", user);
	answer = ReadUntillNewLine (telnet);
	if (! IsOK (answer)) {
	    raise MailerExceptions::UnknownUser (answer);
	}
    }

    void SetPassword (UnixIO telnet, String password) {
	String answer;




	SendCommand (telnet, "PASS", password);
	answer = ReadUntillNewLine (telnet);
	if (! IsOK (answer)) {
	    raise MailerExceptions::IncorrectPassword (answer);
	}
    }

    String ListMessages (UnixIO telnet)[] {
	String answer;
	unsigned int i, amount;
	String id [];




	SendCommand (telnet, "LIST", 0);
	answer = ReadUntillNewLine (telnet);
	if (! IsOK (answer)) {
	    raise MailerExceptions::UnknownPOPError (answer);
	}
	amount = answer->GetSubString (4, 0)->AtoI ();
	length id = amount;
	for (i = 0; i < amount; i ++) {
	    unsigned int delimiter;

	    answer = ReadUntillNewLine (telnet);
	    delimiter = answer->StrChr (' ');
	    id [i] = answer->GetSubString (0, delimiter);
	}
	answer = ReadUntillNewLine (telnet);
	if (answer->CompareToArrayOfChar (".\n") != 0) {
	    raise MailerExceptions::UnknownPOPError (answer);
	}
	return id;
    }

    String ReadUntillFullStop (UnixIO telnet, unsigned int size) {
	String result=>NewFromArrayOfChar ("");
	String line;

	do {
	    line = ReadUntillNewLine (telnet);



	    result = result->Concatenate (line);
	} while (line->CompareToArrayOfChar (".\n") != 0);
	return result;
    }

    String RetrieveMessages (UnixIO telnet, String id [])[] {
	String retr=>NewFromArrayOfChar ("RETR ");
	String dele=>NewFromArrayOfChar ("DELE ");
	String answer;
	String result [];
	unsigned int i, size, len = length id;




	length result = len;
	for (i = 0; i < len; i ++) {
	    SendCommand (telnet, "RETR", id [i]);
	    answer = ReadUntillNewLine (telnet);
	    if (! IsOK (answer)) {
		raise MailerExceptions::UnknownPOPError (answer);
	    }
	    size = answer->GetSubString (4, 0)->AtoI ();
	    result [i] = ReadUntillFullStop (telnet, size);
	    SendCommand (telnet, "DELE", id [i]);
	    answer = ReadUntillNewLine (telnet);
	    if (! IsOK (answer)) {
		raise MailerExceptions::UnknownPOPError (answer);
	    }
	}
	SendCommand (telnet, "QUIT", 0);
	return result;
    }

    String Receive (String user, String password)[] : locked {
	char args [][];
	UnixIO telnet;
	String id [];
	String result [];

	length args = 3;
	args [0] = "telnet";
	args [1] = POPServer->Content ();
	args [2] = "pop";

	telnet=>Spawn (args);
	try {
	    SkipHello (telnet);
	    SetUser (telnet, user);
	    SetPassword (telnet, password);
	    id = ListMessages (telnet);
	    result = RetrieveMessages (telnet, id);
	} except {
	    default {
		telnet->Close ();
		raise;
	    }
	}
	telnet->Close ();
	return result;
    }

    void Send (String contents) : locked {
	char args [][];
	UnixIO sendmail;

	length args = 2;
	args [0] = SMTPAgent->Content ();
	args [1] = "-t";
	sendmail=>Spawn (args);
	sendmail->PutString (contents);
	sendmail->PutStr ("\n.\n");
	sendmail->Close ();
    }
}
