/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComISize : CommandFor<Item> {
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "size"; }

  int Execute( SList args ){
    int w = args -> Car() -> AsString() -> AtoI();
    int h = args -> Cdr() -> Car() -> AsString() -> AtoI();

    Client -> SetSize( w, h );
    return 0;
  }
}
