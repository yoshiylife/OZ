/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComJunkshop : CommandFor<Series> {
 constructor:
  New;
 public:
  Execute;

  /* instance variables */
  JunkshopBrowser aJS;

  /* methods */
  char MyName()[]{ return "Junkshop"; }

  int Execute( SList args ){
    String m = args -> Car() -> AsString();

    if( m -> IsEqualToArrayOfChar( "open" )){
      aJS=>NewWithOwner( Client )->Open();
    }
    else if( m -> IsEqualToArrayOfChar( "close" )){
      if( aJS )
        aJS -> Exit();
    }
    return 0;
  }
}
