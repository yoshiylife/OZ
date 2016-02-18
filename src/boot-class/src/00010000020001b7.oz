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
abstract class GUI {
 protected: StartWish;
 protected: Quit, SendStr, SendInt, SendChar, RecvCommandArgs;
 protected: ReadEvents, ReadEvent, CommandIs, ArgIs, SendString;

 protected: Open, Close, Iconify, Top, ExecProc, CreateList, SplitList;
   
   UnixIO wish;
   char command_delimiter, args_delimiter;
   int command_length;
   String buf, command;
   int buf_length;
   
   int StartWish (char argv[][], char c1, char c2) : locked
     {
       char tmp[];
       String buf;

       if (wish)
	 return 1;

       length tmp = 256;

// NISHIOKA patch start
       {
           unsigned int len;
	   char p [];

           inline "C" {
	       char *s;
	       s = OzGetenv ("OZROOT");
               len = OzStrlen (s);
	       p = (OZ_Array)s;
           }
           if (len + 9 > 256) {
	       length tmp = len + 9;
	   }
	   inline "C" {
	       OzSprintf (OZ_ArrayElement (tmp, char), "source %s/", (char*)p);
	   }
       }
// original below
/*
       inline "C"  
	 {
	   OzSprintf (OZ_ArrayElement (tmp, char), 
		      "source %s/", getenv ("OZROOT"));
	 }
*/
// NISHIOKA patch end

       buf=>NewFromArrayOfChar (tmp);
       buf = buf->ConcatenateWithArrayOfChar (argv[0])
	 ->ConcatenateWithArrayOfChar ("\n");

       argv[0] = "wish";

       wish=>Spawn(argv);

       SendString (buf);

       command_delimiter = c1;
       args_delimiter = c2;
       command_length = 0;

       detach fork ReadEvents ();

       return 0;
    }
   
   void Quit ()
     {
       if (wish)
	 {
	   wish->Close ();
	   wish = 0;
	 }
     }

   String RecvCommandArgs ()[]
     {
       String tmp, args[];

       tmp = RecvCommand ();

       args = RecvArgs ();

       if (tmp)
	 buf = tmp;
       else
	 buf = 0;

       return args;
     }

    String RecvCommand ()
     {
       int p, len;
       String tmp = 0;
//       UnixIO debugp=>New ();

       if (!buf)
	 {
	   buf=>New ();
	   do 
	     {
// NISHIOKA patch start
               char received [];

               received = wish->Read (256);
               if (received == 0) {
                   return 0;
               }
               if (received [255] != '\0') {
		   length received = 257;
	       }
	       buf = buf->ConcatenateWithArrayOfChar (received);
// original below
/*
	       buf = buf->ConcatenateWithArrayOfChar (wish->Read (256));
*/
// NISHIOKA patch end
	       len = buf->Length ();
	     }
	   while (buf->At (len - 1) != '\n');
	 }
       else
	 len = buf->Length ();

       if ((p = buf->StrChr ('\n')) != (len - 1))
	 {
	   tmp=>New ();
	   tmp->Assign (buf->GetSubString (p + 1, len - p -1));
	   buf_length = p;
	 }
       else
	 buf_length = len - 1;

       if ((p = buf->StrChr (command_delimiter)) < 0)
	 {
	   command_length = 0;
	   command=>New ();
	   command->Assign (buf);
	 }
       else
	 {
	   command_length = p;
	   command=>New ();
	   command->Assign (buf->GetSubString (0, p));
	 }
//       debugp->PutString (command)->PutReturn ();

       return tmp;
     }
   
   String RecvArgs ()[]
     {
       String str = 0, tmp[], args[];
       int i = 0, p, num = 16, len, j; 
//       UnixIO debug=>New ();
       
       if (!command_length)
	 return 0;

       len = buf_length - command_length - 1;

       if (len > 0)
	 {
	   str = buf->GetSubString (command_length + 1, len);
	 }

       if (str)
	 length args = num;
       
       while (len > 0 && str && ((p = str->StrChr (args_delimiter)) > -1))
	 {
	   if (i == num)
	     {
	       length args += num;
	       num += 16;
	     }

	   if (p)
	     {
	       args[i]=>New ();
	       args[i++]->Assign (str->GetSubString (0, p));
	     }
	   else
//	     args[i++]=>New ();
	     args[i++] = 0;

	   len -= (p + 1);
	   if (len)
	     {
	       str = str->GetSubString (p + 1, len);
	     }
	 }

       if (str)
	 {
	   args[i]=>New ();
	   if (str->StrChr (args_delimiter) < 0)
	     args[i]->Assign (str);
	   i++;
	 }

       if (args)
	 {
	   tmp = args;
	   length args = i;
	   
	   for (j = 0; j < i; j++)
	     tmp[j] = 0;

	   inline "C"
	     {
	       OzExecFree ((void *) tmp);
	     }
/*
	   for (j = 0; j < i; j++)
	     debug->PutInt (j)->PutStr (": ")
	       ->PutString (args[j])->PutReturn ();
*/
	 }
       else
	 length args = 1;

       return args;
     }

   int CommandIs (char str[])
     {
       return command ? command->IsEqualToArrayOfChar (str) : 0;
     }
   
   int ArgIs (int index, char str[])
     {
/*
       return args && args[index] ? 
	 args[index]->IsEqualToArrayOfChar (str) : 0;
*/
     }
   
