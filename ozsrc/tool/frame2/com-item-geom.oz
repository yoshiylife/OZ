/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandItemAttGeometry
//

class FCommandItemAttGeometry : FCommandFor<FItem>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "geom";
    }


    //------------------------------------------------------------------
    //  args = {X Y}
    int Execute(SList args)
    {
	int x = args->Car()->AsString()->AtoI();
	int y = args->Cdr()->Car()->AsString()->AtoI();

	Client->Locate(x, y);

	return 0;
    }
}

