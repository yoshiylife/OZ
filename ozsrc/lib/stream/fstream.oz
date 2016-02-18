/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

inline "C"{
        #include <unistd.h>
}

abstract class FStream{
 public: Open, OpenWithName, Append, AppendWithName, Close, Seek, SeekCur, SeekEnd, Dup;
 protected: Fname, Fd;
     
   String Fname;
   int    Fd;

   void OpenWithName( String ) : abstract;
   void Open(){
     OpenWithName( Fname );
   }

   void AppendWithName( String ) : abstract;
   void Append(){
     AppendWithName( Fname );
   }

   void Dup( int f ){ Fd = f; }

   void Close() : abstract;

   int Seek( int pos ) : abstract;
   int SeekCur( int pos ) : abstract;
   int SeekEnd( int pos ) : abstract;
}
