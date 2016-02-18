/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

abstract class WorkbenchTools 
{
 constructor: 
  Initialize;

 protected: 
  UI, aClass;

  WorkbenchUI UI;
  global Class aClass;

   void Initialize (global Class cl, WorkbenchUI ui)
     {
       aClass = cl;
       UI = ui;
     }
   
}
