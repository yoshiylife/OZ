/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	DebugManagerLaunchable: Bootup DebugManager
//
class	DebugManaerLaunchable : Launchable, GUI {
	try {
		global	Object	o = cell ;
				char	id[] ;
				String	name, tmp ;
		length id = 17 ;
		inline "C" {
			char	buf[32] ;
			OzSprintf( buf, "%O", o ) ;
			OzStrcpy( OZ_ArrayElement(id,char), buf ) ;
		}
		tmp => NewFromArrayOfChar( "Debugger:" ) ;
		name = tmp->ConcatenateWithArrayOfChar( buf ) ;
		nd = OM->GetNameDirectory() ;
	} except {
		default {
			OM->Removing(
		}
	}


} // class DebugManagerLaunchable [dml.oz]
