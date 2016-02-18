/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Parser1 : SimpleParser ( alias New SuperNew; ){
 constructor:
  New;
 public:
  Parse, AsString;

  void New(){ SuperNew( '(', ')', " \t\n" ); }
}
