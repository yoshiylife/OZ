/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

record EnvironmentVariable 
{
  String GetEnv (char env[])
    {
      String str;
      char buf[];
      int len, e;
      
      inline "C"
	{
	  if (e = (int) OzGetenv (OZ_ArrayElement (env, char)))
	    len = OzStrlen ((char *)e) + 1;
	}
      
      length buf = len;
      
      inline "C"
	{
	  if (len)
	    OzStrcpy (OZ_ArrayElement (buf, char), (char *) e);
	}
      
      return len ? str=>NewFromArrayOfChar (buf) : 0;
    }
}
