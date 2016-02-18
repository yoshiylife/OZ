/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FTestModel
//


class FTestModel : FModel
{
constructor:
    New;

public:
    Action;


    void New()
    {
    }
    

// Public Methods ................................................... //

    void Action(FComponent target, int event, Object arg)
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}

	debug(0, "\tTestMode: Action called\n");
    }

}

