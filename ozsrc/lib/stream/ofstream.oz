/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

inline "C"{
  #include <fcntl.h>
  #include <unistd.h>
}

class OFStream : OStream, FStream{
 constructor: New, Name;
 protected: Fd;
 public: Open, OpenWithName, Append, AppendWithName, Close, Seek, SeekCur, SeekEnd, Write, WriteAll, WriteToCurrent, Dup;

   /* Instance Variables */
   StreamFunctions  Ofuncs;

   /* Methods */
   void New(){ Ofuncs => New(); }
   void Name( String n ){ Fname = n; Ofuncs => New(); }

   void OpenWithName( String n ){
     Fname = n;
     Fd = Ofuncs -> Open( n, "w" );
   }

   void AppendWithName( String n ){
     Fname = n;
     Fd = Ofuncs -> Open( n, "a" );
   }

   void Close(){
     Fd = 0;
     Ofuncs -> Close();
   }

   OStream Write( StreamBuffer buf, int len ){
     Ofuncs -> Write( buf, len );
     return self;
   }

   OStream WriteAll( StreamBuffer buf ){
     Ofuncs -> Write( buf, buf -> GetLength());
     return self;
   }

   OStream WriteToCurrent( StreamBuffer buf ){
     Ofuncs -> Write( buf, buf -> GetPoint());
     return self;
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

   int Seek( int pos ){ return Ofuncs -> Seek( pos, get_mode( 0 ) ); }
   int SeekCur( int pos ){ return Ofuncs -> Seek( pos, get_mode( 1 ) ); }
   int SeekEnd( int pos ){ return Ofuncs -> Seek( pos, get_mode( 2 ) ); }

 }
