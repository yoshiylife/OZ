/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: class
//  name: FColor
//


class FColor
{
constructor:
    New, NewWithList;

public:
    AsList, Set, SetByList;


// Instance Variabels ............................................... //

    int Red;
    int Green;
    int Blue;

    
// Constructor Implementations ..................................... //

    void New(int r, int g, int b)
    {
	Set(r, g, b);
    }

    void NewWithList(SList list)
    {
	SetByList(list);
    }


// Public Method Implementation ..................................... //

    //------------------------------------------------------------------
    SList AsList()
    {
	SList  list=>New();
	Atom  r=>NewFromInteger(Red);
	Atom  g=>NewFromInteger(Green);
	Atom  b=>NewFromInteger(Blue);

	list->Add(r);
	list->Add(g);
	list->Add(b);

	return list;
    }


    //------------------------------------------------------------------
    FColor Set(int r, int g, int b)
    {
	Red = r;
	Green = g;
	Blue = b;

	return self;
    }


    //------------------------------------------------------------------
    FColor SetByList(SList list)
    {
	Red = list->Car()->Print()->AtoI();
	Green = list->Cdr()->Car()->Print()->AtoI();
	Blue = list->Cdr()->Cdr()->Car()->Print()->AtoI();

	return self;
    }
}

