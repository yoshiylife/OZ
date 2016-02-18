/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class BinaryNode : Node{
 constructor:
  New;
 public:
  Evaluate;

  /* instance variables */
  String Operator;
  Node Left;
  Node Right;
  
  /* constructors */
  void New( String o, Node l, Node r ){
    Operator = o;
    Left = l;
    Right = r;
  }

  /* public methods */
  CellValue Evaluate(){
    return Left -> Evaluate() -> BinaryOperate( Operator, Right -> Evaluate());
  }
}
