/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<<  >>>
//
//  type: class
//  name: Checkbutton
//


class FCheckButton : FItem
{
constructor:
    New, NewWithLabel, NewWithLabelAndValue;

public:
    DeSelect, GetLabel, IsSelected, Select, SetLabel, Toggle;

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
    int     Value;


// Construcotr Implementation ....................................... //

    void New()
    {
	Label=>New();
	DeSelect();
	UnTerminate();
    }

    void NewWithLabel(String l)
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}
	SetLabel(l);
	DeSelect();
	UnTerminate();
    }

    void NewWithLabelAndValue(String label, int value)
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}
	SetLabel(label);
	UnTerminate();
	value ? Select() : DeSelect();
    }


// Public Method Implementation ..................................... //

    //------------------------------------------------------------------
    void Action(FComponent target, int event, Object arg)
    {
	FModel model = GetModel();
	FBinaryHolder  val;

	switch (event) {
	case FEvent::ACTION:
	    val = narrow(FBinaryHolder, arg);
	    val->IsTrue() ? Select() : DeSelect();
	    break;
	}
	
	if (model) {
	    model->Action(target, event, arg);
	}

	if (!IsTerminated()) {
	    Owner->Action(target, event, arg);
	}
    }


    //------------------------------------------------------------------
    FCheckButton DeSelect()
    {
	Value = 0;

	return self;
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
    int IsSelected()
    {
	return Value;
    }
    

    //------------------------------------------------------------------
    char Kind()[]
    {
	return "checkbutton";
    }


    //------------------------------------------------------------------
    void ReDraw(FSlide slide)
    {
    }


    //------------------------------------------------------------------
    FCheckButton Select()
    {
	Value = 1;

	return self;
    }


    //------------------------------------------------------------------
    FCheckButton SetLabel(String label)
    {
	if (label) {
	    Label = label->Duplicate();
	} else {
	    Label=>New();
	}

	return self;
    }


    //------------------------------------------------------------------
    FCheckButton Toggle()
    {
	Value = Value ? 0 : 1;

	return self;
    }


// Protected Method Implemenation ................................... //

    //------------------------------------------------------------------
    void NewAttHandler()
    {
	FCommandCheckButtonLabel com1=>New(self);

	newAttHandler();
	AttHandler->PutCommand(com1);
    }


    //------------------------------------------------------------------
    SList MakeInitialArgs(FSlide slide)
    {
	SList att_list = makeInitialList();
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

	att_list->Add(makePairInt("value", Value));

	return att_list;
    }
}
