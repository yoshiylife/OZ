/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: abstract class
//  name: FItem
//


abstract class FItem : FComponent
{
public:
    Bind, ChangeAttributes, ChangeSlide, Disable, Draw, Enable,
    GetAnchor, GetBackground, GetForeground, GetID, GetName, GetOwner,
    GetParamInt, GetParamString, Hash, Hide, Initialize,
    IsEnabled, IsEqual, IsTerminated,
    Locate, Move, ReDraw, Resize, SetAnchor,
    SetBackground, SetForeground, SetName, SetParamInt, SetParamString,
    Terminate, UnTerminate;
    
public:  // inherited from "FComponent"
    Action, GetModel, Kind, SetModel;

protected:
    MakeInitialArgs, makeInitialList, makePair, makePairInt, makePairInt2,
    NewAttHandler, newAttHandler;

protected:  // variables
    AttHandler,
    ID, Name, State, X, Y, Width, Height, Anchor, Background, Foreground,
    Font, FontSize, Owner, ParamInt, ParamString, Terminator;



// Instance Variabels ............................................... //

    IntAsKey   ID;
    String     Name;
    int        State;
    int        X;
    int        Y;
    int        Width;
    int        Height;
    int        Anchor;
    FColor     Background;
    FColor     Foreground;
    String     Font;
    int        FontSize;
    int        ParamInt;
    String     ParamString;
    int        Terminator;  // 0: not terminated

    FComponent Owner;
    Evaluator  AttHandler;


// Public Method Implementation ..................................... //

    //------------------------------------------------------------------
    void Action(FComponent target, int type, Object arg) : abstract;
    
    
    //------------------------------------------------------------------
    void Bind(int id, FComponent c)
    {
	ID=>New(id);
	Owner = c;
    }
    

    //------------------------------------------------------------------
    FItem ChangeAttributes(SList list)
    {
	if (AttHandler == 0) {
	    NewAttHandler();
	}

	for ( ; !(list->IsNil()); list = list->Cdr()) {
	    SList list2 = narrow(SList, list->Car());
	    try{
		AttHandler->Execute(list2);
	    } except {
		ListExp::UnknownCommand(key){}
	    }
	}

	return self;
    }


    //------------------------------------------------------------------
    void ChangeSlide(FSlide slide)
    {
    }


    //------------------------------------------------------------------
    FItem Disable()
    {
	State = FState::DISABLED;

	return self;
    }
    

    //------------------------------------------------------------------
    void Draw(FSlide slide)
    {
	SList  list=>New();
	SimpleParser  parser=>New('{', '}', " ");
	Atom  a1=>NewFromArrayOfChar("OpenItem");
	Atom  a2=>NewFromArrayOfChar(Kind());
	Atom  a3=>NewFromInteger(ID->Get());

	list->Add(a1);
	list->Add(a2);
	list->Add(a3);
	list->AddList(MakeInitialArgs(slide));
    
	slide->GetSeries()->SendEvent(parser->AsString(list));
    }


    //------------------------------------------------------------------
    FItem Enable()
    {
	State = FState::ENABLED;

	return self;
    }
    

    //------------------------------------------------------------------
    int GetAnchor()
    {
	return Anchor;
    }


    //------------------------------------------------------------------
    FColor GetBackground()
    {
	return Background;
    }
    

    //------------------------------------------------------------------
    FColor GetForeground()
    {
	return Foreground;
    }
    

    //------------------------------------------------------------------
    IntAsKey GetID()
    {
	return ID;
    }


    //------------------------------------------------------------------
    FModel GetModel()
    {
	return MyModel;
    }


    //------------------------------------------------------------------
    String GetName()
    {
	return Name;
    }


    //------------------------------------------------------------------
    FComponent GetOwner()
    {
	return Owner;
    }
    

    //------------------------------------------------------------------
    int GetParamInt()
    {
	return ParamInt;
    }
    

    //------------------------------------------------------------------
    String GetParamString()
    {
	return ParamString;
    }
    

    //------------------------------------------------------------------
    unsigned int Hash()
    {
	return ID->Get();
    }


    //------------------------------------------------------------------
    FItem Hide(FSeries series)
    {
	SList  list=>New();
	SimpleParser  perser=>New(' ', ' ', " ");
	Atom  a1=>NewFromArrayOfChar("CloseItem");
	Atom  a2=>NewFromInteger(ID->Get());

	list->Add(a1);
	list->Add(a2);
	series->SendEvent(perser->AsString(list));

	return self;
    }


    // 不要か？
    //------------------------------------------------------------------
    void Initialize() : abstract;


    //------------------------------------------------------------------
    int IsEnabled()
    {
	return (State == FState::ENABLED);
    }
    

    //------------------------------------------------------------------
    int IsEqual(FItem another)
    {
	return ID->IsEqual(another->GetID());
    }


    //------------------------------------------------------------------
    int IsTerminated()
    {
	return Terminator;
    }
    

    //------------------------------------------------------------------
    FItem Locate(int x, int y) : locked
    {
	X = x;
	Y = y;

	return self;
    }


