/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class CompilerFrontend : WorkbenchTools {
 constructor:
  New;

 public: 
  CheckVersion, CheckVersions, RegisterClass, GetConfiguredClassID,
  InstallClass;
  
  /* instance variables */

  UnixIO debugp;

  String errors;

  void New (global Class cl, WorkbenchUI ui)
    {
      Initialize (cl, ui);

      debugp=>New ();
    }

  int CheckVersion (String school_name, String class_name, 
		    String vid_str,
		    char part, char kind, int many)
    {
      try
	{
	  AssignVersionID (school_name, class_name, vid_str, part, kind);
	}

      except
	{
	SHCompiler::AlreadyCompiled (name)
	  {
	    String msg=>NewFromArrayOfChar ("Already Compiled (");

	    msg = msg->Concatenate (name)->ConcatenateWithArrayOfChar (")");

	    if (many)
	      AddErrors (msg);
	    else
	      UI->ShowShortResult (school_name, "CFE", msg);
	    
	    return 1;
	  }
	SHCompiler::IllegalPart (name)
	  {
	    String msg=>NewFromArrayOfChar ("Illegal Part (");

	    msg = msg->Concatenate (name)->ConcatenateWithArrayOfChar (")");
	    
	    if (many)
	      AddErrors (msg);
	    else
	      UI->ShowShortResult (school_name, "CFE", msg);

	    return 1;
	  }
	SHCompiler::IllegalClass (vid)
	  {
	    String msg=>NewFromArrayOfChar ("Illegal Class (");

	    msg = msg->Concatenate (vid)->ConcatenateWithArrayOfChar (")");

	    if (many)
	      AddErrors (msg);
	    else
	      UI->ShowShortResult (school_name, "CFE", msg);

	    return 1;
	  }
	}

      return 0;
    }
  
  char CheckVersions (String school_name, String class_names[], 
		      String vid_strs[],
		      char part, char kinds[])[]
    {
      int i, len = length class_names;
      int status = 0;
      char result[];

      length result = len * 2 + 1;

      errors=>New ();
      
      for (i = 0; i < len; i++)
	{
	  result[i * 2] =
	    CheckVersion (school_name, class_names[i], vid_strs[i], 
			  part, kinds[i], 1) 
	      + '0';

	  result[i * 2 + 1] = ' ';
	}

      if (errors->Length ())
	UI->ShowResult (school_name, "CFE", errors);

      result[i * 2] = 0;

      return result;
    }
  
  void AssignVersionID (String school_name, String class_name, 
			String vid_str,
			char part, char kind) : locked
    {
      global VersionID new_vid[], vid;
      String vids[];
      CIDOperators cid_ops;
      int i, len = 0;
      
      if ((kind && kind != 8) && 
	  (part == SHCompiler::Protected ||
	   part == SHCompiler::Implementation ||
	   part == SHCompiler::NewProtected ||
	   part == SHCompiler::NewImplementation))

	raise SHCompiler::IllegalPart (class_name);
      
      try 
	{
	  int p;

	  if (!vid_str)
	    raise CollectionExceptions<char []>::UnknownKey (class_name
							     ->Content ());
	  else
	    {
/*
	      if (part == SHCompiler::ID)
		raise SHCompiler::AlreadyCompiled (class_name);
*/
	      vid = cid_ops.ToVID (vid_str);
	    }
	  
	  if (part < SHCompiler::NewPublic)
	    {
	      if (part > SHCompiler::Implementation)
		{
		  int fin, done = ClassPartName::aPublicPart;

		  if (!kind || kind == 8)
		    fin = part;
		  else
		    fin = ClassPartName::aProtectedPart;

		  for (p = aClass->WhichPart (vid); p < fin; p++)
		    {
		      if (aClass->GetClassInformations (vid))
			done++;
		      
		      if (p + 1 < fin)
			vid = aClass->GetDefaultVersionID (vid);
		    }

		  if (done == fin)
		    raise SHCompiler::AlreadyCompiled (class_name);
		    
		  return;
		}
	      else
		{
		  if (aClass->GetClassInformations (vid))
		    {
//		      debugp->PutOID (vid)->PutReturn ();
		      raise SHCompiler::AlreadyCompiled (class_name);
		    }
		  
		  return;
		}
	    }
	  else 
	    {
	      vid = aClass->GetUpperPart (vid);

	      p = aClass->WhichPart (vid);
	      
	      if (p > ClassPartName::aRootPart &&
		  !aClass->GetClassInformations (vid))
		raise SHCompiler::IllegalClass (cid_ops.ToString (vid));

//	      part -= SHCompiler::All;
	    }
	}
      except
	{
        CollectionExceptions<char []>::UnknownKey (name)
	  {
	    len = 1;
	    if (part != SHCompiler::NewPublic)
	      raise SHCompiler::IllegalPart (class_name);

/*
	    if (part != SHCompiler::ID)
	      raise SHCompiler::IllegalPart (class_name);
*/
	  }
        ClassExceptions::UnknownClass (vid)
	  {
	    raise SHCompiler::IllegalClass (cid_ops.ToString (vid));
	  }
        }

      debugp->PutString (class_name)->PutStr (" ")->PutOID (vid)->PutReturn ();

      switch (part)
	{
/*
	case SHCompiler::If:
	case SHCompiler::All:
	  if (!kind || kind == 8)
	    len = length vids = length new_vid = 3;
	  else
	    len = length vids = length new_vid = 1;
	  break;
	case SHCompiler::ID:
	  if (!kind || kind == 8)
	    len = length vids = length new_vid = 4;
	  else
	    len = length vids = length new_vid = 2;
	  break;
*/
	case SHCompiler::NewPublic:
	  if (!kind || kind == 8)
	    len += 3;
	  else
	    len += 1;
	  break;
	case SHCompiler::NewProtected:
	  len += 2;
	  break;
	case SHCompiler::NewImplementation:
	  len += 1;
	  break;
	}

      length vids = length new_vid = len;

      new_vid[0] = aClass->CreateNewPart (vid);
      for (i = 1 ; i < len; i++)
	{
	  new_vid[i] = aClass->CreateNewPart (new_vid[i - 1]);
	  aClass->SetDefaultLowerVersionID (new_vid[i - 1], new_vid[i]);
	}
	  
      for (i = 0; i < len; i++)
	{
	  vids[i] = cid_ops.ToString (new_vid[i]);

	  debugp->PutOID (new_vid[i])->PutStr (" ");
	}
      debugp->PutReturn ();
      
      UI->SetNewVersionID (school_name, class_name, kind, vids);
    }
  
  void RegisterClass (String vid) 
    {
      CIDOperators cid_ops;

      aClass->RegisterClassInformations (cid_ops.ToVID (vid));
    }

  String GetConfiguredClassID (String vids[])[]
    {
      CIDOperators cid_ops;
      global ConfiguredClassID buf;
      String ccids[];
      int i, len = length vids;

      length ccids = len;

      for (i = 0; i < len; i++)
	{
	  buf = aClass->CreateNewConfiguredClass (cid_ops.ToVID(vids[i]));
	  ccids[i] = cid_ops.ToString (buf);

	  debugp->PutString (vids[i])->PutStr (" ")->PutOID (buf)
	    ->PutReturn ();
	}
	 
      return ccids;
    }

  void AddErrors (String msg)
    {
      errors = errors->Concatenate (msg)->ConcatenateWithArrayOfChar ("\n");
    }

  void InstallClass (String file)
    {
      aClass->Read (file->Content ());
    }
}



