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
class CatalogBrowserFor<OwnerClass> 
	: CatalogBrowser
		( rename New not_used; 
		  rename SuperNew New; )
{
 constructor:
  New;

 public:
  Launch, SetPath, Import, Quit, SelectPath;

   void Export (String package_names[])
     {
       Package packages[];

       if (!Owner)
	 return;

       packages = Retrieve (package_names);

       detach fork narrow (OwnerClass, Owner)
	 ->ImportPackage (package_names, packages);
     }
}
