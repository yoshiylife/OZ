/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandItemAttColor
//

class FCommandItemAttColor : FCommandFor<FItem>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "color";
    }


    //------------------------------------------------------------------
    //  args = {type {R G B}}
    //    type = fgcolor | bgcolor
    int Execute(SList args)
    {
	String  type = args->Car()->AsString();
	SList  rgb;
	int  r, g, b;
	FColor  color;
	char  tmp[];
	int  size;

	inline "C" {
	    _oz_debug_flag = 1;
	}
	tmp = type->Content();
	debug(0, "\t\tCommandItemAttColor: type = %S\n", tmp);

	rgb = narrow(SList, args->Cdr()->Car());
	tmp = rgb->AsString()->Content();
	r = rgb->Car()->AsString()->AtoI();

	g = rgb->Cdr()->Car()->AsString()->AtoI();
	b = rgb->Cdr()->Cdr()->AsString()->AtoI();
	debug(0, "\t\tComIColor::Execute - (%d, %d, %d)\n", r, g, b);

	color=>New(r, g, b);
	if (type->IsEqualToArrayOfChar("fgcolor")) {
	    Client->SetForeground(color);
	} else if (type->IsEqualToArrayOfChar("bgcolor")) {
	    Client->SetBackground(color);
	}

	return 0;
    }
}
