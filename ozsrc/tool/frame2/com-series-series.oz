/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FCommandSeriesEvent
//


class FCommandSeriesEvent : FCommandFor<FSeries>
{
constructor:
    New;

public:
    Execute;


    char MyName()[]
    {
	return "SeriesEvent";
    }


    //------------------------------------------------------------------
    int Execute(SList args)
    {
	int  event = args->Car()->AsString()->AtoI();

	inline "C" {
	    _oz_debug_flag = 1;
	}

	debug(0, "\t\tSeriesEvent\n");
	switch (event) {
	case FEvent::QUIT:
	    Client->Quit();
	    return 1;
	    break;

	case FEvent::ACTION:
	    Client->Action(Client, FEvent::ACTION, 0);
	    break;

	case FEvent::ATTRIBUTE:
	    Attribute(args->Cdr());
	    break;

	case FEvent::DELETE_ITEM:
	    DeleteItem(args->Cdr());
	    break;

	case FEvent::DELETE_SLIDE:
	    DeleteSlide(args->Cdr());
	    break;

	case FEvent::GOTO_SLIDE:
	    debug(0, "\t\t\t...GOTO_SLIDE\n");
	    GotoSlide(args->Cdr());
	    break;

	case FEvent::NEW_SLIDE:
	    NewSlide(args->Cdr());
	    break;

	}

	return 0;
    }


// Private Method Implementation .................................... //

    //------------------------------------------------------------------
    //  args = {att_list}
    void Attribute(SList args)
    {
    }


    //------------------------------------------------------------------
    //  args = {ID}
    void DeleteItem(SList args)
    {
	IntAsKey  key=>New(args->Car()->AsString()->AtoI());
	FSlide  current = Client->GetCurrentSlide();
	FScreen  screen;

	if (current->FindItem(key)) {
	    current->RemoveItem(key);
	} else {
	    screen = current->GetScreen();
	    if (screen->FindItem(key)) {
		screen->RemoveItem(key);
	    } else {
		raise FFrameExceptions::ObjectNotFound("SeriesEvent::DELETE_ITEM");
	    }
	}
    }


    //------------------------------------------------------------------
    // args = {}
    void DeleteSlide(SList args)
    {
    }


    //------------------------------------------------------------------
    //  args = {pos}
    //  pos = first | prev | next | last
    void GotoSlide(SList args)
    {
	FSlide  current = Client->GetCurrentSlide();
	String  pos = args->Car()->AsString();
	char  tmp[];

	inline "C" {
	    _oz_debug_flag = 1;
	}
	tmp = pos->Content();
	debug(0, "\t\t...GOTO_SLIDE: pos = %S\n", tmp);

	if (pos->IsEqualToArrayOfChar("first")) {
	    Client->GotoFirstSlide();
	} else if (pos->IsEqualToArrayOfChar("last")) {
	    Client->GotoLastSlide();
	} else if (pos->IsEqualToArrayOfChar("prev")) {
	    Client->ShiftSlide(-1);
	} else if (pos->IsEqualToArrayOfChar("next")) {
	    Client->ShiftSlide(1);
	}
    }


    //------------------------------------------------------------------
    // args = {}
    void NewSlide(SList args)
    {
	FSlide  new_sld, current_sld;
	FScreen  current_scr;

	inline "C" {
	    _oz_debug_flag = 1;
	}
	
	current_sld = Client->GetCurrentSlide();
	if (current_sld) {
	    debug(0, "\t\tevent NewSlide - generating...");
	    current_scr = current_sld->GetScreen();
	    if (current_scr) {
		new_sld = current_scr->NewSlide();
		debug(0, " done.\n");

		//  In this version, the new Slide is appended to the tail.
		Client->AddSlide(new_sld);
		Client->GotoLastSlide();
	    } else {
		debug(0, " current screen not found.\n");
	    }
	}
    }

}

