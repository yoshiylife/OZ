/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class UnaryNode : Node{
 constructor:
  New;
 public:
  Evaluate;

  /* instance variables */
  String Operator;
  Node Right;

  /* constructors */
  void New( String o, Node r ){
    Operator = o;
    Right = r;
  }

  /* public methods */
  CellValue Evaluate(){
    return Right -> Evaluate() -> UnaryOperate( Operator );
  }
}
