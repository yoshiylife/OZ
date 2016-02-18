/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Lock
//
class	Lock
{
constructor:
	New
;
public:
	TryLock,
	Lock,
	UnLock
;
protected: /* Instance */
	Locked,
	Wait
;

		int			Locked ;	// Boolean(0:false, oterwise:true)
		condition	Wait ;

void
New()
{
	Locked = 0 ;
}

int
TryLock() : locked
{
	int	ret ;

	ret = Locked ;
	if ( ! Locked ) Locked = 1 ;

	return( ret ) ;
}

void
Lock() : locked
{
	while( Locked ) wait Wait ;
	Locked = 1 ;
}

void
UnLock() : locked
{
	Locked = 0 ;
	signal Wait ;
}

} // End of file: Lock.oz
