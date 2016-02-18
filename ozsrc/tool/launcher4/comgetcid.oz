/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
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


