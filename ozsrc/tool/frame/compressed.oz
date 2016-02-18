/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComPressed : CommandFor<Series> {
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "ButtonMouseUp"; }

  int Execute( SList args ){
    IntAsKey key => New( args -> Car() -> AsString() -> AtoI());
    Slide current = Client -> GetCurrentSlide();
    Item anItem;
    Button aButton;

//    Client -> ButtonPressed( key );
    if(( anItem = current -> FindItem( key )) == 0 ){
      if(( anItem = current -> GetScreen() -> FindItem( key )) == 0 ){
        raise CollectionExceptions<IntAsKey>::UnknownKey( key );
      }
    }
    aButton = narrow( Button, anItem );
    aButton -> Pressed( Client, current );
    
    return 0;
  }
}
