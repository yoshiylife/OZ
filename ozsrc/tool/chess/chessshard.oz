/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

shared ChessShared {
  UndefinedUnaryOperator(char[]);
  UndefinedBinaryOperator(char[]);
  UnknownOperator(String);
  CannotCastToString( CellValue );
  CannotCastToNumeric( CellValue );
  SyntaxError(String);
  RangeError();
  UnknownBoard(String);
}
