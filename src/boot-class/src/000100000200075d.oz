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
class CB<OwnerType> : Launchable {
 public: Initialize, Launch;

  global CatalogBrowserFor<OwnerType> cb;

   void Initialize ()
     {
       if (!cb)
	 cb=>New (cell, ":catalog");

       Where()->PermanentizeObject (cb);
     }

   void Launch ()
     {
       cb->Launch ();
     }
}
