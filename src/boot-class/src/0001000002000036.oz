/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
 */
/*
  Copyright (c) 1994 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class StreamBuffer{
 constructor: New, Size, NewFromArrayOfChar;
 public: GetByte, GetByteAt, GetNBytes, GetNBytesAt, GetAll, GetAllAt, 
  PutByte, PutByteAt, PutNBytes, PutNBytesAt, SetLength, GetLength,
  ResetPoint, GetPoint, IsPointEnd, MovePoint, ShiftPoint, DebugPrint,
   GetTillAChar, PutNBytesSub, AsArrayOfChar, AsString;

  /* instance variables */

  int   Current;
  char   Body[];

  /* constructors */
  void New(){ length Body = 1024; Current = 0; }
  void Size( int l ){ length Body = l; Current = 0; }
  void NewFromArrayOfChar( char b[] ){
    int i;
    length Body = length b;
    for( i = 0; i < length b; i++ )
      Body[ i ] = b[ i ];
//    Current = length Body - 1;
    Current = 0;
  }

  /* public methods */
  char GetByte() : locked { 
    int old = Current;
    try{
      return Body[ Current++ ]; 
    }
    except{
      ArrayRangeOverflow{
        Current = old;
        raise StreamExceptions::Range( Current );
      }
    }
  }

  char GetByteAt( int idx ){ 
    try{
      return Body[ idx ]; 
    }
    except{
      ArrayRangeOverflow{
        raise StreamExceptions::Range( idx );
      }
    } 
  }

  char GetNBytes( int n )[] : locked { 
    int i = 0;
    char tmp[];

    if( Current + n > length Body )
      raise StreamExceptions::Range( Current + n );

    length tmp = n;
    while( n-- && Current < length Body )
      tmp[ i++ ] = Body[ Current++ ];

    return tmp;
  }

  char GetNBytesAt( int idx, int n )[]{
    int i = 0;
    char tmp[];

    if( idx + n > length Body )
      raise StreamExceptions::Range( idx + n );

    length tmp = n;
    while( n-- )
      tmp[ i++ ] = Body[ idx++ ];
    return tmp;
  }

  char GetAll()[]{
    int i = 0;
    char tmp[];
    length tmp = length Body - Current + 1;
    if( Current == 0 )
      return Body;
    while( Current < length Body )
      tmp[ i++ ] = Body[ Current++ ];
    return tmp;
  }

  char GetAllAt( int idx )[]{
    int i = 0;
    char tmp[];

    length tmp = length Body - idx;
    if( idx == 0 )
      return Body;
    while( idx++ <= length Body )
      tmp[ i++ ] = Body[ idx ];
    return tmp;
  }

   char GetTillAChar( char c )[]{
     int i;
     int max = length Body;

     for( i = Current; i < max; i++ ){
       if( Body[ i ] == c ){
         return GetNBytes( i - Current + 1 );
       }
     }
     return 0;
   }

  StreamBuffer PutByte( char c ) : locked {
    Body[ Current++ ] = c;
    return self;
  }

  StreamBuffer PutByteAt( int idx, char c ) : locked {
    Body[ idx ] = c; 
    return self;
  }

  StreamBuffer PutNBytes( char array[] ) : locked {
    int i;

    for( i = 0; i < length array; i++ )
      Body[ Current++ ] = array[ i ];
    return self;
  }

  StreamBuffer PutNBytesSub( char array[], int start ) : locked {
    int i;
    for( i = start; i < length array; i++ )
      Body[ Current++ ] = array[ i ];
    return self;
  }

  StreamBuffer PutNBytesAt( int idx, char array[] ) : locked {
    int i;

    for( i = 0; i < length array; i++ )
      Body[ idx++ ] = array[ i ];
    return self;
  }

  void SetLength( int l ){
    length Body = l;
  }

  int GetLength(){ return length Body; }
  void ResetPoint() : locked { Current = 0; }
  int GetPoint(){ return Current; }
  int IsPointEnd(){ return Current == length Body; }
  void MovePoint( int idx ) : locked { 
    Current = idx; 
  }
  void ShiftPoint( int off ) : locked { 
    Current += off; 
  }

   char AsArrayOfChar()[]{
     return Body;
   }

   String AsString(){
     String s;
     char b[];
     b = Body;
     length b += 1;
     b[ length Body ] = '\0';
     return s => NewFromArrayOfChar( b );
   }

  void DebugPrint(){
    int i;
    for( i = 0; i < length Body; i++ ){
      char c = Body[ i ];
      inline "C" {
        OzDebugf( "%d:%c ", i, c );
      }
    }
  }
}
