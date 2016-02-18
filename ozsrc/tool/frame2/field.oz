/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FTextField
//


class FTextField : FItem
{
constructor:
    New;

public:
    GetText, SetText;

public: // methods inherited from "FItem"
    Bind, ChangeAttributes, ChangeSlide, Disable, Draw, Enable,
    GetAnchor, GetBackground, GetForeground, GetID, GetName, GetOwner,
    GetParamInt, GetParamString, Hash, Hide, Initialize,
    IsEnabled, IsEqual, IsTerminated,
    Locate, Move, ReDraw, Resize, SetAnchor,
    SetBackground, SetForeground, SetName, SetParamInt, SetParamString,
    Terminate, UnTerminate;

public:  // methods inherited from "FComponent"
    Action, GetModel, Kind, SetModel;

protected:
    NewHolder;

protected:  // methods inherited from "FItem"
    MakeInitialArgs, makeInitialList, makePair, makePairInt, makePairInt2,
    NewAttHandler, newAttHandler;

protected:  // variables
    Text;
    
protected:  // variables inherited from "FItem"
    AttHandler,
    ID, Name, State, X, Y, Width, Height, Anchor, Background, Foreground,
    Font, FontSize, ParamInt, ParamString, Terminator;


// Instance Variabels ............................................... //
    String  Text;


// Construcotr Implementation ....................................... //

    void New()
    {
	Text=>New();
	UnTerminate();
    }


// Public Method Implementation ..................................... //

    //------------------------------------------------------------------
    void Action(FComponent target, int event, Object arg)
    {
	FSeries  srs;
	FSlide  slide;
	FModel  model;
	FHolder  holder;
	FStringHolder  str_holder;
	String  text, type=>NewFromArrayOfChar("screen");

	text = narrow(String, arg);

	switch (event) {
	case FEvent::ACTION:
	    if (type->IsEqualToArrayOfChar(Owner->Kind())) {
		slide = narrow(FScreen, Owner)->GetSeries()->GetCurrentSlide();
	    } else {
		slide = narrow(FSlide, Owner)->GetSeries()->GetCurrentSlide();
	    }
	    SetText(slide, text);
	    break;
	}

	model = GetModel();
	if (model) {
	    model->Action(target, event, arg);
	}

	if (!IsTerminated()) {
	    Owner->Action(target, event, arg);
	}
    }


    //------------------------------------------------------------------
    void ChangeSlide(FSlide slide)
    {
	ReDraw(slide);
    }


    //------------------------------------------------------------------
    String GetText(FSlide slide)
    {
	FHolder        holder;
	FStringHolder  str_holder;

	holder = slide->GetHolder(ID);
	if (holder) {
	    str_holder = narrow(FStringHolder, holder);

	    return str_holder->Get()->Duplicate();

	} else {
	    return 0;
	}
    }


    //------------------------------------------------------------------
    void Initialize()
    {
    }
    

    //------------------------------------------------------------------
    char Kind()[]
    {
	return "field";
    }


    //------------------------------------------------------------------
    FTextField SetText(FSlide slide, String txt)
    {
	FHolder  holder;
	FStringHolder  str_holder;

	if (!txt) {
	    txt=>New();
	}

	holder = slide->GetHolder(ID);
	if (holder) {
	    str_holder = narrow(FStringHolder, holder);
	} else {
	    str_holder = NewHolder();
	    slide->SetHolder(ID, str_holder);
	}
	str_holder->Assign(txt);
    
	return self;
    }


// Protected Method Implementation .................................. //

    //------------------------------------------------------------------
    FStringHolder NewHolder()
    {
	FStringHolder holder=>New();

	return holder;
    }


    //------------------------------------------------------------------
    SList MakeInitialArgs(FSlide slide)
    {
	SList  list = makeInitialList();
	String  quote=>NewFromArrayOfChar("\""), text;

	text = GetText(slide);
	if (text == 0) {
	    text=>New();
	}
	
	list->Add(
	    makePair("text",
		     quote->Concatenate(text)->Concatenate(quote)
		)
	    );

	return list;
    }

}

