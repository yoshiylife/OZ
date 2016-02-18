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
 * dnsmaintener.oz
 *
 * DNS resolver maintenance tool
 *
 * A DNS resolver has 2 possible status -- one is enabled and another is
 * disabled.  An enabled DNS resolver is a member of the name directory system,
 * while a disabled is not.  That is, a disabled resolver works completely as
 * same as enabled one, except that other name directories in the domain cannot
 * delegate a name resolution to the disabled DNS resolver.
 */

class DNSResolverMaintainer :
  CommandInterpreter (alias Initialize SuperInitialize;
		      alias SetCommandHash SuperSetCommandHash;
		      alias SetHelpMessages SuperSetHelpMessages;
		      alias SetOneLineHelp SuperSetOneLineHelp;)
{
  constructor: New;
  public: Launch;

  protected: IsReady;


/* instance variables */
    global DNSResolver aDNSResolver;
    String DNSResolverName;

/* method implementations */
    void Initialize () {
	SuperInitialize ();
	DNSResolverName=>NewFromArrayOfChar (":DNS-resolver");
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

	      case DNSCommands::Clear: Clear (argv); break;
	      case DNSCommands::Disable: Disable (argv); break;
	      case DNSCommands::Dump: Dump (argv); break;
	      case DNSCommands::Enable: Enable (argv); break;
	      case DNSCommands::Exclude: Exclude (argv); break;
	      case DNSCommands::Kill: Kill (argv); break;
	      case DNSCommands::List: List (argv); break;
	      case DNSCommands::New: NewOne (argv); break;
	      case DNSCommands::Read: ReadSetupFile (argv); break;
	      case DNSCommands::Register: Register (argv); break;
	      case DNSCommands::Status: Status (argv); break;
	      case DNSCommands::Unregister: Unregister (argv); break;
	    }
	} else {
	    TypeStr ("Unknown command ");
	    TypeString (f);
	    TypeStr (".\n");
	}
    }

    void SetCommandHash () {
	SuperSetCommandHash ();

	/* DNS resolver maintenance */
	AddCommand ("clear", DNSCommands::Clear);
	AddCommand ("disable", DNSCommands::Disable);
	AddCommand ("dump", DNSCommands::Dump);
	AddCommand ("enable", DNSCommands::Enable);
	AddCommand ("exclude", DNSCommands::Exclude);
	AddCommand ("kill", DNSCommands::Kill);
	AddCommand ("list", DNSCommands::List);
	AddCommand ("new", DNSCommands::New);
	AddCommand ("read", DNSCommands::Read);
	AddCommand ("register", DNSCommands::Register);
	AddCommand ("status", DNSCommands::Status);
	AddCommand ("unregister", DNSCommands::Unregister);
    }

    void SetHelpMessages () {
	SuperSetHelpMessages ();

	AddHelp ("clear",
		 "clear\n\n"
		 "clear makes the DNS resolver empty to have no domain map.");

	AddHelp ("disable",
		 "disable\n\n"
		 "disable disables the running DNS resolver.  A DNS resolver "
		 "is disabled by deleting it from the domain's name directory "
		 "system.  A disabled DNS resolver can be enabled later.  "
		 "Disabling disabled DNS resolver has no effect.  If the DNS "
		 "resolver doesn't exist, or cannot be accessed, an error "
		 "will be reported.");

	AddHelp ("dump",
		 "dump <FileName>\n\n"
		 "dump dumps the contents of the DNS resolver to a file in "
		 "setup file format.");

	AddHelp ("enable",
		 "enable\n\n"
		 "enable enables the disabled DNS resolver.  A DNS resolver "
		 "is enabled by adding it to the domain's directory system.  "
		 "Enabling already enabled DNS resolver has no effect.  If "
		 "the DNS resolver doesn't exist, or cannot be accessed, an "
		 "error will be reported.");

	AddHelp ("exclude",
		 "exclude\n\n"
		 "exclude excludes the (possibly malfunctinoed) DNS resolver "
		 "(named as \":DNS-resolver\") from the domain's name "
		 "directory system.");

	AddHelp ("kill",
		 "kill\n\n"
		 "kill removes the DNS resolver object.  A killed DNS "
		 "resolver is permanently lost.");

	AddHelp ("list",
		 "list\n\n"
		 "list shows all domains and object IDs of their name "
		 "directory listed in the DNS resolver.");

	AddHelp ("new",
		 "new\n\n"
		 "new creates a new DNS resolver.  If there is another DNS "
		 "resolver, an error will be reported even if it is "
		 "disabled.");

	AddHelp ("read",
		 "read <SetupFileName>\n\n"
		 "read gives the file <SetupFileName> to the running DNS "
		 "resolver to register domains.  The file format of the setup "
		 "file is as following:\n\n"
		 "        <setup-file> ::= <record>*\n"
		 "        <record>     ::= <domain-name> ':' <oid> '\\n'\n\n"
		 "<domain-name> must be a DNS resolvable name of a domain.  "
		 "<oid> must be a global object ID of a name directory in the "
		 "domain.  Following is an example of a setfile:\n\n"
		 "        stu.edu:0082000001000003\n"
		 "        vwwu.edu:018a00220d000003\n"
		 "        asw-c.com:0021000001000003\n\n"
		 "No blanks and tabs are permitted.  A DNS resolver can read "
		 "a file even if it is disabled.");

	AddHelp ("register",
		 "register <DomainName> <OID>\n\n"
		 "register registers a name directory of domain <DomainName> "
		 "to the running DNS resolver.  A DNS resolver can accept a "
		 "registration even if it is disabled.");

	AddHelp ("status",
		 "status\n\n"
		 "status shows the status of the DNS resolver.\n\n"
		 "  Not exist ... No DNS resolver is found in the "
		 "NameDirectory of this domain.\n"
		 "  Down      ... A DNS resolver is at :DNS-resolver, but "
		 "cannot access\n"
		 "                it.\n"
		 "  Disabled  ... A DNS resolver is up and disabled.\n"
		 "  Enabled   ... A DNS resolver is up and enabled.");

	AddHelp ("unregister",
		 "unregister <DomainName>\n\n"
		 "unregister unregisters a domain from DNS resolver.  A DNS "
		 "resolver can accept an unregistration even if it is "
		 "disabled.");
    }

    void SetInitialPrompt () {
	Prompt=>NewFromArrayOfChar ("DNS Resolver Maintainer> ");
    }

    void SetOneLineHelp () {
	SuperSetOneLineHelp ();
	AddOneLineHelp ("clear", "Empty the running DNS resolver.");
	AddOneLineHelp ("disable", "Disable the running DNS resolver.");
	AddOneLineHelp ("dump", "Dump the contents to a file.");
	AddOneLineHelp ("enable", "Enable the disabled DNS resolver.");
	AddOneLineHelp ("exclude", "Exclude the malfunctioned DNS resolver.");
	AddOneLineHelp ("kill", "Kill the running DNS resolver.");
	AddOneLineHelp ("list", "List domain names.");
	AddOneLineHelp ("new", "Create a DNS resolver.");
	AddOneLineHelp ("register", "Register a domain.");
	AddOneLineHelp ("read", "Initialize with a setup file.");
	AddOneLineHelp ("status", "Report status.");
	AddOneLineHelp ("unregister", "Unregister a domain.");
    }

    void CheckDNSResolver () {
	switch (GetStatus ()) {
	  case ServerStatus::NotExist:
	    TypeStr ("No DNS resolver exists in this domain.\n");
	    raise Abort;
	  case ServerStatus::NotAccessible:
	    TypeStr ("The DNS resolver cannot be accessed.\n");
	    raise Abort;
	  case ServerStatus::Disabled:
	  case ServerStatus::Enabled:
	    return;
	  default:
	    TypeStr ("OOPS, something wrong.\n");
	    raise Abort;
	}
    }

    void Clear (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	CheckDNSResolver ();
	aDNSResolver->Clear ();
    }

    void Disable (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	CheckDNSResolver ();
	if (GetStatus () == ServerStatus::Enabled) {
	    Where ()->GetNameDirectory ()->Exclude (aDNSResolver);
	}
    }

    void Dump (OrderedCollection <String> argv) {
	String path;

	CheckArgSize (argv->Size (), 2, 2);
	CheckDNSResolver ();
	argv->RemoveFirst ();
	path = argv->RemoveFirst ();
	aDNSResolver->Dump (path);
    }

    void Enable (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	CheckDNSResolver ();
	if (GetStatus () == ServerStatus::Disabled) {
	    Where ()->GetNameDirectory ()->Join (aDNSResolver);
	}
    }

    void Exclude (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	GetStatus ();
	Where ()->GetNameDirectory ()->Exclude (aDNSResolver);
    }

    int GetStatus () {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	global DNSResolver dr;

	dr =narrow (DNSResolver, nd->ResolveWithArrayOfChar (":DNS-resolver"));
	aDNSResolver = dr;
	if (dr == 0) {
	    return ServerStatus::NotExist;
	} else {
	    Waiter w=>New ();
	    global DNSResolver dr2;

	    detach fork IsReady (dr, w);
	    detach fork w->Timer (10);
	    if (w->WaitAndTest ()) {
		String st=>NewFromArrayOfChar (":");

		dr2 = narrow (DNSResolver, nd->ResponsibleResolver (st));
		if (dr == dr2) {
		    return ServerStatus::Enabled;
		} else {
		    return ServerStatus::Disabled;
		}
	    } else {
		return ServerStatus::NotAccessible;
	    }
	}
    }

    void IsReady (global DNSResolver dr, Waiter w) {
	dr->IsReady ();
	w->Done ();
    }

    void Kill (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	CheckDNSResolver ();
	aDNSResolver->Terminate ();
    }

    void List (OrderedCollection <String> argv) {
	Dictionary <String, global DirectoryServer <global ResolvableObject>>
	  map;
	Iterator <Assoc <String,
	                 global DirectoryServer <global ResolvableObject>>> i;
	Assoc <String, global DirectoryServer <global ResolvableObject>> a;
	unsigned int max_rows = GetVariable ("Rows")->AtoI ();
	unsigned int max_columns = GetVariable ("Columns")->AtoI ();
	unsigned int len, longest = 0, j, col = 0, rows = 0;

	CheckArgSize (argv->Size (), 1, 1);
	CheckDNSResolver ();
	map = aDNSResolver->GetDomainMap ();
	for (i=>New (map); (a = i->PostIncrement ()) != 0;) {
	    len = a->Key ()->Length ();
	    if (len > longest) {
		longest = len;
	    }
	}
	i->Finish ();
	for (i=>New (map); (a = i->PostIncrement ()) != 0;) {
	    String name = a->Key ();

	    len = name->Length ();
	    TypeString (name);
	    for (j = 0; j < longest + 1 - len; j ++) {
		TypeStr (" ");
	    }
	    TypeOID (a->Value ());
	    col += (longest + 18);
	    if (col + longest + 18 > max_columns) {
		TypeStr ("\n");
		col = 0;
		rows ++;
		if ((rows + 1) % (max_rows - 1) == 0) {
		    if (BreakScroll ()) {
			break;
		    }
		}
	    } else {
		TypeStr (" ");
	    }
	}
	if (col != 0) {
	    TypeReturn ();
	}
    }

    void NewOne (OrderedCollection <String> argv) {
	String path;

	CheckArgSize (argv->Size (), 1, 1);
	switch (GetStatus ()) {
	  case ServerStatus::NotExist:
	    break;
	  case ServerStatus::NotAccessible:
	    TypeStr ("Warning: the current DNS resolver cannot be ");
	    TypeStr ("accessed.\n");
	    TypeStr ("An entry in the name directory will be overwritten.\n");
	    TypeStr ("Continue (y/n) ? [y] ");
	    if (ReadYN (1)) {
		global NameDirectory nd = Where ()->GetNameDirectory ();

		nd->RemoveObjectWithNameWithArrayOfChar (":DNS-resolver");
	    } else {
		raise Abort;
	    }
	    break;
	  case ServerStatus::Disabled:
	  case ServerStatus::Enabled:
	    TypeStr ("Warning: a running DNS resolver will be terminated ");
	    TypeStr ("and permanently lost.\n");
	    TypeStr ("Continue (y/n) ? [y] ");
	    if (ReadYN (1)) {
		aDNSResolver->Terminate ();
	    } else {
		raise Abort;
	    }
	    break;
	  default:
	    TypeStr ("OOPS, something wrong.\n");
	    raise Abort;
	}
	aDNSResolver=>New ();
	Where ()->PermanentizeObject (aDNSResolver);
	TypeStr ("A new DNS resolver was created (");
	TypeOID (aDNSResolver);
	TypeStr (").\n");
    }

    void ReadSetupFile (OrderedCollection <String> argv) {
	String setup_file;

	CheckArgSize (argv->Size (), 2, 2);
	CheckDNSResolver ();
	argv->RemoveFirst ();
	setup_file = argv->RemoveFirst ();
	aDNSResolver->Setup (setup_file);
    }

    void Register (OrderedCollection <String> argv) {
	String domain_name;
	global NameDirectory nd;

	CheckArgSize (argv->Size (), 3, 3);
	CheckDNSResolver ();
	argv->RemoveFirst ();
	domain_name = argv->RemoveFirst ();
	nd = narrow (NameDirectory, StringToOID (argv->RemoveFirst ()));
	aDNSResolver->RegisterDomain (domain_name, nd);
    }

    void Status (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	switch (GetStatus ()) {
	  case ServerStatus::NotExist:
	    TypeStr ("No DNS resolver exists.\n");
	    break;
	  case ServerStatus::NotAccessible:
	    TypeStr ("A DNS resolver ");
	    TypeOID (aDNSResolver);
	    TypeStr (" cannot be accessed.\n");
	    break;
	  case ServerStatus::Disabled:
	    TypeStr ("A DNS resolver ");
	    TypeOID (aDNSResolver);
	    TypeStr (" is running but disabled.\n");
	    break;
	  case ServerStatus::Enabled:
	    TypeStr ("A DNS resolver ");
	    TypeOID (aDNSResolver);
	    TypeStr (" is running and enabled.\n");
	    break;
	  default:
	    TypeStr ("OOPS, somethng wrong.\n");
	    raise Abort;
	}
    }

    void Unregister (OrderedCollection <String> argv) {
	String domain_name;

	CheckArgSize (argv->Size (), 2, 2);
	CheckDNSResolver ();
	argv->RemoveFirst ();
	domain_name = argv->RemoveFirst ();
	aDNSResolver->UnregisterDomain (domain_name);
    }

    String Title () {
	String title=>NewFromArrayOfChar ("DNS Resolver Maintainance Tool");

	return title;
    }
}
