/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/frame 2 >>>
//
//  type: class
//  name: FCommandItemAttParamString
//


class FCommandItemAttParamString : FCommandFor<FItem>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "paramstring";
    }


    //------------------------------------------------------------------
    int Execute(SList args)
    {
	String  val = args->Car()->AsString();

	Client->SetParamString(val);

	return 0;
    }
}
