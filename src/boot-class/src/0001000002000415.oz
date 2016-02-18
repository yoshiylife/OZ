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
