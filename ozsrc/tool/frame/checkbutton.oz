/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class CheckButton : Button ( alias Pressed SuperPressed; alias MakeInitialArgs SuperInitialArgs;){
 constructor:
  New, NewWithLabel, NewWithLabelA;
 public:
  SetLabel, GetLabel, Draw, Pressed;
 public:
  bind, getID, Move, Shift, ReDraw, SlideMove, Close, GetModel;
 public:
  SetName, SetState, SetGeometry, SetSize, SetFont, SetFontSize, SetModel;

  /* methods */
  char Kind()[]{ return "checkbutton"; }

  BinaryHolder GetHolder( Slide aSlide ){
    Holder h = aSlide -> GetHolder( ID );
    return narrow( BinaryHolder, h );
//    return h ? narrow( BinaryHolder, h ) : 0;
  }

  void Pressed( Series aSeries, Slide aSlide ){
    BinaryHolder h = GetHolder( aSlide );
    if( h )
      h -> Reverse();
    SuperPressed( aSeries, aSlide );
  }

  SList MakeInitialArgs( Slide aSlide ){
    SList aList = SuperInitialArgs( aSlide );
    BinaryHolder aHolder = narrow( BinaryHolder, aSlide -> GetHolder( ID ));

    if( aHolder == 0 ){
      aHolder => New();
      aSlide -> setHolder( ID, aHolder );
    }
    aList -> Add( make_pair_int( "check", aHolder -> IsTrue()));
    return aList;
  }

  void SlideMove( Slide aSlide ){
    ReDraw( aSlide );
  }
}
