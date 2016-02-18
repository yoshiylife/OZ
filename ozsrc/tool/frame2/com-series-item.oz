/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//   <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandItemEvent
//


class FCommandItemEvent : FCommandFor<FSeries>
{
constructor:
    New;

public:
    Execute;

    char MyName()[]
    {
	return "ItemEvent";
    }


    //------------------------------------------------------------------
    // args = {event ID att_list}
    int Execute(SList args)
    {
	int  event = args->Car()->AsString()->AtoI();
	IntAsKey  ID=>New(args->Cdr()->Car()->AsString()->AtoI());
	FItem  item;
	FSlide  current = Client->GetCurrentSlide();

	inline "C" {
	    _oz_debug_flag = 1;
	}

	debug(0, "\t\tItemEvent\n");
	item = current->FindItem(ID);
	if (item == 0) {
	    item = current->GetScreen()->FindItem(ID);
	    if (item == 0) {
		debug(0, "\t\tItemEvent: item not found\n");
		raise FFrameExceptions::ObjectNotFound("ItemEvent");
	    }
	}

	switch (event) {
	case FEvent::ATTRIBUTE:
	    debug(0, "\t\tItemEvent::ATTRIBUTE\n");
	    item->ChangeAttributes(args->Cdr()->Cdr());
	    break;
	}

	return 0;
    }

}

