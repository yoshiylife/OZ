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
  #include "oz++/ozlibc.h"
}

class StreamFunctions {
 constructor: New;
 public: Open, SetFd, Close, Read, Write, Seek;

   int Fd;

   void New(){ Fd = 0; }

   int Open( String name, char mode[] ) : locked{
     int flg;
     char fn[];

     if( Fd != 0 ){
       raise StreamExceptions::IllOpen;
     }

     inline "C"{
       char *m = OZ_ArrayElement( mode, char );
       if( !OzStrcmp( m, "r" )){
         flg = O_RDONLY;
       }
       else if( !OzStrcmp( m, "w" )){
         flg = O_CREAT | O_TRUNC | O_WRONLY;
       }
       else if( !OzStrcmp( m, "rw" )){
         flg = O_RDWR | O_APPEND;
       }
       else if( !OzStrcmp( m, "a" )){
         flg = O_WRONLY | O_APPEND;
       }
       else flg = -1;
     }
     if( flg < 0 ) raise StreamExceptions::IllOpen;

     fn = name -> Content();
     inline "C" {
       OZ_InstanceVariable_StreamFunctions( Fd ) = OzOpen( OZ_ArrayElement( fn, char ), flg, 0666 );
     }
     if( Fd < 0 )
       raise StreamExceptions::IllOpen;

     return Fd;
   }
   void SetFd( int f ) : locked { Fd = f; }
 
   void Close() : locked{
     inline "C"{
       OzClose( OZ_InstanceVariable_StreamFunctions( Fd ));
     }
     Fd = 0;
   }
     
   StreamBuffer Read( int len ) : locked{
     StreamBuffer buf;
     char tmp[];
     int read_len;

     length tmp = len;
     inline "C"{
       read_len = OzRead( OZ_InstanceVariable_StreamFunctions( Fd ), OZ_ArrayElement( tmp, char), len );
     }
     if( read_len < 0 )
       raise StreamExceptions::CannotRead;

     if( read_len < len )
       length tmp = read_len;
     buf => NewFromArrayOfChar( tmp );
     buf -> ResetPoint();
     return buf;
   }

   void Write( StreamBuffer buf, int len ) : locked{
     char tmp[];
     tmp = buf -> GetNBytesAt( 0, len );

     inline "C"{
       OzWrite( OZ_InstanceVariable_StreamFunctions( Fd ), OZ_ArrayElement( tmp, char ), len );
     }
   }

   int Seek( int pos, int mode ) : locked { 
     int r;
     inline "C"{
       r = OzLseek( OZ_InstanceVariable_StreamFunctions( Fd ), pos, mode );
     }
     return r;
   }
}   
