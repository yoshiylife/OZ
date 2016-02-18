/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComILabelText : CommandFor<Label>{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "text"; }

  int Execute( SList args ){
    Client -> SetText( args -> Car() -> AsString());
    return 0;
  }
}
