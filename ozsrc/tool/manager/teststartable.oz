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
 * teststartable.oz
 *
 * TestStartable
 */

class TestStartable
  : Startable,
    CommandInterpreter(alias Initialize SuperInitialize;
		       alias SetCommandHash SuperSetCommandHash;
		       alias SetHelpMessages SuperSetHelpMessages;
		       alias SetOneLineHelp SuperSetOneLineHelp;)
{
/* Startable Staff */
  public: Go, Removing, Stop, Where;
  protected: Flush;

/* CommandInterpreter Staff */
  protected: Initialize, Launch;

/* instance variables */

/* method implementations */
    void Initialize(): global {
	SuperInitialize();
	Go();
    }

    void Go(): global {
	Launch();
    }

    void Stop(): global {


	inline "C" {
	    _oz_debug_flag = 1;
	}


	debug(0, "TestStartable::Stop: called\n");
    }

    void Dispatch(OrderedCollection <String> argv) {
	String f = argv->First();

	if (CommandHash->IncludesKey(f)) {
	    switch (CommandHash->AtKey(f)) {
	      case CommandInterpreterCommands::NOP: NOP(argv); break;
	      case CommandInterpreterCommands::Help: Help(argv); break;
	      case CommandInterpreterCommands::Alias: Alias(argv); break;
	      case CommandInterpreterCommands::Unalias: Unalias(argv); break;
	      case CommandInterpreterCommands::SetVar: SetVar(argv); break;
	      case CommandInterpreterCommands::Show: Show(argv); break;
	      case CommandInterpreterCommands::Quit: Quit(argv); break;

	      case TestStartableCommands::List: List(argv); break;
	      case TestStartableCommands::Keep: Keep(argv); break;
	      case TestStartableCommands::Unkeep: Unkeep(argv); break;
	    }
	} else {
	    TypeStr("Unknown command ");
	    TypeString(f);
	    TypeStr(".\n");
	}
    }

    void SetCommandHash () {
	SuperSetCommandHash();

	/* class table */
	AddCommand("list", TestStartableCommands::List);
	AddCommand("keep", TestStartableCommands::Keep);
	AddCommand("unkeep", TestStartableCommands::Unkeep);
    }

    void SetHelpMessages() {
	SuperSetHelpMessages();

	AddHelp("list",
		"list [<directory>]\n\n"
		"list shows listings of contents of the specified "
		"<directory>.");

	AddHelp("keep",
		"keep\n\n"
		"keep permanentizes this global object.");

	AddHelp("unkeep",
		"unkeep\n\n"
		"unkeep transientize this global object.");
    }

    void SetOneLineHelp() {
	SuperSetOneLineHelp();

	AddOneLineHelp("list", "Shows listings of the specified directory.");
	AddOneLineHelp("keep", "Permanentizes this global object.");
	AddOneLineHelp("unkeep", "Transientizes this global object.");
    }

    void SetInitialPrompt () {
	Prompt=>NewFromArrayOfChar ("TestStartable> ");
    }

    String Title() {
	String title=>NewFromArrayOfChar("Class Object Service Interface");

	return title;
    }

/* command implementations */
    void List(OrderedCollection<String> argv) {
	FileOperators file;
	char path[];

	CheckArgSize(argv->Size(), 2, 2);
	argv->RemoveFirst();
	try {
	    char list[][] = file.List(argv->RemoveFirst());
	    unsigned int max_rows = GetVariable ("Rows")->AtoI ();
	    unsigned int max_columns = GetVariable ("Columns")->AtoI ();
	    unsigned int i, len = length list, col = 0, row = 0;
	    unsigned int maxlen = 0;
	    String blanks;
	    char blankbuf[];

	    for (i = 0; i < len; i ++) {
		if (maxlen < length list[i]) {
		    maxlen = length list[i];
		}
	    }
	    length blankbuf = maxlen + 1;
	    for (i = 0; i < maxlen; i ++) {
		blankbuf[i] = ' ';
	    }
	    blankbuf[i] = '\0';
	    blanks=>NewFromArrayOfChar(blankbuf);

	    for (i = 0; i < len; i ++) {
		TypeStr(list[i]);
		col += maxlen + 1;
		if (col + maxlen + 1 > max_columns) {
		    TypeStr("\n");
		    col = 0;
		    row ++;
		    if ((row + 1) % (max_rows - 1) == 0) {
			if (BreakScroll()) {
			    break;
			}
		    }
		} else {
		    TypeString(
		       blanks->GetSubString(0, maxlen - length list[i] + 1));
		}
	    }
	    if (col > 0) {
		TypeReturn();
	    }
	} except {
	  FileExceptions::CannotOpenDirectory(path) {
	      TypeStr(path);
	      TypeStr(": Cannot open directory.\n");
	  }
	    default {
		TypeStr("Command failed.\n");
	    }
	}
    }

    void Keep(OrderedCollection<String> argv) {
	CheckArgSize(argv->Size(), 1, 1);
	argv->RemoveFirst();
	Where()->PermanentizeObject(cell);
    }

    void Unkeep(OrderedCollection<String> argv) {
	CheckArgSize(argv->Size(), 1, 1);
	argv->RemoveFirst();
	Where()->TransientizeObject(cell);
    }
}
