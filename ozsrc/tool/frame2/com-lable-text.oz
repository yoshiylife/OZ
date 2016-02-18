/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCOmmandLabelText
//


class FCommandLabelText : FCommandFor<FLabel>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "text";
    }


    int Execute(SList args)
    {
	String  text = args->Car()->AsString();
	
	Client->SetText(text);

	return 0;
    }
}
