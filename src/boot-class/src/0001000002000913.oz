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
