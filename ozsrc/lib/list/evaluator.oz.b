class Evaluator{
 constructor:
  NewWithParser;

 protected:
  Initialize;

 public:
  SetParser, PutCommand, GetCommand, Spawn, EventLoop, GetOText;

  /* instance variables */
  Parser Syntax;
  IOText Sock;
  Dictionary<String,Command>  Commands;

  /* constructors */
  void NewWithParser( Parser par ){
    Syntax = par;
    Commands => New();
    Initialize();
  }

  /* access */
  Parser SetParser( Parser np ){
    Parser old = Syntax;
    Syntax = np;
    return old;
  }

  void PutCommand( Command com ){
    Commands -> AddAssoc( com -> GetName(), com );
  }

  Command GetCommand( String name ){
    return Commands -> AtKey( name );
  }

  void Initialize(){}

  void Spawn( String path, SequencedCollection<String> args ){
    ExternalProgram pgm => NewWithPath( path );
    Sock = pgm -> Spawn( args ) -> GetText();
  }

  void EventLoop(){
    String rec;
    SList list;
    SList args;
    Linkable head;
    Command com;

    if( Sock == 0 )
      raise ListExp::NotSpawned;

    while( 1 ){
      rec = Sock -> GetLine();
rec -> DebugPrint();
      list = Syntax -> Parse( rec );
      head = list -> Car();
      try{
        com = GetCommand( head -> AsString());
      }
      except{
        CollectionExceptions<String>::UnknownKey (key){
          raise ListExp::UnknownCommand(key);
        }
      }
      args = list -> Cdr();
      detach fork com -> Execute( args );
    }
  }

  void exec( Command com, SList args ){
    if( com -> Execute( args ) == 0 );
  }

  OText GetOText(){ return Sock; }

}
