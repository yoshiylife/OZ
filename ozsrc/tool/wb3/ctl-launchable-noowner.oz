/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class CB : Launchable {
 public: Initialize, Launch;

  global CatalogBrowser cb;

   void Initialize ()
     {
       if (!cb)
	 cb=>New ("catalog");

       Where()->PermanentizeObject (cb);
     }

   void Launch ()
     {
       cb->Launch ();
     }
}
