/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class CellValue{
 public:
  Print, UnaryOperate, BinaryOperate, AsStringCellValue, AsNumericCellValue;

 public:
  unary_minus, unary_plus, binary_plus, binary_minus, binary_asterisk, binary_slash, binary_at, binary_sharp, binary_equal, operated;

  /* internal methods */
  void undefined_u( char op[] ){
    raise ChessShared::UndefinedUnaryOperator( op );
  }
  void undefined_b( char op[] ){
    raise ChessShared::UndefinedBinaryOperator( op );
  }

  CellValue unary_minus(){ undefined_u( "-" ); }
  CellValue unary_plus(){ undefined_u( "+" ); }
  CellValue binary_plus( CellValue right ){ undefined_b( "+" ); }
  CellValue binary_minus( CellValue right ){ undefined_b( "-" ); }
  CellValue binary_asterisk( CellValue right ){ undefined_b( "*" ); }
  CellValue binary_slash( CellValue right ){ undefined_b( "/" ); }
  CellValue binary_at( CellValue right ){ undefined_b( "@" ); }
  CellValue binary_sharp( CellValue right ){ undefined_b( "#" ); }
  CellValue binary_equal( CellValue right ){ undefined_b( "=" ); }

  CellValue operated(){ return self; }

  /* public methods */
  String Print(){ return AsStringCellValue() -> Print(); }

  CellValue UnaryOperate( String op ){
    if( op -> IsEqualToArrayOfChar( "-" )){
      return operated() -> unary_minus();
    }
    else if( op -> IsEqualToArrayOfChar( "+" )){
      return operated() -> unary_plus();
    }
    else
      raise ChessShared::UnknownOperator( op );
  }

  CellValue BinaryOperate( String op, CellValue right ){
    if( op -> IsEqualToArrayOfChar( "+" )){
      return operated() -> binary_plus( right );
    }
    else if ( op -> IsEqualToArrayOfChar( "-" )){
      return operated() -> binary_minus( right );
    }
    else if( op -> IsEqualToArrayOfChar( "*" )){
      return operated() -> binary_asterisk( right );
    }
    else if( op -> IsEqualToArrayOfChar( "/" )){
      return operated() -> binary_slash( right );
    }
    else if( op -> IsEqualToArrayOfChar( "@" )){
      return operated() -> binary_at( right );
    }
    else if( op -> IsEqualToArrayOfChar( "#" )){
      return operated() -> binary_sharp( right );
    }
    else if( op -> IsEqualToArrayOfChar( "=" )){
      return binary_equal( right );
    }
    else{
      raise ChessShared::UnknownOperator( op );
    }
  }

  StringCellValue AsStringCellValue(){ raise ChessShared::CannotCastToString(self); }
  NumericCellValue AsNumericCellValue(){ raise ChessShared::CannotCastToNumeric(self); }
}
