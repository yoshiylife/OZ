/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: abstract class
//  name: FModel
//


abstract class FModel
{
public:
    Action;

protected:
    Name;


// Instance Variables ............................................... //

    String Name;

    
// Public Method Implementation ..................................... //

    void Action(FComponent target, int event, Object arg) : abstract;


    String GetName()
    {
	return Name;
    }
    

    FModel SetName(String name): locked
    {
	Name = name->Duplicate();
	return self;
    }
    
}

