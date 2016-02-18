/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ChessLaunchable2 : Launchable{
  void Launch(){
    global Chess a => New();
    global Chess b => New();
    String an => NewFromArrayOfChar( ":chess:a" );
    String bn => NewFromArrayOfChar( ":chess:b" );
    global NameDirectory nd = Where() -> GetNameDirectory();

    if( nd -> Includes( an )){
      nd -> RemoveObjectWithName( an );      
    }
    nd -> AddObject( an, a );
    if( nd -> Includes( bn )){
      nd -> RemoveObjectWithName( bn );      
    }
    nd -> AddObject( bn, b );
  }
}
