/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

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
