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

class ExternalSpawnedProcess : ExternalProcess{
 constructor:
  NewWithPidAndFd;
 public:
  GetStream, GetText;
 public:
  Kill, SetSignal, Status, Wait, IsEqual, Hash, Id;

  /* Instance Variables */
  IOFStream  Strm;

  /* constructors */
  void NewWithPidAndFd( int p, int f ){
    Pid = p;
    Strm => New();
    Strm -> Dup( f );
    detach fork Chld();
  }

  /* services */
  IOStream GetStream(){ return Strm; }
  IOText GetText(){ 
    IOTextA2 text => New();
    text -> Dup( Strm -> GetFd() );
    return text;
  }
}
