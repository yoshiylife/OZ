/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class IntervalJob {
 public:
  Past, Reset, IsEqual, Hash;

 protected:
  Interval, Do;

  /* instance variables */
  int Counter;

  /* methods */
  int Past( int d ){
    if(( Counter -= d ) <= 0 ){
      if( Do() == 0 )
        return 0; // datached from the server
      Reset();
    }
    return 1;
  }

  void Reset(){
    Counter = Interval();
  }

  int Interval() : abstract;

  int Do() : abstract;

  int IsEqual( IntervalJob another ){
    return self == another;
  }

  unsigned int Hash(){ return 0; }
}
