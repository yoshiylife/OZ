/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	global	DebugManager
//
class	DebugManager : ResolvableObject {
{
constructor:
New
;
public:	/* special method for global object */
	Go, Removing, Stop, Flush, Where
;
public:	/* DebugManager functions */
	ListOfProcesses
;
protected:
;
	char	Name[] ;	/* name of this class for debug */
	global	ObjectManager	OM ;

void
New()
{

	Name = "DebugManager" ;
	debug( default, "%S(%O)::New() begin\n", Name, cell ) ;

	OM = Where() ;
	debug( default, "%S(%O)::New() end\n", Name, cell ) ;
}

void
Go()
{
	global	Object	o = cell ;
	debug( default, "%S(%O)::Go() begin\n", Name, cell ) ;
	OzDmStarted( cell ) ;
	debug( default, "%S(%O)::Go() end\n", Name, cell ) ;
}

void
Removing()
{
	debug( default, "%S(%O)::Removing() begin\n", Name, cell ) ;
	debug( default, "%S(%O)::Removing() end\n", Name, cell ) ;
}

void
Stop()
{
	debug( default, "%S(%O)::Stop() begin\n", Name, cell ) ;
	OzDmStopped() ;
	debug( default, "%S(%O)::Stop() end\n", Name, cell ) ;
}

void
Flush()
{
	debug( default, "%S(%O)::Flush() begin\n", Name, cell ) ;
	debug( default, "%S(%O)::Flush() end\n", Name, cell ) ;
}

} // class Debugger [debugger.oz]
