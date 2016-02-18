/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Monitor scheduler load and memory heap.
//
//	For global object.
//
//	uses:
//		class	ObjectManager
//		class	NameDirectory
//		class	ResolvableObject
//		class	LoadAndHeap
//		class	String
//
inline "C" {
extern	int				OzIdleTime() ;
extern	unsigned int	OzFreeMemory() ;
	extern	OZ_Array	OzFormat() ;
}
//
class	LoadAndHeapMonitor : ResolvableObject( rename New SuperNew ; )
{
constructor:
	New
;
public:	// To be managed by an ObjectManager
	Go,
	Removing,
	Stop,
	Flush
;
public:	// For any client
	LoadAverage,
	HeapConsume,
	Monitor
;
protected:	// Method
	Load,
	Heap,
	Measure
;
protected:	// Instance
	Queue,
	Aborted,
	NameDirKey
;
//------------------------------------------------------------------------------
//
//	Protected Instance
//
String				NameDirKey ;	// Key for NameDirectory
LoadAndHeap			Queue ;
int					Aborted ;

//------------------------------------------------------------------------------
//
//	Private instance
//
char	NAME[] ;	// Class Name (Read only)

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
New( String aName ) : global
{
	long	exid ;
	char	buf[] ;

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}

	NAME = "LoadAndHeapMonitor" ;
	debug( 0, "%S::New()\n", NAME ) ;

	SuperNew() ;

	NameDirKey = aName ;

	Queue = 0 ;
	Aborted = 0 ;

	debug( 0, "%S::New() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Go() : global
{
	global	ObjectManager		OM ;
	global	NameDirectory		ND ;
	global	ResolvableObject	O ;

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}

	debug( 0, "%S::Go()\n", NAME ) ;

	Queue = 0 ;
	Aborted = 0 ;

	OM = Where() ;

	// Check & Register self to NameDirectory
	if ( NameDirKey ) {
		try {
			ND = OM->GetNameDirectory() ;
			O = ND->Resolve( NameDirKey ) ;
			if ( O == 0 ) {
				ND->AddObject( NameDirKey, oid ) ;
				OM->PermanentizeObject( oid ) ;
			} else if ( O != oid ) {
				debug( 0, "%S::Go Replace %O with %O.\n", NAME, O, oid ) ;
				ND->ChangeObject( NameDirKey, oid ) ;
				OM->PermanentizeObject( oid ) ;
			}
		} except {
			default {
				debug( 0, "%S::Go Can't regist to NameDirectory.\n", NAME ) ;
				raise ;
			}
		}
	}

	debug( 0, "%S::Go() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Removing() : global
{
	global	ObjectManager		OM ;
	global	NameDirectory		ND ;
	global	ResolvableObject	O ;

//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}

	debug( 0, "%S::Removing()\n", NAME ) ;

	OM = Where() ;

	// Remove self from NameDirectory
	if ( NameDirKey ) {
		OM->TransientizeObject( oid ) ;
		try {
			ND = OM->GetNameDirectory() ;
			O = ND->Resolve( NameDirKey ) ;
			if ( O == oid ) ND->RemoveObjectWithName( NameDirKey ) ;
		} except {
			default {
				/* Nothing */
			}
		}
	}

	Abort() ;

	debug( 0, "%S::Removing() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Stop() : global
{
//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}
	debug( 0, "%S::Stop()\n", NAME ) ;

	Abort() ;

	debug( 0, "%S::Stop() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method to be managed by an ObjectManager
//
void
Flush() : global
{
//	inline "C" {
//		_oz_debug_flag = 1 ;
//	}
	debug( 0, "%S::Flush()\n", NAME ) ;
	Where()->FlushObject( oid ) ;
	debug( 0, "%S::Flush() return\n", NAME ) ;
}

//------------------------------------------------------------------------------
//	Public method: Scheduler loadaverage.
//
unsigned int
LoadAverage( int aInterval ) : global
{
	unsigned int	result ;

	debug( 0, "%S::LoadAverage( aInterval=%u )\n", NAME, aInterval ) ;

	abortable ;
	result = Load( aInterval ) ;
	abortable ;

	debug( 0, "%S::LoadAverage()=%u\n", NAME, result ) ;
	return( result ) ;
}

//------------------------------------------------------------------------------
//	Public method: Executor heap consume.
//
unsigned int
HeapConsume() : global
{
	unsigned int	result ;

	debug( 0, "%S::HeapConsume()\n", NAME ) ;

	abortable ;
	result = Heap() ;
	abortable ;

	debug( 0, "%S::HeapConsume()=%u\n", NAME, result ) ;
	return( result ) ;
}

//------------------------------------------------------------------------------
//	Protected method
//
unsigned int
Load( int aInterval )
{
	unsigned int	result ;

	debug( 0, "%S::Load( aInterval=%u )\n", NAME, aInterval ) ;

	inline "C" {
		result = 100 - OzIdleTime( aInterval ) ;
	}

	debug( 0, "%S::Load()=%u\n", NAME, result ) ;
	return( result ) ;
}

//------------------------------------------------------------------------------
//	Protected method
//
unsigned int
Heap()
{
	unsigned int	result ;

	debug( 0, "%S::Heap()\n", NAME ) ;

	inline "C" {
		result = OzFreeMemory() ;
	}

	debug( 0, "%S::Heap()=%u\n", NAME, result ) ;
	return( result ) ;
}

LoadAndHeap
Monitor( int aInterval ) : global
{
	LoadAndHeap	data ;

	data => New() ;
	detach fork Measure( aInterval, data ) ;
	return( data->Wait() ? 0 : data ) ;
}

void
Measure( int aInterval, LoadAndHeap aData )
{
	Add( aData ) ;
	aData->Set( Load(aInterval), Heap() ) ;
	Remove( aData ) ;
}

void
Abort() : locked
{
	LoadAndHeap		now, prev ;

	Aborted = 1 ;
	now = Queue ;
	prev = 0 ;
	while ( now ) {
		if ( prev ) prev->SetNext( 0 ) ;
		now->Abort() ;
		prev = now ;
		now = now->GetNext() ;
	}
}

void
Add( LoadAndHeap aData ) : locked
{
	if ( Aborted ) aData->Abort() ;
	else {
		aData->SetNext( Queue ) ;
		Queue = aData ;
	}
}

void
Remove( LoadAndHeap aData ) : locked
{
	LoadAndHeap	now, prev ;

	now = Queue ;
	prev = 0 ;
	while ( now ) {
		if ( aData == now ) {
			if ( prev ) prev->SetNext( now->GetNext() ) ;
			else Queue = now->GetNext() ;
			break ;
		}
		prev = now ;
		now = now->GetNext() ;
	}
}

}
// End of file: LoadAndHeapMonitor.oz