    //------------------------------------------------------------------
    FItem Move(int x, int y) : locked
    {
	X += x;
	Y += y;

	return self;
    }


    //------------------------------------------------------------------
    void ReDraw(FSlide slide)
    {
	SList  list=>New();
	SimpleParser  parser=>New('{', '}', " ");
	Atom  a1=>NewFromArrayOfChar("RefreshItem");
	Atom  a3=>NewFromInteger(ID->Get());

	list->Add(a1);
	list->Add(a3);
	list->AddList(MakeInitialArgs(slide));
    
	slide->GetSeries()->SendEvent(parser->AsString(list));
    }


    //------------------------------------------------------------------
    FItem Resize(int w, int h)
    {
	Width = w;
	Height = h;
	
	return self;
    }


    //------------------------------------------------------------------
    FItem SetAnchor(int a)
    {
	switch (a) {
	case FAnchor::NW:
	case FAnchor::N:
	case FAnchor::NE:
	case FAnchor::E:
	case FAnchor::SE:
	case FAnchor::S:
	case FAnchor::SW:
	case FAnchor::W:
	    Anchor = a;
	    break;
	default:
	    Anchor = FAnchor::NW;
	    debug(0, "\t\tItem::SetAnchor - warning ... unknown anchor\n");
	    break;
	}

	return self;
    }


    //------------------------------------------------------------------
    FItem SetBackground(FColor c)
    {
	Background = c;

	return self;
    }


    //------------------------------------------------------------------
    FItem SetForeground(FColor c)
    {
	Foreground = c;

	return self;
    }


    //------------------------------------------------------------------
    FItem SetName(String name)
    {
	if (name) {
	    Name = name->Duplicate();
	} else {
	    Name=>New();
	}

	return self;
    }


    //------------------------------------------------------------------
    FItem SetParamInt(int i)
    {
	ParamInt = i;

	return self;
    }


    //------------------------------------------------------------------
    FItem SetParamString(String s)
    {
	ParamString = s->Duplicate();

	return self;
    }
    

    //------------------------------------------------------------------
    FItem Terminate()
    {
	Terminator = 1;

	return self;
    }

    //------------------------------------------------------------------
    FItem UnTerminate()
    {
	Terminator = 0;

	return self;
    }
    

// Protected Method Implementation .................................. //

    //------------------------------------------------------------------
    SList MakeInitialArgs(FSlide slide)
    {
	return makeInitialList();
    }


    //------------------------------------------------------------------
    SList makeInitialList()
    {
	SList  list=>New();
	String  normal=>NewFromArrayOfChar("normal");
	String  disabled=>NewFromArrayOfChar("disabled");

	list->Add(makePairInt2("geom", X, Y));
	if (Width && Height) {
	    list->Add(makePairInt2("size", Width, Height));
	}
	if (Name) {
	    list->Add(makePair("name", Name));
	}
	list->Add(makePair("state", IsEnabled() ? normal : disabled));
	list->Add(makePairInt("value", ParamInt));
	list->Add(makePairInt("terminator", Terminator));

	return list;
    }


    //------------------------------------------------------------------
    SList makePair(char key[], String value)
    {
	SList  list=>New();
	Atom  ak=>NewFromArrayOfChar(key);
	Atom  av=>NewFromString(value);

	list->Add(ak);
	list->Add(av);

	return list; 
    }


    //------------------------------------------------------------------
    SList makePairInt(char key[], int value)
    {
	SList  list=>New();
	Atom  ak=>NewFromArrayOfChar(key);
	Atom  av=>NewFromInteger(value);

	list->Add(ak);
	list->Add(av);

	return list; 
    }


    //------------------------------------------------------------------
    SList makePairInt2(char key[], int value1, int value2)
    {
	SList  list=>New();
	Atom  ak=>NewFromArrayOfChar(key);
	Atom  av1=>NewFromInteger(value1);
	Atom  av2=>NewFromInteger(value2);

	list->Add(ak);
	list->Add(av1);
	list->Add(av2);

	return list; 
    }


    //------------------------------------------------------------------
    SList makeUpdateList()
    {
	return makeInitialList();
    }


    //------------------------------------------------------------------
    void NewAttHandler()
    {
	newAttHandler();
    }
    

    //------------------------------------------------------------------
    void newAttHandler()
    {
	FCommandItemAttGeometry     com_geom=>New(self);
	FCommandItemAttSize         com_size=>New(self);
	FCommandItemAttColor        com_color=>New(self);
	FCommandItemAttName         com_name=>New(self);
	FCommandItemAttParamInt     com_int=>New(self);
	FCommandItemAttParamString  com_string=>New(self);
	FCommandItemAttTerminator   com_term=>New(self);
	SimpleParser  parser=>New('{', '}', " \t");

    	AttHandler=>NewWithParser(parser);
	AttHandler->PutCommand(com_geom);
	AttHandler->PutCommand(com_size);
	AttHandler->PutCommand(com_color);
	AttHandler->PutCommand(com_name);
	AttHandler->PutCommand(com_int);
	AttHandler->PutCommand(com_string);
	AttHandler->PutCommand(com_term);
    }

}

