/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Button : Item{
 constructor:
  New, NewWithLabel, NewWithLabelA;
 public:
  bind, getID, Move, Shift, Draw, ReDraw, SlideMove, Close, GetModel, SetUsersValue, GetUsersValue;
 public:
  SetName, SetState, SetGeometry, SetSize, SetFont, SetFontSize, SetModel;
 public:
  SetLabel, GetLabel, Pressed;
 protected:
  ID, Name, State, X, Y, Width, Height, Font, FontSize, UsersValue;
 protected:
  Label, MakeInitialArgs, Kind, make_initial_list, make_pair, make_pair_int, AttList, MakeAttList;
  /* instance variables */
  String Label;

  /* construcotrs */
  void New(){ State = 1; Label => New(); }
  void NewWithLabel( String l ){ State = 1; Label = l; }
  void NewWithLabelA( char l[] ){ State = 1; Label => NewFromArrayOfChar( l );}

  /* methods */
  char Kind()[]{ return "button"; }

  /* access */
  Button SetLabel( String l ){ Label = l; return self; }
  String GetLabel(){ return Label; }

  SList MakeInitialArgs( Slide aSlide ){
    SList aList = make_initial_list();

    aList -> Add( make_pair( "label", Label ));
    return aList;
  }

  void MakeAttList(){
    ComIButtonLabel com1 => New( self );

    make_att_list();
    AttList -> PutCommand( com1 );
  }
    
  void Pressed( Series aSeries, Slide aSlide ){
    Model aModel = GetModel();
    if( aModel == 0 )
      return;
    aModel -> ButtonPressed( aSeries, self );
  }

  void ReDraw( Slide aSlide ){}
}
