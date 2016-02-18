/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComUpdateItem : CommandFor<Series> {
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "ItemAttChanged"; }

  int Execute( SList args ){
    IntAsKey key => New( args -> Car() -> AsString() -> AtoI());
    SList list;
    Item anItem;
    Slide current = Client -> GetCurrentSlide();

    if(( anItem = current -> FindItem( key )) == 0 ){
      if(( anItem = current -> GetScreen() -> FindItem( key )) == 0 ){
        raise CollectionExceptions<IntAsKey>::UnknownKey( key );
      }
    }
args -> DebugPrint();
    anItem -> ChangeAttributes( args -> Cdr());
    return 0;
  }
}
