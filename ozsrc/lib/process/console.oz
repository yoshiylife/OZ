/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class Console{
 constructor:
  New, NewWithTitle;
 public:
  Open, Write, Read, SetPrompt, Close;

  String Title;
  String Prompt;
  IOTextA2 Term;

  void New(){
    Title => New();
    Prompt = 0;
  }

  void NewWithTitle( String title ){
    Title = title;
    Prompt = 0; 
  }

  String SetPrompt( String prm ){
    String old = Prompt;
    Prompt = prm;
    return old;
  }

  void put_prompt(){
    if( Prompt ){
      Term -> PutString( Prompt );
    }
  }

  void Open(){
    int fd;
    char title[] = Title -> Content();
    IOFStream str;

    inline "C" {
      fd = OzCreateKterm( OZ_ArrayElement( title, char ), 0 );
    }
    Term => New();
    Term -> Dup( fd );
  }

  void Write( String rec ){
    if( Term == 0 )
      raise EP::NotOpend;
    Term -> PutString( rec );
    Term -> FlushBuf();
  }

  String Read(){
    StreamBuffer buf;

    if( Term == 0 )
      raise EP::NotOpend;

    put_prompt();
    return Term -> GetLine() -> ConcatenateWithArrayOfChar( "\n" );
  }

  void Close(){
    if( Term == 0 )
      raise EP::NotOpend;
    Term -> Close();
  }
}
