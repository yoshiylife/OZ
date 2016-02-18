/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Cell : StringHolder {
 constructor:
  New;
 public:
  SetExpression, Evaluate, IntrruptEvaluation, SetValue, Print;

  /* instance variables */
  String    Script;
  CellValue Value;
  CellValue@  Active;
  CellEvaluator Evaluator;

  /* constructors */
  void New(){ Evaluator => new(); }

  /* public methods */
  void SetExpression( String s ){ Script = s; }

  CellValue Evaluate(){
/*
    try{
      set_proc( fork Evaluator -> Evaluate( Script ));
      Value = join get_proc();
inline "C" { OzDebugf( "%x\n", OZ_InstanceVariable_Cell( Value )); }
    }
    except{
      ChildAborted{
        return 0;
      }
    }
*/
    try{
      if( Script != 0 ){
        Value = Evaluator -> Evaluate( Script );
        Assign( Value -> Print());
        return Value;
      }
    }
    except{
      ChessShared::SyntaxError{}
    }
    return 0;
  }

  void IntrruptEvaluation(){
    CellValue@ p;
    if( p = get_proc() )
      kill p;
  }

  CellValue SetValue( CellValue v ){ Value = v; return Value; }

  String Print(){ 
    if( Value == 0 ){
      String s => New();
      return s;
    }
    return Value -> Print(); 
  }
  String Get(){ return Print(); }

  /* internal methods */
  void set_proc( CellValue@ p ) : locked { Active = p; }
  CellValue@ get_proc() : locked { 
    CellValue@ p = Active; 
    Active = 0;
    return p;
  }
}
