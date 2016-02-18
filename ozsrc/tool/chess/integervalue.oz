/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class IntegerCellValue : NumericCellValue{
 constructor:
  new;
 public:
  Print, UnaryOperate, BinaryOperate, AsStringCellValue, AsNumericCellValue;
 protected:
  unary_minus, binary_plus, binary_minus, binary_asterisk, binary_slash, binary_at, binary_sharp;

  /* instance variables */
  int  Content;

  /* constructors */
  void new( int i ){ Content = i; }

  /* public methods */
  double GetFloat(){ return Content + 0.0; }
  int GetInteger(){ return Content; }

  StringCellValue AsStringCellValue(){
    Atom a => NewFromInteger( Content );
    StringCellValue newValue => NewFromString( a -> AsString());
    return newValue;
  }

  /* internal methods */
  CellValue unary_minus(){
    NumericCellValue newValue => NewFromInteger( -Content );
    return newValue;
  }

  CellValue unary_plus(){
    NumericCellValue newValue => NewFromInteger( Content );
    return newValue;
  }

  CellValue binary_plus( CellValue right ){
    NumericCellValue newValue;
    NumericCellValue r2 = right -> AsNumericCellValue();

    if( r2 -> IsInteger()){
      newValue => NewFromInteger( Content + r2 -> GetInteger());
    }
    else{
      newValue => NewFromFloat( Content + r2 -> GetFloat());
    }
    return newValue;      
  }

  CellValue binary_minus( CellValue right ){
    String op => NewFromArrayOfChar( "-" );
    return binary_plus( right -> UnaryOperate( op ));
  }

  CellValue binary_asterisk( CellValue right ){
    NumericCellValue newValue;
    NumericCellValue r2 = right -> AsNumericCellValue();

    if( r2 -> IsInteger()){
      newValue => NewFromInteger( Content * r2 -> GetInteger()); 
    }
    else{
      newValue => NewFromFloat( Content * r2 -> GetFloat());
    }
    return newValue;      
  }

  CellValue binary_slash( CellValue right ){
    NumericCellValue newValue;
    NumericCellValue r2 = right -> AsNumericCellValue();

    if( r2 -> IsInteger()){
      newValue => NewFromInteger( Content / r2 -> GetInteger()); 
    }
    else{
      newValue => NewFromFloat( Content / r2 -> GetFloat());
    }
    return newValue;      
  }

  CellValue binary_at( CellValue right ){
    CellReference newValue => newInternal( Content, right -> AsNumericCellValue() -> GetInteger());
    return newValue;
  }
}
