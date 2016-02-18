/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class IntervalServer{
 constructor:
  New;

 public:
  AddAll, Add, Start, Remove, Go;
  /* instance variables */
  int Precision;
  Set<IntervalJob> Jobs;

  void New( int p ){ 
    Precision = p; 
    Jobs => New();
  }

  void AddAll( Collection<IntervalJob> c ){
    Iterator<IntervalJob> ite;
    IntervalJob   j;

    ite => New( c );
    while( j = ite -> PostIncrement()){
      Add( j );
    }
  }

  void Add( IntervalJob j ) : locked {
    j -> Reset();
    Jobs -> Add( j );
  }

  void Start() {
    for(;;){
      inline "C"{
        OzSleep( OZ_InstanceVariable_IntervalServer( Precision ));
      }
      loop();
    }
  }

  void loop() : locked{
    Iterator<IntervalJob> ite;
    IntervalJob j;

    ite => New( Jobs );
    for( ite -> Reset(); j = ite-> PostIncrement(); j != 0 ){
      if( j -> Past( Precision ) == 0 ){
        Jobs -> Remove( j );
      }
    }
  }

  void Remove( IntervalJob j ) : locked{
    Jobs -> Remove( j );
  }

  void Go() : global{
    Iterator<IntervalJob> ite;
    IntervalJob   j;

    ite => New( Jobs );
    while( j = ite -> PostIncrement()){
      j -> Reset();
    }
  }
}  
