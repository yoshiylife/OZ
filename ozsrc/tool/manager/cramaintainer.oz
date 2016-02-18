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
 * cramaintener.oz
 *
 * Class request agent maintenance tool
 */

class ClassRequestAgentMaintainer :
  CommandInterpreter (alias Initialize SuperInitialize;
		      alias SetCommandHash SuperSetCommandHash;
		      alias SetHelpMessages SuperSetHelpMessages;
		      alias SetOneLineHelp SuperSetOneLineHelp;)
{
  constructor: New;
  public: Launch;

  protected: IsReady;


/* instance variables */
    global ClassRequestAgent aClassRequestAgent;
    String ClassRequestAgentName;
    int Status;
    char Mode;

/* method implementations */
    void Initialize () {
	SuperInitialize ();
	ClassRequestAgentName
	  =>NewFromArrayOfChar (ClassRequestAgentConstants::Name);
	SetStatus ();
	Mode = 's';    /* s for SList; d for DList */
    }

    void Dispatch (OrderedCollection <String> argv) {
	String f = argv->First ();

	if (CommandHash->IncludesKey (f)) {
	    switch (CommandHash->AtKey (f)) {
	      case CommandInterpreterCommands::NOP: NOP (argv); break;
	      case CommandInterpreterCommands::Help: Help (argv); break;
	      case CommandInterpreterCommands::Alias: Alias (argv); break;
	      case CommandInterpreterCommands::Unalias: Unalias (argv); break;
	      case CommandInterpreterCommands::SetVar: SetVar (argv); break;
	      case CommandInterpreterCommands::Show: Show (argv); break;
	      case CommandInterpreterCommands::Quit: Quit (argv); break;

	      case ClassRequestAgentCommands::Add: Add (argv); break;
	      case ClassRequestAgentCommands::Append: Append (argv); break;
	      case ClassRequestAgentCommands::Clear: Clear (argv); break;
	      case ClassRequestAgentCommands::Disable: Disable (argv); break;
	      case ClassRequestAgentCommands::DList:
		ChangeMode (argv, 'd'); break;
	      case ClassRequestAgentCommands::Dump: Dump (argv); break;
	      case ClassRequestAgentCommands::Enable: Enable (argv); break;
	      case ClassRequestAgentCommands::Insert: Insert (argv); break;
	      case ClassRequestAgentCommands::Kill: Kill (argv); break;
	      case ClassRequestAgentCommands::List: List (argv); break;
	      case ClassRequestAgentCommands::New: NewOne (argv); break;
	      case ClassRequestAgentCommands::Read: ReadSetupFile (argv);break;
	      case ClassRequestAgentCommands::Remove: Remove (argv); break;
	      case ClassRequestAgentCommands::SList:
		ChangeMode (argv, 's'); break;
	      case ClassRequestAgentCommands::Status: GetStatus (argv); break;
	    }
	} else {
	    TypeStr ("Unknown command ");
	    TypeString (f);
	    TypeStr (".\n");
	}
    }

    void SetCommandHash () {
	SuperSetCommandHash ();

	/* class request agent maintenance */
	AddCommand ("add", ClassRequestAgentCommands::Add);
	AddCommand ("append", ClassRequestAgentCommands::Append);
	AddCommand ("clear", ClassRequestAgentCommands::Clear);
	AddCommand ("dlist", ClassRequestAgentCommands::DList);
	AddCommand ("disable", ClassRequestAgentCommands::Disable);
	AddCommand ("dump", ClassRequestAgentCommands::Dump);
	AddCommand ("enable", ClassRequestAgentCommands::Enable);
	AddCommand ("insert", ClassRequestAgentCommands::Insert);
	AddCommand ("kill", ClassRequestAgentCommands::Kill);
	AddCommand ("list", ClassRequestAgentCommands::List);
	AddCommand ("new", ClassRequestAgentCommands::New);
	AddCommand ("read", ClassRequestAgentCommands::Read);
	AddCommand ("remove", ClassRequestAgentCommands::Remove);
	AddCommand ("slist", ClassRequestAgentCommands::SList);
	AddCommand ("status", ClassRequestAgentCommands::Status);
    }

    void SetHelpMessages () {
	SuperSetHelpMessages ();

	AddHelp ("add",
		 "add n name1 name2 ...\n\n"
		 "add adds objects listed in the arguments to the n-th set of "
		 "the current list.  The current list is either DList or "
		 "SList according to the list mode.  Each argument name " 
		 "must be a name of a class request agent in SList mode, "
		 "otherwise (i.e., in DList mode) a name of another class " 
		 "object.");

	AddHelp ("append",
		 "append name1 name2 ...\n\n"
		 "append appends a set of objects listed in the arguments to "
		 "the current list.  The objects in the set will be searched "
		 "in parallel.  The current list is either DList or SList "
		 "according to the list mode.  Each argument name must be a "
		 "name of a class request agent in SList mode, otherwise "
		 "(i.e., in DList mode) a name of another class object."); 

	AddHelp ("clear",
		 "clear\n\n"
		 "clear makes the current list empty.  The current list is "
		 "either DList or SList according to the list mode.");

	AddHelp ("disable",
		 "disable\n\n"
		 "disable disables the running class request agent.");

	AddHelp ("dlist",
		 "dlist\n\n"
		 "dlist changes the current list to DList.");

	AddHelp ("dump",
		 "dump <FileName>\n\n"
		 "dump dumps the contents of the class request agent to a "
		 "file in setup file format:\n\n"
		 "        <setup-file> ::= <dlist> <slist>\n"
		 "        <dlist>      ::= 'dlist' <record>* ';'\n"
		 "        <slist>      ::= 'slist' <record>* ';'\n"
		 "        <record>     ::= '[' <name>* ']'\n\n"
		 "<name> must be a name resolvable by the NameDirectory.  "
		 "Following is an example of a setfile:\n\n"
		 "        dlist [ ::ipa.go.jp:class-request-agent ]\n"
		 "        slist [ ::stu.edu:classes:site-master\n"
		 "                ::vwwu.edu:classes:export ]\n"
		 "              [ ::asw-c.com:classes:export ]\n\n"
		 "Continuous blanks, tabs and new lines are interpreted as a "
		 "single blank."); 

	AddHelp ("enable",
		 "enable\n\n"
		 "enable enables the class request agent.");

	AddHelp ("insert",
		 "insert n name1 name2 ...\n"
		 "insert inserts a set of objects listed in the arguments "
		 "in n-th position in the current list.  The current list is "
		 "either DList or SList according to the list mode.  Each "
		 "argument name must be a name of a class request agent in "
		 "SList mode, otherwise (i.e., in DList mode) a name of "
		 "another class object.");

	AddHelp ("kill",
		 "kill\n\n"
		 "kill removes the class request agent.  A killed class "
		 "request agent is permanently lost.");

	AddHelp ("list",
		 "list\n\n"
		 "list shows contents of the current list.  The current list "
		 "is either DList or SList according to the list mode.  Each "
		 "argument name must be a name of a class request agent in "
		 "SList mode, otherwise (i.e., in DList mode) a name of "
		 "another class object.");

	AddHelp ("new",
		 "new om\n\n"
		 "new creates a class request agent at the executor managed "
		 "by an ObjectManager om.  om must be a name of an "
		 "ObjectManager or an object ID.  If another class request "
		 "agent is accessible, an error will be reported."); 

	AddHelp ("read",
		 "read <SetupFileName>\n\n"
		 "read gives the file <SetupFileName> to the class request "
		 "agent to set DList and SList.  The file format of the setup "
		 "file is as following:\n\n" 
		 "        <setup-file> ::= <dlist> <slist>\n"
		 "        <dlist>      ::= 'dlist' <record>* ';'\n"
		 "        <slist>      ::= 'slist' <record>* ';'\n"
		 "        <record>     ::= '[' <name>* ']'\n\n"
		 "<name> must be a name resolvable by the NameDirectory.  "
		 "Following is an example of a the setup-file:\n\n"
		 "        dlist [ ::ipa.go.jp:class-request-agent ]\n"
		 "        slist [ ::stu.edu:classes:site-master\n"
		 "                ::vwwu.edu:classes:export ]\n"
		 "              [ ::asw-c.com:classes:export ]\n\n"
		 "Continuous blanks, tabs and new lines are interpreted as a "
		 "single blank."); 

	AddHelp ("remove",
		 "remove n\n\n"
		 "remove removes the n-th set of objects in the current "
		 "list.  The current list is either DList or SList according "
		 "to the list mode."); 

	AddHelp ("slist",
		 "slist\n\n"
		 "slist changes the current list to SList.");

	AddHelp ("status",
		 "status\n\n"
		 "status shows the status of the class request agent.\n\n"
		 "  Not exist ... No class request agent is found in the "
		 "NameDirectory of this domain.\n"
		 "  Down      ... A class request agent is found in the "
		 "NameDirectory of\n"
		 "                this domain, but isn't accessible.\n"
		 "  Disabled  ... A class request agent is accessible but "
		 "disabled.\n"
		 "  Enabled   ... A class request agent is accessible and "
		 "enabled.");
    }

    void SetInitialPrompt () {
	SetStatus ();
	MakePrompt (Mode);
    }

    void SetOneLineHelp () {
	SuperSetOneLineHelp ();
	AddOneLineHelp ("add", "Add objects to DList or SList.");
	AddOneLineHelp ("append",
			"Append a set of objects to DList or SList.");
	AddOneLineHelp ("clear", "Empty DList orSList.");
	AddOneLineHelp ("disable", "Disable the class request agent.");
	AddOneLineHelp ("dlist", "Change to DList mode.");
	AddOneLineHelp ("dump", "Dump the contents to a file.");
	AddOneLineHelp ("enable", "Enable the class request agant.");
	AddOneLineHelp ("insert",
			"Insert a set of objects to DList or SList.");
	AddOneLineHelp ("kill", "Kill the class request agent.");
	AddOneLineHelp ("list", "List DList or SList.");
	AddOneLineHelp ("new", "Create a class request agent.");
	AddOneLineHelp ("read", "Initialize with a setup file.");
	AddOneLineHelp ("remove",
			"Remove a set of objects from DList or SList.");
	AddOneLineHelp ("slist", "Change to SList mode.");
	AddOneLineHelp ("status", "Report status.");
    }

    void CheckClassRequestAgent () {
	switch (SetStatus ()) {
	  case ServerStatus::NotExist:
	    TypeStr ("No class request agent exists in this domain.\n");
	    raise Abort;
	  case ServerStatus::NotAccessible:
	    TypeStr ("The class request agent isn't accessible.\n");
	    raise Abort;
	  case ServerStatus::Disabled:
	  case ServerStatus::Enabled:
	    return;
	  default:
	    TypeStr ("OOPS, something wrong.\n");
	    raise Abort;
	}
    }

    int SetStatus () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	global ResolvableObject ro
	  = nd->ResolveWithArrayOfChar (ClassRequestAgentConstants::Name);
	global ClassRequestAgent cra = narrow (ClassRequestAgent, ro);

	aClassRequestAgent = cra;
	if (cra == 0) {
	    Status = ServerStatus::NotExist;
	} else {
	    Waiter w=>New ();
	    global ClassRequestAgent cra2;
	    int @p, status;

	    p = fork IsReady (cra, w);
	    detach fork w->Timer (10);
	    if (w->WaitAndTest ()) {
		status = join p;
		if (p) {
		    Status = ServerStatus::Enabled;
		} else {
		    Status = ServerStatus::Disabled;
		}
	    } else {
		kill p;
		detach p;
		Status = ServerStatus::NotAccessible;
	    }
	}
	MakePrompt (Mode);
	return Status;
    }

    void InvalidMode () {
	TypeStr ("OOPS, something wrong!\n");
	TypeStr ("Type `slist' or `dlist' to fix it, please.\n");
    }

    int IsReady (global ClassRequestAgent cra, Waiter w) {
	int ret = cra->IsReady ();

	abortable;
	w->Done ();
	return ret;
    }

    void MakePrompt (char mode) {
	switch (Status) {
	  case ServerStatus::NotExist:
	    Prompt = PromptString ("not existing", 0); break;
	  case ServerStatus::NotAccessible:
	    Prompt = PromptString ("not accessible", 0); break;
	  case ServerStatus::Disabled:
	    Prompt = PromptString ("disable: ", mode); break;
	  case ServerStatus::Enabled:
	    Prompt = PromptString ("enable: ", mode); break;
	  default:
	    TypeStr ("OOPS, something wrong!\n");
	    TypeStr ("You'd better to quit ...\n");
	    Prompt=>NewFromArrayOfChar ("(somthing wrong)> ");
	    break;
	}
    }

    String PromptString (char message [], char mode) {
	String s=>NewFromArrayOfChar ("[");

	s = s->ConcatenateWithArrayOfChar (message);
	switch (mode) {
	  case 0:
	    s = s->ConcatenateWithArrayOfChar ("]> "); break;
	  case 'd':
	    s = s->ConcatenateWithArrayOfChar ("DList]> "); break;
	  case 's':
	    s = s->ConcatenateWithArrayOfChar ("SList]> "); break;
	  default:
	    InvalidMode ();
	    s = s->ConcatenateWithArrayOfChar ("]> "); break;
	}
	return s;
    }

