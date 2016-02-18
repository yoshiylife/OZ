/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Recursive global invoke test.
//
class TestRecursiveGlobalInvoke : Launchable, ResolvableObject
{
constructor:
	New
;
public:	/* for Local */
	Initialize,
	Launch
;
public:	/* for Global */
	Invoke,
	Go
;
protected:	/* Method */
	Test
;

	char	Name[] ;	/* Class Name */

	/* for Launchable */
	int		Sleep ;		/* Sleep time on last invoke */
	int		Level ;		/* Nest level of recursive invoke */
	Lock	P_Lock ;	/* Mutex for instance variable: Process */
	int		@Process ;	/* Process of recursive global invoke */

	global	TestRecursiveGlobalInvoke	Self ;

void
New() : global
{
	Name = "TestRecursiveGlobalInvoke" ;
	debug( 0, "%S::New()\n", Name ) ;
	Self = narrow( TestRecursiveGlobalInvoke, cell ) ;
	debug( 0, "%S::New return\n", Name ) ;
}

void
Go() : global
{
	debug( 0, "%S::Go()\n", Name ) ;
	debug( 0, "%S::Go return\n", Name ) ;
}

int
Invoke( int aSleep, int aLevel ) : global
{
	debug( 0, "%S::Invoke( aSleep=%d, aLevel=%d )\n", Name, aSleep, aLevel ) ;
	if ( aLevel <= 0 ) inline "C" { OzSleep( aSleep ) ; }
	else Self->Invoke( aSleep, aLevel-1 ) ;
	debug( 0, "%S::Invoke = %d\n", Name, aLevel ) ;
	return( aLevel ) ;
}

void
Initialize()
{
	Number	number ;
	Input	input ;
	char	buf[] ;

	number => New() ;
	input => New( "TestRecursiveGlobalInvoke" ) ;
	buf = input->Get( "Level" ) ;
	Level = number->Integer( buf ) ;
	buf = input->Get( "Sleep" ) ;
	Sleep = number->Integer( buf ) ;
	input->Delete() ;

	Self => New() ;
	P_Lock => New() ;
}

void
Test() : locked
{
	int		ret ;

	debug( 0, "%S::Test()\n", Name ) ;
	P_Lock->Lock() ;
	try {
		Process = fork Self->Invoke( Sleep, Level ) ;
	} except {
		default {
			Process = 0 ;
		}
	}
	P_Lock->UnLock() ;
	if ( Process ) {
		ret = join Process ;
		debug( 0, "%S::Test @Process=%d\n", Name, ret ) ;
		P_Lock->Lock() ;
		Process = 0 ;
		P_Lock->UnLock() ;
	}
	debug( 0, "%S::Test return\n", Name ) ;
}

void
Launch()
{
	debug( 0, "%S::Launch()\n", Name ) ;
	P_Lock->Lock () ;
	if ( Process == 0 ) {
		detach fork Test() ;
	} else {
		debug( 0, "%S::Test Process=%P\n", Name, Process ) ;
	}
	P_Lock->UnLock () ;
	debug( 0, "%S::Launch return\n", Name ) ;
}

} // class TestRecursiveGlobalInvoke [Test/RecursiveGlobalInvoke.oz]
