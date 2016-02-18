/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Mutual exclusion with abortable
//
class	Mutex
{
constructor:
	New, NewAbortable
;
public:
	TryLock,
	Lock,
	UnLock,
	TryAbort,
	Abort
;
protected: /* Instance */
	Locked,
	Aborted,
	Wait
;

		int			Locked ;	// Boolean(0:false, oterwise:true)
		int			Aborted ;	// 3 state flag
								//	<  0 : no check
								//	== 0 : not abort
								//  >  0 : aborted
		condition	Wait ;

void
New()
{
	Locked = 0 ;
	Aborted = -1 ;
}

void
NewAbortable()
{
	Locked = 0 ;
	Aborted = 0 ;
}

int
TryLock() : locked
{
	int		ret ;

	if ( 0 < Aborted ) ret = -1 ;
	else {
		ret = Locked ;
		if ( ! Locked ) Locked = 1 ;
	}

	return( ret ) ;
}

void
Lock() : locked
{
	while( Locked ) {
		wait Wait ;
		if ( 0 < Aborted ) abort ;
	}
	Locked = 1 ;
}

void
UnLock() : locked
{
	Locked = 0 ;
	signal Wait ;
	return ;
}

int
TryAbort() : locked
{
	if ( Aborted == 0 ) Aborted = 1 ;
	signalall Wait ;
	return( Locked ) ;
}

void
Abort() : locked
{
	if ( Aborted == 0 ) Aborted = 1 ;
	signalall Wait ;
	while( Locked ) {
		wait Wait ;
	}
	return ;
}

}
// End of file: Mutex.oz
