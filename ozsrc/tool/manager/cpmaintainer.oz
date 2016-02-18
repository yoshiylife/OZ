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
 * cpmaintener.oz
 *
 * class package maintenance tool
 */

class ClassPackageMaintainer :
  CommandInterpreter (alias Initialize SuperInitialize;
		      alias SetCommandHash SuperSetCommandHash;
		      alias SetHelpMessages SuperSetHelpMessages;
		      alias SetOneLineHelp SuperSetOneLineHelp;)
{
  constructor: New;
  public: Launch;

/* instance variables */
    global Class C;
    String ClassPackageDirectory;

/* method implementations */
    void Initialize () {
	SuperInitialize ();
	ClassPackageDirectory=>NewFromArrayOfChar (":class-packages");
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

	      case ClassPackageCommands::Add: Add (argv); break;
	      case ClassPackageCommands::AddMirror: AddMirror (argv); break;
	      case ClassPackageCommands::ChangeMode: ChangeMode (argv); break;
	      case ClassPackageCommands::Delete: Delete (argv); break;
	      case ClassPackageCommands::DeleteMirror: DeleteMirror (argv);
		break;
	      case ClassPackageCommands::Describe: Describe (argv); break;
	      case ClassPackageCommands::Destroy: Destroy (argv); break;
	      case ClassPackageCommands::List: List (argv); break;
	      case ClassPackageCommands::ListMirrors: ListMirrors (argv);break;
	      case ClassPackageCommands::ListNames: ListNames (argv); break;
	      case ClassPackageCommands::Name: Name (argv); break;
	      case ClassPackageCommands::Pack: Pack (argv); break;
	      case ClassPackageCommands::SetClass: SetClass (argv); break;
	      case ClassPackageCommands::SetDir: SetDir (argv); break;
	      case ClassPackageCommands::SetMirror: SetMirror (argv); break;
	      case ClassPackageCommands::Unname: Unname (argv); break;
	      case ClassPackageCommands::UnsetMirror: UnsetMirror (argv);break;
	    }
	} else {
	    TypeStr ("Unknown command ");
	    TypeString (f);
	    TypeStr (".\n");
	}
    }

    void SetCommandHash () {
	SuperSetCommandHash ();

	/* class package maintenance */
	AddCommand ("add", ClassPackageCommands::Add);
	AddCommand ("addmirror", ClassPackageCommands::AddMirror);
	AddCommand ("changemode", ClassPackageCommands::ChangeMode);
	AddCommand ("delete", ClassPackageCommands::Delete);
	AddCommand ("deletemirror", ClassPackageCommands::DeleteMirror);
	AddCommand ("describe", ClassPackageCommands::Describe);
	AddCommand ("destroy", ClassPackageCommands::Destroy);
	AddCommand ("list", ClassPackageCommands::List);
	AddCommand ("listmirrors", ClassPackageCommands::ListMirrors);
	AddCommand ("listnames", ClassPackageCommands::ListNames);
	AddCommand ("name", ClassPackageCommands::Name);
	AddCommand ("pack", ClassPackageCommands::Pack);
	AddCommand ("setclass", ClassPackageCommands::SetClass);
	AddCommand ("setdir", ClassPackageCommands::SetDir);
	AddCommand ("setmirror", ClassPackageCommands::SetMirror);
	AddCommand ("unname", ClassPackageCommands::Unname);
	AddCommand ("unsetmirror", ClassPackageCommands::UnsetMirror);
    }

    void SetHelpMessages () {
	SuperSetHelpMessages ();

	AddHelp ("add",
		 "add <ClassPackage> <CID1> <CID2> ...\n\n"
		 "add adds a series of class IDs <CID1>, <CID2>, ... to a "
		 "class pakcage <ClassPackage>.  Adding an already included "
		 "class ID has no effect.  <ClassPackage> must be a class "
		 "package name (given with the pack command) or a class "
		 "package ID.");

	AddHelp ("addmirror",
		 "addmirror <ClassPackage> <Class> <Mode>\n\n"
		 "addmirror adds a class object <Class> as a mirror of the "
		 "class package <ClassPackage> in mode <Mode>.  <Mode> must "
		 "be one of following:\n"
		 "  o copy       ... copy on write\n"
		 "                   mirrored class parts are copied "
		 "immediately after\n"
		 "                   updation of their originals.\n"
		 "  o invalidate ... write invalidate\n"
		 "                   mirrored class parts are copied at first "
		 "access\n"
		 "                   after updation of their originals.\n"
		 "  o polling    ... currently not supported.\n"
		 "Because this command simply adds <Class> to <ClassPackage> "
		 "and doesn't care about mirrors at <Class>, inappropriate "
		 "use of this command makes inconsistent status between "
		 "original and mirrored class packages.  Thus, using of this "
		 "command should be limited for testing and recovery from "
		 "inconsistent status of mirroring due to a severe accident.  "
		 "You should use a command setmirror to set up a mirror.");

	AddHelp ("changemode",
		 "changemode <ClassPackage> <Mode>\n\n"
		 "changemode changes a mirror mode of a mirrored class "
		 "package <ClassPackage> to <Mode>.  <Mode> must be one of "
		 "following:\n"
		 "  o copy       ... copy on write\n"
		 "                   mirrored class parts are copied "
		 "immediately after\n"
		 "                   updation of their originals.\n"
		 "  o invalidate ... write invalidate\n"
		 "                   mirrored class parts are copied at first "
		 "access after\n"
		 "                   updation of their originals.\n"
		 "  o polling    ... currently not supported.\n"
		 "<ClassPackage> must be a class package name (given with the "
		 "pack command) or a class package ID.");

	AddHelp ("delete", "delete <ClassPackage> <CID1> <CID2> ...\n\n"
		 "delete deletes a series of class IDs <CID1>, <CID2>, ... "
		 "from a class package <ClassPackage>.  Deleting a "
		 "non-existing class ID causes an error.  <ClassPackage> must "
		 "be a class package name (given with the pack command) or a "
		 "class package ID.");

	AddHelp ("deletemirror",
		 "deletemirror <ClassPackage> <Class>\n\n"
		 "deletemirror deletes a class object <Class> from the class "
		 "package <ClassPackage>.  Because this command simply "
		 "deletes <Class> from <ClassPackage> and doesn't take care "
		 "about mirrors at <Class>, inappropriate use of this command "
		 "makes inconsistent status between original and mirrored "
		 "class packages.  Thus, using of this command should be "
		 "limited for testing and recovery from inconsistent state of "
		 "mirroring due to a severe accident.  You should use the "
		 "command unsetmirror to eliminate a mirror.");

	AddHelp ("describe",
		 "describe <ClassPackage>\n\n"
		 "describe lists all contents of a class package "
		 "<ClassPackage>.  <ClassPackage> must be a class package "
		 "name (given with the pack command) or a class package ID.");

	AddHelp ("destroy",
		 "destroy <ClassPackage>\n\n"
		 "destroy destroies a class package <ClassPackage>.  "
		 "<ClassPackage> must be a class package name (given with the "
		 "pack command) or a class package ID.");

	AddHelp ("list",
		 "list\n\n"
		 "list lists all original class packages in the class "
		 "object.");

	AddHelp ("listmirrors",
		 "listmirrors\n\n"
		 "listmirrors lists all mirrored class packages in the class "
		 "object.");

	AddHelp ("listnames",
		 "listnames\n\n"
		 "listnames lists all names in the class package directory in "
		 "the name directory.  The class package directory is set by "
		 "setdir command (it defaults to \":class-packages\").");

	AddHelp ("name",
		 "name <ClassPackageID> <ClassPackageName>\n\n"
		 "name registers a class package <ClassPackageID> to the name "
		 "directory with a name <ClassPackageName>.");

	AddHelp ("pack",
		 "pack <PackageName> <PackageMode> [<ClassPackageName>]\n\n"
		 "pack packs all public IDs in a package <PackageName> in the "
		 "catalog into a class package, registers it to the target "
		 "class, and gives a name <ClassPackageName> to the package.  "
		 "All kind of copies can be packed.  <PackageMode> must be "
		 "one of the following:\n"
		 "  o public ... only public parts in the package are "
		 "packed.\n"
		 "  o exec   ... public parts in the package, their "
		 "configured classes,\n"
		 "               and their implementation parts used in the "
		 "configured\n"
		 "               classes are packed.  The configured classes "
		 "are taken\n"
		 "               from the configuration table in the "
		 "package.  If it\n"
		 "               doesn't exist, default configured classes "
		 "are used.\n"
		 "  o all    ... public parts in the package, their all lower "
		 "parts (i.e.,\n"
		 "               protected and implementation parts of all "
		 "versions),\n"
		 "               their root parts, and all their configured "
		 "classes are\n"
		 "               packed.\n"
		 "After successfull registration, a new class package ID "
		 "given to the class package is shown.  Without a "
		 "<ClassPackageName> argument, pack gives no name to the "
		 "class package.");

	AddHelp ("setclass",
		 "setclass [<Class>]\n\n"
		 "setclass sets a class object <Class> as a target class of "
		 "this service interface.  All commands are directed to the "
		 "target class.  <Class> must be a name of a class object or "
		 "a global object ID.  With no argument, setclass sets a "
		 "local class object as a target class.");

	AddHelp ("setdir",
		 "setdir [<DirectoryName>]\n\n"
		 "setdir sets the class package directory in the name "
		 "directory to <DirectoryName>.  If it doesn't exists, "
		 "whether it should be newly made is asked.  If "
		 "<DirectoryName> is omitted, the default value "
		 "\":class-packages\" is used instead.");

	AddHelp ("setmirror",
		 "setmirror <ClassPackage> <Class> <Mode>\n\n"
		 "setmirror sets a mirrored class package at the target class "
		 "mirroring a class package <ClassPackage> at a class object "
		 "<Class>.  <Mode> must be one of following:\n"
		 "  o copy       ... copy on write\n"
		 "                   mirrored class parts are copied "
		 "immediately after\n"
		 "                   updation of their originals.\n"
		 "  o invalidate ... write invalidate\n"
		 "                   mirrored class parts are copied at first "
		 "access after\n"
		 "                   updation of their originals.\n"
		 "  o polling    ... currently not supported.\n"
		 "<ClassPackage> must be a class package name (given with the "
		 "pack command) or a class package ID.");

	AddHelp ("unname",
		 "unname <ClassPackageName>\n\n"
		 "unname unregisters a class package name from the name "
		 "directory.  <ClassPackageName> must be a class package name "
		 "(given with the pack command).");

	AddHelp ("unsetmirror",
		 "unsetmirror <ClassPackage>\n\n"
		 "usnetmirror unsets a mirrored class package and the "
		 "contents of the class package become snapshots.  "
		 "<ClassPackage> must be a class package name (given with "
		 "the pack command) or a class package ID.");
    }

    void SetOneLineHelp () {
	SuperSetOneLineHelp ();

	AddOneLineHelp ("add", "Add class parts to a class package.");
	AddOneLineHelp ("addmirror",
		"Add a mirror to original class package (handle with care).");
	AddOneLineHelp ("changemode", "Change mirror mode of a mirror.");
	AddOneLineHelp ("delete", "Delete class parts from a class package.");
	AddOneLineHelp ("deletemirror",
	"Delete a mirror from original class package (handle with care).");
	AddOneLineHelp ("describe", "List contents of a class package.");
	AddOneLineHelp ("destroy", "Destroy a class package.");
	AddOneLineHelp ("list", "List original class packages.");
	AddOneLineHelp ("listmirrors", "List mirrored class packages.");
	AddOneLineHelp ("listnames", "List class package names.");
	AddOneLineHelp ("name", "Name a class package.");
	AddOneLineHelp ("pack", "Pack class parts to be a class package.");
	AddOneLineHelp ("setclass", "Set Class Object to be operated.");
	AddOneLineHelp ("setdir", "Set class package directory.");
	AddOneLineHelp ("setmirror", "Mirror a class package.");
	AddOneLineHelp ("unname", "Make a class package no name.");
	AddOneLineHelp ("unsetmirror", "Unset a mirror.");
    }

    void CheckTargetClass () {
	if (C == 0) {
	    TargetClassNotSet ();
	    raise Abort;
	}
    }

    void Add (OrderedCollection <String> argv) {
	unsigned int i, len = argv->Size ();
	global ClassPackageID cpid;
	global ClassID cids [];

	CheckTargetClass ();
	CheckArgSize (len, 3, 0);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	len -= 2;
	length cids = len;
	for (i = 0; i < len; i ++) {
	    cids [i] = narrow (ClassID, StringToOID (argv->RemoveFirst ()));
	}
	C->AddToClassPackage (cpid, cids);
    }

    void AddMirror (OrderedCollection <String> argv) {
	global ClassPackageID cpid;
	global Class to;
	String mode_str;
	int mode;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 4, 4);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	to = GetClassFromName (argv->RemoveFirst ());
	mode_str = argv->RemoveFirst ();
	if (mode_str->IsEqualToArrayOfChar ("copy")) {
	    mode = MirrorMode::CopyOnWrite;
	} else if (mode_str->IsEqualToArrayOfChar ("invalidate")) {
	    mode = MirrorMode::WriteInvalidate;
	} else if (mode_str->IsEqualToArrayOfChar ("polling")) {
	    mode = MirrorMode::Polling;
	} else {
	    TypeStr ("Unknwon mirror mode ");
	    TypeString (mode_str);
	    TypeReturn ();
	    raise Abort;
	}
	C->RegisterMirror (to, cpid, mode);
    }

    void ChangeMode (OrderedCollection <String> argv) {
	global ClassPackageID cpid;
	String mode_str;
	int mode;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 3, 3);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	mode_str = argv->RemoveFirst ();
	if (mode_str->IsEqualToArrayOfChar ("copy")) {
	    mode = MirrorMode::CopyOnWrite;
	} else if (mode_str->IsEqualToArrayOfChar ("invalidate")) {
	    mode = MirrorMode::WriteInvalidate;
	} else if (mode_str->IsEqualToArrayOfChar ("polling")) {
	    mode = MirrorMode::Polling;
	} else {
	    TypeStr ("Unknwon mirror mode ");
	    TypeString (mode_str);
	    TypeReturn ();
	    raise Abort;
	}
	C->ChangeMirrorMode (cpid, mode);
    }

    void Delete (OrderedCollection <String> argv) {
	unsigned int i, len = argv->Size ();
	global ClassPackageID cpid;
	global ClassID cids [];

	CheckTargetClass ();
	CheckArgSize (len, 3, 0);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	len -= 2;
	length cids = len;
	for (i = 0; i < len; i ++) {
	    cids [i] = narrow (ClassID, StringToOID (argv->RemoveFirst ()));
	}
	C->DeleteFromClassPackage (cpid, cids);
    }

    void DeleteMirror (OrderedCollection <String> argv) {
	global ClassPackageID cpid;
	global Class to;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 3, 3);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	to = GetClassFromName (argv->RemoveFirst ());
	C->UnregisterMirror (to, cpid);
    }

    void Describe (OrderedCollection <String> argv) {
	String name;
	global ClassPackageID cpid;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	name = argv->RemoveFirst ();
	cpid = StringToPackageID (name);
	if (C->IsOriginalClassPackage (cpid)) {
	    OriginalClassPackage ocp = C->GetOriginalClassPackage (cpid);

	    TypeStr ("Original Class Package ");
	    TypeOID (cpid);
	    TypeStr (":\n");
	    TypeStr ("To be propagated to:\n");
	    DescribeToBePropagated (ocp);
	    TypeStr ("Dead mirrors:\n");
	    ListOIDs (ocp->ListDeadList ());
	    TypeStr ("Contents:\n");
	    ListOIDs (ocp->SetOfContents ());
	} else if (C->IsMirroredClassPackage (cpid)) {
	    MirroredClassPackage mcp = C->GetMirroredClassPackage (cpid);

	    TypeStr ("Mirrored Class Package ");
	    TypeOID (cpid);
	    TypeStr (":\n");
	    TypeStr ("Mirrored from ");
	    TypeOID (mcp->GetOriginal ());
	    TypeReturn ();
	    TypeStr ("Mirror mode: ");
	    switch (mcp->GetMirrorMode ()) {
	      case MirrorMode::CopyOnWrite:
		TypeStr ("copy-on-write\n");
		break;
	      case MirrorMode::WriteInvalidate:
		TypeStr ("write-invalidate\n");
		break;
	      case MirrorMode::Polling:
		TypeStr ("polling\n");
		break;
	      default:
		TypeStr ("unknown??\n");
		break;
	    }
	    TypeStr ("Contents:\n");
	    ListOIDs (mcp->SetOfContents ());
	} else {
	    TypeStr ("Unknown class package ");
	    TypeString (name);
	    TypeReturn ();
	    raise Abort;
	}
    }

    void DescribeToBePropagated (OriginalClassPackage ocp) {
	global Class classes [] = ocp->ListToBePropagated ();
	unsigned int max_rows = GetVariable ("Rows")->AtoI ();
	unsigned int max_columns = GetVariable ("Columns")->AtoI ();
	unsigned int i, len = length classes, col = 0, rows = 0;

	for (i = 0; i < len; i ++) {
	    TypeOID (classes [i]);
	    switch (ocp->WhichMirrorMode (classes [i])) {
	      case MirrorMode::CopyOnWrite:
		TypeStr (" copy-on-write    ");
		break;
	      case MirrorMode::WriteInvalidate:
		TypeStr (" write-invalidate ");
		break;
	      default:
		TypeStr (" unknown          ");
		break;
	    }
	    col += 34;
	    if (col + 34 > max_columns) {
		TypeReturn ();
		col = 0;
		rows ++;
		if ((rows + 1) % (max_rows - 1) == 0) {
		    if (BreakScroll ()) {
			break;
		    }
		}
	    }
	}
	if (col != 0) {
	    TypeReturn ();
	}
    }

    void Destroy (OrderedCollection <String> argv) {
	global ClassPackageID cpid;

	CheckTargetClass ();
	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	C->DestroyClassPackage (cpid);
    }

    void List (OrderedCollection <String> argv) {
	CheckTargetClass ();
	CheckArgSize (argv->Size (), 1, 1);
	ListOIDs (C->ListOriginalClassPackages ());
    }

    void ListMirrors (OrderedCollection <String> argv) {
	CheckTargetClass ();
	CheckArgSize (argv->Size (), 1, 1);
	ListOIDs (C->ListMirrors ());
    }

    void ListNames (OrderedCollection <String> argv) {
	global NameDirectory nd;
	Set <String> s;
	Iterator <String> i;
	String st;
	unsigned int max_rows = GetVariable ("Rows")->AtoI ();
	unsigned int max_columns = GetVariable ("Columns")->AtoI ();
	unsigned int j, len, longest = 0, col = 0, rows = 0;

	CheckArgSize (argv->Size (), 1, 1);
	nd = Where ()->GetNameDirectory ();
	try {
	    if (nd->IsaDirectory (ClassPackageDirectory)) {
		s = nd->List (ClassPackageDirectory);
		for (i=>New (s); (st = i->PostIncrement ()) != 0;) {
		    len = st->Length ();
		    if (longest < len) {
			longest = len;
		    }
		}
		i->Finish ();
		for (i=>New (s); (st = i->PostIncrement ()) != 0;) {
		    len = st->Length ();
		    TypeString (st);
		    for (j = 0; j < longest + 1 - len; j ++) {
			TypeStr (" ");
		    }
		    st = ClassPackageDirectory
		      ->ConcatenateWithArrayOfChar (":")->Concatenate (st);
		    if (nd->IsaDirectory (st)) {
			TypeStr ("directory       ");
		    } else {
			TypeOID (nd->Resolve (st));
		    }
		    col += longest + 18;
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
		return;
	    }
	} except {
	    DirectoryExceptions::UnknownDirectory (path) {}
	}
	TypeStr ("There is no directory named ");
	TypeString (ClassPackageDirectory);
	TypeReturn ();
	TypeStr ("Try setdir.\n");
    }

    void ListOIDs (global Object oids []) {
	unsigned int max_rows = GetVariable ("Rows")->AtoI ();
	unsigned int max_columns = GetVariable ("Columns")->AtoI ();
	unsigned int i, len = length oids, col = 0, rows = 0;

	for (i = 0; i < len; i ++) {
	    TypeOID (oids [i]);
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
	if (col != 0) {
	    TypeReturn ();
	}
    }

    void Name (OrderedCollection <String> argv) {
	global ClassPackageID cpid;
	String name;
	global NameDirectory nd;

	CheckArgSize (argv->Size (), 3, 3);
	argv->RemoveFirst ();
	cpid = narrow (ClassPackageID, StringToOID (argv->RemoveFirst ()));
	name
	  = ClassPackageDirectory
	    ->ConcatenateWithArrayOfChar (":")
	      ->Concatenate (argv->RemoveFirst ());
	nd = Where ()->GetNameDirectory ();
	nd->AddObject (name, cpid);
    }

    void Pack (OrderedCollection <String> argv) {
	unsigned int len = argv->Size ();
	String package_name, class_package_name, mode;
	global Catalog catalog;
	Package package;
	ClassPackage cp;
	global ClassPackageID cpid;
	global NameDirectory nd;

	CheckTargetClass ();
	CheckArgSize (len, 3, 4);
	argv->RemoveFirst ();
	package_name = argv->RemoveFirst ();
	mode = argv->RemoveFirst ();
	if (len == 4) {
	    class_package_name
	      = ClassPackageDirectory
		->ConcatenateWithArrayOfChar (":")
		  ->Concatenate (argv->RemoveFirst ());
	} else {
	    class_package_name = 0;
	}
	nd = Where ()->GetNameDirectory ();
	catalog = narrow (Catalog, nd->ResolveWithArrayOfChar (":catalog"));
	package = catalog->Retrieve (package_name);
	if (mode->IsEqualToArrayOfChar ("public")) {
	    cp = PackPublic (package);
	} else if (mode->IsEqualToArrayOfChar ("exec")) {
	    cp = PackExec (package);
	} else if (mode->IsEqualToArrayOfChar ("all")) {
	    cp = PackAll (package);
	} else {
	    TypeStr ("Unkown pack mode ");
	    TypeString (mode);
	    TypeReturn ();
	    raise Abort;
	}
	cpid = C->RegisterClassPackage (cp);
	if (class_package_name != 0) {
	    nd->AddObject (class_package_name, cpid);
	}
    }

    ClassPackage PackAll (Package package) {
	School school = package->GetSchool ();
	Set <String> names = school->ListNames ();
	String st;
	ArchitectureID aid=>Any ();
	ConfigurationTable conf_table = package->GetConfigurationTable ();
	global ConfiguredClassID ccid;
	global VersionID root, pub;
	global Class c;
	global VersionID protids [], implids [];
	unsigned int j, len;
	Iterator <String> i;
	ClassPackage cp=>New ();

	for (i=>New (names); (st = i->PostIncrement ()) != 0;) {
	    pub = school->VersionIDOf (st);
	    cp->Add (pub);
	    root = C->GetUpperPart (pub);
	    cp->Add (root);
	    protids = C->GetLowerVersions (pub);
	    cp->AddArray (protids);
	    len = length protids;
	    for (j = 0; j < len; j ++) {
		c = Where ()->SearchClass (protids [j], aid);
		implids = c->GetLowerVersions (protids [j]);
		cp->AddArray (implids);
	    }
	    ccid = 0;
	    if (conf_table != 0) {
		ccid = conf_table->Lookup (pub);
	    }
	    if (ccid == 0) {
		ccid = C->GetDefaultConfiguredClassID (pub);
	    }
	    if (ccid != 0) {
		cp->Add (ccid);
	    }
	}
	i->Finish ();
	return cp;
    }

    ClassPackage PackExec (Package package) {
	School school = package->GetSchool ();
	Set <String> names = school->ListNames ();
	String st;
	ArchitectureID aid=>Any ();
	ConfigurationTable conf_table = package->GetConfigurationTable ();
	global VersionID pub, impl;
	global ConfiguredClassID ccid;
	global VersionID vids [];
	global Class c;
	unsigned int len;
	Iterator <String> i;
	ClassPackage cp=>New ();

	for (i=>New (names); (st = i->PostIncrement ()) != 0;) {
	    ccid = 0;
	    pub = school->VersionIDOf (st);
	    cp->Add (pub);
	    if (conf_table != 0) {
		ccid = conf_table->Lookup (pub);
	    }
	    if (ccid == 0) {
		ccid = C->GetDefaultConfiguredClassID (pub);
	    }
	    if (ccid != 0) {
		cp->Add (ccid);
		c = Where ()->SearchClass (ccid, aid);
		vids = c->GetImplementationParts (ccid);
		len = length vids;
		if (len != 0) {
		    impl = vids [len - 1];
		    if (impl != 0) {
			cp->Add (impl);
		    }
		}
	    }
	}
	i->Finish ();
	return cp;
    }

    ClassPackage PackPublic (Package package) {
	School school = package->GetSchool ();
	Set <String> names = school->ListNames ();
	String st;
	ClassPackage cp=>New ();
	Iterator <String> i;

	for (i=>New (names); (st = i->PostIncrement ()) != 0;) {
	    cp->Add (school->VersionIDOf (st));
	}
	i->Finish ();
	return cp;
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

    void SetDir (OrderedCollection <String> argv) {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	unsigned int i, len = argv->Size (), name_len;
	String name, prompt;

	CheckArgSize (len, 1, 2);
	argv->RemoveFirst ();
	if (len == 2) {
	    name = argv->RemoveFirst ();
	} else {
	    name=>NewFromArrayOfChar (":class-packages");
	}
	name_len = name->Length ();
	if (name->At (name_len - 1) == ':') {
	    if (name_len == 1) {
		name=>NewFromArrayOfChar ("");
	    } else {
		name = name->GetSubString (0, name_len - 1);
	    }
	    -- name_len;
	}
	if (name_len != 0 && name->At (0) != ':') {
	    TypeStr ("Not a correct directory path: ");
	    TypeString (name);
	    TypeReturn ();
	    raise Abort;
	}
	try {
	    if (nd->IsaDirectory (name)) {
		ClassPackageDirectory = name;
		return;
	    }
	} except {
	  DirectoryExceptions::UnknownDirectory (path) {}
	}
	TypeStr ("Unknown directory ");
	TypeString (name);
	TypeReturn ();
	TypeStr ("Do you want to make it (y/n) ? [n] ");
	if (ReadYN (0)) {
	    try {
		nd->MakeDirectory (name);
		ClassPackageDirectory = name;
		return;
	    } except {
	      DirectoryExceptions::OverWriteProhibited (name) {
		  TypeStr ("Cannot make directory ");
		  TypeString (name);
		  TypeReturn ();
		  raise Abort;
	      }
	    }
	} else {
	    raise Abort;
	}
    }

    void SetMirror (OrderedCollection <String> argv) {
	unsigned int len = argv->Size ();
	global ClassPackageID cpid;
	global Class from;
	String mode_str;
	int mode;

	CheckTargetClass ();
	CheckArgSize (len, 4, 4);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	from = GetClassFromName (argv->RemoveFirst ());
	mode_str = argv->RemoveFirst ();
	if (mode_str->IsEqualToArrayOfChar ("copy")) {
	    mode = MirrorMode::CopyOnWrite;
	} else if (mode_str->IsEqualToArrayOfChar ("invalidate")) {
	    mode = MirrorMode::WriteInvalidate;
	} else if (mode_str->IsEqualToArrayOfChar ("polling")) {
	    mode = MirrorMode::Polling;
	} else {
	    TypeStr ("Unknwon mirror mode ");
	    TypeString (mode_str);
	    TypeReturn ();
	    raise Abort;
	}
	C->SetMirror (from, cpid, mode);
    }

    void Unname (OrderedCollection <String> argv) {
	String name;
	global NameDirectory nd;

	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	name = ClassPackageDirectory
	  ->ConcatenateWithArrayOfChar (":")
	    ->Concatenate (argv->RemoveFirst ());
	nd = Where ()->GetNameDirectory ();
	nd->RemoveObjectWithName (name);
    }

    void UnsetMirror (OrderedCollection <String> argv) {
	unsigned int len = argv->Size ();
	global ClassPackageID cpid;

	CheckTargetClass ();
	CheckArgSize (len, 2, 2);
	argv->RemoveFirst ();
	cpid = StringToPackageID (argv->RemoveFirst ());
	C->UnsetMirror (cpid);
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

    global Class GetClassFromName (String name) {
	global Class c;

	try {
	    c = narrow (Class, Where ()->GetNameDirectory ()->Resolve (name));
	} except {
	    default {
		c = 0;
	    }
	}
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

    global ClassPackageID StringToPackageID (String s) {
	global NameDirectory nd = Where ()->GetNameDirectory ();
	String name;
	global ResolvableObject o;
	global ClassPackageID cpid;

	name
	  = ClassPackageDirectory
	    ->ConcatenateWithArrayOfChar (":")->Concatenate (s);
	if ((o = nd->Resolve (name)) == 0) {
	    TypeStr ("Unknown class package name ");
	    TypeString (s);
	    TypeReturn ();
	    TypeStr ("Trying it as global Object ID ...\n");
	    cpid = narrow (ClassPackageID, StringToOID (s));
	} else {
	    cpid = narrow (ClassPackageID, o);
	}
	return cpid;
    }

    void TargetClassNotSet () {
	TypeStr ("Target class has not been set.  Try help setclass.\n");
    }

    String Title () {
	String title=>NewFromArrayOfChar ("Class Package Maintainance Tool");

	return title;
    }
}
