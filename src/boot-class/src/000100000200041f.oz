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
class WorkbenchUI : GUI 
  ( rename Open GUIOpen; )
{
 constructor: 
  New;

 public: 
  Register, Open, SetCurrent, InputClassObject, SetTools, ShowShortResult, 
  ShowResult, SetNewVersionID, Quit, OpenSchools;

  Workbench aWB;
  
  CompilerFrontend aCFE;
  SchoolBrowser aSB;

  void New (Workbench wb)
    {
      aWB = wb;
    }

  void SetTools (CompilerFrontend cfe, SchoolBrowser sb)
    {
      aCFE = cfe;
      aSB = sb;
    }

  int ReadEvent ()
    {
      String args[] = RecvCommandArgs ();
      
      if (CommandIs ("Quit"))
	{
	  aWB->Quit (args[0], args[1]);
	  return 1;
	}
      
      else if (CommandIs ("SetClass"))
	{
	  char cpath [];
	  
	  if (cpath = aWB->SetClass (args[0]))
	    SetClassPath (cpath);
	}

      else if (CommandIs ("SetConfiguration"))
	{
	  aWB->SetConfiguration (args[0], args[1]);
	}

      else if (CommandIs ("ConvertSchool"))
	aWB->ConvertPackage (args[0], args[1]);

      else if (CommandIs ("NewSchool"))
	aWB->NewPackage (args[0]);

      else if (CommandIs ("Export"))
	aWB->Export (args);

      else if (CommandIs ("SetCurrent"))
        aWB->SetCurrent (args[0]);
      
      else if (CommandIs ("Unregister"))
        aWB->Unregister (args);
      
      else if (CommandIs ("RenameSchool"))
	aWB->Rename (args[0], args[1]);
      
      else if (CommandIs ("DuplicateSchool"))
	aWB->Duplicate (args[0], args[1]);

/*
      else if (CommandIs ("LaunchSDB"))
	aWB->LaunchSDB ();
*/
      else if (CommandIs ("LaunchCB"))
	aWB->LaunchCB ();

      else if (CommandIs ("CloseSchool"))
	aWB->ClosePackage (args);

      else if (CommandIs ("CreatePackage"))
	aWB->CreatePackage (args[0], SplitList (args[1]), SplitList (args[2]),
			    SplitList (args[3]), SplitList (args[4]));

      else if (CommandIs ("GetFileName"))
	SetResult (args[0], args[1], aWB->GetFileName (args[2]));

      else if (CommandIs ("Install"))
	aCFE->InstallClass (args[0]);

      else if (CommandIs ("CheckVersion"))
	{
	  char status[];
	  String buf;
	  
	  char part = (args[4]->Content ())[0] - '0';
	  char kind = (args[5]->Content ())[0] - '0';
	  if (aCFE->CheckVersion (args[0], args[2], args[3], part, kind, 0))
	    status = "1";
	  else
	    status = "0";
	  
	  SetResult (args[0], args[1], buf=>NewFromArrayOfChar (status));
	}
      
      else if (CommandIs ("CheckVersions"))
	{
	  String class_names[] = SplitList (args[2]);
	  String vids[] = SplitList (args[3]);
	  String kinds[] = SplitList (args[5]);
	  int i, len = length kinds;
	  char kind[], buf[], part;
	  String status;
	  
	  length kind = len;
	  
	  for (i = 0; i < len; i++)
	    {
	      buf = kinds[i]->Content ();
	      
	      kind[i] = buf[0] - '0';
	    }
	  
	  part = (args[4]->Content ())[0] - '0';

	  if (!length vids)
	    length vids = len;

	  status=>NewFromArrayOfChar (aCFE->CheckVersions (args[0], 
							   class_names, vids,
							   part, kind));

	  SetResult (args[0], args[1], status);
	}
      
      else if (CommandIs ("RegisterClass"))
	aCFE->RegisterClass (args[0]);

      else if (CommandIs ("GetConfiguredClassID"))
	{
	  String vids[] = SplitList (args[2]);
	  
	  SetResult (args[0], args[1], 
		     CreateList (aCFE->GetConfiguredClassID (vids)));
	}

      else if (CommandIs ("ShowDefaultVersions"))
	{
	  String buf = CreateList (aSB->ShowDefaultVersions (args[2]));

	  SetResult (args[0], args[1], buf);
	}

      else if (CommandIs ("ShowOtherVersions"))
	{
	  String buf = CreateList (aSB->ShowOtherVersions (args[2]));

	  SetResult (args[0], args[1], buf);
	}

      else if (CommandIs ("ShowOtherConfigurations"))
	{
	  String buf = CreateList (aSB->ShowOtherConfigurations (args[2]));

	  SetResult (args[0], args[1], buf);
	}

      else if (CommandIs ("ShowDefaultConfiguration"))
	{
	  String buf = aSB->ShowDefaultConfiguration (args[2]);

	  SetResult (args[0], args[1], buf);
	}

      else if (CommandIs ("ChangeDefaultVersion"))
	aSB->ChangeDefaultVersion (args[0]);

      else if (CommandIs ("ChangeDefaultConfiguration"))
	aSB->ChangeDefaultConfiguration (args[0]);

      else if (CommandIs ("ChangeVisible"))
	{
	  String buf = aSB->ChangeVisible (args[2]);

	  SetResult (args[0], args[1], buf);
	}

      else if (CommandIs ("SearchClass"))
	{
	  String s;

	  if (aSB->SearchClass (args[2]))
	    s=>NewFromArrayOfChar ("1");
	  else
	    s=>NewFromArrayOfChar ("0");

	  SetResult (args[0], args[1], s);
	}

      else if (CommandIs ("AddProperty"))
	aSB->AddProperty (args[0], args[1]);

      return 0;
    }
   
  void SetCurrent (String package_name)
    {
      char args[][];
      
      length args = 1;
      if (package_name)
	args[0] = package_name->Content ();
      else
	args[0] = "";
      
      ExecProc ("SetCurrent", args);
    }
   
  void Open (String package_name, String package_names[], String files[],
	     String cd, String lang, char class_path[], String class_name)
    {
      char args[][];
      
      length args = class_path ? 6 : 4;
      args[0] = "lib/gui/wb2/wb.tcl";
      args[1] = cd->Content ();
      args[2] = lang->Content ();
      args[3] = "oz++";
//      args[3] = "boot";
      
      if (class_path)
	{
	  args[4] = class_path;
	  args[5] = class_name->Content ();
	}

      StartWish (args, ':', '|');

      if (length package_names)
	Register (package_names, files);
      
      if (package_name)
	SetCurrent (package_name);
    }

  void Register (String names[], String files[])
    {
       char args[][];

       length args = 2;
       args[0] = CreateList (names)->Content ();
       args[1] = CreateList (files)->Content ();
       
       ExecProc ("Register", args);
    }

  void InputClassObject ()
    {
      ExecProc ("InputClassObject", 0);
    }
  
  void SetClassPath (char path[]) 
    {
      char args[][];
      
      length args = 1;
      args[0] = path;
      
      ExecProc ("SetClassPath", args);
    }

  void ShowResult (String package_name, char kind[], String msg)
    {
      char args[][];
      
      length args = 3;
      args[0] = package_name->Content ();
      args[1] = kind;
      args[2] = msg->Content ();
      
      ExecProc ("ShowResult", args);
    }

  void ShowShortResult (String package_name, char kind[], String msg)
    {
      char args[][];
      
      length args = 3;
      args[0] = package_name->Content ();
      args[1] = kind;
      args[2] = msg->Content ();
      
      ExecProc ("ShowShortResult", args);
    }

  void SetNewVersionID (String package_name, String class_name, 
			char kind, String vids[])
    {
      char args[][];
      
      length args = 4;
      args[0] = package_name->Content ();
      args[1] = class_name->Content ();
      length args[2] = 1;
      args[2][0] = kind + '0';
      args[3] = CreateList (vids)->Content ();
      
      ExecProc ("SetNewVersionID", args);
    }

  void SetResult (String package_name, String kind, String result)
    {
      char args[][];
      
      length args = 3;
      args[0] = package_name->Content ();
      args[1] = kind->Content ();
      args[2] = result->Content ();
      
      ExecProc ("SetResult", args);
    }

  void Quit ()
    {
      ExecProc ("Quit", 0);
    }

  void OpenSchools (String path, String package_names[], String files[])
    {
      char args[][];
      
      length args = 3;
      args[0] = path->Content ();
      args[1] = CreateList (package_names)->Content ();
      args[2] = CreateList (files)->Content ();
      
      ExecProc ("OpenSchools", args);
    }
}
