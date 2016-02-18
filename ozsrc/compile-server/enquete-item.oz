/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * $Id$
 */

class EnqueteItem 
{
 constructor:
  New;

 public:
  AddAnswer, Register, GetQuestion, ResultOf, GetAnswers, GetComments;

  char question[];
  char answers[][];
  int no_answers;
  int results[];
  String comments[];

  void New (char question_str[])
    {
      question = question_str;

      length answers = length results = 10;
      no_answers = 0;
    }

  void AddAnswer (char answer_str[])
    {
      if (no_answers + 1 == length answers)
	{
	  length answers += 10;
	  length results += 10;
	}

      answers[no_answers] = answer_str;
      results[no_answers++] = 0;
    }

  void Register (int index_of_answer, String comment_str)
    {
      results[index_of_answer] += 1;
      if (comment_str->Length ())
	{
	  if (!comments)
	    {
	      length comments = no_answers;
	      comments[index_of_answer]=>NewFromArrayOfChar ("<UL>");
	    }

	  if (!comments[index_of_answer])
	    comments[index_of_answer]=>NewFromArrayOfChar ("<UL>");

	  comments[index_of_answer] 
	    = comments[index_of_answer]->ConcatenateWithArrayOfChar ("\n<LI>")
	      ->Concatenate (comment_str);
	}
    }

  char GetQuestion ()[]
    {
      return question;
    }

  int ResultOf (int index_of_answer)
    {
      return results[index_of_answer];
    }

  char GetAnswers ()[][]
    {
      return answers;
    }

  String GetComments ()[]
    {
      int i;
      String buf[];

      if (!comments)
	return 0;

      length buf = no_answers;
      
      for (i = 0; i < no_answers; i++)
	if (comments[i])
	  buf[i] = comments[i]->ConcatenateWithArrayOfChar ("\n</UL>");

      return buf;
    }
}
