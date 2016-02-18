/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name FSeries
//


class FSeries : FComponent
{
constructor:
    New;

public:
    AddSlide, Cardinality, DrawCurrentSlide, FindScreen, FindSlideByName,
    GetCurrentSlide, GetName, GotoFirstSlide, GotoLastSlide, GotoSlideAt,
    GotoSlideByName,
    Quit, Resize, SetName, SendEvent, ShiftSlide, Start;

public:  // inherited from "FComponent"
    Action, GetModel, Kind, SetModel;

protected:
    Name, Width, Height;


// Instance Varibales ............................................... //

    OrderedCollection<FSlide>    Slides;
    Set<FScreen>                 Screens;
    FSlide                       CurrentSlide;
    FSlide                       LastSlide;
    int                          Index;
    Evaluator                    Eval;
    OText                        Sock;

    String  Name;
    int  Width;
    int  Height;


// Constructors ..................................................... //
    
    void New()
    {
	SimpleParser              parser=>New('{', '}', " \t\n");
	FCommandSeriesEvent       com_series=>New(self);
	FCommandItemEvent         com_item=>New(self);
	FCommandButtonEvent       com_button=>New(self);
	FCommandCheckButtonEvent  com_checkbutton=>New(self);
	FCommandTextFieldEvent    com_textfield=>New(self);
	
	inline "C" {
	    _oz_debug_flag = 1;
	    OzSetDebug(1);
	}
	debug(0, "\t\tSeries::New ... ");
	Slides=>New();
	Screens=>New();
	CurrentSlide = 0; 
	LastSlide = 0;
	Index = 0;
	Resize(FSize::SERIES_DEFAULT_W, FSize::SERIES_DEFAULT_W);

	Eval=>NewWithParser(parser);
	Eval->PutCommand(com_series);
	Eval->PutCommand(com_item);
	Eval->PutCommand(com_button);
	Eval->PutCommand(com_checkbutton);
	Eval->PutCommand(com_textfield);

	debug(0, "done.\n");
    }


// Public Methods ................................................... //

    //------------------------------------------------------------------
    void Action(FComponent target, int event, Object arg)
    {
	if (MyModel) {
	    MyModel->Action(target, event, arg);
	}
    }


    //------------------------------------------------------------------
    void AddSlide(FSlide slide)
    {
	FScreen  old_scr, new_scr = slide->GetScreen();
	int  n_slides;

	inline "C" {
	    _oz_debug_flag = 1;
	}

	if (new_scr == 0) {
	    // スクリーンを持たないスライドは追加できない
	    // 将来、例外にする
	    return;
	}

	if (Screens->Includes(new_scr)) {
	    old_scr = Screens->FindObjectWithKey(new_scr);
	    slide->SetScreen(old_scr);
	} else {
	    Screens->Add(new_scr);
	}

	slide->SetSeries(self);
	if (Slides->Size() <= 0) {
	    CurrentSlide = slide;
	}
	Slides->AddLast(slide);
	new_scr->SetSeries(self);
	debug(0, "\t\tSeries: AddSlide, SetSeries\n");

	n_slides = Slides->Size();
	debug(0, "\t\tSeries::AddSlide  size=%d\n", n_slides);
    }


    //------------------------------------------------------------------
    int Cardinality()
    {
	return Slides->Size();
    }
    

    //------------------------------------------------------------------
    void DrawCurrentSlide() : locked
    {
	FScreen  current_scr, last_scr;

	if (CurrentSlide == 0) {
	    return;
	}

	current_scr = CurrentSlide->GetScreen();

	if (LastSlide != 0) {
	    LastSlide->HideAllItems(self);
	    last_scr = LastSlide->GetScreen();

	    if (last_scr != current_scr) {
		last_scr->HideAllItems(self);
		current_scr->Draw(CurrentSlide);
		CurrentSlide->Draw();
	    } else {
		current_scr->ChangeSlide(CurrentSlide);
		CurrentSlide->Draw();
	    }

	} else {
	    current_scr->Draw(CurrentSlide);
	    CurrentSlide->Draw();
	}
    }


    //------------------------------------------------------------------
    FScreen FindScreen(FScreen screen)
    {
	return Screens->FindObjectWithKey(screen);
    }


