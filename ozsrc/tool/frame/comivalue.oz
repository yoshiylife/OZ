/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComIValue : CommandFor<Item> {
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "value"; }

  int Execute( SList args ){
    long v = args -> Car() -> AsString() -> AtoI();

    Client -> SetUsersValue( v );
    return 0;
  }
}
