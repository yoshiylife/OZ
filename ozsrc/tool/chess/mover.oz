/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class SlideMover : Model {
 constructor:
  New;

 public:
  ButtonPressed, FieldEntered;

 public:
  HomeButton, PrevButton, NextButton, LastButton, JumpButton;

  /* instance variables */
  Field JumpField;

  /* constructors */
  void New(){}

  /* public methods */
  Button HomeButton(){
    Button b1 => NewWithLabelA( "Home" );
    b1 -> SetUsersValue( 0LL );
    b1 -> SetModel( self );

    return b1;
  }

  Button PrevButton(){
    Button b1 => NewWithLabelA( "Prev" );
    b1 -> SetUsersValue( 1LL );
    b1 -> SetModel( self );

    return b1;
  }

  Button NextButton(){
    Button b1 => NewWithLabelA( "Next" );
    b1 -> SetUsersValue( 2LL );
    b1 -> SetModel( self );

    return b1;
  }

  Button LastButton(){
    Button b1 => NewWithLabelA( "Last" );
    b1 -> SetUsersValue( 3LL );
    b1 -> SetModel( self );

    return b1;
  }

  Button JumpButton( Field aField ){
    Button b1 => NewWithLabelA( "Jump" );
    b1 -> SetUsersValue( 4LL );
    b1 -> SetModel( self );
    JumpField = aField;
    return b1;
  }    

  void ButtonPressed( Series aSeries, Button aButton ){
    int value = aButton -> GetUsersValue();
    try{
      switch( value ){
      case 0:
        aSeries -> MoveFirst();
        break;

      case 1:
        aSeries -> ShiftSlide( -1 );
        break;

      case 2:
        aSeries -> ShiftSlide( 1 );
        break;

      case 3:
        aSeries -> MoveLast();
        break;

      case 4:
        aSeries -> MoveSlideByName( JumpField -> GetValue( aSeries -> GetCurrentSlide()));
        break;

      default:
        break;
      }
    }
    except{
      CollectionExceptions<Slide>::InvalidIntParameter( i ){}
    }
  }
}
