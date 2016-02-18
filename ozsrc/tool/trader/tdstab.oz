/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class TraderAccessStab : AccessStab{
 constructor:
  New;

  global Object Td;

  void New( global Object td ){ Td = td; }

  global Object Get(){
    return Td;
  }
}
    
