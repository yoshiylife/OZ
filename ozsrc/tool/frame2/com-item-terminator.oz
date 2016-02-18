/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandItemAttTerminator
//


class FCommandItemAttTerminator : FCommandFor<FItem>
{
constructor:
    New;

public:
    Execute;


    //------------------------------------------------------------------
    char MyName()[]
    {
	return "terminator";
    }


    //------------------------------------------------------------------
    int Execute(SList args)
    {
	int   term = args->Car()->AsString()->AtoI();
	char  tmp[];
	
	inline "C" {
	    _oz_debug_flag = 1;
	}
	debug(0, "\t\tCommandItemTerminator: terminator = %d.\n", term);
	if (term) {
	    Client->Terminate();
	} else {
	    Client->UnTerminate();
	}

	return 0;
    }
}

