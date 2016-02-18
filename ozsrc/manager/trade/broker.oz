/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class Broker : IntervalJob ( rename Interval RefreshInterval; ){
 public:
  Preferences, Refresh, RefreshInterval, Request, AddAll, Add;

 protected:
  PreferenceTable;

  /* instance variables */
  Dictionary<String,String> PreferenceTable;

  void Refresh(){}

  int Do(){ 
    Refresh();
    return 1;
  }

  int RefreshInterval(){ return 0; }

  AccessStab Request( Dictionary<String,String> preferences, global ObjectManager where ) : abstract;

  Collection<String> Preferences(){ 
    if( PreferenceTable == 0 ){
      PreferenceTable => New();
    }
    return PreferenceTable -> SetOfKeies();
  }

  void AddAll( Dictionary<String,String> preferences ){
    Iterator<Assoc<String,String>> ite;
    Assoc<String,String>  asc;

    if( PreferenceTable == 0 ){
      PreferenceTable => New();
    }
    ite => New( PreferenceTable );
    while(( asc = ite -> PostIncrement()) != 0 ){
      PreferenceTable -> AddAssoc( asc -> Key(), asc -> Value() );
    }
  }

  void Add( String key, String value ){
    if( PreferenceTable == 0 ){
      PreferenceTable => New();
    }
    PreferenceTable -> AddAssoc( key, value );
  }
}
