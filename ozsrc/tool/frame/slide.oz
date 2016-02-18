/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Slide : Dependency{
 constructor:
  newWithItems;
 public:
  Hash, IsEqual, GetScreen, setScreen, GetSeries, setSeries, Draw, EraseAllItems, GetHolder, FindHolderByItem, GetModel, SetModel, FindItem, AddItem, DeleteItem, setHolder, SetName, SetNameA, compareName;
 protected:
  Name;

  /* instance variables */
  Screen    MyScreen;
  Dictionary<IntAsKey,Holder>  Holders;
  Set<Item>  Items;
  Series     MySeries;
  int        NextID;
  String     Name;

  /* constructors */
  void newWithItems( Collection<Item> items ){
    Iterator<Item> ir => New( items );
    Item im;

    Holders => New();
    while( im = ir -> PostIncrement()){
      Holders -> AddAssoc( im -> getID(), 0 );
    }
    Items => New();
    NextID = 0;
  }

  /* compare */
  unsigned int Hash(){ return Name ? Name -> Hash() : 0; }
  int IsEqual( Slide another ){ return 0; }

  /* access */
  Slide SetName( String n ){ Name = n; return self; }
  Slide SetNameA( char n[]) { String s => NewFromArrayOfChar( n ); SetName( s ); return self; }
  int compareName( String n ){ return Name ? Name -> IsEqual( n ) : 0; }

  Screen GetScreen(){ return MyScreen; }
  void setScreen( Screen aScreen ){ 
    /* called by a series or a screen */
    MyScreen = aScreen; 
  } 
  Series GetSeries(){ return MySeries; }
  void setSeries( Series aSeries ){ 
    /* call from a series */
    MySeries = aSeries; 
  }

  int generateID(){
    return --NextID;
  }

  Slide AddItem( Item anItem ){
    anItem -> bind( generateID(), self );
    Items -> Add( anItem );
    Holders -> AddAssoc( anItem -> getID(), 0 );
    return self;
  }

  Slide DeleteItem( IntAsKey key ){
    Items -> Remove( FindItem( key ));
    return self;
  }

  void Draw(){
    Iterator<Item> ir => New( Items );
    Item im;

    while( im = ir -> PostIncrement()){
      im -> Draw( self );
    }
  }

  void EraseAllItems( Series aSeries ){
    Iterator<Item> ir => New( Items );
    Item im;

    while( im = ir -> PostIncrement()){
      im -> Close( aSeries );
    }
  }

  Holder GetHolder( IntAsKey key ){
    return Holders -> AtKey( key );
  }

  Holder FindHolderByItem( Item anItem ){
    return GetHolder( anItem -> getID());
  }

  void setHolder( IntAsKey key, Holder value ){
    Holders -> SetAtKey( key, value );
  }

  Model GetModel(){
    return MyModel ? MyModel : MyScreen -> GetModel();
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
