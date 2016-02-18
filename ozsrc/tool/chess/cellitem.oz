/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class CellItem : Field {
 constructor:
  New, NewWithLength;
 public:
  Draw, ReDraw, SlideMove, GetValue, Entered, GetLength, SetLength, Move, Shift, SetUsersValue, GetUsersValue, SetModel;
 public:
  SetName, SetState, SetGeometry, SetSize, SetFont, SetFontSize;
 protected:
  CreateHolder;

  StringHolder CreateHolder(){
    Cell aHolder => New();
    return aHolder;
  }
}  