    //------------------------------------------------------------------
    FSlide FindSlideByName(String name)
    {
	Iterator<FSlide>  i=>New(Slides);
	FSlide  slide;

	if (name) {
	    while (slide = i->PostIncrement()) {
		if (slide->CompareName(name)) {

		    return slide;
		}
	    }
	    raise FFrameExceptions::ObjectNotFound(name->Content());

	} else {
	    raise FFrameExceptions::InvalidObject("slide name");
	}
    }


    //------------------------------------------------------------------
    FSlide GetCurrentSlide()
    {
	return CurrentSlide;
    }


    //------------------------------------------------------------------
    String GetName()
    {
	if (Name) {
	    return Name->Duplicate();
	} else {
	    return 0;
	}
    }


    //------------------------------------------------------------------
    FModel GetModel()
    {
	return MyModel;
    }


    //------------------------------------------------------------------
    int GotoFirstSlide()
    {
	return GotoSlideAt(0);
    }


    //------------------------------------------------------------------
    int GotoLastSlide()
    {
	return GotoSlideAt(Slides->Size() - 1);
    }


    //------------------------------------------------------------------
    int GotoSlideAt(int i)
    {
	if (i < 0 || i >= Slides->Size()) {
	    raise FFrameExceptions::InvalidArgument;
	    // raise FFrameExceptions::InvalidArgument();
	    // return 0;
	}

	LastSlide = CurrentSlide;
	CurrentSlide = Slides->At(i);
	Index = i;
	DrawCurrentSlide();

	return Index;
    }


    //------------------------------------------------------------------
    int GotoSlideByName(String name)
    {
	Iterator<FSlide>  i=>New(Slides);
	FSlide  slide;
	int  idx;

	for (idx = 0; slide = i->PostIncrement(); idx++) {
	    if (slide->CompareName(name)) {
		return GotoSlideAt(idx);
	    }
	}

	raise CollectionExceptions<String>::UnknownKey(name);
    }


    //------------------------------------------------------------------
    char Kind()[]
    {
	return "sereis";
    }


    //------------------------------------------------------------------
    void Quit()
    {
	Sock->Close();
    }


    //------------------------------------------------------------------
    FSeries Resize(int w, int h)
    {
	Width = w;
	Height = h;
	debug(0, "\t\tSeries::Resize (%d, %d)\n", w, h);

	return self;
    }
    

    //------------------------------------------------------------------
    void SendEvent(String str)
    {
	Sock->PutLine(str);
	Sock->FlushBuf();
    }


    //------------------------------------------------------------------
    FSeries SetName(String name)
    {
	if (name) {
	    Name = name->Duplicate();
	} else {
	    Name->AssignFromArrayOfChar("");
	}

	return self;
    }
    

    //------------------------------------------------------------------
    int ShiftSlide(int i)
    {
	return GotoSlideAt((Index + i) % Slides->Size());
    }


    //------------------------------------------------------------------
    void Start()
    {
	String  path;
	EnvironmentVariable  env;
	String  com=>NewFromArrayOfChar("source ");
	String  srs=>NewFromArrayOfChar("OpenSeries ");
	char  tmp[];
	ArrayOfCharOperators  acop;

	inline "C" {
	    _oz_debug_flag = 1;
	    OzSetDebug(1);
	}
	debug(0, "\t\tSeries::Start\n");
	path=>NewFromArrayOfChar("wish");
	Eval->Spawn(path, 0);
	Sock = Eval->GetOText();

	// load the Tcl script
	com = com->Concatenate(env.GetEnv("OZROOT"))
	    ->ConcatenateWithArrayOfChar("/lib/gui/frame2/ga-mut.tcl");
	tmp = com->Content();
	debug(0, "\t\tSeries::Start - load Tcl script = %S\n", tmp);
	SendEvent(com);

	if (Name) {
	    srs = srs->Concatenate(Name);
	} else {
	    srs = srs->ConcatenateWithArrayOfChar("\"\" ");
	}
	srs = srs->ConcatenateWithArrayOfChar(acop.ItoA(Width))
	    ->ConcatenateWithArrayOfChar(" ")
	    ->ConcatenateWithArrayOfChar(acop.ItoA(Height));
	tmp = srs->Content();
	debug(0, "\t\tOpenSeries string - %S\n", tmp);
	SendEvent(srs);

	detach fork Eval->EventLoop();
	LastSlide = 0;
	DrawCurrentSlide();
    }

}

