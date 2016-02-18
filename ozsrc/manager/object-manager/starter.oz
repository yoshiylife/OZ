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
 * starter.oz
 *
 * Starter
 *
 * Start an user application.
 */

class Starter {
  constructor: New;
  public: GetConfiguredClassID, Start, Shutdown;

/* instance variables */
    global Startable Application;
    Console Dialog;

/* method implementations */
    void New() {
	Application = 0;
    }

    void Start() {
	String configurationFileName;

	Dialog=>NewWithTitle(Title());
	Dialog->Open();
	configurationFileName = ReadConfigurationFileName(Dialog);
	if (configurationFileName != 0) {
	    ConsultConfigurationFile(configurationFileName);
	}
	if (Application == 0 || Where()->LookupObject(Application) == 0) {
	    Application = 0;
	    Application = CreateApplication(Dialog);
	    Application->Initialize();
	} else {
	    Where()->LoadObject(Application);
	}
    }

    String ReadConfigurationFileName(Console dialog) {
	String message=>NewFromArrayOfChar("Configuration File [none]: ");
	String path;
	FileOperators fops;

	while (1) {
	    dialog->Write(message);
	    path = dialog->Read();
	    path = Trim(path);
	    if (path->Length() == 0) {
		return 0;
	    } else if (fops.IsExists(path)) {
		return path;
	    }
	}
    }

    int IsWhite(char c) {
	return c == ' ' || c == '\t' || c == '\n' || c == '\0';
    }

    int LastLetter(char line[], unsigned int i) {
	for (; --i >= 0;) {
	    if (! IsWhite(line[i])) {
		return i;
	    }
	}
	return -1;
    }

    int IsHexaDigit(char c) {
	return
	  (c >= '0' && c <= '9')
	    || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
    }

    global Object MakeOID(char line[], int p) {
	ArrayOfCharOperators acops;
	unsigned int i;
	char buf[];

	length buf = 17;
	buf[16] = '\0';
	if (p < 0 || length line <= p + 16) {
	    return 0;
	}
	for (i = 0; i < 16; i ++) {
	    buf[i] = line[p + i];
	}
	return acops.Str2OID(buf);
    }

    void Error(unsigned int counter, char line[]) {
	ArrayOfCharOperators acops;
	String message;
	message=>NewFromArrayOfChar("Configuration file syntax error, line ");
	message = message->ConcatenateWithArrayOfChar(acops.ItoA(counter));
	message = message->ConcatenateWithArrayOfChar("\n");
	message = message->ConcatenateWithArrayOfChar(line);
	message = message->ConcatenateWithArrayOfChar("\n");
	Dialog->Write(message);
    }

    String ConsultConfigurationFile(String configurationFileName) {
	unsigned int counter = 0;
	char ccidbuf[], pubidbuf[];
	Stream stream=>New(configurationFileName);
	length ccidbuf = 17;
	ccidbuf[16] = '\0';
	length pubidbuf = 17;
	pubidbuf[16] = '\0';
	while (! stream->IsEndOfFile()) {
	    String l=>NewFromArrayOfChar(stream->GetS());
	    char line[] = Trim(l)->Content();
	    unsigned int len = length line;
	    counter++;
	    if (length line > 0) {
		char first = line[0];
		if (first != '\n' && first != '#') {
		    int i = LastLetter(line, len) - 15;
		    global ConfiguredClassID ccid
		      = narrow(ConfiguredClassID, MakeOID(line, i));
		    if (ccid == 0) {
			Error(counter, line);
		    } else {
			global VersionID pubid
			  = narrow(VersionID,
				   MakeOID(line, LastLetter(line, i) - 15));
			if (pubid == 0) {
			    Error(counter, line);
			} else {
			    Where()->AddBootConfiguration(pubid, ccid);
			}
		    }
		}
	    }
	}
    }

    global Startable CreateApplication(Console dialog) {
	/*
	 * 本当は、クラスの名前で指定できた方がいいのですが、
	 * 時間がないので、 public part ID を使います。
	 * クラス名を指定させる場合は、
	 * コンフィギュレーションファイルを参照させるといいでしょう。
	 */
	global ConfiguredClassID ccid;

	try {
	    ccid = GetClassID(dialog);
	    return narrow(Startable, Where()->NewObject(ccid, 0));
	} except {
	    default {
		/* any exception is neglected */
		String message=>NewFromArrayOfChar("An exception is raised "
						   "while creating an "
						   "application object\n");
		Dialog->Write(message);
		return 0;
	    }
	}
    }

    global ConfiguredClassID GetClassID(Console dialog) {
	String message=>NewFromArrayOfChar("Configured Class ID: ");
	global Object answer = ReadOID(dialog, message);
	return narrow(ConfiguredClassID, answer);
    }

    global Object ReadOID(Console dialog, String prompt) {
	String message=>NewFromArrayOfChar("Enter in 16 hexa-decimal "
					   "digits([0-9a-fA-F]).\n\n");
	String s;
	unsigned int i, len;
	global Object o = 0;
	unsigned long l = 0;

	while (1) {
	    dialog->Write(prompt);
	    s = dialog->Read();
	    s = Trim(s);
	    o = s->Str2OID();
	    if (o == 0) {
		dialog->Write(message);
	    } else {
		break;
	    }
	}
	return o;
    }

    String Trim(String s) {
	unsigned int i, b, e, len = s->Length();


	for (i = 0, b = 0; i < len; i ++) {
	    if (! IsWhite(s->At(i))) {
		b = i;
		break;
	    }
	}
	if (i == len) {
	    String st=>NewFromArrayOfChar("");
	    return st;
	}
	for (i = len, e = len; --i >= 0; ) {
	    if (! IsWhite(s->At(i))) {
		e = i;
		break;
	    }
	}
	return s->GetSubString(b, e - b + 1);
    }

    global ConfiguredClassID GetConfiguredClassID(global VersionID vid) {
	String vidstr=>OIDtoHexa(vid);
	String message, answer;
	global ConfiguredClassID ccid = 0;

	message=>NewFromArrayOfChar("Configured Class ID for ");
	message = message->Concatenate(vidstr);
	message = message->ConcatenateWithArrayOfChar(": ");
	while (ccid == 0) {
	    Dialog->Write(message);
	    answer = Dialog->Read();
	    answer = Trim(answer);
	    ccid = narrow(ConfiguredClassID, answer->Str2OID());
	}
	return ccid;
    }

    String Title() {
	String title=>NewFromArrayOfChar("Application Starter");
	return title;
    }

    void Shutdown() {
	Dialog->Close();
    }
}
