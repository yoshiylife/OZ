/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * $Id$
 */

class ESLaunchable : Launchable
{
 public: Initialize, Launch;

   global EnqueteServer es;

   void Initialize ()
     {
       global ObjectManager om = Where ();

       if (!es)
	 es=>New ();
       om->PermanentizeObject (es);
     }

   void Launch ()
     {
       es->Launch ();
     }
}
