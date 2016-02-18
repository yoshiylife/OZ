/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type class
//  name: FBinaryHolder
//


class FBinaryHolder : FHolder
{
constructor:
    New;

public:
    AsFalse, AsTrue, IsFalse, IsTrue, Reverse;


// Instance Variabels ............................................... //

    int Value;


// Constructor Implementation ....................................... //

    void New()
    {
	Value = 0;
    }


// Public Method Implementation ..................................... //

    void AsFalse()
    {
	Value = 0;
    }
    

    void AsTrue()
    {
	Value = 1;
    }
    

    int IsFalse()
    {
	return !Value;
    }


    int IsTrue()
    {
	return Value;
    }
    

    FBinaryHolder Reverse()
    {
	Value = (Value == 0);

	return self;
    }
}

