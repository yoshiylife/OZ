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
