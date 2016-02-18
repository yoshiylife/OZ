/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class FloatCellValue : NumericCellValue{
 constructor:
  new;
 public:
  Print, UnaryOperate, BinaryOperate, AsStringCellValue, AsNumericCellValue;
 protected:
  unary_minus, binary_plus, binary_minus, binary_asterisk, binary_slash, binary_at, binary_sharp;

  /* instance variables */
  double Content;

  /* constructors */
  void new( double f ){ Content = f; }

  /* public methods */
  StringCellValue AsStringCellValue(){
    Atom a => NewFromFloat( Content );
    StringCellValue newValue => NewFromString( a -> AsString());
    return newValue;
  }

  int GetInteger(){ return Content; }
  double GetFloat(){ return Content; }

  /* internal methods */
  CellValue unary_minus(){
    NumericCellValue newValue => NewFromFloat( -Content );
    return newValue;
  }

  CellValue unary_plus(){
    NumericCellValue newValue => NewFromFloat( Content );
    return newValue;
  }

  CellValue binary_plus( CellValue right ){
    NumericCellValue newValue => NewFromFloat( Content + right -> AsNumericCellValue() -> GetFloat());
    return newValue;      
  }

  CellValue binary_minus( CellValue right ){
    String op => NewFromArrayOfChar( "-" );
    return binary_plus( right -> UnaryOperate( op ));
  }

  CellValue binary_asterisk( CellValue right ){
    NumericCellValue newValue => NewFromFloat( Content * right -> AsNumericCellValue() -> GetFloat());
    return newValue;      
  }

  CellValue binary_slash( CellValue right ){
    NumericCellValue newValue => NewFromFloat( Content / right -> AsNumericCellValue() -> GetFloat());
    return newValue;      
  }
}
