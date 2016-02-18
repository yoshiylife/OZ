/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//  <<< OZ++/Frame 2 >>>
//
//  type: abstract class
//  name: FComponent
//
//

abstract class FComponent
{
public:
    Action, GetModel, Kind, SetModel;

protected:
    MyModel;


// Instance Varibales ............................................... //

    FModel   MyModel;


// Public Method Implementation ..................................... //

    void Action(FComponent target, int type, Object arg) : abstract;
    

    FModel GetModel() : abstract;


    char Kind()[] : abstract;


    void SetModel(FModel m)
    {
	MyModel = m;
    }

}
