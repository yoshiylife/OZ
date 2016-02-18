/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class TradeBroker : Broker{
 constructor:
  New;

  Console Con;

  void New(){ Con => New(); Con -> Open(); }

  AccessStab 
    Request( Dictionary<String,String> pref, global ObjectManager where ){
      TraderAccessStab stab => New( cell );
      return stab;
    }

  int RefreshInterval() { return 60; }

  void Refresh(){
    String ref => NewFromArrayOfChar( "refreshd.\n" );
    Con -> Write( ref );
  }
}
  
