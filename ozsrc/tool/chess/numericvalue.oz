/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class NumericCellValue : CellValue{
 constructor:
  NewFromInteger, NewFromString, NewFromFloat;

 public:
  Print, UnaryOperate, BinaryOperate, AsStringCellValue, AsNumericCellValue;

 public:
  IsInteger, IsFloat, GetInteger, GetFloat;

 protected:
  unary_minus, unary_plus, binary_plus, binary_minus, binary_asterisk, binary_slash, binary_at, binary_sharp, binary_equal;
  
 protected:
  Rep, Type;

  /* instance vaiables */
  NumericCellValue Rep;
  int Type;

  /* constructors */
  void NewFromInteger( int i ){
    IntegerCellValue icv => new( i );
    Rep = icv;
    Type = 0;
  }

  void NewFromFloat( double f ){
    FloatCellValue fcv => new( f );
    Rep = fcv;
    Type = 1;
  }

  void NewFromString( String s ){
    Atom a => NewFromString( s );
    if( s -> StrChr( '.' ) >= 0 ){
      FloatCellValue fcv => new( a -> AsFloat() );
      Rep = fcv;
      Type = 1;
    }
    else{
      IntegerCellValue icv => new( a -> AsInteger() );
      Rep = icv;
      Type = 0;
    }
  }

  /* internal methods */
  CellValue operated(){ return Rep; }

  /* public methods */
  /* Print is inherited */
  StringCellValue AsStringCellValue(){
    return Rep -> AsStringCellValue();
  }
  NumericCellValue AsNumericCellValue(){ return self; }

  int IsInteger(){ return !IsFloat(); }
  int IsFloat(){ return Type; }
  int GetInteger(){ return Rep -> GetInteger(); }
  double GetFloat(){ return Rep -> GetFloat(); }
}
