/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class CatalogBrowser : 
  DirectoryBrowser<Catalog, Package>
  	( rename New SuperNew; )
{
 constructor:
  New;

 public:
  Launch, SetPath, Import, Quit, SelectPath;

 protected: 
  SuperNew, Owner, Retrieve, Export;

  void New (char name[]) : global
    {
      SuperNew (0, name);
    }

  String ListNames (Package package)[]
    {
      if (package)
	return package->GetSchool ()->ListNames()->AsArray ();
      else
	return 0;
    }
}
