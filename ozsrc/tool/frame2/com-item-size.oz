/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandItemAttSize
//


class FCommandItemAttSize : FCommandFor<FItem>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "size";
    }


    //------------------------------------------------------------------
    //  args = {W H}
    int Execute(SList args)
    {
	int w = args->Car()->AsString()->AtoI();
	int h = args->Cdr()->Car()->AsString()->AtoI();

	Client->Resize(w, h);

	return 0;
    }
}

