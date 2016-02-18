/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class SList : Linkable, 
  SequencedCollection<Linkable>( rename IsEqual IsEqualCollection; ) {
 constructor:
  New, NewWithLinkable;

 public:
  Car, Cdr, AsString, Print, RemoveAList, IsNil, DebugPrint, Print2, AsString2, AddList;

 public: /* inherited from SequencedCollection */
  At, AtAllPut, DoNext, First, Hash, IsEqual, IndexOf,
  Last, OccurrencesOf, ReplaceFrom;

 public: /* inherited from Collection */
  Add, AddAll, AddContentsTo, AsArray, DoFinish, DoReset,
  Includes, IsEmpty, Remove, RemoveAllContent, RemoveAll, Size;

  /* instance variables */
  SList   Next;
  Linkable Value;

  /* constructors */
  void New(){
    NilAtom  nil => New();
    Value = nil;
    Next = 0;
  }

  void NewWithLinkable( Linkable link ){
    Value = link;
    Next = 0;
  }

  /* public methods */
  /* list operators */
  int IsNil(){
    if( Next == 0 )
      return Value -> IsNil();
    return 0;
  }

  Linkable Car(){ return Value; }

  SList Cdr(){ 
    if( Next == 0 ){  /* return an empty list */
      SList l => New();
      return l;
    }
    return Next; 
  }

  String AsString(){
    String open => NewFromArrayOfChar( "(" );
    String close => NewFromArrayOfChar( ")" );
    String delim => NewFromArrayOfChar( " " );

    return AsString2( open, close, delim );
  }

  String AsString2( String open, String close, String delim ){
//    String delim => NewFromArrayOfChar( " " );

    if( Next == 0 ){
      String empty => New();
      return empty;
    }
    return Value -> Print2( open, close, delim ) 
      -> Concatenate( delim -> GetSubString( 0, 1 ))
        -> Concatenate( Next -> AsString2( open, close, delim ) );
  }

  String Print(){
    String open => NewFromArrayOfChar( "(" );
    String close => NewFromArrayOfChar( ")" );
    String delim => NewFromArrayOfChar( " " );

    return Print2( open, close, delim );
/*    return open -> Concatenate( AsString() )
      -> Concatenate( close ); */ 
  }

  String Print2( String open, String close, String delim ){
    return open -> Concatenate( AsString2( open, close, delim ) )
      -> Concatenate( close );
  }

  /* collection operators */
  Linkable At( unsigned int idx ){
    SList list = self;
    while( idx-- ){
      if(( list = list -> Cdr()) == 0 )
        raise CollectionExceptions<Linkable>::InvalidParameter;
    }
    return list -> Car();
  }

  void AtAllPut( Linkable o ){
    Value = o;
    if( Next )
      Next -> AtAllPut( o );
  }

  void ReplaceFrom(unsigned int start, unsigned int stop,
		      SequencedCollection <Linkable> replacement,
		      unsigned int start_at){}

  Linkable First(){ return Car(); }

  SList RemoveAList( Linkable content ){
    if( Value -> IsEqual( content )){
      return Next;
    }
    return Next -> RemoveAList( content );
  }

  Linkable Remove( Linkable content ){
    if( Value -> IsEqual( content )){
      Value = Next -> Car();
      Next = Next -> Cdr();
    }
    else{
      Next = Next -> RemoveAList( content );
    }
    return content;
  }

  Linkable Add( Linkable content ){
    if( Next )
      Next -> Add( content );
    else{
      SList terminate => New();
      Value = content;
      Next = terminate;
    }
    return self;
  }

  SList AddList( SList another ){
    if( Next ){
      if( Next -> IsNil()){
        Next = another;
      }
      else{
        Next -> AddList( another );
      }
    }
    else{
      SList terminate => New();
      Value =  another -> Car();
      Next = terminate;
    }
    return self;
  }

  void DebugPrint(){
    Linkable link = Car();
    
    if( link -> IsNil() ) return;
    link -> Print() -> DebugPrint();
    Cdr() -> DebugPrint();
  }

  unsigned int Hash(){ return 0; }
}
