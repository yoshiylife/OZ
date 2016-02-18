/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Read/Write Lock
//		A multiple-reader, single-write lock
//
class	RdWrLock
{
constructor:
	New
;
public:
	TryRdLock,
	TryWrLock,
	RdLock,
	WrLock,
	UnLock
;

int			Locked ;	// Lock read
int			Count ;		// Count of reader
condition	RdWait ;	// Wait to read
condition	WrWait ;	// Wait to done

void
New()
{
	Locked = 0 ;
	Count = 0 ;
}


int
TryRdLock() : locked
{
	if ( ! Locked ) Count ++ ;

	return( Locked ) ;
}

int
TryWrLock() : locked
{
	int		ret ;

	if ( Locked == 0 && Count == 0 ) {
		Locked = 1 ;
		ret = 0 ;
	} else ret = 1 ;

	return( ret ) ;
}

void
RdLock() : locked
{
	while( Locked ) {
		wait RdWait ;
	}
	Count ++ ;
}

WrLock() : locked
{
	while( Locked ) {
		wait RdWait ;
	}
	Locked = 1 ;

	try {
		while( Count ) {
			wait WrWait ;
		}
	} except {
		Abort {
			Locked = 0 ;
			raise ;
		}
	}
}

void
UnLock() : locked
{
	if ( Locked ) {
		if ( Count ) {
			Count -- ;
			if ( ! Count ) signal WrWait ;
		} else {
			Locked = 0 ;
			signal RdWait ;
		}
	} else Count -- ;
}

}
// End of file: RdWrLock.oz
