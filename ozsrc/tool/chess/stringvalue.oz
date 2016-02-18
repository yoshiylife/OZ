/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class StringCellValue : CellValue {
 constructor:
  NewFromString, NewFromArrayOfChar;

 public:
  Print, UnaryOperate, BinaryOperate, AsStringCellValue, AsNumericCellValue;

 protected:
  unary_minus, binary_plus, binary_minus, binary_asterisk, binary_slash, binary_at, binary_sharp;

  /* instance variables */
  String Content;

  /* constructors */
  void NewFromString( String s ){ Content = s; }
  void NewFromArrayOfChar( char aoc[] ){ Content => NewFromArrayOfChar( aoc ); }

  /* public methods */
  String Print(){ return Content; }
  StringCellValue AsStringCellValue(){ return self; }
  NumericCellValue AsNumericCellValue(){
    NumericCellValue newValue;
    Atom a => NewFromString( Content );

    if( Content -> StrChr( '.' ) >= 0 ){
      newValue => NewFromFloat( a -> AsFloat());
    }
    else{
      newValue => NewFromInteger( a -> AsInteger());
    }
    return newValue;
  }

  /* internal methods */
  CellValue binary_plus( CellValue right ){
    StringCellValue newValue => NewFromString( Content -> Concatenate( right -> AsStringCellValue() -> Print()));
    return newValue;
  }

  CellValue binary_sharp( CellValue right ){
    RemoteRow newValue => new( Print(), right -> AsNumericCellValue() -> GetInteger());
    return newValue;
  }
}
