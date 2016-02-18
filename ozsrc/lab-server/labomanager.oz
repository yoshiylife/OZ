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
 * labomanager.oz
 *
 * LaboManager - User interface of laboratory servers
 */

class LaboManager : CommandInterpreter
  (alias Initialize SuperInitialize;
   alias SetCommandHash SuperSetCommandHash;
   alias SetHelpMessages SuperSetHelpMessages;
   alias SetOneLineHelp SuperSetOneLineHelp;)
{
  protected: /* for override, if needed */
    Initialize, Launch, New, SetHelpMessages, SetInitialVariables,
    SetOneLineHelp, Start;

  protected: /* for use */
    AddCommand, AddHelp, AddOneLineHelp, BreakScroll, CheckArgSize,
    GetVariable, IsAlphabet, IsAlphanumeric, IsDigit, IsWhite, NotSupported,
    Read, ReadYN, ReadYNFromConsole, SetPrompt, SetVariable, StringToOID, Trim,
    TooFewArguments, TooManyArguments, TypeChar, TypeIndentedString, TypeInt,
    TypeOID, TypeReturn, TypeSpaces, TypeStr, TypeString, WriteStr;

  protected: /* commands */
    Alias, Help, NOP, Quit, SetCommandHash, SetVar, Show, Unalias;

/* instance variables */
  protected: CommandHash, Prompt, Aliases, Variables;

    String DNSName;
    String CatalogName;
    global LaboDNSResolver aLaboDNSResolver;
    global LaboCatalog aLaboCatalog;
    int Mode; /* 0 .. no mode   1 .. DNS mode   2 .. Catalog mode */

/* method implementations */

    void Initalize() {
	SuperInitialize();
	DNSName=>NewFromArrayOfChar(":labo-DNSresolver");
	CatalogName=>NewFromArrayOfChar("labo-catalog");
	Mode = 0;
	GetStatus();
    }

    void SetInitialPrompt () {
	Prompt=>NewFromArrayOfChar ("LaboManager> ");
    }

    void Dispatch (OrderedCollection <String> argv) {
	switch (CommandHash->AtKey (argv->First ())) {
	  case CommandInterpreterCommands::NOP: NOP(argv); break;
	  case CommandInterpreterCommands::Help: Help(argv); break;
	  case CommandInterpreterCommands::Alias: Alias(argv); break;
	  case CommandInterpreterCommands::Quit: Quit(argv); break;
	  case CommandInterpreterCommands::Show: Show(argv); break;
	  case CommandInterpreterCommands::SetVar: SetVar(argv); break;

	  case LaboCommands::Status: Status(argv); break;
	  case LaboCommands::New: NewServers(argv); break;
	  case LaboCommands::Clear: Clear(argv); break;
	  case LaboCommands::DNS: DNS(argv); break;
	  case LaboCommands::Catalog: Catalog(argv); break;
	  case LaboCommands::List: List(argv); break;
	  case LaboCommands::Move: Move(argv); break;
	  case LaboCommands::Remove: Remove(argv); break;
	}
    }

    void SetCommandHash () {
	SuperSetCommandHash ();

	/* object table */
	AddCommand("status", LaboCommands::Status);
	AddCommand("new", LaboCommands::New);
	AddCommand("clear", LaboCommands::Clear);
	AddCommand("dns", LaboCommands::DNS);
	AddCommand("catalog", LaboCommands::Catalog);
	AddCommand("list", LaboCommands::List);
	AddCommand("move", LaboCommands::Move);
	AddCommand("remove", LaboCommands::Remove);
    }

    void SetHelpMessages () {
	SuperSetHelpMessages ();

	AddHelp("status",
		"status\n\n"
		"shows the status of the labo-servers.");
    }

    void SetOneLineHelp () {
	SuperSetOneLineHelp ();

	AddOneLineHelp("status", "shows status.");
    }

/**/

    void Status(OrderedCollection<String> argv) {
	int s;
	switch (argv->Size()) {
	  case 1:
	    s = GetStatus();
	    switch (s) {
	      case 0: TypeStr("Not exist\n"); break;
	      case 1: TypeStr("Not accessible\n"); break;
	      case 2: TypeStr("Running\n"); break;
	      case 3: TypeStr(
			  "Invalid status.  Maybe recreation is required.\n"
		      ); break;
	    }
	    break;
	  default:
	    TooManyArguments();
	    break;
	}
    }

/**/

    int GetStatus() {
	global NameDirectory nd = Where()->GetNameDirectory();
	try {
	    if (nd->Includes(DNSName) && nd->Includes(CatalogName)) {
		global LaboDNSResolver dr
		  = narrow(LaboDNSResolver, nd->Resolve(DNSName));
		global LaboCatalog lc
		  = narrow(LaboCatalog, nd->Resolve(CatalogName));

		aLaboDNSResolver = dr;
		aLaboCatalog = lc;

		dr->IsReady();
		lc->IsReady();
		return 2; /* Running */
	    } else {
		return 0; /* Not exist */
	    }
	} except {
	  DirectoryExceptions::UnknownEntry(path) {
	      /* Do nothing.  The entry is eliminated before the resolution */
	      return 0; /* Not exist */
	  }
	    default {
		return 1; /* Not accessible */
	    }
	}
    }

    void NewServers(OrderedCollection<String> argv) {
    }

    void Clear(OrderedCollection<String> argv) {
    }

    void DNS(OrderedCollection<String> argv) {
	switch (argv->Size()) {
	  case 1:
	    Mode = 1; /* DNS mode */
	    Prompt=>NewFromArrayOfChar("DNS> ");
	    break;
	  default:
	    TooManyArguments();
	}
    }

    void Catalog(OrderedCollection<String> argv) {
	switch (argv->Size()) {
	  case 1:
	    Mode = 2; /* Catalog mode */
	    Prompt=>NewFromArrayOfChar("Catalog> ");
	    break;
	  default:
	    TooManyArguments();
	}
    }

    void List(OrderedCollection<String> argv) {
    }

    void Move(OrderedCollection<String> argv) {
    }

    void Remove(OrderedCollection<String> argv) {
    }

/**/

    String Title() {
	String st=>NewFromArrayOfChar("LaboManager");
	return st;
    }
}
