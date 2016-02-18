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

inline "C"{
  #include <fcntl.h>
  #include <unistd.h>
}

class IFStream : IStream, FStream{
 constructor: New, Name;
 protected: Fname, Fd;
 public: Open, OpenWithName, Append, AppendWithName, Close, Seek, SeekCur, SeekEnd, Read, Eof, Dup;

   StreamFunctions   Funcs;

   void New(){ Funcs => New();}
   void Name( String n ){ Fname = n; Funcs => New(); }

   void OpenWithName( String n ){ 
     Fname = n;
     Fd = Funcs -> Open( n, "r" );
   }

   void AppendWithName( String n ){ OpenWithName( n ); }

   StreamBuffer Read( int len ){
     return Funcs -> Read( len );
   }

   int Eof(){
     int r, cur;
     cur = SeekCur( 0 );
     r = ( cur == SeekEnd( 0 ));
     Seek( cur );
     return r;
   }

   int get_mode( int n ){
     inline "C"{
       switch( n ){
       case 0:
         return SEEK_SET;
       case 1:
         return SEEK_CUR;
       default:
         return SEEK_END;
       }
     }
   }

   int Seek( int pos ){ return Funcs -> Seek( pos, get_mode( 0 ) ); }
   int SeekCur( int pos ){ return Funcs -> Seek( pos, get_mode( 1 ) ); }
   int SeekEnd( int pos ){ return Funcs -> Seek( pos, get_mode( 2 ) ); }

   void Close(){
     Fd = 0;
     Funcs -> Close();
   }
}
             
