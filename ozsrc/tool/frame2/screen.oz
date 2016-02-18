/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FScreen
//


class FScreen : FComponent
{
constructor:
    New, NewWithName;

public:
    AddItem, ChangeSlide, FindItem, Draw, GetID, GetName, GetSeries,
    Hash, HideAllItems, IsEqual, IsTerminated, NewSlide, ReDraw, RemoveItem,
    SetName, SetSeries, Terminate, UnTerminate;

public:  // inherited from "FComponent"
    Action, GetModel, Kind, SetModel;

protected:
    NewID;

protected:  // variables
    Items, Name, Terminator;


// Instance Varibales ............................................... //

    global LockID   ID;
    String          Name;
    Set<FItem>      Items;
    FSeries         MySeries;
    int             NextID;
    int             Terminator;


// Constructor Implementation ....................................... //

    void New()
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}
	ID=>New();
	Items=>New();
	NextID = 0;
	UnTerminate();
    }

    void NewWithName(String name)
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}
	ID=>New();
	Items=>New();
	NextID = 0;
	SetName(name);
	UnTerminate();
    }


// Public Method Implementation ..................................... //

    //------------------------------------------------------------------
    void Action(FComponent target, int event, Object arg)
    {
	inline "C" {
	    _oz_debug_flag = 1;
	}
	if (MyModel) {
	    debug(0, "\t\tScreen: my Action\n");
	    MyModel->Action(target, event, arg);
	} else {
	    debug(0, "\t\tScreen: no Model\n");
	}

	if (!IsTerminated()) {
	    MySeries->Action(target, event, arg);
	}
    }


    //------------------------------------------------------------------
    FScreen AddItem(FItem item)
    {
	item->Bind(NewID(), self);
	Items->Add(item);
	debug(0, "\t\tScreen::AddItem\n");

	return self;
    }


    //------------------------------------------------------------------
    void ChangeSlide(FSlide slide)
    {
	Iterator<FItem>  i=>New(Items);
	FItem  item;

	while (item = i->PostIncrement()) {
	    item->ChangeSlide(slide);
	}
    }


    //------------------------------------------------------------------
    void Draw(FSlide slide)
    {
	Iterator<FItem>  i=>New(Items);
	FItem  item;

	while (item = i->PostIncrement()) {
	    item->Draw(slide);
	}
    }


    //------------------------------------------------------------------
    FItem FindItem(IntAsKey key)
    {
	Iterator<FItem>  i=>New(Items);
	FItem  item;
	int  k;

	k = key->Get();
	while (item = i->PostIncrement()) {
	    if (item->GetID()->IsEqual(key)) {
		debug(0, "\t\tSlide::FindItem - item found (%d)\n", k);

		return item;
	    }
	}

	debug(0, "\t\tSlide::FindItem - item not found (%d)\n", k);

	return 0;
    }


    //------------------------------------------------------------------
    global LockID GetID()
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
    FSeries GetSeries()
    {
	return MySeries;
    }


    //------------------------------------------------------------------
    unsigned int Hash()
    {
	global LockID  id = ID;
	unsigned  int r;

	inline "C"{
	    r = 0xffffffff & id;
	}

	return r;
    }


    //------------------------------------------------------------------
    void HideAllItems(FSeries series)
    {
	Iterator<FItem>  i=>New(Items);
	FItem  item;

	while (item = i->PostIncrement()) {
	    item->Hide(series);
	}
    }


    //------------------------------------------------------------------
    int IsEqual(FScreen another)
    {
	return ID == another->GetID();
    }


    //------------------------------------------------------------------
    int IsTerminated()
    {
	return (Terminator != 0);
    }


    //------------------------------------------------------------------
    char Kind()[]
    {
	return "screen";
    }


    //------------------------------------------------------------------
    FSlide NewSlide()
    {
	FSlide  slide=>NewWithItems(Items);

	slide->SetScreen(self);
	inline "C" {
	    OzDebugf("\t\tScreen::NewSlide\n");
	}

	return slide;
    }


    //------------------------------------------------------------------
    void ReDraw(FSlide slide)
    {
	Iterator<FItem>  i=>New(Items);
	FItem  item;

	while (item = i->PostIncrement()) {
	    item->ReDraw(slide);
	}
    }


    //------------------------------------------------------------------
    FItem RemoveItem(IntAsKey key)
    {
	FItem  i = Items->Remove(FindItem(key));
	// このスクリーンを使っているすべてのスライドの Holders から
	// 対応する Holder を削除する必要がある

	return i;
    }


    //------------------------------------------------------------------
    FScreen SetName(String name)
    {
	if (name) {
	    Name = name->Duplicate();
	} else {
	    Name=>New();
	}

	return self;
    }


    //------------------------------------------------------------------
    FScreen SetSeries(FSeries srs)
    {
	MySeries = srs;

	return self;
    }


    //------------------------------------------------------------------
    FScreen Terminate()
    {
	Terminator = 1;

	return self;
    }


    //------------------------------------------------------------------
    FScreen UnTerminate()
    {
	Terminator = 0;

	return self;
    }


// Protected Method Implementation .................................. //

    int NewID()
    {
	return ++NextID;
    }

}

