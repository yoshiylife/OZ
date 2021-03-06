/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
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


// we distribute class not by tar'ed directory


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

class EntryBrowser : GUI 
	( alias Open SuperOpen; 
	  alias Quit SuperQuit; )
{
 constructor: 
  New;
   
 public: 
  Launch, Quit;

  void New ()
    {
      char args[][];
      
      length args = 1;
      args[0] = "lib/gui/wb2/eb.tcl";
      StartWish (args, ':', '|');
    }

  int ReadEvent ()
    {

      String args [] = RecvCommandArgs ();

      if (CommandIs ("Quit"))
	{
	    Quit ();
	    return 1;
	}

    }
      
  void Quit ()
    {
      ExecProc ("Quit", 0);
    }

  void Launch (String name, String entries[])
    {
      char args[][];
      String entry = CreateList (entries);

      length args = 2;

      args[0] = name->Content ();
      args[1] = entry->Content ();

      ExecProc ("Open", args);
    }
}
  
