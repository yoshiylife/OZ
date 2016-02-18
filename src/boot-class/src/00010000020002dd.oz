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

class OTextSun : OText {
 constructor: New, Assign;
 public: 
   OpenWithName, AppendWithName, Close, PutLine, PutString, PutChar, FlushBuf;

   OFStream  Strm;
   StreamBuffer Buf;

   void New(){
     Strm => New();
     Buf => Size( 1024 );
   }

//   void Assign( int f ){ Strm => New(); Strm ->Dup( f ); }
   void Assign( OFStream of ){ 
     Strm = of;
     Buf => Size( 1024 );
   }

   void OpenWithName( String n ) : locked { 
     Strm -> OpenWithName( n ); 
   }

   void AppendWithName( String n ) : locked { 
     Strm -> AppendWithName( n ); 
   }

   void Close() : locked { 
     FlushBuf();
     Strm -> Close(); 
   }

   void FlushBuf(){
     Strm -> WriteToCurrent( Buf );
     Buf -> ResetPoint();
   }

   void Write( char c[] ) : locked {
     int b_len = Buf -> GetLength() - Buf -> GetPoint();
     int c_len = length c;
     int c_start = 0;

     if( b_len < c_len ){
       FlushBuf();
       if( c_len > Buf -> GetLength()){
         StreamBuffer buf => NewFromArrayOfChar( c );
         Strm -> WriteAll( buf );
         return;
       }
     }
     Buf -> PutNBytes( c );
   }

   void PutLine( String str ) {
//     Write( str -> Content());
     PutString( str );
     PutChar( '\n' );
   }

   void PutString( String str ){
     char content[];
     content = str -> Content();
     length content = str -> Length();
     Write( content );
   }

   void PutChar( char c ) {
     char ca[];
     length ca = 1;
     ca[ 0 ] = c;
     Write( ca );
   }

}
