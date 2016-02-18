/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandItemAttName
//


class FCommandItemAttName : FCommandFor<FItem>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "name";
    }


    //------------------------------------------------------------------
    int Execute(SList args)
    {
	String  name;
	char  tmp[];
	
	inline "C" {
	    _oz_debug_flag = 1;
	}
	name = args->Car()->AsString();
	tmp = name->Content();
	debug(0, "\t\tComIName::Execute - name = %S.\n", tmp);
	Client->SetName(name);

	return 0;
    }
}

