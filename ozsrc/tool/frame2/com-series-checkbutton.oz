/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandCheckButtonEvent
//


class FCommandCheckButtonEvent : FCommandFor<FSeries>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "CheckButtonEvent";
    }


    // args = {event ID}
    int Execute(SList args)
    {
	int  event = args->Car()->AsString()->AtoI();
	IntAsKey  ID=>New(args->Cdr()->Car()->AsString()->AtoI());
	FSlide  current = Client->GetCurrentSlide();
	FItem  item;
	FCheckButton  cbt;

	inline "C" {
	    _oz_debug_flag = 1;
	}
	item = current->FindItem(ID);
	if (item == 0) {
	    item = current->GetScreen()->FindItem(ID);
	    if (item == 0) {
		raise FFrameExceptions::ObjectNotFound("CommandCheckButtonEvent");
	    }
	}

	try {
	    cbt = narrow(FCheckButton, item);
	} except {
	    default {
		debug(0, "\t\tNarrow Failed: not FCheckButton\n");
		raise FFrameExceptions::InvalidObject("type mismatch");
	    }
	}

	switch (event) {
	case FEvent::ACTION:
	    Action(cbt, event, args);
	    break;
	}

	return 0;
    }


    //------------------------------------------------------------------
    void Action(FCheckButton cbt, int event, SList args)
    {
	int  value = args->Car()->AsString()->AtoI();
	FBinaryHolder  val_obj=>New();

	debug(0, "\t\tCheckButtonEvent::ACTION - value(%d)\n", value);

	if (value) {
	    val_obj->AsTrue();
	} else {
	    val_obj->AsFalse();
	}
	
	cbt->Action(Client, FEvent::ACTION, val_obj);
    }

}
