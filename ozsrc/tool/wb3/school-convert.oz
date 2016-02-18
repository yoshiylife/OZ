/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class SchoolConverter 
{
 constructor: New;
 public: Start;

   UnixIO In;
   char buf[];
   int EOF;
   int pos, bufsize;

   String aClassName, aVersionID;
   int kind;

   CIDOperators cidOps;

   School aSchool;

   UnixIO debugp;

   char vid_tmp[];

   void New ()
     {
       bufsize = 256;
       EOF = 0;
       aSchool=>New ();
       debugp=>New ();
       length vid_tmp = 17;
     }

   School Start (String file)
     {
       int count = 0;
       In=>Open (file->Content (), "r", 0644);

       debugp->PutStr ("Read start: ")->PutString (file)->PutReturn ();

       ReadToBuffer ();

       while (! EOF)
	 {
	   if (ReadClassName ())
	     break;

	   ReadVersionID ();
	   Register ();
	   count++;
	 }

       debugp->PutStr ("Read end ")->PutInt (count)->PutReturn ();

       In->Close ();

       return aSchool;
     }

   int ReadClassName ()
     {
       char c, tmp[];
       int i = 0, len = 16;

       length tmp = len;

       kind = getchar () - '0';

       getchar ();
       while ((c = getchar ()) != '\n' && c)
	 {
	   if (i + 1 == len)
	     {
	       char p[] = tmp;
	       length tmp = (len += 16);

	       inline "C"
		 {
		   OzExecFree ((void *) p);
		 }
	     }
	   tmp[i++] = c;
	 }

       if (!c)
	 return 1;

       tmp[i] = 0;

       aClassName=>NewFromArrayOfChar (tmp);

       inline "C"
	 {
	   OzExecFree ((void *) tmp);
	 }

       return 0;
     }

   void ReadVersionID ()
     {
       char c;
       int i, j = 0;

       c = getchar ();
       while (c != '\n' && j < 3)
	 {
	   while (c == ' ' || c == '\t')
	     c = getchar ();

	   i = 0;
	   do
	     {
	       vid_tmp[i++] = c;
	     }
	   while ((c = getchar ()) != '\t' && c != ' ' && c != '\n');

	   vid_tmp[i] = 0;

	   if (! j++)
	     aVersionID=>NewFromArrayOfChar (vid_tmp);
	 }
     }

   char getchar ()
     {
       if (pos == bufsize)
	 ReadToBuffer ();

       while (!EOF && !buf[pos])
	 {
	   pos++;

	   if (pos == bufsize)
	     ReadToBuffer ();
	 }

       if (EOF)
	 return 0;
       else
	 return buf[pos++];
     }

   void ReadToBuffer ()
     {
       buf = In->Read (bufsize);

       if (!buf)
	 {
	   EOF = 1;
	   return;
	 }

       pos = 0;
     }

   void Register ()
     {
       global VersionID vid = cidOps.ToVID (aVersionID);

/*
       debugp->PutString (aClassName)->PutStr (" ")
	 ->PutInt (kind)->PutStr (" ")->PutOID (vid)->PutReturn ();
*/

       aSchool->Register (aClassName, kind, vid);
     }
}
