/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FFrame
//


class FFrame : ResolvableObject
{
constructor:
    New, NewWithWorker;

public:
    Launch;

protected:  // variables
    MySeries;


// Instance variables ............................................... //

    FSeries  MySeries;

    
// Constructor Implementation ....................................... //

    void New() : global
    {
	MySeries=>New();
	Launch();
    }


    void NewWithWorker(FWorker worker) : global
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}
	debug(0, "\t\tFrame::NewWithWorker\n");
	MySeries=>New();
	worker->Do(MySeries);
	Launch();
    }


// Private Method Implementation .................................... //
    
    void Launch() : global
    {
	debug(0, "\t\tlaunching series...\n");
	MySeries->Start();
    }
}

