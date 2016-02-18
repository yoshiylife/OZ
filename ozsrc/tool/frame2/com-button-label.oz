/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandButtonLabel
//


class FCommandButtonLabel : FCommandFor<FButton>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "label";
    }


    int Execute(SList args)
    {
	String  label = args->Car()->AsString();
	
	Client->SetLabel(label);

	return 0;
    }
}

