/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * $Id$
 */

abstract class Enquete 
{
 constructor:
  New;

 public:
  SetQuestions, Register, CreateQueryHTML, CreateResultHTML,
  CheckPassword, GetTitle, AddTitle, GetName, GetMailAddress,
  AddName, AddMailAddress;

 protected:
  AddQuestion, AddAnswer;

  EnqueteItem items[];
  int no_items;
  char title[];
  char name[];
  char mail[];
  String password;

  UnixIO debugp;

  void SetQuestions () : abstract;

  int CheckPassword (String password_str)
    {
      return password->IsEqualTo (password_str);
    }
  
  void New (String password_str)
    {
      debugp=>New ();

      length items = 10;
      no_items = 0;
      password = password_str;
      SetQuestions ();
    }

  void AddTitle (char title_str[])
    {
      title = title_str;
    }

  void AddName (char name_str[])
    {
      name = name_str;
    }

  void AddMailAddress (char mail_str[])
    {
      mail = mail_str;
    }

  char GetTitle ()[]
    {
      return title;
    }

  char GetName ()[]
    {
      return name;
    }

  char GetMailAddress ()[]
    {
      return mail;
    }

  void AddQuestion (char question[])
    {
      if (no_items + 1 == length items)
	{
	  length items += 10;
	}

      items[no_items++]=>New (question);
    }

  void AddAnswer (char answer[])
    {
      items[no_items - 1]->AddAnswer (answer);
    }

  void Register (HTMLMessage inputs)
    {
      int i;
      String key;
      String comment_key;
      String comment;
      ArrayOfCharOperators aco;
      int answer;

      debugp->PutStr ("eq Register\n");

      for (i = 0; i < no_items; i++)
	{
	  key=>NewFromArrayOfChar ("answer_");
	  key=  key->ConcatenateWithArrayOfChar 
	    (aco.ItoA (i));
	  comment_key=>NewFromArrayOfChar ("comment_");
	  comment_key = comment_key->ConcatenateWithArrayOfChar 
	    (aco.ItoA (i));

	  answer = inputs->AtKey (key)->RemoveAny ()->AtoI ();
	  comment = inputs->AtKey (comment_key)->RemoveAny ();

	  items[i]->Register (answer, comment);
	}
    }
  
  String CreateResultHTML ()
    {
      String html;
      int i, j, no_answers;
      char answers[][];
      ArrayOfCharOperators aco;
      String comments[];

      debugp->PutStr ("eq CreateResultHTML\n");

      html=>NewFromArrayOfChar ("<HTML>\n<HEAD>\n<TITLE>\nResult\n"
				"</TITLE>\n</HEAD>\n<BODY>\n"
				"<DL>\n"
				"<H3>\n<DT>");

      html = html->ConcatenateWithArrayOfChar 
	(title);
      html = html->ConcatenateWithArrayOfChar 
	("\n</H3>\n<DD>");
      html = html->ConcatenateWithArrayOfChar 
	(name);
      html = html->ConcatenateWithArrayOfChar 
	("(");
      html = html->ConcatenateWithArrayOfChar 
	(mail);
      html = html->ConcatenateWithArrayOfChar 
	(")\n</DL>\n"
	 "このアンケートの集計状況は、以下の通りです。\n");

      for (i = 0; i < no_items; i++)
	{
	  html = html->ConcatenateWithArrayOfChar ("<HR>\n<H3>\n");
	  html = html->ConcatenateWithArrayOfChar (items[i]->GetQuestion ());
	  html = html->ConcatenateWithArrayOfChar ("\n</H3>\n<DL>");

	  answers = items[i]->GetAnswers ();
	  no_answers = length answers;
	  comments = items[i]->GetComments ();

	  for (j = 0; j < no_answers; j++)
	    {
	      if (answers[j] == 0)
		break;

	      html = html->ConcatenateWithArrayOfChar 
		("\n<DT>");
	      html = html->ConcatenateWithArrayOfChar 
		(answers[j]);
	      html = html->ConcatenateWithArrayOfChar 
		("\n<DD>");
	      html = html->ConcatenateWithArrayOfChar 
		(aco.ItoA (items[i]->ResultOf (j)));

	      if (comments && comments[j])
		html = html->Concatenate (comments[j]);
	    }

	  html = html->ConcatenateWithArrayOfChar ("\n</DL>\n");
	}
      
      html = html->ConcatenateWithArrayOfChar 
	("<HR>\n<FORM METHOD=\"GET\" ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" VALUE=\"enquete.html\">\n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"アンケート一覧\">\n"
	 "</FORM>\n</BODY>\n</HTML>\n");

      return html;
    }

