/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ChessInitModel : FrameWorker, Model{
 constructor:
  New;

 public:
  Do, ButtonPressed, FieldEntered;

  /* instance variables */
  Field Name;
  Field Height;
  Field Width;

  /* constructors */
  void New(){}

  /* methods */
  void Do( Series aSeries ){
    /* making a control panel */
    Label title => NewWithLabelA( "OZ++/Chess" );
    Label l1 => NewWithLabelA( "name:" );
    Label l2 => NewWithLabelA( "rows:" );
    Label l3 => NewWithLabelA( "cols:" );

    Button create => NewWithLabelA( "Create" );
    Screen aScreen => New();
    Slide aSlide = aScreen -> CreateSlide();

    SlideMover aMover => New();

    Name => New();
    Height => New();
    Width => New();

    aScreen -> SetModel( self );

    title -> Move( 50, 1 );
    title -> SetFontSize( 20 );
    l1 -> Move( 10, 50 );
    Name -> Move( 50, 50 );
    l2 -> Move( 10, 100 );
    Height -> Move( 50, 100 );
    l3 -> Move( 10, 150 );
    Width -> Move( 50, 150 );
    create -> Move( 10, 200 );
    create -> SetUsersValue( 0LL );

    aSlide -> AddItem( title ) -> AddItem( Name ) -> AddItem( Height ) -> AddItem( Width ) -> AddItem( create ) -> AddItem( l1 ) -> AddItem( l2 ) -> AddItem( l3 );

    aSlide -> AddItem( aMover -> NextButton() -> Move( 10, 250 ));
    aSlide -> AddItem( aMover -> JumpButton( Name ) -> Move( 50, 250 ));

    aSeries -> AddSlide( aSlide );
  }

  void ButtonPressed( Series aSeries, Button aButton ){
    Slide aSlide;
    switch( aButton -> GetUsersValue()){
    case 0LL:
      aSlide = aSeries -> GetCurrentSlide();
      try{
        newBoard( aSeries, Name -> GetValue( aSlide ), Height -> GetValue( aSlide ) -> AtoI(), Width -> GetValue( aSlide ) -> AtoI());
        aSeries -> MoveLast();
      }
      except{
        ChessShared::RangeError{}
      }
      break;

    default:
      break;
    }
  }

  /* internal methods */
  void newBoard( Series aSeries, String n, int row, int col ){
    ChessBoardModel aModel => NewWithDimention( n, row, col );
    ChessScreen aScreen => NewWithDimention( row, col );
    Screen aScreen2;
    Label aLabel => NewWithLabel( n );
    Board aBoard;

    if(( aScreen2 = aSeries -> FindScreen( aScreen ))!= 0 ){
      aScreen = narrow( ChessScreen, aScreen2 );
      aScreen -> BindModel( aModel );
    }
    else{
      aModel -> MakeItems( aScreen );
    }
    aBoard = aScreen -> CreateBoard();
    aBoard -> SetName( n );
    aLabel -> Move( 50, 0 );
    aBoard -> AddItem( aLabel );
    aBoard -> SetModel( aModel );

    aSeries -> AddSlide( aBoard );
  }
}
