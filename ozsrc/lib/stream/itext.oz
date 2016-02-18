/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/


abstract class IText {
 public:
    OpenWithName, Close, GetLine, GetString, GetChar, GetTillAChar,
    GetTillAString, UngetString, UngetChar, Eof;

    void OpenWithName( String n ) : abstract;
    void Close() : abstract;
    String GetLine() : abstract;
    String GetString( int len ) : abstract;
    char GetChar() : abstract;
    String GetTillAChar( char c ) : abstract;
    String GetTillAString( String s ) : abstract;

    void UngetString() : abstract;
    void UngetChar() : abstract;

    int Eof() : abstract;
}
