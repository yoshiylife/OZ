/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class IOTextA2 : IOTextSun {
 constructor: New;
 public:
  OpenWithName, Close, GetLine, GetString, GetChar, GetTillAChar,
  GetTillAString, UngetString, UngetChar, Eof, Dup;

 public:
  AppendWithName, PutLine, PutString, PutChar, FlushBuf;

   int Eof(){ return 0; }
 }
