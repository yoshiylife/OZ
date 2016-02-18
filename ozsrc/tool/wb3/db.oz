/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class DirectoryBrowser<Directory, Entry> : GUI 
	( rename Open SuperOpen; 
	  rename Quit SuperQuit; )
{
 constructor: 
  New;
   
 public: 
  Launch, SetPath, Quit, Import, SelectPath;

 protected:
  aDirectory, Path, Owner, Retrieve, Export, ListNames;
   
  global Directory aDirectory;
  String Path;

  EntryBrowser aEB;

  global Object Owner;
  char Name[];

  condition selected;
  String SelectedPath;

  void New (global Object owner, char name[]) : global
    {
      String s;
      UnixIO debugp=>New ();
       
      aDirectory = narrow (Directory,
			   Where() ->GetNameDirectory ()
			   ->Resolve (s=>NewFromArrayOfChar (name)));
      
      debugp->PutStr ("Directory = ")->PutOID (aDirectory)->PutReturn ();

      Path=>NewFromArrayOfChar ("");

      Name = name;
      Owner = owner;
    }
  
  int ReadEvent ()
    {
      String args[] = RecvCommandArgs ();
      
      if (CommandIs ("Quit"))
	{
	  Quit ();
	  return 1;
	}
      
      else if (CommandIs ("ChangeDirectory"))
	ChangeDirectory (args[0]);
       
      else if (CommandIs ("OpenEntry"))
	OpenEntry (args[0]);
       
      else if (CommandIs ("NewDirectory"))
	NewDirectory (args[0], args[1]);
       
      else if (CommandIs ("DeleteEntry"))
	{
	  String entries[] = SplitList (args[1]);
	  
	  DeleteEntry (args[0], entries);
	}
       
      else if (CommandIs ("DeleteDirectory"))
	{
	  String entries[] = SplitList (args[1]);
	   
	  DeleteDirectory (args[0], entries);
	}

      else if (CommandIs ("SelectEntry"))
	{
	  String entries[] = SplitList (args[0]);
	  
	  Export (entries);
	}
      
      else if (CommandIs ("SelectDirectory"))
	SelectDirectory (args[0]);
      
      return 0;
    }
   
  void Open (String path)
    {
      char args[][];
      
      length args = Owner ? 2 : 3;
      args[0] = "lib/gui/wb2/db.tcl";
      args[1] = Name;
      if (!Owner)
	args[2] = "noselect";
      StartWish (args, ':', '|');
    }
  
  void ShowEntries (String path, String dirs[], String entries[])
    {
      char args[][];
      String dir_list = CreateList (dirs);
      String entry_list = CreateList (entries);
      
      length args = 3;
      args[0] = path->Content ();
      args[1] = dir_list->Content ();
      args[2] = entry_list->Content ();
      
      ExecProc ("Open", args);
    }
  
  void AddEntries (String path, String entries[])
    {
      char args[][];
      String entry_list = CreateList (entries);
      
      length args = 2;
      args[0] = path->Content ();
      args[1] = entry_list->Content ();
      
      ExecProc ("AddEntries", args);
    }
  
  void NewEntry (String path, String name)
    {
      char args[][];
      
      length args = 2;
      args[0] = path->Content ();
      args[1] = name->Content ();
      
      ExecProc ("NewEntry", args);
    }
  
  void Quit () : global, locked
    {
      if (aEB)
	{
	  aEB->Quit ();
	  aEB = 0;
	}

      SelectedPath = 0;
      signal selected;

      ExecProc ("Quit", 0);
    }

  void ChangeDirectory (String path)
    {
      if (!path)
	path=>NewFromArrayOfChar ("");

      Path = path;

      List (path);
    }

  void NewDirectory (String current, String name)
    {
       String new;

       if (!current)
	 current=>NewFromArrayOfChar ("");

       new = current->ConcatenateWithArrayOfChar (":")->Concatenate (name);
       
       aDirectory->NewDirectory (new);

       NewEntry (current, name);

       Save ();
     }

   void Launch () : global
     {
       Open (Path);

       if (aDirectory)
	 List (Path);
     }

  void List (String path)
     {
       String dirs[], entries[];
       global DirectoryServer <Entry> ds = aDirectory;

       dirs = aDirectory->ListDirectory (path)->AsArray ();
       entries = ds->ListEntry (path)->AsArray ();
       ShowEntries (path, dirs, entries);
     }

   void Import (String target, 
		String entry_names[], Entry entries[]) : global, locked
     {
       int i, len = length entry_names;
       String path;
       char args[];

       length args = 3;

       for (i = 0; i < len; i++)
	 {
	   path = target->ConcatenateWithArrayOfChar (":")
	     ->Concatenate (entry_names[i]);

	   try 
	     {
	       aDirectory->Register (path, entries[i]);
	     }
	   except
	     {
	     DirectoryExceptions::OverWriteProhibited (p)
	       {
		 entry_names[i] = AddSuffix (Path, entry_names[i], 
					      entries[i]);
	       }
	     }
	 }

       AddEntries (Path, entry_names);

       Save ();
     }

   void Save ()
     {
       global Object o = aDirectory;

       o->Flush ();
     }

   void DeleteEntry (String path, String entries[])
     {
       int i, len = length entries;
       String buf;

       if (!path)
	 path=>NewFromArrayOfChar ("");

       for (i = 0; i < len; i++)
	 {
	   buf = path->ConcatenateWithArrayOfChar (":")
	     ->Concatenate (entries[i]);
	   aDirectory->Remove (buf);
	 }
       
       Save ();
     } 

   void DeleteDirectory (String path, String entries[])
     {
       int i, len = length entries;
       String buf;

       if (!path)
	 path=>NewFromArrayOfChar ("");

       for (i = 0; i < len; i++)
	 {
	   buf = path->ConcatenateWithArrayOfChar (":")
	     ->Concatenate (entries[i]);
	   aDirectory->RemoveDirectory (buf);
	 }

       Save ();
     }

  String AddSuffix (String path, String name, Entry entry)
    {
      String new;
      int i = 0;
      char num[];

      length num = 3;

      name = name->ConcatenateWithArrayOfChar (".");

      for (i = 0; ; i++)
	{
	  if (i > 10)
	    {
	      num[0] = i / 10 + '0';
	      num[1] = i % 10 + '0';
	      num[2] = 0;
	    }

	  else 
	    {
	      num[0] = i % 10 + '0';
	      num[1] = 0;
	    }

	  new = name->ConcatenateWithArrayOfChar (num);

	  try 
	    {
	      aDirectory->Register (path->ConcatenateWithArrayOfChar (":")
			     ->Concatenate (new), entry);
	      break;
	    }
	  except
	    {
	    DirectoryExceptions::OverWriteProhibited (p)
	      {
	      }
	    }
	 }

      return new;
    }

  void OpenEntry (String entry_name)
    {
      Entry entry;
      String name;
      
      if (!aEB)
	aEB=>New ();
      
      name = Path->ConcatenateWithArrayOfChar (":")->Concatenate (entry_name);
      entry = aDirectory->Retrieve (name);

      aEB->Launch (name, ListNames (entry));
    }

  void SetPath (String path) : global
    {
      Path = path;
    }

  Entry Retrieve (String entry_names[])[]
     {
       int i, len = length entry_names;
       Entry entries[];
       String buf;

       length entries = len;

       for (i = 0; i < len; i++)
	 {
	   buf = Path->ConcatenateWithArrayOfChar (":")
	     ->Concatenate (entry_names[i]);
	   entries[i] = aDirectory->Retrieve (buf);
	 }

       return entries;
     }

  String SelectPath () : global, locked
    {
      char args[][];

      length args = 1;

      args[0] = "dir";

      ExecProc ("Select", args);

      wait selected;

      return SelectedPath;
    }

  void SelectDirectory (String path) : locked
    {
      if (!path)
	path=>NewFromArrayOfChar ("");

      SelectedPath = path;

      signal selected;
    }


  void Export (String entry_names [])
    {
    }

  String ListNames (Entry entry)[]
    {
    }
}
