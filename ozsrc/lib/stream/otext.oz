/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class OText {
 public:
    OpenWithName, AppendWithName, Close, PutLine, PutString, PutChar, FlushBuf;

    void OpenWithName( String n ) : abstract;
    void AppendWithName( String n ): abstract;
    void Close() : abstract;
    void PutLine( String str ) : abstract;
    void PutString( String str ) : abstract;
    void PutChar( char c ) : abstract;
    void FlushBuf() : abstract;
}


