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
 * cio.oz
 *
 * service interface of class object
 */

class ClassObjectServiceInterface
  : CommandInterpreter (alias SetCommandHash SuperSetCommandHash;
			alias SetHelpMessages SuperSetHelpMessages;
			alias SetOneLineHelp SuperSetOneLineHelp;)
{
  constructor: New;
  public: Launch;

/* instance variables */
    global Class C;

/* method implementations */
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

	      case ClassCommands::Describe: Describe (argv); break;
	      case ClassCommands::List: List (argv); break;
	      case ClassCommands::Load: Load (argv); break;
	      case ClassCommands::Purge: Purge (argv); break;
	      case ClassCommands::Remove: Remove (argv); break;
	      case ClassCommands::Send: Send (argv); break;
	      case ClassCommands::SendAll: SendAll (argv); break;
	      case ClassCommands::SetClass: SetClass (argv); break;
	    }
	} else {
	    TypeStr ("Unknown command ");
	    TypeString (f);
	    TypeStr (".\n");
	}
    }

    void SetCommandHash () {
	SuperSetCommandHash ();

	/* class table */
	AddCommand ("describe", ClassCommands::Describe);
	AddCommand ("list", ClassCommands::List);
	AddCommand ("load", ClassCommands::Load);
	AddCommand ("purge", ClassCommands::Purge);
	AddCommand ("remove", ClassCommands::Remove);
	AddCommand ("send", ClassCommands::Send);
	AddCommand ("sendall", ClassCommands::SendAll);
	AddCommand ("setclass", ClassCommands::SetClass);
    }

    void SetHelpMessages () {
	SuperSetHelpMessages ();

	AddHelp ("describe",
		 "describe <ClassID>\n\n"
		 "describe shows a brief description of a class part "
		 "<ClassID>.");

	AddHelp ("list",
		 "list [<Part>]\n\n"
		 "list shows a listings of contents of the class object.  "
		 "<Part> must be one of `conf', `impl', `protected', `public' "
		 "and `root'.  If <Part> is omitted, all contents of the "
		 "class object will be listed.");

	AddHelp ("load",
		 "load <ClassID>\n\n"
		 "load loads a class part from other class object at "
		 "somewhere to the class managing this executor.  This "
		 "command is different from other commands in the point that "
		 "always the local class object is used instead of the target "
		 "class object set by the setclass command.");

	AddHelp ("purge",
		 "purge <ClassID>\n\n"
		 "purge purges obsolete lower class parts of <ClassID>.  "
		 "Purging a class part removes all lower invisible parts "
		 "which is older than the newest lower visible part.  Purging "
		 "a public part also removes all configured classes "
		 "configured to use one of the purged implementation parts.");

	AddHelp ("remove",
		 "remove <ClassID>\n\n"
		 "remove removes a class part from the target class object "
		 "set by the setclass command.  If no class object has been "
		 "set, an error will be reported.");

	AddHelp ("send",
		 "send <ClassID> <Class>\n\n"
		 "send sends a class part <ClassID> to another class object "
		 "<Class>.  <Class> must be either an global object ID or a "
		 "name of a class object.");

	AddHelp ("sendall",
		 "sendall <Class>\n\n"
		 "sendall sends all class parts to another class object "
		 "<Class>.  <Class> must be either a global object ID or a "
		 "name of a class object.");

	AddHelp ("setclass",
		 "setclass [<Class>]\n\n"
		 "setclass sets a class object <Class> as the target class.  "
		 "Succeeding commands except the load command will be "
		 "directed to the class object until another one is set by "
		 "this command.  <Class> must be a global object ID or a name "
		 "of a class object.  Without the argument, setclass sets a "
		 "local class object as a target class.");
    }

    void SetOneLineHelp () {
	SuperSetOneLineHelp ();

	AddOneLineHelp ("describe", "Describe a class part.");
	AddOneLineHelp ("list", "Show listings of class parts.");
	AddOneLineHelp ("load", "Load a class part.");
	AddOneLineHelp ("purge", "Purge obsolete invisible class parts.");
	AddOneLineHelp ("remove", "Remove a class part.");
	AddOneLineHelp ("send", "Send a class part to another class object.");
	AddOneLineHelp ("sendall",
			"Send all class parts to another class object.");
	AddOneLineHelp ("setclass",
			"Set the target class object to be operated.");
    }

    void CheckTargetClass () {
	if (C == 0) {
	    TargetClassNotSet ();
	    raise Abort;
	}
    }

    void SetInitialPrompt () {
	if (C != 0) {
	    TypeStr ("Current target class is ");
	    TypeOID (C);
	    TypeStr (".\n");
	} else {
	    TypeStr ("Target class is not set currently.\n");
	    Prompt=>NewFromArrayOfChar ("Class> ");
	}
    }

    void TargetClassNotSet () {
	TypeStr ("Target class has not been set.  Try help setclass.\n");
    }

    String Title () {
	String title=>NewFromArrayOfChar ("Class Object Service Interface");

	return title;
    }

    void Describe (OrderedCollection <String> argv) {
	global ClassID cid;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	cid = narrow (ClassID, StringToOID (argv->RemoveFirst ()));
	switch (C->WhichPart (cid)) {
	  case ClassPartName::aConfiguredClass:
	    DescribeConfiguredClass (narrow (ConfiguredClass,
					     C->GetClassPart (cid)));
	    break;
	  case ClassPartName::anImplementationPart:
	    DescribeImplementationPart (narrow (ImplementationPart,
						C->GetClassPart (cid)));
	    break;
	  case ClassPartName::aProtectedPart:
	    DescribeProtectedPart (narrow (ProtectedPart,
					   C->GetClassPart (cid)));
	    break;
	  case ClassPartName::aPublicPart:
	    DescribePublicPart (narrow (PublicPart, C->GetClassPart (cid)));
	    break;
	  case ClassPartName::aRootPart:
	    DescribeRootPart (narrow (RootPart, C->GetClassPart (cid)));
	    break;
	  default:
	    raise ClassExceptions::InternalError;
	    break;
	}
    }

    void DescribeClassCopyKind (unsigned int kind) {
	switch (kind) {
	  case ClassCopyKind::Boot:
	    TypeStr ("boot class");
	    break;
	  case ClassCopyKind::Original:
	    TypeStr ("original copy");
	    break;
	  case ClassCopyKind::Mirror:
	    TypeStr ("mirrored copy");
	    break;
	  case ClassCopyKind::Snapshot:
	    TypeStr ("snapshot copy");
	    break;
	  case ClassCopyKind::Private:
	    TypeStr ("private copy");
	    break;
	}
    }

    void DescribeClassPart (ClassPart cp) {
	String properties [] = cp->GetProperties ();
	unsigned int MAXCOLUMN = GetVariable ("Columns")->AtoI () - 1;
	unsigned int i, l, len = length properties, col = 0, max = 0;

	TypeOID (cp->GetID ());
	TypeStr (" : ");
	DescribeClassCopyKind (cp->WhichKindOfCopy ());
	TypeReturn ();
	if (len > 0) {
	    TypeStr ("Properties:\n ");
	    for (i = 0; i < len; i ++) {
		l = properties [i]->Length ();
		if (max < l) {
		    if (l < MAXCOLUMN / 2) {
			max = MAXCOLUMN / (MAXCOLUMN / (l + 1)) - 1;
		    } else {
			max = MAXCOLUMN - 1;
			break;
		    }
		}
	    }
	    for (i = 0; i < len; i ++) {
		unsigned int j;

		l = properties [i]->Length ();
		col += max + 1;
		if (col > MAXCOLUMN) {
		    TypeStr ("\n  ");
		    col = max + 1;
		} else {
		    TypeStr (" ");
		}
		TypeStr (properties [i]->Content ());
		for (j = 0; j < max - l; j ++) {
		    TypeStr (" ");
		}
	    }
	    TypeReturn ();
	} else {
	    TypeStr ("No properties found.\n");
	}
    }

    void DescribeClassVersion (ClassVersion cv) {
	VersionString vs = cv->GetVersionString ();
	global VersionID parents [] = cv->GetParents ();
	unsigned int len = length parents;

	if (vs == 0) {
	    TypeStr ("No version has been given.\n");
	} else {
	    TypeStr ("Version: ");
	    TypeStr (vs->Content ());
	    TypeReturn ();
	}
	if (len == 0) {
	    TypeStr ("No superclass.\n");
	} else {
	    TypeStr ("SuperClasses: \n");
	    DescribeOIDArray (parents);
	}
    }

    void DescribeConfiguredClass (ConfiguredClass cc) {
	global VersionID impls [] = cc->GetImplementationParts ();

	TypeStr ("Configured Class ");
	DescribeClassPart (cc);
	TypeStr ("Public part: ");
	TypeOID (cc->GetPublicPart ());
	TypeReturn ();
	if (length impls == 0) {
	    TypeStr ("?? No implementation parts.\n");
	} else {
	    TypeStr ("Implementation parts:\n");
	    DescribeOIDArray (impls);
	}
    }

    void DescribeImplementationPart (ImplementationPart ip) {
	ArchitectureID archs [] = ip->Architectures ();
	unsigned int i, len = length archs;

	TypeStr ("Implementation Part ");
	DescribeClassPart (ip);
	DescribeUpperPart (ip);
	DescribeClassVersion (ip);
	if (len == 0) {
	    TypeStr ("?? No architecture is supported.\n");
	} else {
	    TypeStr ("Supported architectures:");
	    for (i = 0; i < len; i ++) {
		TypeStr (" ");
		TypeStr (archs [i]->Type ());
	    }
	    TypeReturn ();
	}
    }

    void DescribeLowerPart (UpperPart up) {
	global VersionID lvs [] = up->GetLowerVersions ();
	global VersionID dlv = up->GetDefaultLowerVersionID ();
	global VersionID vlvs [] = up->GetVisibleLowerVersions ();
	unsigned int i, len;

	len = length lvs;
	if (len > 0) {
	    TypeStr ("Lower parts:\n");
	    DescribeOIDArray (lvs);
	} else {
	    TypeStr ("No lower part.\n");
	}
	if (dlv != 0) {
	    TypeStr ("Default lower part: ");
	    TypeOID (dlv);
	    TypeReturn ();
	} else {
	    TypeStr ("No default lower part.\n");
	}
	len = length vlvs;
	if (len > 0) {
	    TypeStr ("Lower parts with version numbers:\n");
	    DescribeOIDArray (vlvs);
	} else {
	    TypeStr ("No lower parts with version numbers.\n");
	}
    }

    void DescribeOIDArray (global Object oarray []) {
	unsigned int col = 0, i, len = length oarray;

	for (i = 0; i < len; i ++) {
	    if (++ col == 5) {
		TypeStr ("\n ");
		col = 1;
	    }
	    TypeStr (" ");
	    TypeOID (oarray [i]);
	}
	TypeReturn ();
    }

    void DescribeProtectedPart (ProtectedPart protp) {
	UpperPart up = protp;

	TypeStr ("Protected Part ");
	DescribeClassPart (up);
	DescribeUpperPart (protp);
	DescribeClassVersion (up);
	DescribeLowerPart (up);
    }

    void DescribePublicPart (PublicPart pubp) {
	global ConfiguredClassID ccids [] = pubp->ConfiguredClassIDs ();
	UpperPart up = pubp;

	TypeStr ("Public Part ");
	switch (pubp->WhichKind ()) {
	  case KindOfClassPart::aShared:
	    TypeStr ("(Shared) ");
	    break;
	  case KindOfClassPart::aStaticClass:
	    TypeStr ("(Static Class) ");
	    break;
	  case KindOfClassPart::aRecord:
	    TypeStr ("(Record) ");
	    break;
	}
	DescribeClassPart (up);
	DescribeUpperPart (pubp);
	DescribeClassVersion (up);
	if (pubp->WhichKind () == KindOfClassPart::anOrdinaryClass) {
	    DescribeLowerPart (up);
	    if (length ccids > 0) {
		global ConfiguredClassID ccid;

		TypeStr ("Configurations:\n");
		DescribeOIDArray (ccids);
		if ((ccid = pubp->GetDefaultConfiguredClassID ()) != 0) {
		    TypeStr ("Default Configured Class: ");
		    TypeOID (ccid);
		    TypeReturn ();
		} else {
		    TypeStr ("No default configured class.\n");
		}
	    } else {
		TypeStr ("No configurations.\n");
	    }
	}
    }

    void DescribeRootPart (RootPart rp) {
	TypeStr ("Root Part ");
	DescribeClassPart (rp);
	DescribeClassVersion (rp);
	DescribeLowerPart (rp);
    }

    void DescribeUpperPart (LowerPart lp) {
	TypeStr ("Upper Part: ");
	TypeOID (lp->GetUpperPart ());
	TypeReturn ();
    }

    void List (OrderedCollection <String> argv) {
	global ClassID s [];
	String var;
	unsigned int max_rows = GetVariable ("Rows")->AtoI ();
	unsigned int max_columns = GetVariable ("Columns")->AtoI ();
	unsigned int arg_size, i, len, col = 0, rows = 0;

	CheckTargetClass ();
	arg_size = argv->Size ();
	CheckArgSize (arg_size, 1, 2);
	switch (arg_size) {
	  case 1:
	    s = C->ListClassID ();
	    len = length s;
	    for (i = 0; i < len; i ++) {
		TypeOID (s [i]);
		col += 17;
		if (col + 17 > max_columns) {
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
	    if (col != 0)
	      TypeReturn ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    if (argv->First ()->IsEqualToArrayOfChar ("conf")) {
		ListPart (ClassPartName::aConfiguredClass);
	    } else if (argv->First ()->IsEqualToArrayOfChar ("impl")) {
		ListPart (ClassPartName::anImplementationPart);
	    } else if (argv->First()->IsEqualToArrayOfChar("protedted")){
		ListPart (ClassPartName::aProtectedPart);
	    } else if (argv->First ()->IsEqualToArrayOfChar ("public")) {
		ListPart (ClassPartName::aPublicPart);
	    } else if (argv->First ()->IsEqualToArrayOfChar ("root")) {
		ListPart (ClassPartName::aRootPart);
	    }
	    break;
	}
    }

    void ListPart (unsigned int part) {
	global ClassID s [] = C->ListClassID ();
	unsigned int max_rows = GetVariable ("Rows")->AtoI ();
	unsigned int max_columns = GetVariable ("Columns")->AtoI ();
	unsigned int i, len = length s, col = 0, row = 0;

	for (i = 0; i < len; i ++) {
	    if (C->WhichPart (s [i]) == part) {
		TypeOID (s [i]);
		col += 17;
		if (col + 17 > max_columns) {
		    TypeStr ("\n");
		    col = 0;
		    row ++;
		    if ((row + 1) % (max_rows - 1) == 0) {
			if (BreakScroll ()) {
			    break;
			}
		    }
		} else {
		    TypeStr (" ");
		}
	    }
	}
	if (col == 0) {
	    TypeReturn ();
	}
    }

    void Load (OrderedCollection <String> argv) {
	ArchitectureID arch=>Any ();
	global ClassID cid;

	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	cid = narrow (ClassID, StringToOID (argv->RemoveFirst ()));
	Where ()->SearchClass (cid, arch);
    }

    void Purge (OrderedCollection <String> argv) {
	CheckTargetClass ();
	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	C->Purge (narrow (ClassID, StringToOID (argv->RemoveFirst ())));
    }

    void Remove (OrderedCollection <String> argv) {
	CheckTargetClass ();
	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	C->RemoveClass (narrow (ClassID, StringToOID (argv->RemoveFirst ())));
    }

    global Class GetClassFromName (String name) {
	global Class c;

	c = narrow (Class, Where ()->GetNameDirectory ()->Resolve (name));
	if (c == 0) {
	    TypeStr ("Unknown class name ");
	    TypeString (name);
	    TypeStr (".  Trying it as global object ID...\n");
	    c = narrow (Class, StringToOID (name));
	}
	return c;
    }

    global Class GetLocalClass () {
	global ConfiguredClassID ccid;
	ArchitectureID aid=>Any ();

	inline "C" {
	    ccid = OzExecGetObjectTop (self)->head [0].a;
	}
	return Where ()->SearchClass (ccid, aid);
    }

    void Send (OrderedCollection <String> argv) {
	global ClassID cid;
	global Class c;
	String name;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 3, 3);
	argv->RemoveFirst ();
	cid = narrow (ClassID, StringToOID (argv->RemoveFirst ()));
	c = GetClassFromName (argv->RemoveFirst ());
	try {
	    C->DelegateClass (cid, c);
	} except {
	  ClassExceptions::UnknownClass (ucid) {
	      TypeStr ("Unknown class ");
	      TypeOID (cid);
	      TypeStr (".\n");
	      TypeReturn ();
	      raise;
	  }
	}
    }

    void SendAll (OrderedCollection <String> argv) {
	global Class c;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 2, 2);
	c = GetClassFromName (argv->RemoveLast ());
	C->DelegateAll (c);
    }

    void SetClass (OrderedCollection <String> argv) {
	unsigned int len = argv->Size ();
	String name;

	CheckArgSize (len, 1, 2);
	if (len == 2) {
	    name = argv->RemoveLast ();
	    C = GetClassFromName (name);
	} else {
	    C = GetLocalClass ();
	    name=>OIDtoHexa (C);
	}
	TypeStr ("The target class is changed to ");
	TypeOID (C);
	TypeStr (".\n");
	Prompt = name->ConcatenateWithArrayOfChar ("> ");
    }
}
