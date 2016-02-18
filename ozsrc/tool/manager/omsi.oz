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
 * omsi.oz
 *
 * Service interface of ObjectManager
 */

class ObjectManagerServiceInterface :
  CommandInterpreter (alias Initialize SuperInitialize;
		      alias SetCommandHash SuperSetCommandHash;
		      alias SetHelpMessages SuperSetHelpMessages;
		      alias SetOneLineHelp SuperSetOneLineHelp;)
{
  constructor: New;
  public: Launch;
  protected: ForkSearchClass;

/* instance variables */
    char StatusString [][];

/* method implementations */
    void Initialize () {
	SuperInitialize ();
	length StatusString = 11;
	StatusString [0] = "Illegal Status 0";
	StatusString [1] = "Frozen";
	StatusString [2] = "Melting";
	StatusString [3] = "MeltingToStop";
	StatusString [4] = "Running";
	StatusString [5] = "SwappedOut";
	StatusString [6] = "CellingIn";
	StatusString [7] = "CellingInToStop";
	StatusString [8] = "OrderStopped";
	StatusString [9] = "Closed";
	StatusString [10] = "Removed";
    }

    void Dispatch (OrderedCollection <String> argv) {
	switch (CommandHash->AtKey (argv->First ())) {
	  case CommandInterpreterCommands::NOP: NOP (argv); break;
	  case CommandInterpreterCommands::Help: Help (argv); break;
	  case CommandInterpreterCommands::Alias: Alias (argv); break;
	  case CommandInterpreterCommands::Quit: Quit (argv); break;
	  case CommandInterpreterCommands::Show: Show (argv); break;
	  case CommandInterpreterCommands::SetVar: SetVar (argv); break;

	  case ObjectManagerCommands::CellIn: CellIn (argv); break;
	  case ObjectManagerCommands::CellOut: CellOut (argv); break;
	  case ObjectManagerCommands::Describe: Describe (argv); break;
	  case ObjectManagerCommands::Flush: FlushObject (argv); break;
	  case ObjectManagerCommands::List: List (argv); break;
	  case ObjectManagerCommands::Load: Load (argv); break;
	  case ObjectManagerCommands::Permanentize: Permanentize (argv); break;
	  case ObjectManagerCommands::Remove: Remove (argv); break;
	  case ObjectManagerCommands::Restore: Restore (argv); break;
	  case ObjectManagerCommands::Size: Size (argv); break;
	  case ObjectManagerCommands::Stop: StopObject (argv); break;
	  case ObjectManagerCommands::Suspend: Suspend (argv); break;
	  case ObjectManagerCommands::Resume: Resume (argv); break;
	  case ObjectManagerCommands::Transientize: Transientize (argv); break;
	  case ObjectManagerCommands::SearchClass: SearchClass (argv); break;
	  case ObjectManagerCommands::Preload: Preload (argv); break;
	  case ObjectManagerCommands::ClearCache: ClearCache (argv); break;
	  case ObjectManagerCommands::ChangeCache: ChangeCache (argv); break;
	  case ObjectManagerCommands::FlushCache: FlushCache (argv); break;
	  case ObjectManagerCommands::ShowCache: ShowCache (argv); break;
	  case ObjectManagerCommands::Arch: Arch (argv); break;
	  case ObjectManagerCommands::GC: GC (argv); break;
	  case ObjectManagerCommands::ChangeDomain: ChangeDomain (argv); break;
	  case ObjectManagerCommands::WhichDomain: WhichDomain (argv); break;
	  case ObjectManagerCommands::Shutdown: Shutdown (argv); break;
	}
    }

    void SetCommandHash () {
	SuperSetCommandHash ();

	/* object table */
	AddCommand ("cellin", ObjectManagerCommands::CellIn);
	AddCommand ("cellout", ObjectManagerCommands::CellOut);
	AddCommand ("describe", ObjectManagerCommands::Describe);
	AddCommand ("flush", ObjectManagerCommands::Flush);
	AddCommand ("list", ObjectManagerCommands::List);
	AddCommand ("load", ObjectManagerCommands::Load);
	AddCommand ("permanentize", ObjectManagerCommands::Permanentize);
	AddCommand ("remove", ObjectManagerCommands::Remove);
	AddCommand ("restore", ObjectManagerCommands::Restore);
	AddCommand ("size", ObjectManagerCommands::Size);
	AddCommand ("stop", ObjectManagerCommands::Stop);
	AddCommand ("suspend", ObjectManagerCommands::Suspend);
	AddCommand ("resume", ObjectManagerCommands::Resume);
	AddCommand ("transientize", ObjectManagerCommands::Transientize);

	/* lookup class */
	AddCommand ("searchclass", ObjectManagerCommands::SearchClass);

	/* preload settings */
	AddCommand ("preload", ObjectManagerCommands::Preload);

	/* configuration cache table */
	AddCommand ("clearcache", ObjectManagerCommands::ClearCache);
	AddCommand ("changecache", ObjectManagerCommands::ChangeCache);
	AddCommand ("flushcache", ObjectManagerCommands::FlushCache);
	AddCommand ("showcache", ObjectManagerCommands::ShowCache);

	/* architecture */
	AddCommand ("arch", ObjectManagerCommands::Arch);

	/* gc */
	AddCommand ("gc", ObjectManagerCommands::GC);

	/* domain */
	AddCommand ("changedomain", ObjectManagerCommands::ChangeDomain);
	AddCommand ("whichdomain", ObjectManagerCommands::WhichDomain);

	/* shutdown */
	AddCommand ("shutdown", ObjectManagerCommands::Shutdown);
    }

    void SetHelpMessages () {
	SuperSetHelpMessages ();

	AddHelp ("cellin",
		 "cellin <Object>\n\n"
		 "Sorry, currently not supported.");

	AddHelp ("cellout",
		 "cellout <Object>\n\n"
		 "Sorry, currently not supported.");

	AddHelp ("describe",
		 "describe <Object>\n\n"
		 "describe describes status of a global object <Object>.  "
		 "<Object> must be a global object ID.");

	AddHelp ("flush",
		 "flush <Object>\n\n"
		 "flush flushes a global object <Object> to its object image "
		 "file.  <Object> must be a global object ID.");

	AddHelp ("list",
		 "list\n\n"
		 "list shows the listings of global objects on the executor.");

	AddHelp ("load",
		 "load <Object>\n\n"
		 "load loads and calls a method called Go () to wake up the "
		 "object <Object>.  <Object> must be a global object ID.");

	AddHelp ("permanentize",
		 "permanentize <Object>\n\n"
		 "permanantize makes a global object <Object> permanent.  "
		 "permanent object isn't removed when the executor is going "
		 "down.  <Object> must be a global object ID.");

	AddHelp ("remove",
		 "remove <Object>\n\n"
		 "remove removes a global object <Object>.  <Object> must "
		 "be a global object ID.");

	AddHelp ("restore",
		 "restore <Object>\n\n"
		 "restore restores an object image of <Object> from its "
		 "object image file.  <Object> must be a global Object ID.");

	AddHelp ("size",
		 "size\n\n"
		 "size prints the number of global objects managed by this "
		 "object manager.");

	AddHelp ("stop",
		 "stop <Object>\n\n"
		 "stop stops a global object <Object>.  <Object> must be a "
		 "global object ID.");

	AddHelp ("suspend",
		 "suspend <Object>\n\n"
		 "suspend suspends a global object <Object>.  <Object> must "
		 "be a global object ID.");

	AddHelp ("resume",
		 "resume <Object>\n\n"
		 "resume resumes a suspended global object <Object>.  "
		 "<Object> must be a global object ID.");

	AddHelp ("transientize",
		 "transientize <Object>\n\n"
		 "transientize makes a permanet object <Object> transient.  "
		 "transientizing a transient object has no effect.  <Object> "
		 "must be a global object ID.");

	AddHelp ("searchclass",
		 "searchclass <ClassID>\n\n"
		 "Search a class part by a class ID.  If the local classes "
		 "don't have the class part, a class request is broadcasted "
		 "to the site.");

	AddHelp ("preload",
		 "preload <command> <kind> [<args> ...]\n\n"
		 "preload controls various preloading configurations.  "
		 "<command> must be one of following:\n"
		 "    list       ... Show listings.  No argument.\n"
		 "    add        ... Add entries.  Any arguments.\n"
		 "    remove     ... Remove entries.  Any arguments.\n"
		 "    isincluded ... Test if an entry is included.  An "
		 "argument.\n"
		 "An argument must be an OID (16 hexa-decimal digits).\n"
		 "<kind> must be one of following:\n"
		 "    object ... Preloading object\n"
		 "    class  ... Preloading configured class\n"
		 "    code   ... Preloading code\n"
		 "    layout ... Preloading layout");

	AddHelp ("clearcache",
		 "clearcache\n\n"
		 "Clear (make empty) configuration cache table.");

	AddHelp ("changecache",
		 "changecache <PublicVersionID> <ConfiguredClassID>\n\n"
		 "changecache changes an entry in the configuration cache "
		 "table.  The corresponding configured class ID of a public "
		 "part <PublicVersionID> is changed to <ConfiguredClassID>.  "
		 "If there is no entry of <PublicVersionID> on the cache "
		 "table, the mapping is simply added to the table.  "
		 "<PublicVersionID> and <ConfiguredClassID> must be a class "
		 "ID.");

	AddHelp ("flushcache",
		 "flushcache <PublicVersionID>\n\n"
		 "flushcache removes an entry of <PublicVersionID> in the "
		 "configuration cache table.  <PublicVersionID> must be a "
		 "class ID.");

	AddHelp ("showcache",
		 "showcache <PublicVersionID>\n\n"
		 "showcache shows the corresponding configured class ID of a "
		 "public part <PublicVersionID>.  <PublicVersionID> must be a "
		 "class ID.");

	AddHelp ("arch",
		 "arch\n\n"
		 "Sorry, currently not supported.");

	AddHelp ("gc",
		 "gc <Object>\n\n"
		 "Sorry, currently not supported.");

	AddHelp ("changedomain",
		 "changedomain <DomainName>\n\n"
		 "changedomain changes the domain of the executor to "
		 "<DomainName>.");

	AddHelp ("whichdomain",
		 "whichdomain\n\n"
		 "whichdomain shows the domain name of the executor.");

	AddHelp ("shutdown",
		 "shutdown\n\n"
		 "shutdown terminates this executor (confirmation is "
		 "required).");
    }

    void SetOneLineHelp () {
	SuperSetOneLineHelp ();

	AddOneLineHelp ("cellin", "Cell-in an object.");
	AddOneLineHelp ("cellout", "Cell-out an object.");
	AddOneLineHelp ("describe", "Describe an object.");
	AddOneLineHelp ("flush", "Flush an object.");
	AddOneLineHelp ("list", "List objects.");
	AddOneLineHelp ("load", "Load an object.");
	AddOneLineHelp ("permanentize", "Make an object persistent.");
	AddOneLineHelp ("remove", "Stop and remove an object.");
	AddOneLineHelp ("restore", "Restore an object.");
	AddOneLineHelp ("size", "Show the number of objects.");
	AddOneLineHelp ("stop", "Stop an object.");
	AddOneLineHelp ("suspend", "Suspend an object.");
	AddOneLineHelp ("resume", "Resume an object.");
	AddOneLineHelp ("transientize", "Make an object not persistent.");
	AddOneLineHelp ("searchclass", "Search a class part.");
	AddOneLineHelp ("preload", "Configure preloading settings.");
	AddOneLineHelp ("clearcache", "Clear the configuration cache.");
	AddOneLineHelp ("changecache", "Change a configuration cache entry.");
	AddOneLineHelp ("flushcache", "Flush a configuration cache entry.");
	AddOneLineHelp ("showcache", "Show a configuration cache entry.");
	AddOneLineHelp ("arch", "Show the architecture ID of this station.");
	AddOneLineHelp ("gc", "GC an object.");
	AddOneLineHelp ("changedomain", "Change the domain.");
	AddOneLineHelp ("whichdomain", "Show the domain name.");
	AddOneLineHelp ("shutdown", "Terminate this executor.");
    }

    void Shutdown (OrderedCollection <String> argv) {
	TypeStr ("Do you really shutdown this executor (y/n) ? [y] ");
	if (ReadYN (1)) {
	    Where ()->Shutdown ();
	} else {
	    TypeStr ("Shutdown is not confirmed.\n");
	}
    }

    void CellIn (OrderedCollection <String> argv) {NotSupported ();}
    void CellOut (OrderedCollection <String> argv) {NotSupported ();}

    void Describe (OrderedCollection <String> argv) {
	global Object o;
	int status;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    if (Where ()->IsPermanentObject (o)) {
		TypeStr ("Permanent");
	    } else {
		TypeStr ("Transient");
	    }
	    TypeStr (" object ");
	    TypeOID (o);
	    TypeReturn ();
	    status = Where ()->WhichStatus (o);
	    if (status >= 1 && status <= 10) {
		TypeStr ("Status: ");
		TypeStr (StatusString [status]);
	    } else {
		TypeStr ("Illegal status: ");
		TypeInt (status);
	    }
	    TypeStr (", ");
	    if (! Where ()->IsSuspendedObject (o)) {
		TypeStr ("not ");
	    }
	    TypeStr ("suspended\n");
	    if (! Where ()->WasSafelyShutdown (o)) {
		TypeStr ("Previous shutdown was not incomplete.\n");
	    }
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void FlushObject (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->FlushObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void List (OrderedCollection <String> argv) {
	global Object a [];
	unsigned int i, len;

	switch (argv->Size ()) {
	  case 1:
	    a = Where ()->ListObjects ();
	    len = length a;
	    for (i = 0; i < len; i ++) {
		TypeOID (a [i]);
		TypeReturn ();
	    }
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Load (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->LoadObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Permanentize (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->PermanentizeObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Remove (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->RemoveObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Restore (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->RestoreObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Size (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    argv->RemoveFirst ();
	    TypeInt (Where ()->Size ());
	    TypeReturn ();
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void StopObject (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->StopObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Suspend (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->SuspendObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Resume (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->ResumeObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Transientize (OrderedCollection <String> argv) {
	global Object o;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    o = StringToOID (argv->First ());
	    Where ()->TransientizeObject (o);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void ForkSearchClass (global ClassID cid, Waiter w) {
	ArchitectureID aid=>Any ();

	Where ()->SearchClass (cid, aid);
	w->Done ();
    }

    void SearchClass (OrderedCollection <String> argv) {
	global ClassID cid;
	Waiter w;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    cid = narrow (ClassID, StringToOID (argv->RemoveFirst ()));
	    w=>New ();

	    TypeStr ("Searching ... ");
	    detach fork ForkSearchClass (cid, w);
	    detach fork w->Timer (4);
	    if (w->WaitAndTest ()) {
		TypeStr ("found.\n");
	    } else {
		TypeStr ("couldn't be found.  Backgrounding ...\n");
	    }
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void UnknownKindOfPreloadingEntity (String kind) {
	TypeStr ("Unknown kind of preloading entity: ");
	TypeStr (kind->Content ());
	TypeReturn ();
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

    global Object MakeOIDArray (OrderedCollection <String> argv)[] {
	global Object oids [];
	unsigned int i, len = argv->Size ();

	length oids = len;
	for (i = 0; i < len; i ++) {
	    oids [i] = StringToOID (argv->RemoveFirst ());
	}
	return oids;
    }

    void TypeYesNo (int b) {
	if (b) TypeStr ("yes\n");
	else TypeStr ("no\n");
    }

    void Preload (OrderedCollection <String> argv) {
	global ObjectManager om = Where ();
	String command, kind;
	global Object oids [];
	global Object o;
	unsigned int i, len;

	switch (argv->Size ()) {
	  case 1:
	  case 2:
	    TooFewArguments ();
	    break;
	  default:
	    argv->RemoveFirst ();
	    command = argv->RemoveFirst ();
	    kind = argv->RemoveFirst ();

	    if (command->IsEqualToArrayOfChar ("list")) {
		switch (argv->Size ()) {
		  case 0:
		    if (kind->IsEqualToArrayOfChar ("class")) {
			global ConfiguredClassID ccids [];

			ccids = om->ListPreloadingConfiguredClasses ();
			inline "C" {
			    oids = ccids;
			}
		    } else if (kind->IsEqualToArrayOfChar ("code")) {
			global VersionID vids [];

			vids = om->ListPreloadingCodes (); 
			inline "C" {
			    oids = vids;
			}
		    } else if (kind->IsEqualToArrayOfChar ("layout")) {
			global VersionID vids [];

			vids = om->ListPreloadingLayouts (); 
			inline "C" {
			    oids = vids;
			}
		    } else if (kind->IsEqualToArrayOfChar ("object")) {
			oids = om->ListPreloadingObjects ();
		    } else {
			UnknownKindOfPreloadingEntity (kind);
		    }
		    ListOIDs (oids);
		    break;
		  default:
		    TooManyArguments ();
		    break;
		}
	    } else if (command->IsEqualToArrayOfChar ("add")) {
		switch (argv->Size ()) {
		  case 0:
		    TypeStr ("No ");
		    TypeStr (kind->Content ());
		    TypeStr (" to add?\n");
		    break;
		  default:
		    oids = MakeOIDArray (argv);
		    if (kind->IsEqualToArrayOfChar ("class")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    global ConfiguredClassID ccid;

			    ccid = narrow (ConfiguredClassID, oids [i]);
			    om->AddPreloadingConfiguredClass (ccid);
			}
		    } else if (kind->IsEqualToArrayOfChar ("code")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    om->AddPreloadingCode (narrow (VersionID,
							   oids [i]));
			}
		    } else if (kind->IsEqualToArrayOfChar ("layout")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    om->AddPreloadingLayout (narrow (VersionID,
							     oids [i]));
			}
		    } else if (kind->IsEqualToArrayOfChar ("object")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    om->AddPreloadingObject (oids [i]);
			}
		    } else {
			UnknownKindOfPreloadingEntity (kind);
		    }
		    break;
		}
	    } else if (command->IsEqualToArrayOfChar ("remove")) {
		switch (argv->Size ()) {
		  case 0:
		    TypeStr ("No ");
		    TypeStr (kind->Content ());
		    TypeStr (" to remove?\n");
		    break;
		  default:
		    oids = MakeOIDArray (argv);
		    if (kind->IsEqualToArrayOfChar ("class")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    global ConfiguredClassID ccid;

			    ccid = narrow (ConfiguredClassID, oids [i]);
			    om->RemovePreloadingConfiguredClass (ccid);
			}
		    } else if (kind->IsEqualToArrayOfChar ("code")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    om->RemovePreloadingCode (narrow (VersionID,
							      oids [i]));
			}
		    } else if (kind->IsEqualToArrayOfChar ("layout")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    om->RemovePreloadingLayout (narrow (VersionID,
								oids [i]));
			}
		    } else if (kind->IsEqualToArrayOfChar ("object")) {
			len = length oids;
			for (i = 0; i < len; i ++) {
			    om->RemovePreloadingObject (oids [i]);
			}
		    } else {
			UnknownKindOfPreloadingEntity (kind);
		    }
		    break;
		}
	    } else if (command->IsEqualToArrayOfChar ("isincluded")) {
		switch (argv->Size ()) {
		  case 0:
		    TypeStr ("No ");
		    TypeStr (kind->Content ());
		    TypeStr (" to test?\n");
		    break;
		  case 1:
		    o = StringToOID (argv->First ());
		    if (kind->IsEqualToArrayOfChar ("class")) {
			global ConfiguredClassID ccid
			  = narrow (ConfiguredClassID, o);

			TypeYesNo (om->IsaPreloadingConfiguredClass (ccid));
		    } else if (kind->IsEqualToArrayOfChar ("code")) {
			TypeYesNo (om->IsaPreloadingCode (narrow (VersionID,
								  o)));
		    } else if (kind->IsEqualToArrayOfChar ("layout")) {
			TypeYesNo (om->IsaPreloadingLayout (narrow (VersionID,
								    o)));
		    } else if (kind->IsEqualToArrayOfChar ("object")) {
			TypeYesNo (om->IsaPreloadingObject (o));
		    } else {
			UnknownKindOfPreloadingEntity (kind);
		    }
		    break;
		  default:
		    TooManyArguments ();
		    break;
		}
	    } else {
		TypeStr ("Unknown sub command name: ");
		TypeStr (command->Content ());
		TypeReturn ();
	    }
	    break;
	}
    }

    void ClearCache (OrderedCollection <String> argv) {
	switch (argv->Size ()) {
	  case 1:
	    argv->RemoveFirst ();
	    Where ()->ClearConfigurationCache ();
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void ChangeCache (OrderedCollection <String> argv) {
	global VersionID vid;
	global ConfiguredClassID ccid;

	switch (argv->Size ()) {
	  case 1:
	  case 2:
	    TooFewArguments ();
	    break;
	  case 3:
	    argv->RemoveFirst ();
	    vid = narrow (VersionID, StringToOID (argv->RemoveFirst ()));
	    ccid = narrow (ConfiguredClassID,
			   StringToOID (argv->RemoveFirst ()));
	    Where ()->ChangeConfigurationCache (vid, ccid);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void FlushCache (OrderedCollection <String> argv) {
	global VersionID vid;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    vid = narrow (VersionID, StringToOID (argv->RemoveFirst ()));
	    Where ()->ChangeConfigurationCache (vid, 0);
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void ShowCache (OrderedCollection <String> argv) {
	global VersionID vid;
	global ConfiguredClassID ccid;

	switch (argv->Size ()) {
	  case 1:
	    TooFewArguments ();
	    break;
	  case 2:
	    argv->RemoveFirst ();
	    vid = narrow (VersionID, StringToOID (argv->RemoveFirst ()));
	    ccid = Where ()->ShowConfigurationCache (vid);
	    TypeOID (ccid);
	    TypeReturn ();
	    break;
	  default:
	    TooManyArguments ();
	    break;
	}
    }

    void Arch (OrderedCollection <String> argv) {NotSupported ();}
    void GC (OrderedCollection <String> argv) {NotSupported ();}

    void ChangeDomain (OrderedCollection <String> argv) {
	String name;

	CheckArgSize (argv->Size (), 2, 2);
	argv->RemoveFirst ();
	name = argv->RemoveFirst ();
	Where ()->ChangeDomain (name->Content ());
    }

    void WhichDomain (OrderedCollection <String> argv) {
	CheckArgSize (argv->Size (), 1, 1);
	TypeStr (Where ()->WhichDomain ());
	TypeReturn ();
    }

    void SetInitialPrompt () {Prompt=>NewFromArrayOfChar ("ObjectManager> ");}

    String Title () {
	String title=>NewFromArrayOfChar ("ObjectManager Service Interface");
	return title;
    }
}