  String CreateQueryHTML (int index)
    {
      String html;
      int i, j, no_answers;
      char answers[][];
      ArrayOfCharOperators aco;

      debugp->PutStr ("eq CreateQueryHTML\n");
      
      html=>NewFromArrayOfChar ("<HTML>\n<HEAD>\n<TITLE>\nPlease answer ?\n"
				"</TITLE>\n</HEAD>\n<BODY>\n"
				"<DL>\n"
				"<H3>\n<DT>");

      html = html->ConcatenateWithArrayOfChar 
	(title);
      html = html->ConcatenateWithArrayOfChar 
	("\n</H3>\n<DD>");
      html = html->ConcatenateWithArrayOfChar 
	(name);
      html = html->ConcatenateWithArrayOfChar 
	("(");
      html = html->ConcatenateWithArrayOfChar 
	(mail);
      html = html->ConcatenateWithArrayOfChar 
	(")\n</DL>\n");
      html = html->ConcatenateWithArrayOfChar 
	("以下の質問にお答え願います。\n<P>\n"
	 "<FORM METHOD=\"GET\" "
	 "ACTION=\"/cgi-bin/t.cgi\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"form\" "
	 "VALUE=\"enquete.html\">\n"
	 "<INPUT TYPE=\"hidden\" NAME=\"index\" "
	 "VALUE=\"");

      html = html->ConcatenateWithArrayOfChar
	(aco.ItoA (index));
      html = html->ConcatenateWithArrayOfChar
	("\">\n");

      for (i = 0; i < no_items; i++)
	{
	  html = html->ConcatenateWithArrayOfChar ("<HR>\n<H3>\n");
	  html = html->ConcatenateWithArrayOfChar (items[i]->GetQuestion ());
	  html = html->ConcatenateWithArrayOfChar ("\n</H3>\n<DL>");

	  answers = items[i]->GetAnswers ();
	  no_answers = length answers;

	  for (j = 0; j < no_answers; j++)
	    {
	      if (answers[j] == 0)
		break;

	      html = html->ConcatenateWithArrayOfChar 
		("<DT><INPUT TYPE=\"radio\" NAME=\"answer_");
	      html = html->ConcatenateWithArrayOfChar 
		(aco.ItoA (i));
	      html = html->ConcatenateWithArrayOfChar 
		("\" VALUE=");
	      html = html->ConcatenateWithArrayOfChar 
		(aco.ItoA (j));
	      if (j == 0)
		html = html->ConcatenateWithArrayOfChar 
		  (" CHECKED>\n");
	      else
		html = html->ConcatenateWithArrayOfChar 
		  (">\n");
	      html = html->ConcatenateWithArrayOfChar 
		(answers[j]);
	      html = html->ConcatenateWithArrayOfChar 
		("\n");
	    }
	  
	  html = html->ConcatenateWithArrayOfChar 
	    ("\n<DT>コメント\n<DD>\n"
	     "<TEXTAREA NAME=comment_");
	  html = html->ConcatenateWithArrayOfChar 
	    (aco.ItoA (i));
	  html = html->ConcatenateWithArrayOfChar 
	    (" ROWS=2 COLS=20>\n</TEXTAREA>\n</DL>\n");
	}

      html = html->ConcatenateWithArrayOfChar 
	("<HR>\n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"回答登録\">\n"
	 "<INPUT TYPE=\"submit\" NAME=\"command\" VALUE=\"アンケート一覧\">\n"
	 "</FORM>\n</BODY>\n</HTML>\n");

      return html;
    }
}
