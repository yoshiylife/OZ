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

class ITextSun : IText{
 constructor: New, Assign;
 public:
    OpenWithName, Close, GetLine, GetString, GetChar, GetTillAChar,
    GetTillAString, UngetString, UngetChar, Eof;

    IFStream  Strm;
    StreamBuffer Buf;

   int IsEmptyBuffer(){
     return ( Buf != 0 ) && ( Buf -> IsPointEnd());
   }

   void New(){ 
     Strm => New();      
//     Buf = 0;
   }

   void Assign( IFStream s ){
     Strm = s;
//     Buf => New();
     Buf = 0;
   }

    void OpenWithName( String n ) : locked {
      Strm -> OpenWithName( n );
      Buf = Strm -> Read( 1024 );
    }

    void Read()  {
      Buf = Strm -> Read( 1024 );
//      Buf -> DebugPrint();
    }

    void Close() : locked {
      Strm -> Close();
    }

   char add( char s[], char c[], int len )[]{
     int i;

     if( length s < length c + len )
       length s = length c + len;
     for( i = 0; i < length c; i++ )
       s[ len++ ] = c[ i ];
     return s;
   }
   
    String GetTillAChar( char del ) : locked {
      char c[];
      char s[];
      String ret;
      int s_len;

      length s = 1024;
      s_len = 0;
      if(( Buf == 0 ) || IsEmptyBuffer() ) Read();

      while(( c = Buf -> GetTillAChar( del )) == 0 ){
        c = Buf -> GetAll();

        s = add( s, c, s_len );
        s_len += ( length c - 1 );
        if( Strm -> Eof())
          raise StreamExceptions::NotFound;
        Read();
      }
      s = add( s, c, s_len );
      s_len += length c;
      s[ s_len - 1 ] = '\0';
      ret => NewFromArrayOfChar( s );
      return ret;
    }

    String GetString( int len ) : locked {
      int read_len = len;
      String s;

      if(( Buf == 0 ) || IsEmptyBuffer())
        Read();
      s = 0;
      for(;;){
        if( s )
          s = s -> ConcatenateWithArrayOfChar( Buf -> GetNBytes( read_len ));
        else
          s => NewFromArrayOfChar( Buf -> GetNBytes( read_len ));      

        if( s -> Length() >= len || Strm->Eof())
          break;
        Read();
        read_len = len - s -> Length();
      }
      return s;
    }

    char GetChar() : locked {
      if( IsEmptyBuffer())
        Read();
      return Buf -> GetByte();
    }

    String GetLine(){
      String s;
      try{
        s = GetTillAChar( '\n' );
      }
      except{
      }
      return s;
    }
      
    String GetTillAString( String s ){ raise StreamExceptions::NotYet; }

    void UngetString(){ raise StreamExceptions::NotYet; }
    void UngetChar() : locked { 
      if( Buf -> GetPoint() == 0 ){
        Strm -> SeekCur( -1 );
        Buf -> MovePoint( Buf -> GetLength());
      }
      else{
        Buf -> ShiftPoint( -1 );
      }
    }

   int Eof(){ return IsEmptyBuffer() && Strm -> Eof(); }
}
