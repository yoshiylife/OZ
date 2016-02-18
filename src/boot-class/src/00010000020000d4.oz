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
class ComGetCid : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{  return "GetCid" ; }

  int Execute( SList args ){
    LauncherEvaluator le = MyEvaluator();
    ProjectLinkSS link = le -> Search( args );
    long id = narrow( CIDHolderSS, link ) -> GetCID();
    String rec;
    char buf[];

    length buf = 17;
    inline "C"{
      OzSprintf( OZ_ArrayElement( buf, char ), "%08x%08x", (unsigned long)( id >> 32 ), (unsigned long)( id & 0xffffffff ));
    }

    rec => NewFromArrayOfChar( buf );
    le -> SendEvent( rec );
    return 0;
  }
}