   void SendStr (char str[])
     {
       if (wish)
	 wish->PutStr (str);
     }
   
   void SendString (String string)
     {
       if (wish)
	 if (string)
	   wish->PutString (string);
	 else
	   wish->PutStr ("\"\"");
     }

   void SendInt (int value)
     {
       if (wish)
	 wish->PutInt (value);
     }
		    
   void SendChar (char c)
     {
       if (wish)
	 wish->PutChar (c);
     }
		    
   void ReadEvents ()
     {
       while (1)
	 {
	   if (ReadEvent ())
	     break;
	 }

       wish = 0;
     }

   int ReadEvent () : abstract;

   void Open ()
     {
       SendStr ("wm deiconify .\n");
       SendStr ("raise .\n");
     }

   void Close ()
     {
       SendStr ("wm withdraw .\n");
     }

   void Iconify ()
     {
       SendStr ("wm iconify .\n");
     }

   void Top ()
     {
       SendStr ("raise .\n");
     }

   void ExecProc (char proc_name[], char args[][])
     {
       int i, len, buflen, k = 0, p_len;
       String names;
       char buf[];
//       UnixIO debug=>New ();

       if (!wish)
	 return;

       buflen = (p_len = length proc_name) + 1;

       len = length args;

       for (i = 0; i < len; i++)
	 buflen += length args[i] + 3;

// NISHIOKA patch start
       length buf = buflen + 2;
// original below
/*
       length buf = buflen + 1;
*/
// NISHIOKA patch end

       for (i = 0; i < p_len && proc_name[i]; i++)
	 buf[k++] = proc_name[i];

       for (i = 0; i < len; i++)
	 {
	   int j, e_len;

	   buf[k++] = ' ';

	   e_len = length args[i];

	   buf[k++] = '{';

	   for (j = 0; j < e_len && args[i][j]; j++)
	     buf[k++] = args[i][j];

	   buf[k++] = '}';
	 }

       buf[k++] = '\n';
       buf[k] = 0;
       names=>NewFromArrayOfChar (buf);

//       debug->PutStr (buf);

       inline "C"
	 {
	   OzExecFree ((void *) buf);
	 }

       SendString (names);
     }

   String CreateList (String elements[])
     {
       int i, len, buflen = 0, k = 0;
       String names;
       char buf[];

       len = length elements;

       for (i = 0; i < len; i++)
	 {
	   if (!elements[i])
	     continue;

	   buflen += elements[i]->Length () + 3;
	 }

       length buf = buflen + 1;

       for (i = 0; i < len; i++)
	 {
	   int j, e_len;

	   if (!elements[i])
	     continue;

	   e_len = elements[i]->Length ();

	   buf[k++] = '{';

	   for (j = 0; j < e_len; j++)
	     buf[k++] = elements[i]->At(j);

	   buf[k++] = '}';

	   if (i + 1 < len)
	     buf[k++] = ' ';
	 }

       buf[k] = 0;
       names=>NewFromArrayOfChar (buf);

       inline "C"
	 {
	   OzExecFree ((void *) buf);
	 }

       return names;
     }

   String SplitList (String list)[]
     {
       int i = 0, len = list->Length (), j = 0, num = 0;
       int level = 0;
       char c, p = 0, buf[];
       String elements[], tmp[];
       int size = 16, buf_size = 256;

//       UnixIO debug=>New ();

//       debug->PutString (list)->PutReturn ();
       
       while (i < len && list->At (i) != '{')
	 i++; 

       if (i == len)
	 {
	   length elements = 1;
	   elements[0]=>New ();
	   elements[0]->Assign (list);
	   return elements;
	 }

       length elements = size;
       length buf = buf_size;


       for (; i < len;) 
	 {
	   c = list->At (++i);

	   if (c == ' ' || (c == '}' && p != '\\'))
	     {
	       if (j)
		 {
		   buf[j] = 0;
		   elements[num++]=>NewFromArrayOfChar (buf);
		 }
	       else
		 {
		   elements[num++] = 0;
		 }
	       
	       if (num == size)
		 length elements = (size += 16);
	       
	       if (c == '}')
		 break;
	       
	       j = 0;
	       p = 0;
	     }


	   while (c == ' ')
	     c = list->At (++i);
	   
	   do 
	     {
	       if (c == '{' && p != '\\')
		 {
		   if (++level == 1)
		     {
		       p = c;
		       c = list->At (++i);
		       continue;
		     }
		 }
	       else if (c == '}' && p != '\\')
		 {
		   if (--level == 0)
		     continue;
		 }

	       buf[j++] = c;

	       if (j == buf_size)
		 length buf = (buf_size += 64);

	       if (level > 0)
		 {
		   p = c;
		   c = list->At (++i);
		 }
	     }
	   while (level > 0);

	   p = c;
	 }

       tmp = elements;
       length elements = num;

       for (i = 0; i < num; i++)
	 tmp[i] = 0;

       inline "C"
	 {
	   OzExecFree ((void *) tmp);
	   OzExecFree ((void *) buf);
	 }

/*
       for (i = 0; i < num; i++)
	 debug->PutString (elements[i])->PutReturn ();
*/

       if (num == 1 && elements[0] == 0)
	 return 0;
       else
	 return elements;
     }
}
