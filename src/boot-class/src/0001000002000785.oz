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
class PackagePool : Dictionary<String, String>
  ( rename New SuperNew; 
    rename AtKey GetFile; )
{
 constructor: 
  New;
   
 public: 
  Register, Unregister, RegisterPackages, GetAll, GetFile, Convert,
  ConvertToFile;

  int count;
  int index;

  UnixIO debugp;

  void New (int i)
     {
       SuperNew ();

       count = 0;
       index = i;

       debugp=>New ();
     }

  String Register (String names[], String files[])[]
    {
      int i, len = length names;
      String file;

      if (!files)
	length files = len;

      for (i = 0; i < len; i++)
	{
	  files[i] = CreateFile (files[i]);

	  try 
	    {
	      AddAssoc (names[i], files[i]);
	    }
	  except 
	    {
	      CollectionExceptions<String>::RedefinitionOfKey (key)
		{
		  names[i] = AddSuffix (names[i]);
		  AddAssoc (names[i], file);
		}
	    }
	}
      
      return files;
    }
   
   String RegisterPackages (String names[], Package packages[])[]
    {
      int i, len = length names;
      String files[];

      files = ConvertToFile (packages);

      for (i = 0; i < len; i++)
	{
	  try 
	    {
	      AddAssoc (names[i], files[i]);
	    }
	  except 
	    {
	      CollectionExceptions<String>::RedefinitionOfKey (key)
		{
		  names[i] = AddSuffix (names[i]);
		  AddAssoc (names[i], files[i]);
		}
	    }
	 }

      return files;
    }
   
   void Unregister (String names[]) : locked
     {
       int i, len = length names;
       FileOperators fops;

       for (i = 0; i < len; i++)
	 {
	   try 
	     {
	       String buf = GetFile (names[i]);

	       fops.Remove (buf);
	       fops.Remove (buf->ConcatenateWithArrayOfChar ("-cfedrc"));
	     }
	   except
	     {
	       default
		 {
		 }
	     }
	   RemoveKey (names[i]);
	 }
     }
   
  Package Convert (String name)
    {
      Package package=>New ();
      SchoolConverter sc=>New ();
      
      package->SetSchool (sc->Start (GetFile (name)));

      return package;
    }

  String AddSuffix (String name)
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
	      GetFile (new);
	    }
	  except 
	    {
	      CollectionExceptions<String>::UnknownKey (key)
		{
		  break;
		}
	    }
	}

      debugp->PutStr ("new file = ")->PutString (new)->PutReturn ();

      return new;
    }

  String CreateFileName ()
    {
      String new=>NewFromArrayOfChar ("images/");
      String eid=>OIDtoHexa (cell);
      char num[];
      FileOperators fops;

      new = new->Concatenate (eid->GetSubString (4, 6))
	->ConcatenateWithArrayOfChar ("/wb");

      if (!fops.IsExists (new))
	fops.MakeDirectory (new);

      new = new->ConcatenateWithArrayOfChar ("/")
	->Concatenate(eid);

      if (!fops.IsExists (new))
	fops.MakeDirectory (new);

      length num = 7;

      num[0] = index % 10 + '0';
      num[1] = '-';
      num[2] = count / 1000 + '0';
      num[3] = count / 100 + '0';
      num[4] = count / 10 + '0';
      num[5] = count % 10 + '0';
      num[6] = 0;
      
      count++;

      new = new->ConcatenateWithArrayOfChar ("/sf-")
	  ->ConcatenateWithArrayOfChar (num);

      debugp->PutStr ("new file = ")->PutString (new)->PutReturn ();

      return new->Duplicate ();
    }

  String CreateFile (String orig)
    {
      String file = CreateFileName ();
      FileOperators fops;

      if (orig)
	fops.Copy (orig, file);

      else
	fops.Touch (file);

      return file;
    }

  String GetAll ()[]
    {
      return SetOfKeies ()->AsArray ();
    }

  String ConvertToFile (Package packages[])[]
    {
      int i, len = length packages;
      String files[];

      length files = len;

      for (i = 0; i < len; i++)
	{
	  files[i] = CreateFileName ();

	  packages[i]->GetSchool ()->PrintIt (files[i]);
	 }

      return files;
    }
}


