/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Atom : Linkable {
 constructor:
  NewFromInteger, NewFromHexa, NewFromString, NewFromFloat, NewFromArrayOfChar;
 public:
  IsNil, AsString, AsFloat, AsInteger, AsHexa, Hash, IsEqual;

  /* instance variables */
  String   Name;

  /* constructors */
  void NewFromString( String s ){
    Name = s;
  }

  void NewFromArrayOfChar( char c[] ){
    Name => NewFromArrayOfChar( c );
  }

  void NewFromInteger( int i ){
    char buf[];
    length buf = 1024;
    inline "C"{
      OzSprintf( OZ_ArrayElement( buf, char ), "%d", i );
    }
    Name => NewFromArrayOfChar( buf );
  }

  void NewFromHexa( unsigned int i ){
    char buf[];
    length buf = 1024;
    inline "C"{
      OzSprintf( OZ_ArrayElement( buf, char ), "%x", i );
    }
    Name => NewFromArrayOfChar( buf );
  }

  void NewFromFloat( double f ){
    char buf[];
    length buf = 1024;
    inline "C"{
      OzSprintf( OZ_ArrayElement( buf, char ), "%f", f );
    }
    Name => NewFromArrayOfChar( buf );
  }

  /* private methods */
  int atoi( String a ){
    int i = 0;
    int r = 0;
    int sign = 1;

    switch( a -> At( 0 )){
    case '-':
      sign = -1;
      i++;
      break;

    case '+':
      i++;
      break;

    default:
      break;
    }
    for( ; i < a -> Length(); i++ ){
      char c = a -> At( i );

      if( c >= '0' && c <= '9' ){
        r = r * 10 + ( c - '0' );
      }
      else {
        return 0;
      }
    }

    return r * sign;
  }

  /* public methods */
  int AsInteger(){ 
    return atoi( Name );
  }

 unsigned long AsHexa(){
    int i = 0;
    unsigned long r = 0;

    for( ; i < Name -> Length(); i++ ){
      char c = Name -> At( i );
      if( c >= '0' && c <= '9' ){
        r = r * 16 + ( c - '0' );
      }
      else if( c >= 'a' && c <= 'f' ){
        r = r * 16 + ( c - 'a' + 10 );
      }
      else if( c >= 'A' && c <= 'F' ){
        r = r * 16 + ( c - 'A' + 10 );
      }
      else {
        return 0;
      }
    }

    return r;
  }    

  double AsFloat(){ 
    int period;
    String intp, frac;
    double r = 0;
    int i;

    period = Name -> StrChr( '.' );
    if( period < 0 ){
      return AsInteger();
    }
    intp = Name -> GetSubString( 0, period );
    frac = Name -> GetSubString( period + 1, Name -> Length() - period - 1 );

    for( i = frac -> Length() - 1; i >= 0; i-- ){
      char c = frac -> At( i );
      if( c >= '0' && c <= '9' ){
        r = ( r + ( c - '0' )) / 10;
      }
      else {
        r = 0;
        break;
      }
    }

    return atoi( intp ) + r;
  }

  String AsString(){ return Name; }

  unsigned int Hash(){ return Name -> Hash(); }
}
