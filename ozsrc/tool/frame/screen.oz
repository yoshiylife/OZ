/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Screen : Dependency{
 constructor:
  New;
 public:
  IsEqual, Hash, GetID, AddItem, DeleteItem, CreateSlide, Draw,ReDraw, SlideMove, EraseAllItems, GetModel, SetModel, FindItem;
 protected:
  Items, generateID;

  /* instance variables */
  global LockID   ID;
  Set<Item>       Items;
  int             NextID;

  /* constructors */
  void New(){
    ID => New();
    Items => New();
    NextID = 0;
  }

  /* methods */
  int IsEqual( Screen another ){
    return ID == another -> GetID();
  }
  unsigned int Hash(){ 
    global LockID id = ID;
    unsigned int r;
    inline "C"{
      r = 0xffffffff & id;
    }
    return r;
  }
  global LockID GetID(){ return ID; }

  int generateID(){
    return ++NextID;
  }

  Screen AddItem( Item anItem ){
    anItem -> bind( generateID(), self );
    Items -> Add( anItem );

    return self;
  }

  Screen DeleteItem( IntAsKey key ){
    Items -> Remove( FindItem( key ));
    return self;
  }

  Slide CreateSlide(){
    Slide newSlide => newWithItems( Items );
    newSlide -> setScreen( self );
    return newSlide;
  }

  void Draw( Slide aSlide ){
    Iterator<Item> ir => New( Items );
    Item im;

    while( im = ir -> PostIncrement()){
      im -> Draw( aSlide );
    }
  }
  void ReDraw( Slide aSlide ){
    Iterator<Item> ir => New( Items );
    Item im;
    while( im = ir -> PostIncrement()){
      im -> ReDraw( aSlide );
    }
  }
  void SlideMove( Slide aSlide ){
    Iterator<Item> ir => New( Items );
    Item im;
    while( im = ir -> PostIncrement()){
      im -> SlideMove( aSlide );
    }
  }
  void EraseAllItems( Series aSeries ){
    Iterator<Item> ir => New( Items );
    Item im;

    while( im = ir -> PostIncrement()){
      im -> Close( aSeries );
    }
  }

  Model GetModel(){
    return MyModel;
  }
  Item FindItem( IntAsKey key ){
    Iterator<Item> ite => New( Items );
    Item im;
    while( im = ite -> PostIncrement()){
      if( im -> getID() -> IsEqual( key ))
        return im;
    }
    return 0;
  }
}
