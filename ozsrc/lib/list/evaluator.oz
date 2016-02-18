/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Evaluator{
 constructor:
  NewWithParser;

 protected:
  Initialize;

 public:
  SetParser, PutCommand, GetCommand, Spawn, EventLoop, GetOText, Execute;

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
    
    do {
      rec = Sock -> GetLine();
rec->DebugPrint();
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
    } while  ( com -> Execute( args ) == 0 );
  }

  OText GetOText(){ return Sock; }

  void Execute( SList list ){
    Command com;

    try{
      com = GetCommand( list -> Car() -> AsString());
    }
    except{
      CollectionExceptions<String>::UnknownKey (key){
        raise ListExp::UnknownCommand(key);
      }
    }
    com -> Execute( list -> Cdr());
  }
}
