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
abstract class Linkable {
 public:
  AsString, IsNil, Hash, IsEqual, Print, Print2;

  String AsString() : abstract;
  String Print(){ return AsString(); }
  String Print2( String open, String close, String delim ){ return Print(); }
  int  IsNil(){ return 0 ; }
  int IsEqual( Linkable l ){ return AsString() -> IsEqual( l -> AsString()); }
  unsigned int Hash(){ return 0; }
}
