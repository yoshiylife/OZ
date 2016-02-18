/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandButton
//


class FCommandButtonEvent : FCommandFor<FSeries>
{
constructor:
    New;

public:
    Execute;


    char MyName()[]
    {
	return "ButtonEvent";
    }


// Public Method Implementation ..................................... //

    //  args {event ID}
    int Execute(SList args)
    {
	int  event = args->Car()->AsString()->AtoI();
	IntAsKey  ID=>New(args->Cdr()->Car()->AsString()->AtoI());
	FSlide  current = Client->GetCurrentSlide();
	FItem  item;
	FButton  button;

	inline "C" {
	    _oz_debug_flag = 1;
	}

	debug(0, "\t\tButtonEvent\n");
	item = current->FindItem(ID);
	if (item == 0) {
	    debug(0, "\t\t\t ...not Slide's\n");
	    item = current->GetScreen()->FindItem(ID);
	    if (item == 0) {
		debug(0, "\t\t\t ...not found !!!\n");
		raise FFrameExceptions::ObjectNotFound("FCommandButtonEvent");
	    }
	}
	debug(0, "\t\t\t ...found !!!\n");
	try {
	    button = narrow(FButton, item);
	} except {
	    default {
		debug(0, "\t\tNarrow Failed: not FButton\n");
		raise FFrameExceptions::InvalidObject("type mismatch");
	    }
	}

	switch (event) {
	case FEvent::ACTION:
	    debug(0, "\t\t ACTION\n");
	    if (button) {
		button->Action(button, event, current);
	    } else {
		debug(0, "\t\t\tButtonEvent: null reference\n");
	    }
	    break;
	}
	    
	return 0;
    }
}

