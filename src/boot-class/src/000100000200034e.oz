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
class SchoolBrowser : WorkbenchTools {
 constructor:
  New;

 public:
  ShowDefaultVersions, ShowOtherVersions, ShowOtherConfigurations,
  ShowDefaultConfiguration, ChangeDefaultVersion, ChangeDefaultConfiguration,
  ChangeVisible, SearchClass, AddProperty;

  /* instance variables */

  UnixIO debugp;

  CIDOperators cidOps;

  void New (global Class cl, WorkbenchUI ui)
    {
      Initialize (cl, ui);

      debugp=>New ();
    }

  String ShowDefaultVersions (String vid_str)[]
    {
      global VersionID vid = cidOps.ToVID (vid_str);
      int i, len = 0;
      String result[];
      VersionString vs;

      switch (aClass->WhichPart (vid))
	{
	case ClassPartName::aPublicPart:
	  len = 2;
	  break;
	case ClassPartName::aProtectedPart:
	  len = 1;
	  break;
	}

      length result = len;

      for (i = 0; i < len; i++)
	{
	  result[i] 
	    = cidOps.ToString ((vid = aClass->GetDefaultVersionID (vid)));

	  vs = aClass->GetVersionString (vid);

	  if (vs)
	    result [i] = result[i]->ConcatenateWithArrayOfChar (" ")
	      ->Concatenate (vs->AsString ());
	}

      return result;
    }

  String ShowOtherVersions (String vid_str)[]
    {
      global VersionID vid = cidOps.ToVID (vid_str), buf[], upper;
      int i = 0, len = 0;
      String result[];
      VersionString vs;
      
      upper = aClass->GetUpperPart (vid);
      buf = aClass->GetLowerVersions (upper);

      len = length buf;
      length result = len + 1;

      result[0] = cidOps.ToString (aClass->GetDefaultVersionID (upper));
      for (i = 0; i < len; i++)
	{
	  result[i + 1] = cidOps.ToString (buf[i]);

	  vs = aClass->GetVersionString (buf[i]);

	  if (vs)
	    result [i + 1] = result[i + 1]->ConcatenateWithArrayOfChar (" ")
	      ->Concatenate (vs->AsString ());
	}

      return result;
    }

  String ShowOtherConfigurations (String vid_str)[]
    {
      global VersionID vid = cidOps.ToVID (vid_str);
      global ConfiguredClassID ccids[];
      int i, len = 0;
      String result[];
      
      ccids = aClass->ConfiguredClassIDs (vid);

      len = length ccids;
      length result = len + 1;

      result[0] = cidOps.ToString (aClass->GetDefaultConfiguredClassID (vid));
      for (i = 0; i < len; i++)
	result[i + 1] = cidOps.ToString (ccids[i]);

      return result;
    }

  String ShowDefaultConfiguration (String vid_str)
    {
      global VersionID vid = cidOps.ToVID (vid_str);
      global ConfiguredClassID ccid;
      int i, len = 0;
      
      ccid = Where ()->GetConfiguredClassID (vid, 0);

      return cidOps.ToString (ccid);
    }

  void ChangeDefaultVersion (String vid_str)
    {
      global VersionID vid = cidOps.ToVID (vid_str);
//      global VersionID upper;

//      upper = aClass->GetUpperPart (vid);

//      aClass->SetDefaultLowerVersionID (upper, vid);
      aClass->SetItAsDefaultLowerVersion (vid);
    }

  void ChangeDefaultConfiguration (String ccid_str)
    {
      global ConfiguredClassID ccid = cidOps.ToCCID (ccid_str);
//      global VersionID vid = aClass->VersionIDFromConfiguredClassID (ccid);

//      aClass->SetDefaultConfiguredClassID (vid, ccid);
      aClass->SetItAsDefaultConfiguredClass (ccid);
    }

  String ChangeVisible (String vid_str)
    {
      global VersionID vid = cidOps.ToVID (vid_str);
      String str;
      
      return str=>NewFromArrayOfChar (aClass->CreateNewVersion (vid));
    }

  int SearchClass (String vid_str)
    {
      aClass->SearchClass (cidOps.ToVID (vid_str));

      return 0;
    }

  void AddProperty (String vid_str, String file)
    {
      aClass->AddProperty (cidOps.ToVID (vid_str), file->Content ());
    }
}
  
