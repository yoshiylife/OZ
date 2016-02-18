/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

inline "C"{
        #include <stdio.h>
        #include <unistd.h>
}

//class IOFStream : FStream, IOStream
class IOFStream : IFStream, OFStream( rename Fd Fd2; rename Open Open2; ), IOStream
{
 constructor: New, Name;
 protected: Fd;
 public: Read, Eof, Write, WriteAll, Open, OpenWithName, Append, AppendWithName, Close, Seek, SeekCur, SeekEnd, WriteToCurrent, Dup, GetFd;

   StreamFunctions  Ifuncs, Ofuncs;

   void New(){ Ifuncs => New(); Ofuncs => New(); }
   void Name( String n ){ Fname = n; Ifuncs => New(); Ofuncs => New();}

   void OpenWithName( String n ){
     Fname = n;
     Fd = Ifuncs -> Open( n, "rw" );
     Ofuncs -> SetFd( Fd );
   }
   int GetFd(){ return Fd; }

   void Dup( int f ){
     Fd = f;
     Ifuncs -> SetFd( f );
     Ofuncs -> SetFd( f );
   }

   void AppendWithName( String n ){
     OpenWithName( n );
     SeekEnd( 0 );
   }

   void Close(){
     Fd = 0;
     Ifuncs -> Close();
//     Ofuncs -> Close();
   }
     
   StreamBuffer Read( int len ){
     return Ifuncs -> Read( len );
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

   int Seek( int pos ){ 
     Ofuncs -> Seek( pos, get_mode( 0 ));
     return Ifuncs -> Seek( pos, get_mode( 0 ) ); 
   }
   int SeekCur( int pos ){ 
     Ofuncs -> Seek( pos, get_mode( 1 ));
     return Ifuncs -> Seek( pos, get_mode( 1 ) ); 
   }
   int SeekEnd( int pos ){ 
     Ofuncs -> Seek( pos, get_mode( 2 ));
     return Ifuncs -> Seek( pos, get_mode( 2 ) ); 
   }
}     
