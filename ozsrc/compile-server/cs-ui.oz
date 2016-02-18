/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * $Id$
 */

class CompileServerUI : WorkbenchUI
	( alias Open WBOpen; 
	  alias ReadEvent WBReadEvent; )
{
 constructor: 
  New;

 public: 
  Register, Open, SetCurrent, InputClassObject, SetTools, ShowShortResult, 
  ShowResult, SetNewVersionID, Quit, OpenSchools, StopDispatching;

 protected:
  StartDispatching, DispatchRequest;

  global OZCGI cgi;
  global EnqueteServer es;

  int current_request_id;
  String current_source;
  char compile_done;
  
  void @dispatcher;

  UnixIO debugp;

// override methods 

  void Open (String package_name, String package_names[], String files[],
	     String cd, String lang, char class_path[], String class_name)
    {
      String cgi_name;
      
      debugp=>New ();

      cgi_name=>NewFromArrayOfChar (OZCGIConstants::CGIName);

      debugp->PutStr ("cs Open\n");

      WBOpen (package_name, package_names, files,
	      cd, lang, class_path, class_name);

      SendStr ("global wbw; wm title $wbw(WB) {OZ++ Compile Server}\n");

      cgi = narrow (OZCGI,
		    Where ()->GetNameDirectory ()->Resolve (cgi_name));

      if (cgi != 0) 
	{
	  compile_done = 1;
	  dispatcher = fork StartDispatching ();
	}
    }


  void StopDispatching ()
    {
      kill dispatcher;
    }

  void StartDispatching ()
    {
      String form_name=>NewFromArrayOfChar ("CompileServer.html");
      
      debugp->PutStr ("cs Dispatch\n");

      while (1) 
	{
	  HTMLMessage request = cgi->GetRequest (form_name);
	  
	  if (request == 0) 
	    break;
	  else
	    detach fork DispatchRequest (request);
	}
    }

  void ShowResult (String package_name, char kind[], String msg)
    {
      debugp->PutStr ("cs ShowResult\n");

      cgi->PutResult (current_request_id, ConvertToHTML (msg));
    }
  
  void ShowShortResult (String package_name, char kind[], String msg)
    {
      debugp->PutStr ("cs ShowShortResult\n");

      cgi->PutResult (current_request_id, ConvertToHTML (msg));
    }

  int ReadEvent ()
    {
      debugp->PutStr ("cs ReadEvent\n");

      if (WBReadEvent ())
	return 1;

      if (CommandIs ("CompilationDone"))
	{
	  SendNotifyOfExecution ();
	  return 0;
	}
	  
      if (CommandIs ("CompilationFailed"))
	{
	  
	  InputSourceStart (current_request_id);
	  compile_done = 1;
	  return 0;
	}

      if (CommandIs ("Opened"))
	{
	  AddFile (current_source);
	  return 0;
	}

      if (CommandIs ("Added"))
	{
	  ExecProc ("CompileForCS", 0);
	  return 0;
	}

      return 0;
    }
	  
// override methods end

  void SendNotifyOfExecution()
    {
      String result=>NewFromArrayOfChar 
	("<HTML>\n<HEAD>\n<TITLE>\nSuccess !\n"
	 "</TITLE>\n</HEAD>\n<BODY>\n"
	 "コンパイルが完了しました。\n<P>\n"
	 "これで作成したアンケートを開始させることができます\n<P>\n"
	 "<FORM METHOD=\"POST\" ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" "
	 "VALUE=\"CompileServer.html\">\n"
	 "アンケートにパスワードを設定して下さい "
	 "<INPUT TYPE=\"password\" NAME=\"password\" VALUE=\"0000\"><P>\n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"スタート\"> \n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"キャンセル\">\n"
	 "</FORM>\n</BODY>\n</HTML>");

      debugp->PutStr ("cs SendNotifyOfExecution\n");

      cgi->PutResult (current_request_id, result);
    }
  
  String ConvertToHTML (String msg)
    {
      String html;
      
      debugp->PutStr ("cs ConvertToHTML\n");

      html=>NewFromArrayOfChar 
	("<HTML>\n<HEAD>\n<TITLE>\n"
	 "</TITLE>\n</HEAD>\n<BODY>\n");
      html = html->ConcatenateWithArrayOfChar ("<PRE>");
      html = html->Concatenate (msg);
      html = html->ConcatenateWithArrayOfChar ("</PRE>");
      html = html->ConcatenateWithArrayOfChar ("</BODY>\n</HTML>\n");

      return html;
    }
  
  void DispatchRequest (HTMLMessage request)
    {
      String command_key=>NewFromArrayOfChar ("command");
      String request_id_key
	=>NewFromArrayOfChar (OZCGIConstants::KeyforRequestID);
      String command;
      int request_id;

      debugp->PutStr ("cs DispatchRequest: ");

      command = request->AtKey (command_key)->RemoveAny ();
      request_id = request->AtKey (request_id_key)->RemoveAny ()->AtoI ();
      
      debugp->PutString (command)->PutStr ("\n");

      if (command->IsEqualToArrayOfChar ("設定開始"))
	{
	  InputSourceStart (request_id);
	  return;
	}

      if (command->IsEqualToArrayOfChar ("Input"))
	{
	  InputSource (request, request_id);
	  return;
	}

      if (command->IsEqualToArrayOfChar ("コンパイル"))
	{
	  Compile (request, request_id);
	  return;
	}

      if (command->IsEqualToArrayOfChar ("スタート"))
	{
	  Execute (request, request_id);
	  return;
	}

      if (command->IsEqualToArrayOfChar ("キャンセル"))
	{
	  InputSourceStart (request_id);
	  compile_done = 1;
	  return;
	}
    }
  
  void Compile (HTMLMessage request, int request_id)
    {
      String source_key=>NewFromArrayOfChar ("source");
      String source;
      
      debugp->PutStr ("cs Compile\n");

      source = request->AtKey (source_key)->RemoveAny ();

      InvokeCFE (source, request_id);
    }
  
  void InvokeCFE (String source, int request_id) : locked
    {
      String command;

      debugp->PutStr ("cs InvokeCFE\n");

      if (!compile_done)
	return;

      compile_done = 0;

      current_request_id = request_id;
      current_source = source;

      ExecProc ("OpenCFEforCS", 0);
    }

      
  void AddFile (String source)
    {
      UnixIO file;
      EnvironmentVariable env;
      String buf;
      char args[][];
      int pos;

      debugp->PutStr ("cs AddFile\n");

      while ((pos = source->StrChr (0x0d)) > -1)
	source->SetAt (pos, ' ');

      file=>Open ("tmp/cs_user_src.oz", "w", 0644);
      file->WriteString (source);
      file->Close ();

      buf = env.GetEnv ("OZROOT")->ConcatenateWithArrayOfChar ("/tmp/")
	->ConcatenateWithArrayOfChar ("cs_user_src.oz");

      length args = 2;
      args[0] = "CompileServer";
      args[1] = buf->Content ();

      ExecProc ("AddFileForCS", args);
    }

  void Execute (HTMLMessage request, int request_id)
    {
      String password_key=>NewFromArrayOfChar ("password");
      String result;
      String es_name=>NewFromArrayOfChar (":enquete-server");

      debugp->PutStr ("cs Execute\n");

      es = narrow (EnqueteServer,
		   Where ()->GetNameDirectory ()->Resolve (es_name));

      if (!es)
	{
	  compile_done = 1;
	  result=>NewFromArrayOfChar 
	    ("<HTML>\n<HEAD>\n<TITLE>\nStarted !\n"
	     "</TITLE>\n</HEAD>\n<BODY>\n"
	     "アンケートサーバが動作していないため、開始できませんでした。\n");
	}
      else
	{
	  es->StartEnquete (request->AtKey (password_key)->RemoveAny ());
	  compile_done = 1;

	  result=>NewFromArrayOfChar 
	    ("<HTML>\n<HEAD>\n<TITLE>\nStarted !\n"
	     "</TITLE>\n</HEAD>\n<BODY>\n"
	     "アンケートを開始しました。<P>\n"
	     "アンケート一覧を見るには、"
	     "<A HREF=/cgi-bin/t.cgi?form=enquete.html&command=List>"
	     "ここ</A>を押して下さい。\n");
	}
	  
      result = result->ConcatenateWithArrayOfChar
	("</BODY>\n</HTML>\n");

      cgi->PutResult (request_id, result);
    }
  
  void InputSourceStart (int request_id)
    {
      String result=>NewFromArrayOfChar 
	("<HTML>\n<HEAD>\n<TITLE>\nLet's begin !\n"
	 "</TITLE>\n</HEAD>\n<BODY>\n"
	 "まずあなたのお名前、メイルアドレス、タイトルを入力して下さい。\n"
	 "<P>\n"
	 "<FORM METHOD=\"POST\" ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" "
	 "VALUE=\"CompileServer.html\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"command\" VALUE=\"Input\">\n");

      debugp->PutStr ("cs InputSourceStart\n");

      result = result->ConcatenateWithArrayOfChar 
	("<DL>\n<DT>お名前\n"
	 "<DD><INPUT TYPE=\"text\" NAME=\"name\"><P>\n"
	 "<DT>メイルアドレス\n"
	 "<DD><INPUT TYPE=\"text\" NAME=\"mail\"><P>\n"
	 "<DT>タイトル\n"
	 "<DD><INPUT TYPE=\"text\" NAME=\"title\">\n</DL>\n<P>\n"
	 "<INPUT TYPE=\"submit\" NAME=\"kind\" VALUE=\"タイトルの登録\"><P>\n"
	 "<HR>\n"
	 "現在のソースは以下のようになっています。"
	 "(絶対に変更しないで下さい)<P>\n"
	 "<TEXTAREA NAME=\"source\" ROWS=\"20\" COLS=\"80\">\n");
      
      result = result->ConcatenateWithArrayOfChar 
	("class SampleEnquete : Enquete \n"
	 "{\n"
	 " constructor:\n"
	 "  New;\n\n"
	 " public:\n"
	 "  Register, CreateQueryHTML, CreateResultHTML;\n\n"
	 "   void SetQuestions ()\n"
	 "     {\n");
	   
      result = result->ConcatenateWithArrayOfChar 
	("</TEXTAREA>\n"
	 "</BODY>\n</HTML>\n");
	   
      cgi->PutResult (request_id, result);
    }
	 
  void InputSource (HTMLMessage request, int request_id)
    {
      String kind_key=>NewFromArrayOfChar ("kind");
      String kind;
      String result=>NewFromArrayOfChar 
	("<HTML>\n<HEAD>\n<TITLE>\nLet's begin !\n"
	 "</TITLE>\n</HEAD>\n<BODY>\n"
	 "質問を設定して下さい。\n<P>\n"
	 "\"質問+回答1+回答2+...回答n\"の形式で入力して下さい。\n<P>\n<HR>\n"
	 "<FORM METHOD=\"POST\" ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" "
	 "VALUE=\"CompileServer.html\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"command\" VALUE=\"Input\">\n");

      debugp->PutStr ("cs InputSource: ");

      kind = request->AtKey (kind_key)->RemoveAny ();
	
      debugp->PutString (kind)->PutStr ("\n");

      result = result->ConcatenateWithArrayOfChar 
	     ("質問内容\n"
	      "<TEXTAREA NAME=\"content\" ROWS=10 COLS=80>\n"
	      "</TEXTAREA><P>\n"
	      "<INPUT TYPE=\"submit\" NAME=\"kind\" VALUE=\"質問の登録\"> \n"
	      "<INPUT TYPE=\"submit\" NAME=\"kind\" VALUE=\"入力終了\"><P>\n"
	      "<HR>\n"
	      "現在のソースは以下のようになっています。"
	      "(絶対に変更しないで下さい)<P>\n"
	      "<TEXTAREA NAME=\"source\" ROWS=\"20\" COLS=\"80\">\n");

      if (kind->IsEqualToArrayOfChar ("タイトルの登録"))
	{
	  String source_key=>NewFromArrayOfChar ("source");
	  String source;
	  String title_key=>NewFromArrayOfChar ("title");
	  String title;
	  String name_key=>NewFromArrayOfChar ("name");
	  String name;
	  String mail_key=>NewFromArrayOfChar ("mail");
	  String mail;

	  source = request->AtKey (source_key)->RemoveAny ();
	  title = request->AtKey (title_key)->RemoveAny ();
	  name = request->AtKey (name_key)->RemoveAny ();
	  mail = request->AtKey (mail_key)->RemoveAny ();
	  
	  source = source->ConcatenateWithArrayOfChar 
	    ("       AddName (\"");
	  source = source->Concatenate (name);
	  source = source->ConcatenateWithArrayOfChar ("\");\n");

	  source = source->ConcatenateWithArrayOfChar 
	    ("       AddMailAddress (\"");
	  source = source->Concatenate (mail);
	  source = source->ConcatenateWithArrayOfChar ("\");\n");

	  source = source->ConcatenateWithArrayOfChar 
	    ("       AddTitle (\"");
	  source = source->Concatenate (title);
	  source = source->ConcatenateWithArrayOfChar ("\");\n");

	  result = result->Concatenate (source);
	  result = result->ConcatenateWithArrayOfChar 
	    ("</TEXTAREA>\n"
	     "</BODY>\n</HTML>\n");

	  cgi->PutResult (request_id, result);

	  return;
	}

      if (kind->IsEqualToArrayOfChar ("質問の登録"))
	{
	  String source_key=>NewFromArrayOfChar ("source");
	  String source;
	  String content_key=>NewFromArrayOfChar ("content");
	  String contents[];

	  source = request->AtKey (source_key)->RemoveAny ();
	  contents = ParseContent (request->AtKey (content_key)->RemoveAny ());
	  
	  if (length contents > 2)
	    {
	      int i, len;

	      source = source->ConcatenateWithArrayOfChar 
		("\n       AddQuestion (\"");
	      source = source->Concatenate (contents[0]);
	      source = source->ConcatenateWithArrayOfChar ("\");\n");

	      len = length contents;
	      for (i = 1; i < len; i++)
		{
		  source = source->ConcatenateWithArrayOfChar 
		    ("       AddAnswer (\"");
		  source = source->Concatenate (contents[i]);
		  source = source->ConcatenateWithArrayOfChar ("\");\n");
		}
	    }

	  result = result->Concatenate (source);
	  result = result->ConcatenateWithArrayOfChar 
	    ("</TEXTAREA>\n"
	     "</BODY>\n</HTML>\n");

	  cgi->PutResult (request_id, result);

	  return;
	}

      if (kind->IsEqualToArrayOfChar ("入力終了"))
	{
	  String source_key=>NewFromArrayOfChar ("source");
	  String source;

	  source = request->AtKey (source_key)->RemoveAny ();
	  result=>NewFromArrayOfChar 
	    ("<HTML>\n<HEAD>\n<TITLE>\nPrepared !\n"
	     "</TITLE>\n</HEAD>\n<BODY>\n"
	     "<FORM METHOD=\"POST\" ACTION=\"/cgi-bin/t.cgi\">\n"
	     "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"コンパイル\">"
	     "<P>\n"
	     "<INPUT TYPE=\"hidden\" NAME=\"form\" "
	     "VALUE=\"CompileServer.html\">\n"
	      "<HR>\n"
	      "現在のソースは以下のようになっています。"
	      "(絶対に変更しないで下さい)<P>\n"
	      "<TEXTAREA NAME=\"source\" ROWS=\"20\" COLS=\"80\">\n");

	  result = result->Concatenate (source);
	  result = result->ConcatenateWithArrayOfChar 
	    ("     }\n"
      	     "}\n"
	     "</TEXTAREA>\n"
	     "</BODY>\n</HTML>\n");

	  cgi->PutResult (request_id, result);

	  return;
	}
    }
	  

  String ParseContent (String content) []
    {
      String str, tmp[], args[];
      int i = 0, p, num = 16, len, j; 

      debugp->PutStr ("cs ParseContent\n");

      if (!content)
	 return 0;

      length args = num;

      str = content;
      len = content->Length ();
       
      while (len > 0 && str && ((p = str->StrChr ('+')) >= 0))
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
	    args[i++] = 0;

	  if ((len -= (p + 1)))
	    {
	      str = str->GetSubString (p + 1, len);
	    }
	}


      if (str)
	{
	  args[i]=>New ();
	  if (str->StrChr ('+') < 0)
	    args[i]->Assign (str);
	  i++;
	}

      if (args)
	{
	  length args = i;

/*
	  for (j = 0; j < i; j++)
	    debugp->PutInt (j)->PutStr (": ")
	      ->PutString (args[j])->PutReturn ();
*/
	}
      else
	length args = 1;

      return args;
    }

/*
  String OctalEscape (String source)
    {
      char str[], result_str[];
      String result;
      int i, len, j;
      char c;
      
      str = source->Content ();
      len = length str;

      length result_str = len * 3;
      
      for (i = 0, j = 0; i < len; i++)
	{
	  if (str[i] & 0x80)
	    {
	      result_str[j++] = '%';

	      c = (str[i] >> 4) & 0x0f;
	      if (c < 10)
		result_str[j++] = c + '0';
	      else
		result_str[j++] = 'A' + c - 10;

	      c = (str[i++] & 0x0f);
	      if (c < 10)
		result_str[j++] = c + '0';
	      else
		result_str[j++] = 'A' + c - 10;

	      result_str[j++] = '%';

	      c = (str[i] >> 4) & 0x0f;
	      if (c < 10)
		result_str[j++] = c + '0';
	      else
		result_str[j++] = 'A' + c - 10;

	      c = (str[i] & 0x0f);
	      if (c < 10)
		result_str[j++] = c + '0';
	      else
		result_str[j++] = 'A' + c - 10;
	    }
	  else
	    result_str[j++] = str[i];
	}

      length result_str = j;
      result=>NewFromArrayOfChar (result_str);

      return result;
    }
*/
 }
