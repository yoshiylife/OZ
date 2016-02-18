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
class Workbench 
{
 constructor: 
  New;

 public: 
  Quit, Export, ImportPackage, Launch, NewPackage, ConvertPackage, 
  SetClass, SetConfiguration, SetCurrent, GetCurrent, Rename, Duplicate,
  Unregister, LaunchCB, SetCurrentPath, OpenPackages, Stop, ClosePackage,
  CreatePackage;

 public: /* tempolary */
  GetFileName;
   
  String aClassName;
  String CurrentDir;
  String Language;

  UnixIO debugp;

  char aClassPath[];

  WorkbenchUI UI;
  PackagePool aPackagePool, aSubPackagePool;

  String currentPackage;

//  SchoolDirectoryBrowser aSDB;
  String sdbPath;

  CatalogBrowserFor<Workbench> aCB;

  void New () : global
    {
      EnvironmentVariable env;

      global Workbench gwb = oid;

      CurrentDir = env.GetEnv ("OZROOT");
      Language=>NewFromArrayOfChar ("english");

      aPackagePool=>New (0);
    }
  
  void Launch () : global, locked
    {
      String package_names[], files[];
      int i, len;

      if (!UI)
	{
	  debugp=>New ();

	  UI=>New (self);
	}

      if (!aSubPackagePool)
	aSubPackagePool=>New (1);

      if (aClassName)
	SetClass (aClassName);
      
      package_names = aPackagePool->GetAll ();

      length files = len = length package_names;

      for (i = 0; i < len; i++)
	files[i] = aPackagePool->GetFile (package_names[i]);

      UI->Open (currentPackage, package_names, files,
		CurrentDir, Language, aClassPath, aClassName);
    }

  void Quit (String cd, String lang) : locked
    {
      global Object o = oid;

      CurrentDir = cd;
      Language = lang;

      if (UI)
	{
	  Stop ();
	  o->Flush ();
	}
    }

  void Export (String package_names[])
    {
       int i, len = length package_names;
       String path;
       Package packages[];

       length packages = len;

       for (i = 0; i < len; i++)
	   packages[i] = aPackagePool->Convert (package_names[i]);

      if (!aCB)
	aCB=>New(oid, ":catalog");

      aCB->Launch ();

      if (!(path = aCB->SelectPath ()))
	return;

      aCB->Import (path, package_names, packages);
/*
       if (!aSDB)
	 aSDB=>New (oid, "school");

       aSDB->Launch ();

       if (!(path = aSDB->SelectPath ()))
	 return;

       aSDB->Import (path, school_names, schools);
*/
    }

  void ImportPackage (String package_names [], Package packages[]) : global
    {
      UI->Register (package_names, 
		    aPackagePool->RegisterPackages (package_names, packages));

      Save ();
    }

  void NewPackage (String package_name)
    {
       String names[];

       length names = 1;

       names[0] = package_name;

       UI->Register (names, aPackagePool->Register (names, 0));

       Save ();
    }

  void ConvertPackage (String file, String package_name)
    {
       String names[];
       String files[];

       length files = length names = 1;

       names[0] = package_name;
       files[0] = file;

       UI->Register (names, aPackagePool->Register (names, files));

       Save ();
    }

  void Stop () : global 
    {
      WorkbenchUI tmp;

      if (UI)
	{
	  tmp = UI;
	  UI = 0;
	  tmp->Quit ();
	}

/*
      if (aSDB)
	{
	  aSDB->Quit ();
	  aSDB = 0;
	}
*/
      if (aCB)
	{
	  aCB->Quit ();
	  aCB = 0;
	}

      aClassPath = 0;
      aSubPackagePool = 0;
      debugp = 0;
    }
  
  void Go () : global 
    {
    }
      
  char SetClass (String cname)[]
    {
      global Class c;
      CompilerFrontend cfe;
      SchoolBrowser sb;
      
      try 
	{
	  if (!(c = narrow (Class,  Where ()->GetNameDirectory ()
			 ->Resolve (cname))))
	    raise ObjectNotFound;

	  aClassName = cname;

	  Save ();

	  if (aClassPath)
	    return aClassPath;
	  
	  aClassPath = c->GetClassDirectoryPath ();
	  debugp->PutStr ("Class = ")->PutOID (c)-> PutReturn ();

	  cfe=>New (c, UI);
	  sb=>New (c, UI);

	  UI->SetTools (cfe, sb);
      
	  return aClassPath;
	}
      except
	{
	  default
	    {
	      UI->InputClassObject ();
	      return 0;
	    }
	}
    }

  void SetConfiguration (String vid, String ccid)
    {
      CIDOperators cid_ops;

      Where ()->ChangeConfigurationCache (cid_ops.ToVID (vid), 
					  cid_ops.ToCCID (ccid));
    }

   void SetCurrent (String name) 
     {
       currentPackage = name;
       Save ();
     }

