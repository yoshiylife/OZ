/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class IOTextSun : IOText {
 public:
  OpenWithName, Close, GetLine, GetString, GetChar, GetTillAChar,
  GetTillAString, UngetString, UngetChar, Eof,
  AppendWithName, PutLine, PutString, PutChar, FlushBuf;
 protected:
  Strm, Dup;
 constructor:
  New;

  IOFStream  Strm;
  ITextSun   Input;
  OTextSun   Output;

  void New(){
    Strm => New();
  }

  void OpenWithName( String n ) : locked{
    int f;
    Strm -> OpenWithName( n );
//    f = Strm -> GetFd();
    Input => Assign( Strm );
    Output => Assign( Strm );
  }

  void Dup( int fd ){
    Strm -> Dup( fd );
    Input => Assign( Strm );
    Output => Assign( Strm );
  }

  void AppendWithName( String n ){ 
    OpenWithName( n );
  }

   void Close(){ 
//     Input -> Close();
//     Output -> Close();
     Output -> FlushBuf();
     Strm -> Close(); 
   }

  String GetTillAChar( char del ){
    return Input -> GetTillAChar( del );
  }

  String GetString( int len ){
    return Input -> GetString( len );
  }

  char GetChar(){
    return Input -> GetChar();
  }

  String GetLine(){
    return Input -> GetLine();
  }
      
  String GetTillAString( String s ){ raise StreamExceptions::NotYet; }

  void UngetString(){ raise StreamExceptions::NotYet; }
  void UngetChar(){ 
    Input -> UngetChar();
  }

  int Eof(){ return Input -> Eof(); }

   void PutLine( String str ) {
     Output -> PutLine( str );
   }

   void PutString( String str ){
     Output -> PutString( str );
   }

   void PutChar( char c ) {
     Output -> PutChar( c );
   }

  void FlushBuf(){ Output -> FlushBuf(); }
}
