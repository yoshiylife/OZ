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
