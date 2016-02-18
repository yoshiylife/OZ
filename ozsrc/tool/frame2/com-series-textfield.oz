/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandTextFieldEvent
//


class FCommandTextFieldEvent : FCommandFor<FSeries>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "TextFieldEvent";
    }


    //  args = {event ID text}
    int Execute(SList args)
    {
	int  event = args->Car()->AsString()->AtoI();
	IntAsKey  key=>New(args->Cdr()->Car()->AsString()->AtoI());
	FSlide  current = Client->GetCurrentSlide();
	FItem  item;
	FTextField  field;

	inline "C" {
	    _oz_debug_flag = 1;
	}
	item = current->FindItem(key);
	if (item == 0) {
	    item = current->GetScreen()->FindItem(key);
	    if (item == 0) {
		raise FFrameExceptions::ObjectNotFound("TextFieldEvent");
	    }
	}

	try {
	    field = narrow(FTextField, item);
	} except {
	    default {
		debug(0, "\t\tNarrow Failed: not FTextButton\n");
		raise FFrameExceptions::InvalidObject("type mismatch");
	    }
	}

	switch (event) {
	case FEvent::ACTION:
	    Action(field, event, args);
	    break;
	}

	return 0;
    }


    //------------------------------------------------------------------
    void Action(FTextField field, int event, SList args)
    {
	String  txt = args->Car()->AsString();
	char  tmp[];

	tmp = txt->Content();
	debug(0, "\t\tComEntered::Execute - txt(%S)\n", tmp);

	field->Action(field, FEvent::ACTION, txt);
    }

}
