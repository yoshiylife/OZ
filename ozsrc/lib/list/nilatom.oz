/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class NilAtom : Atom {
 constructor:
  New;
 public:
  IsNil, AsString, AsFloat, AsInteger;

  void New(){}

  int IsNil(){ return 1; }

  String AsString(){ 
    String s => New();
    return s;
  }

  double AsFloat(){ raise ListExp::IllegalInvoke; }
  int AsInteger(){ raise ListExp::IllegalInvoke; }
}
