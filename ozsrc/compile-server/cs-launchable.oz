/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * $Id$
 */

class CSLaunchable : Launchable
{
 public: Initialize, Launch;

   global CompileServer cs;

   void Initialize ()
     {
       global ObjectManager om = Where ();

       if (!cs)
	 cs=>New ();
       om->PermanentizeObject (cs);
     }

   void Launch ()
     {
       cs->Launch ();
     }
}
