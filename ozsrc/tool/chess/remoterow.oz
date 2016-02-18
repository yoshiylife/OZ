/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class RemoteRow : CellValue {
 constructor:
  new;
 public:
  Print, UnaryOperate, BinaryOperate, AsStringCellValue, AsNumericCellValue;

 protected:
  unary_minus, binary_plus, binary_minus, binary_asterisk, binary_slash, binary_at, binary_sharp;

  /* instance variables */
  String BoardName;
  int    Row;

 /* construtors */
  void new( String b, int r ){ BoardName = b; Row = r; }

  /* public methods */
  String Print(){
    raise ChessShared::CannotCastToString;
  }

  /* internal methods */
  CellValue binary_at( CellValue right ){
    CellReference newValue => newExternal( BoardName, Row, right -> AsNumericCellValue() -> GetInteger());
    return newValue;
  }
}
