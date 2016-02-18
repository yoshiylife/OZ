/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Frame : ResolvableObject{
 constructor:
  New, NewWithWorker;
 public:
  ImportSlide, ExportCurrentSlide;

 protected:
  MySeries;

  /* instance variables */
  Series     MySeries;

  /* constructors */
  void New() : global{
    MySeries => New();
    Go();
  }

  void NewWithWorker( FrameWorker aWorker ) : global {
    MySeries => New();
    aWorker -> Do( MySeries );
    Go();
  }

  void Go() : global {
    MySeries -> Start();
  }

  void ImportSlide( Slide aSlide ) : global {
    MySeries -> AddSlide( aSlide );
  }

  Slide ExportCurrentSlide(): global {
    return MySeries -> GetCurrentSlide();
  }
}
