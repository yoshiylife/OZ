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
class SimpleParser : Parser {
 constructor:
  New;
 public:
  Parse, AsString;

  /* instance variables */
  int Idx;
  char Open, Close;
  char Delimiters[];

  /* constructors */
  void New( char o, char c, char d[] ){ 
    Idx = 0; 
    Open = o;
    Close = c;
    Delimiters = d;
  }

  /* public methods */
  SList Parse( String s ){ /* It can parse only one expression. */
    Idx = 0;
    return parse_internal( s );
  }

  SList parse_internal( String s ){
    SList list => New();
    char rec[];
    int rec_idx = 0;
    Atom a;
    int ctr = 0;
    int in_quote = 0;

    length rec = 256;

    for( Idx++ ; Idx < s -> Length(); Idx++ ){
      char c = s -> At( Idx );
      if( c == Open ){
        list -> Add( parse_internal( s ));
        continue;
      }
      else if( c == Close ){
        if( rec_idx > 0 ){
          String s;
          rec[ rec_idx ] = '\0';
          s => NewFromArrayOfChar( rec );
          a => NewFromString( s );
          list -> Add( a );
        }
        return list;
      }
      else if( c == '\"' ){
        in_quote = !in_quote;
        continue;
      }
      else if( !in_quote ){
        if( match( c )){
          if( rec_idx > 0 ){
              String s;
              rec[ rec_idx ] = '\0';
              s => NewFromArrayOfChar( rec );
              a => NewFromString( s );
              list -> Add( a );
              rec_idx = 0;
            }
          continue;
        }
      }
      rec[ rec_idx++ ] = c;
    }
    raise ListExp::Unbalanced;
  }

  int match( char c ){
    int i;
    for( i = 0; i < length Delimiters; i++ ){
      if( c == Delimiters[ i ] ){
        return 1;
      }
    }
    return 0;
  }

  String AsString( SList list ){
    char a[];
    String o, c, d;

    length a = 1;
    a[ 0 ] = Open;
    o => NewFromArrayOfChar( a );

    a[ 0 ] = Close;
    c => NewFromArrayOfChar( a );

    d => NewFromArrayOfChar( Delimiters );

    return list -> AsString2( o, c, d );
  }
}
