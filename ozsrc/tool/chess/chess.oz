/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Chess : Frame{
 constructor:
  New;

 public:
  Evaluate, Assign, get_series;

  /* consturctors */
  void New() : global {
    ChessInitModel aWorker => New();
    NewWithWorker( aWorker );
  }

  /* public methods */
  CellValue Evaluate( String boardName, int row, int col ) : global {
    Board aBoard = narrow( Board, MySeries -> FindSlideByName( boardName ));
    Cell aCell = aBoard -> GetCell( row, col );

    return aCell -> Evaluate();
  }

  void Assign( String boardName, int row, int col, CellValue value ) : global{
    Board aBoard = narrow( Board, MySeries -> FindSlideByName( boardName ));
    Cell aCell = aBoard -> GetCell( row, col );

    aCell -> SetValue( value );
  }

  /* internal methods */
  unsigned int get_series() : global {
    unsigned int r;
    inline "C"{
      r = (unsigned long)(OZ_InstanceVariable_Frame( MySeries ));
    }
    return r;
  }
}
  
