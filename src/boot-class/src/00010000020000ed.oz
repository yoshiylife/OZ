/*
 * Copyright(c) 1994-1996 Information-technology Promotion Agency, Japan(IPA)
 *
 * All rights reserved.
 * This software and documentation is a result of the Open Fundamental
 * Software Technology Project of Information-technology Promotion Agency,
 * Japan(IPA).
 *
 * Permissions to use, copy, modify and distribute this software are governed
 * by the terms and conditions set forth in the file COPYRIGHT, located in
 * this release package.
 */
abstract class Command : Collectable<Command> {
 public:
  Execute, GetName;
 public:
  IsEqual, Hash;
 protected:
  Name, MyName, New;

  /* instance variabels */
  String Name;

  /* public methods */
  String GetName(){ return Name; }

  int Execute( SList ) : abstract;

  int IsEqual( Command another ){
    return Name -> IsEqual( another -> GetName());
  }

  char MyName()[]{
    char n[];
    return n;
  }

  void New(){
    Name => NewFromArrayOfChar( MyName());
  }

  unsigned int Hash(){
    if( Name ){
      return Name -> Hash();
    }
    return 0;
  }
}
