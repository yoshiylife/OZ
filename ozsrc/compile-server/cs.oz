/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 * $Id$
 */

class CompileServer : Workbench
	( 
	  rename Launch WBLaunch; 
	  alias Stop WBStop;
	)
{
 constructor: 
  New;

 public: 
  Quit, Export, ImportPackage, Launch, NewPackage, ConvertPackage, 
  SetClass, SetConfiguration, SetCurrent, GetCurrent, Rename, Duplicate,
  Unregister, LaunchCB, SetCurrentPath, OpenPackages, Stop, ClosePackage,
  CreatePackage;

  CompileServerUI cs_ui;

  UnixIO debugp;

  // override methods start

  void Launch () : global
    {
      if (cs_ui)
	return;

      debugp=>New ();

      debugp->PutStr ("cs Launch\n");

      cs_ui=>New (self);
      UI = cs_ui;

      WBLaunch ();
    }

  void Stop () : global
    {
      debugp->PutStr ("cs Stop\n");

      cs_ui->StopDispatching ();

      cs_ui = 0;
      WBStop ();
    }

  // override methods end
}
