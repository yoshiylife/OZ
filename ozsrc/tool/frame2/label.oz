/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FLabel
//


class FLabel : FItem
{
constructor:
    New, NewWithLabel, NewWithAlignedLabel;

public:
    GetAlignment, GetText, SetAlignment, SetText;

public: // inherited from "FItem"
    Bind, ChangeAttributes, ChangeSlide, Disable, Draw, Enable,
    GetAnchor, GetBackground, GetForeground, GetID, GetName,
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

protected:  // variables inherited from "FItem"
    AttHandler,
    ID, Name, State, X, Y, Width, Height, Anchor, Background, Foreground,
    Font, FontSize, ParamInt, ParamString, Terminator;


// Instance Variabels ............................................... //

    String  Text;
    int     Align;  // FAlign::(LEFT | CENTER | RIGHT)


// Construcotr Implementation ....................................... //

    void New()
    {
	Text=>New();
	UnTerminate();
    }

    void NewWithLabel(String label)
    {
	SetText(label);
	UnTerminate();
    }

    void NewWithAlignedLabel(String label, int align)
    {
	SetText(label);
	SetAlignment(align);
	UnTerminate();
    }
    

// Public Method Implementation ..................................... //

    //------------------------------------------------------------------
    void Action(FComponent target, int event, Object arg)
    {
    }

    //------------------------------------------------------------------
    int GetAlignment()
    {
	return Align;
    }
    

    //------------------------------------------------------------------
    String GetText()
    {
	return Text ? Text->Duplicate() : 0;
    }


    //------------------------------------------------------------------
    void Initialize()
    {
    }
    

    //------------------------------------------------------------------
    FLabel SetAlignment(int align)
    {
	if (align == FAlign::CENTER || align == FAlign::RIGHT) {
	    Align = align;
	} else {
	    Align = FAlign::LEFT;
	}

	return self;
    }
    

    //------------------------------------------------------------------
    FLabel SetText(String text)
    {
	char  tmp[];
	
	if (text) {
	    Text = text->Duplicate();
	} else {
	    Text=>New();
	}

	tmp = Text->Content();
	inline "C" {
	    OzDebugf("\tLabel::SetText Text=%S\n", tmp);
	}

	return self;
    }


// Protected Method Implementation .................................. //

    //------------------------------------------------------------------
    char Kind()[]
    {
	return "string";
    }


    //------------------------------------------------------------------
    void NewAttHandler()
    {
	FCommandLabelText com1=>New(self);

	newAttHandler();
	AttHandler->PutCommand(com1);
    }


    //------------------------------------------------------------------
    SList MakeInitialArgs(FSlide slide)
    {
	SList  att_list = makeInitialList();
	SList  color_list=>New();
	SList  rgb;
	int  align;
	String  align_str, content_str;
	Atom  a1=>NewFromArrayOfChar("color");
	Atom  a2=>NewFromArrayOfChar("fgcolor");
	char  tmp[];

	content_str=>NewFromArrayOfChar("\"");
	content_str = content_str->Concatenate(Text)
	    ->ConcatenateWithArrayOfChar("\"");
	att_list->Add(makePair("text", content_str));

	// Alignment
	align = GetAlignment();
	if (align == FAlign::CENTER) {
	    align_str=>NewFromArrayOfChar("center");
	} else if (align == FAlign::RIGHT) {
	    align_str=>NewFromArrayOfChar("right");
	} else {
	    align_str=>NewFromArrayOfChar("left");
	}
	att_list->Add(makePair("justify", align_str));

	// Colors
	if (Foreground) {
	    rgb = Foreground->AsList();
	    color_list->Add(a1);
	    color_list->Add(a2);
	    color_list->Add(rgb);
	    att_list->Add(color_list);

	    tmp = rgb->AsString()->Content();
	    debug(0, "\t\tLabel::MakeInitialArgs foreground = %S\n", tmp);
	}

	return att_list;
    }
}

