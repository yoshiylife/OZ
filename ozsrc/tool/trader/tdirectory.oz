/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class TradingDirectory : DirectoryServerOfBroker 
  ( rename Copy SuperCopy;
    rename Move SuperMove;
    rename List SuperList;
    rename Register SuperRegister;
    rename Remove SuperRemove;
    rename Update SuperUpdate; ){
 constructor:
  NewDomain;

 public:
  Copy, IsEmpty, Kill, List, ListPreferences, Move, Register, Remove, Request, Retrieve, Update;
 protected: SuperUpdate;

  /* instance variables */
  String DomainName;
  String DirName;
  IntervalServer RefreshBrokers;

  /* private methods */
  String GetDelimiter(){
    String d => NewFromArrayOfChar( ":" );
    return d;
  }

  String path( String name ){
    return DirName -> Concatenate( GetDelimiter() ) -> Concatenate( name );
  }

  global DirectoryServerOfBroker 
    CreateNewDirectoryServer (global ObjectManager where){}

  /* constructors */
  void NewDomain( String domain_name ) : global {
    String trader => NewFromArrayOfChar( "trader" );
    global NameDirectory name;

    DomainName = domain_name;
    DirName => NewFromArrayOfChar( ":a" );

    NewDirectorySystem();
//    NewDirectory( DirName -> Concatenate( GetDelimiter()));
    NewDirectory( DirName );
//    name = Where() -> GetNameDirectory();
//    if( !name -> IsRegisteredResolver( trader ))
//      name -> AddObject( trader, oid );

    RefreshBrokers => New( 60 );
    detach fork RefreshBrokers -> Start();
  }

  global TradingDirectory Copy( String name1, String name2 ) : global{
    SuperCopy( path( name1 ), path( name2 ));
    return oid;
  }

  global TradingDirectory Move( String name1, String name2 ) : global{
    SuperMove( path( name1 ), path( name2 ));
    return oid;
  }

  Collection<String> List() : global{
    return SuperList( DirName );
  }

  Dictionary<String,String> ListPreferences( String service ) : global{
    OwnMap -> AtKey( DirName ) -> Retrieve( service ) -> Preferences();
  }

  global TradingDirectory Register( String name, Broker service ) : global{
    SuperRegister( path( name ), service );
    if( service -> RefreshInterval() > 0 )
      RefreshBrokers -> Add( service );
    return oid;
  }

  Broker Remove( String name ) : global{
    Broker r = SuperRemove( path( name ));
    if( r -> RefreshInterval() > 0 )
      RefreshBrokers -> Remove( r );
    return r;
  }

  AccessStab Request( String name, Dictionary<String,String> pref, global ObjectManager here ) : global{
    if( here == 0 ) here = Where();
    return Retrieve( path( name )) -> Request( pref, here );
  }
  
  global TradingDirectory Update( String name, Broker broker ) : global{
    Broker old = Retrieve( path( name ));
    SuperUpdate( path( name ), broker );
    if( broker -> RefreshInterval() > 0 ){
      RefreshBrokers -> Remove( old );
      RefreshBrokers -> Add( broker );
    }
    return oid;
  }

  void Go() : global{
    RefreshBrokers -> Go();
  }
}
