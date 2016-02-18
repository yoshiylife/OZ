/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/frame 2 >>>
//
//  type: class
//  name: FCommandItemAttParamInt
//


class FCommandItemAttParamInt : FCommandFor<FItem>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "paramint";
    }


    //------------------------------------------------------------------
    int Execute(SList args)
    {
	int  val = args->Car()->AsString()->AtoI();

	Client->SetParamInt(val);

	return 0;
    }
}