//

    void Add (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 3, 0);
	CheckClassRequestAgent ();
	NotSupported ();
    }

    void Append (OrderedCollection <String> argv) {
	Set <String> names;
	unsigned int i, size;

	CheckArgSize (argv->Size (), 2, 0);
	CheckClassRequestAgent ();
	size = argv->Size ();
	names=>NewWithSize (size - 1);
	for (i = 1; i < size; i ++) {
	    names->Add (argv->At (i));
	}
	switch (Mode) {
	  case 'd':
	    aClassRequestAgent->AppendToDList (names);
	    break;
	  case 's':
	    aClassRequestAgent->AppendToSList (names);
	    break;
	  default:
	    InvalidMode ();
	    break;
	}
    }

    void ChangeMode (OrderedCollection <String> argv, char mode) {
	CheckArgSize (argv->Size (), 1, 1);
	CheckClassRequestAgent ();
	if (mode == 'd' || mode == 's') {
	    Mode = mode;
	    MakePrompt (mode);
	} else {
	    TypeStr ("OOPS, something wrong!\n");
	    raise Abort;
	}
    }

    void Clear (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	CheckClassRequestAgent ();
	switch (Mode) {
	  case 'd':
	    aClassRequestAgent->ClearDList ();
	    break;
	  case 's':
	    aClassRequestAgent->ClearSList ();
	    break;
	  default:
	    InvalidMode ();
	    break;
	}
    }

    void Disable (OrderedCollection <String> argv) {
	global ObjectManager om;
	global ClassRequestAgent cra;

	CheckArgSize (argv->Size (), 1, 1);
	switch (SetStatus ()) {
	  case ServerStatus::Enabled:
	    aClassRequestAgent->Disable ();
	    break;
	  case ServerStatus::Disabled:
	    TypeStr ("Already disabled.\n");
	    break;
	  case ServerStatus::NotAccessible:
	    TypeStr ("The class request agent is not accessible.\n"
		     "Trying to ask the ObjectManager directly ... ");
	    cra = aClassRequestAgent;
	    inline "C" {
		om = OzExecObjectManagerOf (cra);
	    }
	    try {
		om->UnregisterClass (cra);
	    } except {
	      ObjectManagerExceptions::UnknownObject (cra) {
		  TypeStr ("failed.\n"
			   "The ObjectManager doesn't know the class request "
			   "agent.\n");
	      }
		GlobalInvokeFailed {
		    TypeStr ("failed.\n"
			     "The ObjectManager isn't accessible, too.\n");
		}
	    }
	    TypeStr ("done.\n");
	    break;
	  case ServerStatus::NotExist:
	    TypeStr ("No class request agent exists.\n");
	    raise Abort;
	    break;
	  default:
	    TypeStr ("OOPS, something wrong.\n");
	    raise Abort;
	}
	SetStatus ();
	MakePrompt (Mode);
    }

    void Dump (OrderedCollection <String> argv) {
	String path;

	CheckArgSize (argv->Size (), 2, 2);
	CheckClassRequestAgent ();
	path = argv->At (1);
	aClassRequestAgent->Dump (path);
    }

    void Enable (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	CheckClassRequestAgent ();

	switch (Status) {
	  case ServerStatus::Enabled:
	    TypeStr ("Already enabled.\n");
	    break;
	  case ServerStatus::Disabled:
	    aClassRequestAgent->Enable ();
	    break;
	  default:
	    TypeStr ("OOPS, something wrong.\n");
	    raise Abort;
	}
	SetStatus ();
	MakePrompt (Mode);
    }

    void Insert (OrderedCollection <String> argv) {
	NotSupported ();
    }

    void Kill (OrderedCollection <String> argv) {
	global NameDirectory nd;

	CheckArgSize (argv->Size (), 1, 1);
	switch (SetStatus ()) {
	  case ServerStatus::NotExist:
	    TypeStr ("No class request agent exists in this domain.\n");
	    break;
	  case ServerStatus::NotAccessible:
	    TypeStr ("The class request agent is not accessible.\n"
		     "Unregistering from the NameDirectory ... ");
	    nd = Where ()->GetNameDirectory ();
	    nd->RemoveObjectWithNameWithArrayOfChar
	      (ClassRequestAgentConstants::Name);
	    TypeStr ("done.\n");
	    break;
	  case ServerStatus::Disabled:
	  case ServerStatus::Enabled:
	    RemoveClassRequestAgent ();
	    break;
	}
	SetStatus ();
	MakePrompt (Mode);
    }

    void List (OrderedCollection <String> argv) {
	OrderedCollection <Set <String>> list;
	unsigned int i, len;

	CheckArgSize (argv->Size (), 1, 1);
	CheckClassRequestAgent ();
	switch (Mode) {
	  case 'd': list = aClassRequestAgent->GetDList (); break;
	  case 's': list = aClassRequestAgent->GetSList (); break;
	  default: InvalidMode (); raise Abort;
	}
	/* naive implementation */
	len = list->Size ();
	for (i = 0; i < len; i ++) {
	    Set <String> set = list->At (i);
	    String st;

	    TypeStr ("[\n");
	    while (! set->IsEmpty ()) {
		st = set->RemoveAny ();
		TypeStr ("  ");
		TypeStr (st->Content ());
		TypeReturn ();
	    }
	    TypeStr ("]\n");
	}
    }

    void NewOne (OrderedCollection <String> argv) {
	unsigned int argsize = argv->Size ();
	global ObjectManager where;
	String path;

	CheckArgSize (argsize, 1, 2);
	switch (argsize) {
	  case 1: where = Where (); break;
	  case 2: where = narrow (ObjectManager, StringToOID (argv->At (1)));
	}
	switch (SetStatus ()) {
	  case ServerStatus::NotExist:
	    break;
	  case ServerStatus::NotAccessible:
	    TypeStr ("Warning: the current class request agent isn't "
		     "accessible, but the entry in\n"
		     "the NameDirectory exists.  Thus, making new the entry "
		     "will overwrite the \n"
		     "entry.\n"
		     "Continue (y/n) ? [y] ");
	    if (ReadYN (1)) {
		global NameDirectory nd = Where ()->GetNameDirectory ();

		nd->RemoveObjectWithNameWithArrayOfChar
		  (ClassRequestAgentConstants::Name);
	    } else {
		raise Abort;
	    }
	    break;
	  case ServerStatus::Disabled:
	  case ServerStatus::Enabled:
	    TypeStr ("Warning: the current class request agent will be "
		     "terminated and permanently\n"
		     "lost.\n"
		     "Continue (y/n) ? [y] ");
	    if (ReadYN (1)) {
		RemoveClassRequestAgent ();
	    } else {
		raise Abort;
	    }
	    break;
	  default:
	    TypeStr ("OOPS, something wrong.\n");
	    raise Abort;
	}
	aClassRequestAgent=>New ()@where;
	where->PermanentizeObject (aClassRequestAgent);
	TypeStr ("A new class request agent was created (");
	TypeOID (aClassRequestAgent);
	TypeStr (").\n");
	SetStatus ();
	MakePrompt (Mode);
    }

    void ReadSetupFile (OrderedCollection <String> argv) {
	String setup_file;

	CheckArgSize (argv->Size (), 2, 2);
	CheckClassRequestAgent ();
	setup_file = argv->At (1);
	aClassRequestAgent->Read (setup_file);
    }

    void Remove (OrderedCollection <String> argv) {
	NotSupported ();
    }

    void RemoveClassRequestAgent () {
	global ObjectManager om = 0;
	global Object o = aClassRequestAgent;

	inline "C" {
	    om = ((o & 0xffffffffff000000LL) | 0x1);
	}
	om->RemoveObject (aClassRequestAgent);
    }

    void GetStatus (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	switch (SetStatus ()) {
	  case ServerStatus::NotExist:
	    TypeStr ("No class request agent exists.\n");
	    break;
	  case ServerStatus::NotAccessible:
	    TypeStr ("A class request agent ");
	    TypeOID (aClassRequestAgent);
	    TypeStr (" cannot be accessed.\n");
	    break;
	  case ServerStatus::Disabled:
	    TypeStr ("A class request agent ");
	    TypeOID (aClassRequestAgent);
	    TypeStr (" is running but disabled.\n");
	    break;
	  case ServerStatus::Enabled:
	    TypeStr ("A class request agent ");
	    TypeOID (aClassRequestAgent);
	    TypeStr (" is running and enabled.\n");
	    break;
	  default:
	    TypeStr ("OOPS, somethng wrong.\n");
	    TypeStr ("You'd better to quit.\n");
	    raise Abort;
	}
    }

    String Title () {
	String title;

	title=>NewFromArrayOfChar ("Class Request Agent Maintainance Tool");
	return title;
    }
}
