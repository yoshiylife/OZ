/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Label : Item{
 constructor:
  New, NewWithLabel, NewWithLabelA;
 public:
  bind, getID, Move, Shift, Draw, ReDraw, SlideMove, Close, GetModel;
 public:
  SetName, SetState, SetGeometry, SetSize, SetFont, SetFontSize, SetModel;
 public:
  SetText;

 protected:
  ID, Name, State, X, Y, Width, Height, Font, FontSize, UsersValue;

  /* instance variables */
  String Content;

  /* construcotrs */
  void New(){ Content => New();}
  void NewWithLabel( String l ){ Content = l;}
  void NewWithLabelA( char l[] ){ Content => NewFromArrayOfChar( l );}

  /* methods */
  char Kind()[]{ return "string"; }

  Label SetText( String s ){ Content = s; return self; }

  SList MakeInitialArgs( Slide aSlide ){
    SList aList = make_initial_list();

    aList -> Add( make_pair( "text", Content ));
    return aList;
  }

  void MakeAttList(){
    ComILabelText com1 => New( self );

    make_att_list();
    AttList -> PutCommand( com1 );
  }
}
