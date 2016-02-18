/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class IOText : IText, OText (
        rename OpenWithName OpenWithName2;
        rename Close Close2;)
{
 public:
  OpenWithName, Close, GetLine, GetString, GetChar, GetTillAChar,
  GetTillAString, UngetString, UngetChar, Eof;

 public:
  AppendWithName, PutLine, PutString, PutChar, FlushBuf;

 protected:
  OpenWithName2, Close2;
  
  void OpenWithName2( String n ){ OpenWithName( n ); }
  void Close2(){ Close(); }
}








