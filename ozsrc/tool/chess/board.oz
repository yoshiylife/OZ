/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Board : Slide {
 constructor:
  newWithItems;

 public:
  Hash, IsEqual, GetScreen, setScreen, GetSeries, setSeries, Draw, EraseAllItems, GetHolder, FindHolderByItem, GetModel, SetModel, FindItem, AddItem, DeleteItem, setHolder, SetName, SetNameA, compareName;
 public:
  GetCell, RefreshCell;

  /* public methods */
  Cell GetCell( int row, int col ){
    IntAsKey key => New( row << 16 & 0xffff0000 | col );
    return narrow( Cell, GetHolder( key ));
  }

  void RefreshCell( int row, int col ){
    IntAsKey key => New( row << 16 & 0xffff0000 | col );
    GetScreen() -> FindItem( key ) -> ReDraw( self );
  }
}
