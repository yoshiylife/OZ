/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class CellEvaluator{
 constructor:
  new;

 public:
  Evaluate;

  /* instance variables */
  OrderedCollection<String> Words;
  int   Level[];

  /* constructors */
  void new(){}

  /* public methods */
  CellValue Evaluate( String script ) : locked {
    CellValue r;
    CellReference ref;

    lex( script );
    r = yacc( 0, Words -> Size() - 1 ) -> Evaluate();
    try{
      ref = narrow( CellReference, r );
    }
    except{
      NarrowFailed{
        return r;
      }
      ChessShared::SyntaxError( n ){
        raise ChessShared::SyntaxError( script );
      }
    }
    return ref -> Evaluate();
  }

  /* internal methods */
  void lex( String script ){
    int i;
    int max = script -> Length();
    int current_level = 0;
    int words_ctr = 0;
    int symbol_start = -1;
    int symbol_length = 0;
    int unary = 1;

    length Level = max;
    Words => New();

    for( i = 0; i < max; i++ ){
      char c = script -> At( i );
      switch( c ){
      case '(':
        if( symbol_length > 0 ){
          raise ChessShared::SyntaxError(0);
        }
        ++current_level;
        break;

      case ')':
        if( symbol_length > 0 ){
          Words -> AddLast( script -> GetSubString( symbol_start, symbol_length ));
          Level[ words_ctr++ ] = current_level;
          symbol_length =  0;
        }
        if( --current_level < 0 )
          raise ChessShared::SyntaxError(0);
        unary = 1;
        break;

      case '+':
      case '-':
        if( unary ){
          String u => NewFromArrayOfChar(( c == '+' ) ? "(" : ")" );
          Words -> AddLast( u );
          Level[ words_ctr++ ] = current_level;
          if( symbol_length > 0 ){
            Words -> AddLast( script -> GetSubString( symbol_start, symbol_length ));
            Level[ words_ctr++ ] = current_level;
            symbol_length =  0;
          }
          break;
        }
        /* through */

      case '#':
      case '*':
      case '/':
      case '@':
      case '=':
        if( symbol_length > 0 ){
          Words -> AddLast( script -> GetSubString( symbol_start, symbol_length ));
          Level[ words_ctr++ ] = current_level;
          symbol_length =  0;
        }
        Words -> AddLast( script -> GetSubString( i, 1 ));
        Level[ words_ctr++ ] = current_level;
        unary = 1;
        break;

      case ' ':
      case '\t':
        if( symbol_length > 0 ){
          Words -> AddLast( script -> GetSubString( symbol_start, symbol_length ));
          Level[ words_ctr++ ] = current_level;
          symbol_length =  0;
        }
        break;
        
      default:
        if( symbol_length++ <= 0 ){
          symbol_start = i;
        }
        unary = 0;
      }
    }
    if( current_level > 0 )
      raise ChessShared::SyntaxError(0);
    if( symbol_length > 0 ){
      Words -> AddLast( script -> GetSubString( symbol_start, symbol_length ));
      Level[ words_ctr++ ] = current_level;
      symbol_length =  0;
    }
  }

  Node yacc( int start, int stop ){
    short current_level = 0x7fff;
    int i;

    if( start > stop )
      raise ChessShared::SyntaxError(0);

    if( start == stop ){
      ConstantNode newNode => New( Words -> At( start ));
      return newNode;
    }

    for( i = start; i <= stop; i++ ){
      if( Level[ i ] < current_level )
        current_level = Level[ i ];
    }

    if(( i = get_op( "=", start, stop, current_level )) > 0 ||
       ( i = get_op( "+-", stop, start, current_level )) > 0 ||
       ( i = get_op( "*/", stop, start, current_level )) > 0 ||
       ( i = get_op( "@#", stop, start, current_level )) > 0 ){
      Node left = yacc( start, i - 1 );
      Node right = yacc( i + 1, stop );
      BinaryNode newNode => New( Words -> At( i ), left, right );
      return newNode;
    }
    if( i = get_op( "()", stop, start, current_level )){
      Node right = yacc( i + 1, stop );
      String op;
      UnaryNode newNode => New( Words -> At( i ) -> IsEqualToArrayOfChar( "(" ) ? op => NewFromArrayOfChar( "+" ) : op => NewFromArrayOfChar( "-" ), right );
      return newNode;
    }
    return 0; /* fatal */
  }

  int get_op( char ops[], int i1, int i2, int current_level ){
    int step = ( i1 < i2 ) ? 1 : -1;
    int i = i1;
    int j;

    for( i = i1; ( step > 0 ) ? ( i <= i2 ) : ( i >= i2 ); i += step ){
      char o = Words -> At( i ) -> At( 0 );
      for( j = 0; j < length ops; j++ ){
        if( o == ops[ j ] && Level[ i ] == current_level ){
          return i;
        }
      }
    }
    return -1;
  }
}
