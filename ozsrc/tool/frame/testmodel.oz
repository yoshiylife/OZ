/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class TestModel : Model{
 constructor:
  New;
 public:
  ButtonPressed, FieldEntered;

  void New(){}

  void ButtonPressed( Series aSeries, Button aButton ){
    try{
      aSeries -> ShiftSlide( 1 );
    }
    except{
      default{
        aSeries -> MoveSlide( 0 );
      }
    }
  }

  void FieldEntered( Series aSeries, Field aField, String value ){}
}
