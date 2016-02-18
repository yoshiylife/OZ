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

class IOTextA : IOText {
 constructor: New;
 public:
  OpenWithName, Close, GetLine, GetString, GetChar, GetTillAChar,
  GetTillAString, UngetString, UngetChar, Eof, Dup;

 public:
  AppendWithName, PutLine, PutString, PutChar, FlushBuf;

   /* instance variables */
   IOFStream Strm;

   void New(){}

   void Dup( IOFStream s ){ Strm = s; }

   void OpenWithName( String name ){ 
     Strm => New();
     Strm -> OpenWithName( name );
   }

   void Close(){
     Strm -> Close();
   }

   void UngetString(){}
   void UngetChar(){}

   String GetString( int len ){
     return Strm -> Read( len ) -> AsString();
   }

   char GetChar(){
     return Strm -> Read(1) -> GetByte();
   }

   String GetTillAChar( char del ){
     char rec[];
     int idx = 0;
     String r;
     char c;

     length rec = 1024;
     while( !Eof() ){
       StreamBuffer buf = Strm -> Read( 1 );
       if( buf -> GetLength() <= 0 )
         break;
       if(( c = buf -> GetByte()) == del )
         break;
       rec[ idx++ ] = c;
     }
     rec[ idx ] = '\0';
     return r => NewFromArrayOfChar( rec );
   }

   String GetTillAString( String s ){}

   String GetLine(){
     return GetTillAChar( '\n' );
   }

   int Eof(){ return Strm -> Eof(); }

   void AppendWithName( String n ){
     OpenWithName( n );
   }

   void PutLine( String r ){
     PutString( r -> ConcatenateWithArrayOfChar( "\n" ) );
   }

   void PutString( String str ){
     StreamBuffer buf;
     buf => NewFromArrayOfChar( str -> Content() );
     Strm -> Write( buf, str -> Length() );
   }

   void PutChar( char c ){
     char ca[];
     StreamBuffer buf;

     length ca = 1;
     ca[ 0 ] = c;
     buf => NewFromArrayOfChar( ca );
     Strm -> Write( buf, 1 );
   }
   void FlushBuf(){}
}     
     
