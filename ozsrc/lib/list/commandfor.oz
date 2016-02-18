/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class CommandFor<T> : Command( alias New SuperNew; ){
 protected:
  Client;
 protected:
  MyName, Execute;
 constructor:
  New;

  /* instance variabels */
  T   Client;

  /* constructors for sub classes */
  void New( T ct ){
    Client = ct;
    SuperNew();
  }
}
