/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ChessBoardModel : Model{
 constructor:
  NewWithDimention;

 public:
  ButtonPressed, FieldEntered, MakeItems;

  /* instance variables */
  int CurrentRow, CurrentCol;
  int NumberOfRows, NumberOfCols;
  String Name;
  Field ErrorField;

  /* constructors */
  void NewWithDimention( String n, int row, int col ){
    if( row < 1 || row > 0xffff || col < 1 || col > 0xffff ){
      raise ChessShared::RangeError;
    }

    Name = n;
    NumberOfRows = row;
    NumberOfCols = col;
  }

  /* public methods */
  void MakeItems( ChessScreen aScreen ){
    int i, j;
    Field colF, rowF, scriptF;
    int cellHeight = 40;
    int cellWidth = 50;
    SlideMover aMover => New();

    for( i = 1; i <= NumberOfRows; i++ ){
      for( j = 1; j <= NumberOfCols; j++ ){
        CellItem aField => New();
        aField -> Move(( j - 1 ) * cellWidth, ( i - 1 ) * cellHeight + 20 );
        aField -> SetSize( cellWidth, cellHeight );
        aField -> SetUsersValue( 3LL );
        aScreen -> AddItem( aField );
        {
          Item anItem = aField;
          anItem -> bind( i << 16 & 0xffff0000 | j, aScreen );
          anItem -> SetModel( self );
        }
      }
    }

    rowF => New();
    colF => New();
    scriptF => New();

    rowF -> Move( 0, NumberOfRows * cellHeight + 40 ) -> SetUsersValue( 0LL );
    rowF -> SetSize( 20, 20 );
    rowF -> SetModel( self );
    colF -> Move( 20, NumberOfRows * cellHeight + 40 ) -> SetUsersValue( 1LL );
    colF -> SetSize( 20, 20 );
    colF -> SetModel( self );

    scriptF -> SetUsersValue( 2LL );
    scriptF -> Move( 50, NumberOfRows * cellHeight + 40 );
    scriptF -> SetModel( self );
    aScreen -> AddItem( rowF );
    aScreen -> AddItem( colF );
    aScreen -> AddItem( scriptF );

    aScreen -> AddItem( aMover -> HomeButton() -> Move( 0, NumberOfRows * cellHeight + 60 ));
    aScreen -> AddItem( aMover -> PrevButton() -> Move( 50, NumberOfRows * cellHeight + 60 ));
    aScreen -> AddItem( aMover -> NextButton() -> Move ( 100, NumberOfRows * cellHeight + 60 ));

    ErrorField => New();
    aScreen -> AddItem( ErrorField -> Move( 0, NumberOfRows * cellHeight + 80 ) -> SetSize( 500, 30 ));
  }
    
  void FieldEntered( Series aSeries, Field aField, String value ){
    Slide aSlide;
    Cell aCell;
    int f;

    switch( aField -> GetUsersValue()){
    case 0:      /* row */
      f = value -> AtoI();
      if( f != CurrentRow ){
        CurrentRow = f;
        change( aSeries );
      }
      break;

    case 1:      /* col */
      f = value -> AtoI();
      if( f != CurrentCol ){
        CurrentCol = f;
        change( aSeries );
      }
      break;

    case 2: /* script */
      if( CurrentRow > 0 && CurrentRow <= NumberOfRows && CurrentCol > 0 && CurrentCol <= NumberOfCols ){
        narrow( Board, aSeries -> GetCurrentSlide()) -> GetCell( CurrentRow, CurrentCol ) -> SetExpression( value );
      }
      break;

    case 3: /* cell */
      aSlide = aSeries -> GetCurrentSlide();
      aCell = narrow( Cell, aSlide -> FindHolderByItem( aField ));

      if( aCell != 0 ){
        try{
          aCell -> Evaluate();
        }
        except{
          ChessShared::SyntaxError( n ){
            String msg => NewFromArrayOfChar( "Syntax error in " );
            error( aSeries -> GetCurrentSlide(), msg -> Concatenate( n ));
          }
          ChessShared::CannotCastToString{
            String msg => NewFromArrayOfChar( "Illegal operation. Cannot cast to string." );
            error( aSeries -> GetCurrentSlide(), msg );
          }
          ChessShared::CannotCastToNumeric{
            String msg => NewFromArrayOfChar( "Illegal operation. Cannot cast to numeric." );
            error( aSeries -> GetCurrentSlide(), msg );
          }
          ChessShared::UndefinedUnaryOperator( op ){
            String msg => NewFromArrayOfChar( "undefined unary operator '" );
            error( aSeries -> GetCurrentSlide(), msg -> ConcatenateWithArrayOfChar( op ) -> ConcatenateWithArrayOfChar( "'." ));
          }
          ChessShared::UndefinedBinaryOperator( op ){
            String msg => NewFromArrayOfChar( "undefined binary operator '" );
            error( aSeries -> GetCurrentSlide(), msg -> ConcatenateWithArrayOfChar( op ) -> ConcatenateWithArrayOfChar( "'." ));
          }
          ChessShared::UnknownBoard( b ){
            String msg => NewFromArrayOfChar( "board '" );
            error( aSeries -> GetCurrentSlide(), msg -> Concatenate( b ) -> ConcatenateWithArrayOfChar( "' not found." ));
          }
        }
        aField -> ReDraw( aSlide );
      }
      break;

    default:
      break;
    }
  }

  void error( Slide aSlide, String msg ){
    IntAsKey key;
    StringHolder aHolder;
    {
      Item anItem = ErrorField;
      key = anItem -> getID();
    }
    aHolder = narrow( StringHolder, aSlide -> GetHolder( key ));    
    if( aHolder == 0 ){
      aHolder => New();
      aSlide -> setHolder( key, aHolder );
    }
    aHolder -> Assign( msg );
    ErrorField -> ReDraw( aSlide );
  }

  void change( Series aSeries ){
/*
    IntAsKey key;
    if( CurrentRow > 0 && CurrentCol > 0 ){
      key => New( CurrentRow << 16 & 0xffff0000 | col );
      aSeries -> GetCurrentSlide() -> GetScreen() -> FindItem( key ) -> SetColor( aColor );
    }
*/
  }
}
