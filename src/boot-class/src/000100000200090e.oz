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
class CatalogBrowserForLauncher : CatalogBrowser (alias Quit SuperQuit; rename SuperNew New;){
 constructor:
  New;

 protected:
  Owner;
 public:
  Launch, SetPath, Import, Quit, SelectPath;

  /* instance variables */
  int Flg;

   void Export (String package_names[])
     {
       Package packages[];

       if (!Owner)
	 return;

       packages = Retrieve (package_names);

       detach fork narrow (LauncherSS, Owner)
	 ->ImportPackage (package_names, packages);
     }


  void Quit(){
    SuperQuit();
    if( Flg++ % 2 ) return;
    narrow( LauncherSS, Owner ) -> CatalogBrowserQuited();
  }
}
