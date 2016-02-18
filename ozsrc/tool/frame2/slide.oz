/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FSlide
//


class FSlide : FComponent
{
constructor:
    New, NewWithItems;

public:
    AddHolder, AddItem, CompareName, Draw, FindHolderFromItem, FindItem,
    GetHolder, GetName, GetScreen, GetSeries,
    Hash, HideAllItems, IsEqual, IsTerminated, ReDraw, RemoveItem,
    SetHolder, SetName, SetScreen, SetSeries, Terminate, UnTerminate;

public:  // inherited from "FComponent"
    Action, GetModel, Kind, SetModel;

protected:
    NewID;

protected:  // variables
    Items, Holders, Name, Terminator;


// Instance varibales ............................................... //

    Set<FItem>                     Items;
    Dictionary<IntAsKey, FHolder>  Holders;
    FScreen                        MyScreen;
    FSeries                        MySeries;
    String                         Name;
    int                            NextID;
    int                            Terminator;
    
    
// Constructor Implementation ....................................... //

    void New()
    {
	Items=>New();
	Holders=>New();
	Name=>New();
	NextID = 0;
	UnTerminate();
    }

    void NewWithItems(Set<FItem> items)
    {
	Iterator<FItem>  i=>New(items);
	FItem  item;

	inline "C" {
	    _oz_debug_flag = 1;
	}
	Holders=>New();
	while (item = i->PostIncrement()) {
	    Holders->AddAssoc(item->GetID(), 0);
	}
	Items=>New();
	Name=>New();
	NextID = 0;
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
	    debug(0, "\t\tSlide: my Action\n");
	    MyModel->Action(target, event, arg);
	} else {
	    debug(0, "\t\tSlide: no Model\n");
	}

	if (!IsTerminated()) {
	    MyScreen->Action(target, event, arg);
	}
    }


    //------------------------------------------------------------------
    FSlide AddHolder(IntAsKey key, FHolder holder)
    {
	Holders->AddAssoc(key, holder);

	return self;
    }


    //------------------------------------------------------------------
    FSlide AddItem(FItem item)
    {
	item->Bind(NewID(), self);
	Items->Add(item);
	Holders->AddAssoc(item->GetID(), 0);

	return self;
    }


    //------------------------------------------------------------------
    int CompareName(String name)
    {
	return Name ? Name->IsEqual(name) : 0;
    }


    //------------------------------------------------------------------
    void Draw()
    {
	Iterator<FItem>  i=>New(Items);
	FItem  item;

	while (item = i->PostIncrement()) {
	    item->Draw(self);
	}
    }


    //------------------------------------------------------------------
    FHolder FindHolderFromItem(FItem item)
    {
	return GetHolder(item->GetID());
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
    FHolder GetHolder(IntAsKey key)
    {
	return Holders->AtKey(key);
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
    FScreen GetScreen()
    {
	return MyScreen;
    }


    //------------------------------------------------------------------
    FSeries GetSeries()
    {
	return MySeries;
    }


    //------------------------------------------------------------------
    unsigned int Hash()
    {
	return Name ? Name->Hash() : 0;
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
    int IsEqual(FSlide another)
    {
	return 0;
    }


    //------------------------------------------------------------------
    IsTerminated()
    {
	return Terminator;
    }
    

    //------------------------------------------------------------------
    char Kind()[]
    {
	return "slide";
    }


    //------------------------------------------------------------------
    void ReDraw()
    {
	Iterator<FItem>  i=>New(Items);
	FItem  item;

	while (item = i->PostIncrement()) {
	    item->ReDraw(self);
	}
    }


    //------------------------------------------------------------------
    FItem RemoveItem(IntAsKey key)
    {
	FItem  item;

	item = Items->Remove(FindItem(key));
	Holders->RemoveKey(key);

	return item;
    }


    //------------------------------------------------------------------
    void SetHolder(IntAsKey key, FHolder value)
    {
	Holders->SetAtKey(key, value);
    }


    //------------------------------------------------------------------
    FSlide SetName(String name)
    {
	Name = name->Duplicate();

	return self;
    }


    //------------------------------------------------------------------
    void SetScreen(FScreen screen)
    {
	MyScreen = screen; 
    }


    //------------------------------------------------------------------
    void SetSeries(FSeries srs)
    {
	MySeries = srs; 
    }


    //------------------------------------------------------------------
    FSlide Terminate()
    {
	Terminator = 1;

	return self;
    }


    //------------------------------------------------------------------
    FSlide UnTerminate()
    {
	Terminator = 0;

	return self;
    }


// Protected Method Implementation .................................. //

    int NewID()
    {
	return --NextID;
    }
}

