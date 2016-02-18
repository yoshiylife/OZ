/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ConstantNode : Node{
 constructor:
  New;
 public:
  Evaluate;

  /* instance variables */
  CellValue Content;

  /* constructors */
  void New( String v ){
    NumericCellValue cell1;
    StringCellValue cell2;

    char c = v -> At( 0 );
    if( c >= '0' && c <= '9' ){
      cell1 => NewFromString( v );
      Content = cell1;
    }
    else{
      cell2 => NewFromString( v );
      Content = cell2;
    }
  }

  /* public methods */
  CellValue Evaluate(){ return Content; }
}
  
