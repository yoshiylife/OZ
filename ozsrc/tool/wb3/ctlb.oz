/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
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
