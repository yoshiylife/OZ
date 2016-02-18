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
 * confchanger.oz
 *
 * configuration cache changer
 */

class ConfigurationCacheChanger
  : LaunchableWithKterm (alias Initialize SuperInitialize;) {
    constructor: New;
    public: Launch;

/* instance variables */
      global ObjectManager OM;
      global VersionID PublicID;
      global ConfiguredClassID CCID;

/* method implementations */
      void Initialize () {
	  char m1 [] = "Enter a name (or an object ID) of an ObjectManager of which you want to change the configuration cache entry in 16 hexa-decimal digits.\n> ";
	  char m2 [] = "Enter a public part ID of which you want to change the corresponding configured class ID in 16 hexa-decimal digits.\n> ";
	  char m3 [] = "Enter the configured class ID in 16 hexa-decimal digits.\n> ";

	  String title, prompt, name;
	  Console dialog;

	  SuperInitialize ();

	  title=>NewFromArrayOfChar ("Configuration Changer Parameter Setup");
	  dialog=>NewWithTitle (title);
	  dialog->Open ();
	  prompt=>NewFromArrayOfChar (m1);
	  while (OM == 0) {
	      name = Trim (ReadFromConsole (dialog, prompt));
	      if ((OM = narrow (ObjectManager,
				Where ()->GetNameDirectory ()->Resolve (name)))
		  == 0) {
		  WriteStr (dialog, "Unknown object manager name ");
		  dialog->Write (name);
		  WriteStr (dialog, ".  Trying it as global object ID...\n");
		  OM = narrow (ObjectManager, StringToOID (name, dialog));
	      }
	  }
	  prompt=>NewFromArrayOfChar (m2);
	  PublicID = narrow (VersionID, ReadOIDFromConsole (dialog, prompt));
	  prompt=>NewFromArrayOfChar (m3);
	  CCID = narrow (ConfiguredClassID,
			 ReadOIDFromConsole (dialog, prompt));
	  dialog->Close ();
      }

      void Start () {
	  TypeStr ("Changing [");
	  TypeOID (OM);
	  TypeStr ("]s configuration cache table ... ");
	  OM->ChangeConfigurationCache (PublicID, CCID);
	  TypeStr ("done.\n");
	  TypeStr ("Configured class ID of [");
	  TypeOID (PublicID);
	  TypeStr ("] is changed to [");
	  TypeOID (CCID);
	  TypeStr ("].\n");
	  TypeStr ("\nType return to close.\n");
	  Read ();
      }

      global Object StringToOID (String arg, Console dialog) {
	  global Object o;


	  o = arg->Str2OID ();

	  if (o == 0) {
	      WriteStr (dialog, "16 hex-decimal digits ([0-9a-fA-F]) are ");
	      WriteStr (dialog, "needed to represent global Object ID.\n");
	      return 0;
	  }
	  return o;
      }

      String Title () {
	  String title=>NewFromArrayOfChar ("Configuration Changer");

	  return title;
      }
  }
