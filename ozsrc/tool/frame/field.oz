/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Field : Item{
 constructor:
  New, NewWithLength;
 public:
  Draw, ReDraw, SlideMove, GetValue, Entered, GetLength, SetLength, Move, Shift, SetUsersValue, GetUsersValue, SetModel;
 public:
  SetName, SetState, SetGeometry, SetSize, SetFont, SetFontSize;
 protected:
  CreateHolder;

  /* instance variables */
  int Length;

  /* constructors */
  void New(){}
  void NewWithLength( int l ){ Length = l; }

  /* methods */
  char Kind()[]{ return "field"; }

  Field SetLength( int l ){ Length = l; return self; }
  int GetLength(){ return Length; }

  SList MakeInitialArgs( Slide aSlide ){
    SList aList = make_initial_list();
    StringHolder aHolder = narrow( StringHolder, aSlide -> GetHolder( ID ));
    String quote => NewFromArrayOfChar( "\"" );

    if( aHolder == 0 ){
      aHolder = CreateHolder();
      aSlide -> setHolder( ID, aHolder );
    }
    aList -> Add( make_pair( "text", quote -> Concatenate ( aHolder -> Get() ) -> Concatenate( quote )));
    aList -> Add( make_pair_int( "length", Length ));
    return aList;
  }

  void SlideMove( Slide aSlide ){ 
    ReDraw( aSlide );
  }

  String GetValue( Slide aSlide ){
    return narrow( StringHolder, aSlide -> GetHolder( ID )) -> Get();
  }

  void Entered( Series aSeries, Slide aSlide, String value ){
    Model aModel;
    Holder aHolder;
    StringHolder aSHolder;

    if(( aHolder = aSlide -> GetHolder( ID )) == 0 ){
      aSHolder = CreateHolder();
      aSlide -> setHolder( ID, aSHolder );
    }
    else{
      aSHolder = narrow( StringHolder, aHolder );
    }

    aSHolder -> Assign( value );

    if(( aModel = GetModel()) != 0 ){
      aModel -> FieldEntered( aSeries, self, value );     
    }
  }

  StringHolder CreateHolder(){
    StringHolder aHolder => New();
    return aHolder;
  }
}
