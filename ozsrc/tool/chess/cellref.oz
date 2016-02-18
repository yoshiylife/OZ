/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class CellReference : CellValue {
 constructor:
  newInternal, newExternal;
 public:
  Print, UnaryOperate, BinaryOperate, AsStringCellValue, AsNumericCellValue, Evaluate;

 protected:
  unary_minus, binary_plus, binary_minus, binary_asterisk, binary_slash, binary_at, binary_sharp;

  /* instance variables */
  String BoardName;
  int Row;
  int Col;
  Series MySeries;

  /* constructors */
  void newInternal( int r, int c ){ BoardName = 0; Row = r; Col = c; }
  void newExternal( String b, int r, int c ){ BoardName = b; Row = r; Col = c; }

  /* public methods */
  String Print(){
    raise ChessShared::CannotCastToString;
  }

  CellValue Evaluate(){
    int colon;
    String chessName;
    String boardName;
    global Chess aChess;

    if( BoardName != 0 && BoardName -> At( 0 ) == ':' ){ /* remote */
      if(( colon = BoardName -> StrRChr( ':' )) == 0 )
        raise CollectionExceptions<String>::UnknownKey( BoardName );

      chessName = BoardName -> GetSubString( 0, colon );
      boardName = BoardName -> GetSubString( colon + 1, BoardName -> Length() - colon - 1 );

      aChess = narrow( Chess, Where() -> GetNameDirectory() -> Resolve( chessName ));
      if( aChess == 0 ){
        raise ChessShared::UnknownBoard( BoardName );
      }
      return aChess -> Evaluate( boardName, Row, Col ) -> operated();
    }
    else{ /* internal */
      CellValue r = search_cell() -> Evaluate();
      if( BoardName == 0 ){
        narrow( Board, MySeries -> GetCurrentSlide()) -> RefreshCell( Row, Col );
      }
      return r -> operated();
    }
  }

  /* internal methods */
  CellValue operated(){ return Evaluate(); }

  Cell search_cell(){
    global Chess aChess = narrow( Chess, cell );
    unsigned int r = aChess -> get_series();
    Board aBoard;

    inline "C"{
      OZ_InstanceVariable_CellReference( MySeries ) = (OZ_Object)r;
    }
    if( BoardName == 0 )
      aBoard = narrow( Board, MySeries -> GetCurrentSlide());
    else
      aBoard = narrow( Board, MySeries -> FindSlideByName( BoardName ));
    return aBoard -> GetCell( Row, Col );
  }

  CellValue binary_equal( CellValue right ){
    String chessName, boardName;
    int colon;
    global Chess aChess;

    if( BoardName != 0 && BoardName -> At( 0 ) == ':' ){
      if(( colon = BoardName -> StrRChr( ':' )) == 0 )
        raise CollectionExceptions<String>::UnknownKey( BoardName );

      chessName = BoardName -> GetSubString( 0, colon );
      boardName = BoardName -> GetSubString( colon + 1, BoardName -> Length() - colon - 1 );
      try{
        aChess = narrow( Chess, Where() -> GetNameDirectory() -> Resolve( chessName ));
        aChess -> Assign( boardName, Row, Col, right );
      }
      except{
        CollectionExceptions<String>::UnknownKey( key ){
          raise ChessShared::UnknownBoard( BoardName );
        }
      }
    }
    else{
      search_cell() -> SetValue( right );
      if( BoardName == 0 ){
        narrow( Board, MySeries -> GetCurrentSlide()) -> RefreshCell( Row, Col );
      }
    }
    return right;
  }
}
