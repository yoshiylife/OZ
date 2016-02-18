/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComDeleteItem : CommandFor<Series> {
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "ItemDeleted"; }

  int Execute( SList args ){
    Slide current = Client -> GetCurrentSlide();
    Screen screen;
    IntAsKey key => New( args -> Car() -> AsString() -> AtoI());

    if( current -> FindItem( key )){
      current -> DeleteItem( key );
    }
    else if(( screen = current -> GetScreen()) -> FindItem( key )){
      screen -> DeleteItem( key );
    }
    else{
      raise CollectionExceptions<IntAsKey>::UnknownKey( key );
    }
    return 0;
  }
}
