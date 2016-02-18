/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

record CIDOperators 
{
  String ToString (global ClassID object_id)
    {
      String str;
      
      return str=>OIDtoHexa (object_id);
    }
  
  global ClassID ToCID (String str)
    {
      char buf[];
      global ClassID cid;
      
      buf = str->Content ();
      
      inline "C"
	{
	  unsigned char *p = OZ_ArrayElement (buf, char);
	  int i, l = 0, h = 0;
	  long long id;
	  
	  for (i = 7; i >= 0; i--)
	    {
	      if (*p >= 'a')
		l += (*p++ - 'a' + 10) << (4 * i);
	      else
		l += (*p++ - '0') << (4 * i);
	    }
	  
	  for (i = 7; i >= 0; i--)
	    {
	      if (*p >= 'a')
		h += (*p - 'a' + 10) << (4 * i);
	      else
		h += (*p - '0') << (4 * i);
	      
	      if (i > 0)
		p++;
	    }
	  
	  cid  = (long long) ((long long) l << 32) + (h & 0xffffffff);
	}
      
      inline "C"
	{
	  OzExecFree ((void *) buf);
	}
      
      return cid;
    }
  
  global VersionID ToVID (String str)
    {
      return narrow (VersionID, ToCID (str));
    }
  
  global ConfiguredClassID ToCCID (String str)
    {
      return narrow (ConfiguredClassID, ToCID (str));
    }
}
