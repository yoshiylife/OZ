/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * $Id$
 */

class EnqueteServer : ResolvableObject (alias New SuperNew;)
{
 constructor:
  New;

 public:
  StartEnquete, Launch, GetEnquetes, Stop;

  Enquete enquetes[];
  int no_enquetes;

  EnqueteServerUI es_ui;

  UnixIO debugp;

  void New () : global
    {
      debugp=>New ();

      SuperNew ();
      AddName (":enquete-server");
      length enquetes = 10;
      no_enquetes = 0;
    }

  void Go () : global
    {
    }

  void Launch () : global
    {
      if (es_ui)
	return;

      debugp->PutStr ("es Launch\n");

      try 
	{
	  RegisterToNameDirectory ();
	} 
      except 
	{
	default 
	  {
	    Where ()->GetNameDirectory ()
	      ->RemoveObjectWithNameWithArrayOfChar (":enquete-server");
	    RegisterToNameDirectory ();
	  }
        }
      es_ui=>New (self);
    }

  void Stop () : global
    {
      debugp->PutStr ("es Stop\n");

      es_ui = 0;

      UnRegisterFromNameDirectory ();
    }

  void StartEnquete (String password) : global, locked
    {
      SampleEnquete sample;

      debugp->PutStr ("es StartEnquete\n");
	
      if (no_enquetes + 1 == length enquetes)
	{
	  length enquetes += 10;
	}
      
      sample=>New (password);
      enquetes[no_enquetes++] = sample;
    }

  Enquete GetEnquetes ()[]
    {
      return enquetes;
    }
}
