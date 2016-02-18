/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Color{
 constructor:
  New, NewWithList;
 public:
  AsList, SetByList, Set;

  /* instance variables */
  int Red;
  int Green;
  int Blue;

  /* constructors */
  void New( int r, int g, int b ){ Set( r, g, b ); }
  void NewWithList( SList aList ){ SetByList( aList ); }

  /* methods */
  SList AsList(){
    SList aList => New();
    Atom r => NewFromInteger( Red );
    Atom g => NewFromInteger( Green );
    Atom b => NewFromInteger( Blue );

    aList -> Add( r );
    aList -> Add( g );
    aList -> Add( b );
    return aList;
  }

  Color SetByList( SList aList ){
    Red = aList -> Car() -> Print() -> AtoI();
    Green = aList -> Cdr() -> Car() -> Print() -> AtoI();
    Blue = aList -> Cdr() -> Cdr() -> Car() -> Print() -> AtoI();
    return self;
  }

  Color Set( int r, int g, int b ){
    Red = r;
    Green = g;
    Blue = b;
    return self;
  }
}
