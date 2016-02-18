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
class PassParser : Parser{
 public:
  Parse, AsString;

  SList Parse( String rec ){
    int pos, slash, len;
    SList list;
    String str;
    Atom a;

    if( rec -> IsEqualToArrayOfChar( "/" )){
      SList nil => New();
      return nil;
    }

    if( rec -> At( 0 ) != '/' ){
      String rec2 => NewFromArrayOfChar( "./" );
      rec = rec2 -> Concatenate( rec );
    }

    list => New();
    len = rec -> Length();
    for( pos = 0; pos < len; ){
      str = rec -> GetSubString( pos, 0 );
      if(( slash = str -> StrChr( '/' )) < 0 ){
        a => NewFromString( str );
        list -> Add( a );
        break;
      }

      str = str -> GetSubString( pos, slash );
      a => NewFromString( str );
      pos += slash + 1;
    }
    return list;
  }

  String AsString( SList list ){
    
  }
}
      
