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
