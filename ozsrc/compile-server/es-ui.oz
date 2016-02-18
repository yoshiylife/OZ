/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class EnqueteServerUI
{
 constructor:
  New;

 public:
  Quit;

 protected: 
  Dispatch, DispatchRequest;

  global OZCGI cgi;
  void @dispatcher;
  EnqueteServer es;

  UnixIO debugp;
	
  void New (EnqueteServer enquete_server)
    {
      String cgi_name=>NewFromArrayOfChar (OZCGIConstants::CGIName);

      debugp=>New ();

      debugp->PutStr ("es Dispatch\n");

      es = enquete_server;

      cgi = narrow (OZCGI,
		    Where ()->GetNameDirectory ()->Resolve (cgi_name));

      if (cgi != 0) 
	{
	  dispatcher = fork Dispatch ();
	}
    }

  void Dispatch ()
    {
      String form_name=>NewFromArrayOfChar ("enquete.html");

      while (1) 
	{
	  HTMLMessage request = cgi->GetRequest (form_name);
	  
	  if (request == 0) 
	    break;
	  else
	    detach fork DispatchRequest (request);
	}
    }

  void DispatchRequest (HTMLMessage request)
    {
      String command_key=>NewFromArrayOfChar ("command");
      String request_id_key
	=>NewFromArrayOfChar (OZCGIConstants::KeyforRequestID);
      String command_name;
      int request_id;

      debugp->PutStr ("es DispatchRequest: ");

      command_name = request->AtKey (command_key)->RemoveAny ();
      request_id = request->AtKey (request_id_key)->RemoveAny ()->AtoI ();

      debugp->PutString (command_name)->PutStr ("\n");
      
      if (command_name->IsEqualToArrayOfChar ("回答"))
	{
	  ShowQueryHTML (request, request_id);
	  return;
	}

      if (command_name->IsEqualToArrayOfChar ("集計状況"))
	{
	  ShowResultHTML (request, request_id);
	  return;
	}

      if (command_name->IsEqualToArrayOfChar ("アンケートの終了"))
	{
	  StopEnquete (request, request_id);
	  return;
	}

      if (command_name->IsEqualToArrayOfChar ("回答登録"))
	{
	  RegisterEnquete (request, request_id);
	  return;
	}

      if (command_name->IsEqualToArrayOfChar ("アンケート一覧") ||
	  command_name->IsEqualToArrayOfChar ("List"))
	{
	  ListEnquetes (request_id);
	  return;
	}

      if (command_name->IsEqualToArrayOfChar ("停止"))
	{
	  Quit (request_id);
	  return;
	}
    }

  void ShowQueryHTML (HTMLMessage request, int request_id)
    {
      String index_key=>NewFromArrayOfChar ("index");
      int index;
      Enquete enquete;
      Enquete enquetes[] = es->GetEnquetes ();

      debugp->PutStr ("es ShowQueryHTML\n");

      try
	{
	  index = request->AtKey (index_key)->RemoveAny ()->AtoI ();
	}
      except
	{
	default
	  {
	    ListEnquetes (request_id);
	    return;
	  }
	}

      if (!(enquete = enquetes[index]))
	{
	  NoService (request_id);
	  return;
	}

      cgi->PutResult (request_id, enquete->CreateQueryHTML (index));
    }

  void ShowResultHTML (HTMLMessage request, int request_id)
    {
      String index_key=>NewFromArrayOfChar ("index");
      int index;
      Enquete enquete;
      Enquete enquetes[] = es->GetEnquetes ();

      debugp->PutStr ("es ShowResultHTML\n");

      try
	{
	  index = request->AtKey (index_key)->RemoveAny ()->AtoI ();
	}
      except
	{
	default
	  {
	    ListEnquetes (request_id);
	    return;
	  }
	}

      if (!(enquete = enquetes[index]))
	{
	  NoService (request_id);
	  return;
	}

      cgi->PutResult (request_id, enquete->CreateResultHTML ());
    }

  void StopEnquete (HTMLMessage request, int request_id) : locked
    {
      String index_key=>NewFromArrayOfChar ("index");
      String password_key=>NewFromArrayOfChar ("password");
      int index;
      Enquete enquete;
      Enquete enquetes[] = es->GetEnquetes ();
      
      debugp->PutStr ("es StopEnquete\n");

      try
	{
	  index = request->AtKey (index_key)->RemoveAny ()->AtoI ();
	}
      except
	{
	default
	  {
	    ListEnquetes (request_id);
	    return;
	  }
	}

      if (!(enquete = enquetes[index]))
	{
	  NoService (request_id);
	  return;
	}

      if (enquete->CheckPassword (request->AtKey (password_key)->RemoveAny ()))
	{
	  enquetes[index] = 0;
	  cgi->PutResult (request_id, enquete->CreateResultHTML ());
	}
      else
	{
	  String result=>NewFromArrayOfChar
	    ("<HTML>\n<HEAD>\n<TITLE>Illegal password !\n</TITLE>\n</HEAD>\n"
	     "<BODY>\nパスワードが正しくありません<P>\n<HR>\n"
	     "<FORM METHOD=\"GET\" ACTION=\"/cgi-bin/t.cgi\">\n"
	     "<INPUT TYPE=\"hidden\" NAME=\"form\" VALUE=\"enquete.html\">\n"
	     "<INPUT TYPE=\"submit\" NAME=\"command\" "
	     "VALUE=\"アンケート一覧\">\n"
	     "</FORM>\n</BODY>\n</HTML>\n");

	  cgi->PutResult (request_id, result);
	}
    }

  void RegisterEnquete (HTMLMessage request, int request_id)
    {
      String index_key=>NewFromArrayOfChar ("index");
      int index;
      String result;
      Enquete enquete;
      Enquete enquetes[] = es->GetEnquetes ();
      ArrayOfCharOperators aco;
      
      debugp->PutStr ("es RegisterEnquete\n");

      try
	{
	  index = request->AtKey (index_key)->RemoveAny ()->AtoI ();
	}
      except
	{
	default
	  {
	    ListEnquetes (request_id);
	    return;
	  }
	}

      if (!(enquete = enquetes[index]))
	{
	  NoService (request_id);
	  return;
	}

      enquete->Register (request);

      result=>NewFromArrayOfChar 
	("<HTML>\n<HEAD>\n<TITLE>Thanks !\n</TITLE>\n</HEAD>\n"
	 "<BODY>\n"
	 "ありがとうございます。<P>\n"
	 "\"集計状況\"を押して頂くと、現在の集計状況が御覧頂けます。<HR>\n"
	 "<FORM METHOD=\"GET\" ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" VALUE=\"enquete.html\">\n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"集計状況\"> \n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"アンケート一覧\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"index\" VALUE=\"");

      result = result->ConcatenateWithArrayOfChar
	(aco.ItoA (index));
      result = result->ConcatenateWithArrayOfChar
	("\">\n"
	 "</FORM>\n</BODY>\n</HTML>\n");

      cgi->PutResult (request_id, result);
    }

  void NoService (int request_id)
    {
      String result;

      debugp->PutStr ("es NoService\n");

      result=>NewFromArrayOfChar 
	("<HTML>\n<HEAD>\n<TITLE>No Service\n</TITLE>\n</HEAD>\n"
	 "<BODY>\n"
	 "Sorry !<P>\n"
	 "Requested questions <HR>\n"
	 "<FORM METHOD=\"GET\" ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" VALUE=\"enquete.html\">\n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"List\">\n"
	 "</FORM>\n</BODY>\n</HTML>\n");
      
      cgi->PutResult (request_id, result);
    }

  void ListEnquetes (int request_id)
    {
      String result;
      int i;
      ArrayOfCharOperators aco;
      Enquete enquete;
      Enquete enquetes[] = es->GetEnquetes ();
      int no_enquetes = length enquetes;

      debugp->PutStr ("es ListEnquetes\n");

      result=>NewFromArrayOfChar 
	("<HTML>\n<HEAD>\n<TITLE>Enquete List\n</TITLE>\n</HEAD>\n"
	 "<BODY>\n"
	 "現在行なわれているアンケートの一覧です。"
	 "<FORM METHOD=\"GET\" ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" VALUE=\"enquete.html\">\n"
	 "<DL>\n");

      for (i = 0; i < no_enquetes; i++)
	{
	  if (!(enquete = enquetes[i]))
	    continue;

	  result = result->ConcatenateWithArrayOfChar 
	    ("<DT><INPUT TYPE=\"radio\" NAME=\"index\" VALUE=\"");
	  result = result->ConcatenateWithArrayOfChar
	    (aco.ItoA (i));
	  result = result->ConcatenateWithArrayOfChar 
	    ("\">\n");
	  result = result->ConcatenateWithArrayOfChar 
	    (enquete->GetTitle ());
	  result = result->ConcatenateWithArrayOfChar 
	    ("\n<DD>");
	  result = result->ConcatenateWithArrayOfChar 
	    (enquete->GetName());
	  result = result->ConcatenateWithArrayOfChar 
	    ("(");
	  result = result->ConcatenateWithArrayOfChar 
	    (enquete->GetMailAddress ());
	  result = result->ConcatenateWithArrayOfChar 
	    (")\n");
	}

      result = result->ConcatenateWithArrayOfChar 
	("</DL>\n<HR><P>\n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"回答\"> \n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"集計状況\"> \n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"アンケートの終了\">"
	 "<P>\n"
	 "アンケートの終了のためのパスワード \n"
	 "<INPUT TYPE=\"password\" NAME=\"password\" VALUE=\"0000\">\n"
	 "</FORM>\n</BODY>\n</HTML>\n");

      cgi->PutResult (request_id, result);
    }

  void Quit (int request_id)
    {
      String result=>NewFromArrayOfChar
	("<HTML>\n<HEAD>\n<TITLE>Stopped !\n</TITLE>\n</HEAD>\n"
	 "<BODY>\nアンケートサーバは停止しました。\n</BODY>\n</HTML>\n");

      kill dispatcher;

      es->Stop ();

      cgi->PutResult (request_id, result);
      cgi = 0;
    }

/*
  void SendToCGI (int request_id, String result)
    {
      char orig[], conv[];
      int i, j, len;
      char c1, c2;
      String converted;

      orig = result->Content ();
      len = length orig;
      length conv = len;

      for (i = 0, j = 0; i < len; i++)
	{
	  if (orig[i] == '%')
	    {
	      c1 = orig[++i];
	      c2 = orig[++i];

	      c1 = c1 >= 'A' ? c1 - 'A' + 10 : c1 - '0';
	      c2 = c2 >= 'A' ? c2 - 'A' + 10 : c2 - '0';
	      conv[j++] = ((c1 << 4) & 0xf0) | (c2 & 0x0f);
	    }
	  else
	    conv[j++] = orig[i];
	}

      length conv = j;

      converted=>NewFromArrayOfChar (conv);
      cgi->PutResult (request_id, converted);
    }
*/
}
