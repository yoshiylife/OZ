/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
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

  unsigned int Hash () { return 0; }
}
