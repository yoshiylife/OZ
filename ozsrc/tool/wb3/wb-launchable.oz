/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

class WorkbenchLaunchable : Launchable 
{
 public: Initialize, Launch;

   global Workbench aWorkbench;

   void Initialize ()
     {
       global ObjectManager om = Where ();

       if (!aWorkbench)
	 aWorkbench=>New ();
       om->PermanentizeObject (aWorkbench);
     }

   void Launch ()
     {
       aWorkbench->Launch ();
     }
}
