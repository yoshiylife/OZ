/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//
//
class	LoadAndHeap
{
constructor:
	New
;
public:
	Load,
	Heap,
	Set,
	Wait,
	Abort,
	SetNext,
	GetNext
;

unsigned	int			load ;
unsigned	int			heap ;
			int			flag ;
		condition		cond ;
		LoadAndHeap		next ;

void
New()
{
	flag = 0 ;
}

void
Set( unsigned int aLoad, unsigned int aHeap ) : locked
{
	flag = 0 ;
	load = aLoad ;
	heap = aHeap ;
	signal cond ;
}

int
Wait() : locked
{
	wait cond ;
	return( flag ) ;
}

void
Abort() : locked
{
	flag = 1 ;
	signal cond ;
}

unsigned int
Load()
{
	return( load ) ;
}

unsigned int
Heap()
{
	return( heap ) ;
}

LoadAndHeap
SetNext( LoadAndHeap aData ) : locked
{
	next = aData ;
	return( next ) ;
}

LoadAndHeap
GetNext() : locked
{
	return( next ) ;
}

}
