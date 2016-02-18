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
