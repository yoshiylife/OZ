/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class ComCatalog : LauncherCommand{
 constructor:
  New;
 public:
  Execute;

  char MyName()[]{ return "Catalog"; }

  int Execute( SList args ){
    narrow( LauncherSS, cell ) -> OpenCatalogBrowser();
    return 0;
  }
}
