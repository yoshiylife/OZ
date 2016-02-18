/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Series{
 constructor:
  New;
 public:
  Start, DrawCurrentSlide, MoveSlide, MoveFirst, MoveLast, ShiftSlide, AddSlide, SendEvent, GetCurrentSlide, Quit, FindSlideByName, MoveSlideByName, FindScreen;

  /* instance variables */
  OrderedCollection<Slide>     Slides;
  Set<Screen>                  Screens;
  Slide                        CurrentSlide;
  Slide                        LastSlide;
  int                          Index;
  Evaluator                    Eval;
  OText                        Sock;

  /* constructors */
  void New(){
    SimpleParser aParser => New( '{', '}', " \t\n" );
    ComPressed com1 => New( self );
    ComEntered com2 => New( self );
    ComCheck com3 => New( self );
    ComFrameQuit com4 => New( self );
    ComDeleteItem com5 => New( self );
    ComUpdateItem com6 => New( self );
    ComJunkshop com7 => New( self );

    Slides => New();
    Screens => New();
    CurrentSlide = 0; 
    LastSlide = 0;
    Index = 0;
    Eval => NewWithParser( aParser );
    
    Eval -> PutCommand( com1 );
    Eval -> PutCommand( com2 );
    Eval -> PutCommand( com3 );
    Eval -> PutCommand( com4 );
    Eval -> PutCommand( com5 );
    Eval -> PutCommand( com6 );
    Eval -> PutCommand( com7 );
  }

  /* methods */
  void Start(){
    String path, com;
    EnvironmentVariable env;
    String command => NewFromArrayOfChar( "source " );
    
    path => NewFromArrayOfChar( "wish" );
    Eval -> Spawn( path, 0 );
    Sock = Eval -> GetOText();

    command = command -> Concatenate( env. GetEnv( "OZROOT" )) -> ConcatenateWithArrayOfChar( "/lib/gui/frame/ga-mut.tcl" );
    SendEvent( command );

    detach fork Eval -> EventLoop();
    LastSlide = 0;
    DrawCurrentSlide();
  }

  void DrawCurrentSlide() : locked{
    Screen currentScreen;

    if( CurrentSlide == 0 )
      return;
    currentScreen = CurrentSlide -> GetScreen();

    if( LastSlide != 0 ){
      Screen lastScreen;
      LastSlide -> EraseAllItems( self );
      lastScreen = LastSlide -> GetScreen();
      if( lastScreen != currentScreen ){
        lastScreen -> EraseAllItems( self );
        currentScreen -> Draw( CurrentSlide );
        CurrentSlide -> Draw();
      }
      else{
        currentScreen -> SlideMove( CurrentSlide );
        CurrentSlide -> Draw();
      }
    }
    else{ /* first */
      currentScreen -> Draw( CurrentSlide );
      CurrentSlide -> Draw();
    }
  }

  Slide GetCurrentSlide(){ return CurrentSlide; }

  int MoveSlide( int i ){
    if( i < 0 || i >= Slides -> Size()){
      raise CollectionExceptions<Slide>::InvalidIntParameter( i );
    }
    LastSlide = CurrentSlide;
    CurrentSlide = Slides -> At( i );
    Index = i;
    DrawCurrentSlide();
    return Index;
  }

  int MoveSlideByName( String n ){
    Iterator<Slide> ite => New( Slides );
    Slide aSlide;
    int i;

    for( i = 0; aSlide = ite -> PostIncrement(); i++){
      if( aSlide -> compareName( n )){
        return MoveSlide( i );
      }
    }
    raise CollectionExceptions<String>::UnknownKey( n );
  }
    
  int MoveFirst(){ return MoveSlide( 0 ); }
  int MoveLast(){ return MoveSlide( Slides -> Size() - 1 ); }
  
  int ShiftSlide( int i ){
    return MoveSlide( Index + i );
  }

  void AddSlide( Slide aSlide ){
    Screen newScreen = aSlide -> GetScreen();

   if( newScreen == 0 ){
      ;
    }
    if( Screens -> Includes( newScreen )){
      Screen oldScreen = Screens -> FindObjectWithKey( newScreen );
      aSlide -> setScreen( oldScreen );
    }
    else{
      Screens -> Add( newScreen );
    }
    aSlide -> setSeries( self );
    if( Slides -> Size() <= 0 )
      CurrentSlide = aSlide;
    Slides -> AddLast( aSlide );
  }

  void SendEvent( String rec ){
    Sock -> PutLine( rec );
    Sock -> FlushBuf();
  }

  Slide FindSlideByName( String n ){
    Iterator<Slide> ite => New( Slides );
    Slide aSlide;

    while( aSlide = ite -> PostIncrement()){
      if( aSlide -> compareName( n ))
        return aSlide;
    }
    raise CollectionExceptions<String>::UnknownKey( n );
  }

  void Quit(){
    Sock -> Close();
  }

  Screen FindScreen( Screen aScreen ){
    return Screens -> FindObjectWithKey( aScreen );
  }
}
