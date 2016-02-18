/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class TestWorker : FrameWorker {
 constructor:
  New;
 public:
  Do;

  void New(){}

  void Do( Series aSeries ){
    Screen aScreen => New();
    Screen screen2 => New();
    Slide slide1, slide2;
    Button button1 => NewWithLabelA( "button" );
    CheckButton button2 => NewWithLabelA( "checkbutton" );
    Label label1 => NewWithLabelA( "label" );

    Field field1 => New();
    int i = 10;
    TestModel aModel => New();
    Dependency d;

    button1 -> Move( 100, 100 );
    button2 -> Move( 100, 200 );
    label1 -> Move( 100, 300 );
    aScreen -> AddItem( button1 );
    aScreen -> AddItem( label1 );

    aScreen -> AddItem( field1 );
    d = aScreen;
    d -> SetModel( aModel );
    d = screen2;
    d -> SetModel( aModel );
    
    while( i-- ){
      slide1 = aScreen -> CreateSlide();
      aSeries -> AddSlide( slide1 );
    }

    slide2 = screen2 -> CreateSlide();
    slide2 -> AddItem( button2 );
    aSeries -> AddSlide( slide2 );
  }
}
