/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FButton
//


class FButton : FItem
{
constructor:
    New, NewWithLabel;

public:
    GetLabel, SetLabel;

public: // inherited from "FItem"
    Bind, ChangeAttributes, ChangeSlide, Disable, Draw, Enable,
    GetAnchor, GetBackground, GetForeground, GetID, GetName, GetOwner,
    GetParamInt, GetParamString, Hash, Hide, Initialize,
    IsEnabled, IsEqual, IsTerminated,
    Locate, Move, ReDraw, Resize, SetAnchor,
    SetBackground, SetForeground, SetName, SetParamInt, SetParamString,
    Terminate, UnTerminate;

public:  // inherited from "FComponent"
    Action, GetModel, Kind, SetModel;

protected:  // inherited from "FItem"
    MakeInitialArgs, makeInitialList, makePair, makePairInt, makePairInt2,
    NewAttHandler, newAttHandler;

protected:  //variables
    Label;

protected:  // variables inherited from "FItem"
    AttHandler,
    ID, Name, State, X, Y, Width, Height, Anchor, Background, Foreground,
    Font, FontSize, ParamInt, ParamString, Terminator;


// Instance Variabels ............................................... //

    String  Label;


// Construcotr Implementation ....................................... //

    void New()
    {
	Label=>New();
	UnTerminate();
    }


    void NewWithLabel(String label)
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}
	SetLabel(label);
	UnTerminate();
    }


// Public Method Implementation ..................................... //

    //------------------------------------------------------------------
    void Action(FComponent target, int event, Object arg)
    {
	FModel model = GetModel();

	inline "C" {
	    _oz_debug_flag = 1;
	}
	debug(0, "\t\tButton Action\n");
	if (model) {
	    debug(0, "\t\t...my Action\n");
	    model->Action(target, event, arg);
	} else {
	    debug(0, "\t\t...no Model\n");
	}

	if (!IsTerminated()) {
	    if (!Owner) {
		debug(0, "\t\t\t... no Owner\n");
	    } else {
		debug(0, "\t\t\t... pass to Owner\n");
		Owner->Action(target, event, arg);
	    }
	}
    }


    //------------------------------------------------------------------
    String GetLabel()
    {
	return Label ? Label->Duplicate() : 0;
    }


    //------------------------------------------------------------------
    void Initialize()
    {
    }
    

    //------------------------------------------------------------------
    char Kind()[]
    {
	return "button";
    }


    //------------------------------------------------------------------
    void ReDraw(FSlide slide)
    {
    }


    //------------------------------------------------------------------
    FButton SetLabel(String label)
    {
	if (!Label) {
	    Label=>New();
	}
	if (label) {
	    Label->Assign(label);
	} else {
	    Label->AssignFromArrayOfChar("");
	}

	return self;
    }


// Protected Method Implementation .................................. //

    //------------------------------------------------------------------
    void NewAttHandler()
    {
	FCommandButtonLabel com1=>New(self);

	newAttHandler();
	AttHandler->PutCommand(com1);
    }


    //------------------------------------------------------------------
    SList MakeInitialArgs(FSlide slide)
    {
	SList  att_list = makeInitialList();
	SList  color_list;
	SList  rgb;
	Atom  a1=>NewFromArrayOfChar("color");
	Atom  a2=>NewFromArrayOfChar("bgcolor");
	Atom  a3=>NewFromArrayOfChar("fgcolor");
	char  tmp[];

	inline "C" {
	    _oz_debug_flag = 1;
	}
	att_list->Add(makePair("label", Label));

	if (Foreground) {
	    rgb = Foreground->AsList();
	    color_list=>New();
	    color_list->Add(a1);
	    color_list->Add(a3);
	    color_list->Add(rgb);
	    att_list->Add(color_list);

	    tmp = rgb->AsString()->Content();
	    debug(0, "\t\tButton::MakeInitialArgs foreground = %S\n", tmp);
	} else {
	    debug(0, "\t\tButton::MakeInitialArgs no foreground\n");
	}

	if (Background) {
	    rgb = Background->AsList();
	    color_list=>New();
	    color_list->Add(a1);
	    color_list->Add(a2);
	    color_list->Add(rgb);
	    att_list->Add(color_list);

	    tmp = rgb->AsString()->Content();
	    debug(0, "\t\tButton::MakeInitialArgs background = %S\n", tmp);
	} else {
	    debug(0, "\t\tButton::MakeInitialArgs no background\n");
	}

	return att_list;
    }
}
