/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class Item : Dependency{
 public:
  Hash, IsEqual, bind, getID, Move, Shift, Draw, ReDraw, SlideMove, GetModel, SetModel, SetUsersValue, GetUsersValue, Close;
 public:
  SetName, SetState, SetGeometry, SetSize, SetFont, SetFontSize, ChangeAttributes;

 protected: 
  ID, Name, State, X, Y, Width, Height, Font, FontSize, UsersValue, make_initial_list, make_update_list, make_pair, make_pair_int, make_pair_int2, MakeInitialArgs, Kind, AttList, MakeAttList, make_att_list;

  /* instance variabels */
  IntAsKey   ID;
  String     Name;
  int        State;
  int        X;
  int        Y;
  int        Width;
  int        Height;
  Color      ForeGround;
  String     Font;
  int        FontSize;
  long       UsersValue;

  Dependency Owner;
  Evaluator  AttList;

  /* public methods */
  /* compare */
  unsigned int Hash(){ return ID -> Get(); }
  int IsEqual( Item another ){ return ID -> IsEqual( another -> getID()); }

  void bind( int id, Dependency o ){ ID => New( id ); Owner = o; }
  IntAsKey getID(){ return ID; }

  char Kind()[] : abstract;


  /* mutate */
  Item Move( int x, int y ){ X = x; Y = y; return self; }
  Item Shift( int dx, int dy ){ X += dx; Y += dy; return self; }

  Item SetName( String n ){ Name = n; return self; }
  Item SetState( int i ){ State = i; return self; }
  Item SetGeometry( int xx, int yy ){ X = xx; Y = yy; return self; }
  Item SetSize( int w, int h ){ Width = w; Height = h; return self; }
  Item SetFont( String f ){ Font = f; return self; }
  Item SetFontSize( int s ){ FontSize = s; return self; }
  Item SetForeGround( Color c ){ ForeGround = c; }

  Item SetUsersValue( long v ){ UsersValue = v; return self; }
  long GetUsersValue(){ return UsersValue; }

  /* draw */
  void Draw( Slide aSlide ){
    SList aList => New();
    SimpleParser aParser => New( '{', '}', " " );
    Atom a1 => NewFromArrayOfChar( "OpenItem" );
    Atom a2 => NewFromArrayOfChar( Kind() );
    Atom a3 => NewFromInteger( ID -> Get());

    aList -> Add( a1 );
    aList -> Add( a2 );
    aList -> Add( a3 );
    aList -> AddList( MakeInitialArgs( aSlide ) );
    
    aSlide -> GetSeries() -> SendEvent( aParser -> AsString( aList ));
  }

  void ReDraw( Slide aSlide ){
    SList aList => New();
    SimpleParser aParser => New( '{', '}', " " );
    Atom a1 => NewFromArrayOfChar( "RefreshItem" );
    Atom a3 => NewFromInteger( ID -> Get());

    aList -> Add( a1 );
    aList -> Add( a3 );
    aList -> AddList( MakeInitialArgs( aSlide ) );
    
    aSlide -> GetSeries() -> SendEvent( aParser -> AsString( aList ));
  }

  void SlideMove( Slide aSlide ){}

  void Close( Series aSeries ){
    SList aList => New();
    SimpleParser aParser => New( ' ', ' ', " " );
    Atom a1 => NewFromArrayOfChar( "CloseItem" );
    Atom a2 => NewFromInteger( ID -> Get());

    aList -> Add( a1 );
    aList -> Add( a2 );
    aSeries -> SendEvent( aParser -> AsString( aList ));

/*
    SimpleParser sp => New( ' ', ' ', " " );
    String a1 => NewFromArrayOfChar( "CloseItem " );
    Atom a2 => NewFromInteger( ID -> Get());
    SList list => New();

    list -> Add( a2 );
    aSereis -> SendEvent( a1 -> Concatenate( sp -> AsString( list )));
*/
  }

  Model GetModel(){ return MyModel ? MyModel : Owner -> GetModel(); }

  /* internal methods */
  SList MakeInitialArgs( Slide aSlide ){
    return make_initial_list();
  }

  SList make_initial_list(){
    SList aList => New();
    String normal => NewFromArrayOfChar( "normal" );
    String disabled => NewFromArrayOfChar( "disabled" );

    aList -> Add( make_pair_int2( "geom", X, Y ));
    if( Width && Height )
      aList -> Add( make_pair_int2( "size", Width, Height ));
    if( Name )
      aList -> Add( make_pair( "name", Name ));
//    aList -> Add( make_pair( "state", State ? normal : disabled ));
    aList -> Add( make_pair_int( "value", UsersValue ));

    return aList;
  }

  SList make_update_list(){ return make_initial_list(); }

  SList make_pair( char key[], String value ){
    SList aList => New();
    Atom ak => NewFromArrayOfChar( key );
    Atom av => NewFromString( value );
    aList -> Add( ak );
    aList -> Add( av );
    return aList; 
  }

  SList make_pair_int( char key[], int value ){
    SList aList => New();
    Atom ak => NewFromArrayOfChar( key );
    Atom av => NewFromInteger( value );
    aList -> Add( ak );
    aList -> Add( av );
    return aList; 
  }
  SList make_pair_int2( char key[], int value1, int value2 ){
    SList aList => New();
    Atom ak => NewFromArrayOfChar( key );
    Atom av1 => NewFromInteger( value1 );
    Atom av2 => NewFromInteger( value2 );
    aList -> Add( ak );
    aList -> Add( av1 );
    aList -> Add( av2 );
    return aList; 
  }

  void make_att_list(){
    ComIGeometry com1 => New( self );
    ComISize com2 => New( self );
    ComIValue com3 => New( self );
    SimpleParser aParser => New( '{', '}', " \t" );
    
    AttList => NewWithParser( aParser );
    AttList -> PutCommand( com1 );
    AttList -> PutCommand( com2 );
    AttList -> PutCommand( com3 );
  }
  void MakeAttList(){
    make_att_list();
  }

  Item ChangeAttributes( SList aList ){
    if( AttList == 0 ){
      MakeAttList();
    }
    for( ; !aList -> IsNil(); aList = aList -> Cdr()){
      SList list2 = narrow( SList, aList -> Car());
      try{
        AttList -> Execute( list2 );
      }
      except{
        ListExp::UnknownCommand(key){}
      }
    }
    return self;
  }

}
