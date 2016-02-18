/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ChessScreen : Screen {
 constructor:
  NewWithDimention;

 public:
  IsEqual, Hash, GetID, AddItem, Draw,ReDraw, EraseAllItems, GetModel, SetModel, FindItem, BindModel;

 public:
  Compare, CreateBoard;

  /* inscance variables */
  int NumberOfRows;
  int NumberOfCols;

  /* constructors */
  void NewWithDimention( int r, int c ){
    New(); /* super new */
    NumberOfRows = r;
    NumberOfCols = c;
  }

  /* public methods */
  ChessScreen BindModel( ChessBoardModel aModel ){
    aModel -> MakeItems( self );
    return self;
  }
    
  global LockID GetID(){ return 0; }

  int IsEqual( Screen another ){
    ChessScreen visitor;
    try{
      visitor = narrow( ChessScreen, another );
    }
    except{
      NarrowFailed{
        return 0;
      }
    }
    return visitor -> Compare( NumberOfRows, NumberOfCols );
  }

  int Compare( int r, int c ){
    return NumberOfRows == r &&  NumberOfCols == c;
  }

  Board CreateBoard(){
    Board aBoard => newWithItems( Items );
    aBoard -> setScreen( self );
    return aBoard;
  }
}