   String GetCurrent ()
     {
       return currentPackage;
     }

   void Rename (String old, String new)
     {
       String names[], files[];
  
       length names = length files = 1;
       
       files[0] = aPackagePool->GetFile (old);
       names[0] = new;
       UI->Register (names, aPackagePool->Register (names, files));

       names[0] = old;
       aPackagePool->Unregister (names);

       if (currentPackage && old->IsEqualTo (currentPackage))
	 {
	   currentPackage = new;
	   UI->SetCurrent (new);
	 }

       Save ();
     }

   void Duplicate (String old, String new)
     {
       String names[], files[];
       
       length names = length files = 1;
       
       files[0] = aPackagePool->GetFile (old);

       names[0] = new;
       UI->Register (names, aPackagePool->Register (names, files));

       Save ();
     }

  void Unregister (String names[])
    {
      int i, len = length names;

      aPackagePool->Unregister (names);

      for (i = 0; i < len; i++)
	if (currentPackage && names[i]->IsEqualTo (currentPackage))
	  {
	    currentPackage = 0;
	    break;
	  }

      Save ();
    }

/*
  void LaunchSDB ()
    {
      if (!aSDB)
	aSDB=>New (oid, "school");

      if (sdbPath)
	aSDB->SetPath (sdbPath);

      aSDB->Launch ();
    }
*/

  void LaunchCB ()
    {
      if (!aCB)
	aCB=>New (oid, ":catalog");

      aCB->Launch ();
    }

  void Save ()
    {
      global Object o = oid;
//      SchoolDirectoryBrowser sdb;
      WorkbenchUI ui;
      char cpath[];
      UnixIO tmp;
      PackagePool sp;

      CatalogBrowserFor<Workbench> cb;

      cb = aCB;
      aCB = 0;

/*
      sdb = aSDB;
      aSDB = 0;
*/

      ui = UI;
      UI = 0;

      sp = aSubPackagePool;
      aSubPackagePool = 0;

      cpath = aClassPath;
      aClassPath = 0;
      tmp = debugp;
      debugp = 0;

      o->Flush ();

      aSubPackagePool = sp;
//      aSDB = sdb;
      aCB = cb;
      UI = ui;
      aClassPath = cpath;
      debugp = tmp;
    }

  void SetCurrentPath (String path) : global
    {
      sdbPath = path;

      if (UI)
	Save ();
    }

  void OpenPackages (String path, String package_names[], 
		    Package packages[]) : locked
    {
      String files[], names[], buf[];
      int i, len = length package_names, j = 0;
      Package s[];

      length s = length files = length names = len;

      for (i = 0; i < len; i++)
	{
	  names[j] = path->ConcatenateWithArrayOfChar (":")
	    ->Concatenate (package_names[i]);

	  try
	    {
	      files[i] = aSubPackagePool->GetFile (names[j]);
	    }
	  except
	    {
	      CollectionExceptions<String>::UnknownKey (key)
		{
		  s[j] = packages[i];
		  j++;
		}
	    }
	}
      
      if (j)
	{
	  buf = aSubPackagePool->RegisterPackages (names, s);
  
	  for (j = 0, i = 0; i < len; i++)
	    {
	      if (files[i])
		continue;
	      
	      files[i] = buf[j++];
	    }
	}

      UI->OpenSchools (path, package_names, files);
    }

  void ClosePackage (String package_names[])
    {
      aSubPackagePool->Unregister (package_names);
    }

  void CreatePackage (String pname, 
		      String names[], String kinds[], String pvids[],

		      String vids[])
    {
      Package package=>New (), packages[];
      ConfigurationTable conft=>New ();
//      ConfigurationTable conft=>New (0);
      int len = length vids, i;
      CIDOperators cid_ops;
      School school=>New ();
      int slen = length names, j;
      String pnames[], path;

      for (j = 0; j < slen; j++)
	school->Register (names[j], kinds[j]->Content ()[0] - '0',
			  cid_ops.ToVID (pvids[j]));

      package->SetSchool (school);

      if (len > 1)
	{
	  global ObjectManager om = Where ();
	  global ConfiguredClassID ccid;
	  global VersionID vid;

	  for (i = 0; i < len; i++)
	    {
	      vid = cid_ops.ToVID(vids[i]);
	      ccid = om->GetConfiguredClassID (vid, 0);

	      conft->Set (vid, ccid);
	    }

	  package->SetConfigurationTable (conft);
//	  package->SetConfigurationSet (conft);
	}

      if (!aCB)
	aCB=>New(oid, ":catalog");

      length packages = length pnames = 1;
      packages[0] = package;
      pnames[0] = pname;

      aCB->Launch ();

      if (!(path = aCB->SelectPath ()))
	return;

      aCB->Import (path, pnames, packages);
    }

  String GetFileName (String name)
    {
      return aPackagePool->GetFile (name);
    }
}









