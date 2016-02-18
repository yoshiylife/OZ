/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class Linkable {
 public:
  AsString, IsNil, Hash, IsEqual, Print, Print2;

  String AsString() : abstract;
  String Print(){ return AsString(); }
  String Print2( String open, String close, String delim ){ return Print(); }
  int  IsNil(){ return 0 ; }
  int IsEqual( Linkable l ){ return AsString() -> IsEqual( l -> AsString()); }
  unsigned int Hash(){ return 0; }
}
