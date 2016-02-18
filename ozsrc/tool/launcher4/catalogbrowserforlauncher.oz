/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
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
