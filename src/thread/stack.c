/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Multithread system: stack and memory allocation module
 *
 *	IMPORTANT:
 *		You must be block signal before calling stk...
 *		
 */
/* unix system include */
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
/* multithread system include */
#include "thread.h"
#include "thread/signal.h"
#include "thread/stack.h"

/*
 * Don't include any other module
 */


#define	STACK_TABLE_SIZE	16
#define	STACK_UPGAP_SIZE	(ThrPageSize)
#define	PROT_RDWR		(PROT_READ|PROT_WRITE)

/*
 *	system calls
 */
#if	!defined(SVR4)
extern	int	mprotect( caddr_t addr, size_t len, int prot ) ;
extern	caddr_t	mmap( caddr_t addr, size_t len, int prot, int flags,
			int fildes, off_t off ) ;
#endif	/* SVR4 */


/*
 *	Stack allocation
 */
typedef	struct	StackRec*	Stack ;
typedef	struct	StackRec {
	size_t	page ;
	Stack	next ;
} StackRec ;

static	int	stkPageLog ;			/* log2(PageSize) */
static	struct	{
	u_int	used ;
	u_int	free ;
	Stack	stack ;
} stkTable[STACK_TABLE_SIZE] ;


caddr_t
stkAlloc( size_t size )
{
	caddr_t addr = NULL ;
	Stack	stack, prev ;
	int	page ;

	page = (size ? ((size - 1) >> stkPageLog) : 0) + 1 ;
	size = page << stkPageLog ;
	if ( page < STACK_TABLE_SIZE - 1 ) {
		if ( stkTable[page].stack ) {
			stack = stkTable[page].stack ;
			stkTable[page].stack = stack->next ;
			stkTable[page].used ++ ;
			stkTable[page].free -- ;
			addr = (caddr_t)stack ;
		}
	} else if ( stkTable[0].stack ) {
		prev = stack = stkTable[0].stack ;
		while( stack ) {
			if ( page == stack->page ) {
				prev->next = stack->next ;
				stkTable[0].used ++ ;
				stkTable[0].free -- ;
				addr = (caddr_t)stack ;
				break ;
			}
			prev = stack ;
			stack = stack->next ;
		}
		page = 0 ;
	}
	if ( addr == NULL ) {
		stkTable[page].used ++ ;
		size += STACK_UPGAP_SIZE ;
		addr = mmap( 0, size, PROT_RDWR, MAP_PRIVATE, ThrDevZero, 0 ) ;
		if ( addr == (caddr_t)-1 ) {
			ThrPanic( "stkAlloc mmap(0x%x): %m.", size ) ;
		}
		if ( mprotect( addr, STACK_UPGAP_SIZE, PROT_NONE ) ) {
			ThrPanic( "stkAlloc mprotect(0x%x,0x%x): %m.",
						addr, STACK_UPGAP_SIZE ) ;
		}
		addr += STACK_UPGAP_SIZE ;
	}

	return( addr ) ;
}

void
stkFree( caddr_t addr, size_t size )
{
	Stack	stack = (Stack)addr ;
	int	page ;

	page = (size ? ((size - 1) >> stkPageLog) : 0) + 1 ;
	size = page << stkPageLog ;
	if ( page < STACK_TABLE_SIZE - 1 ) {
		stack->next = stkTable[page].stack ;
		stkTable[page].stack = stack ;
		stkTable[page].used -- ;
		stkTable[page].free ++ ;
	} else {
		stack->next = stkTable[0].stack ;
		stack->page = page ;
		stkTable[0].stack = stack ;
		stkTable[0].used -- ;
		stkTable[0].free ++ ;
	}

	/*
	 *	munmap ?
	 */
}

void
StkInitialize()
{
	int	i ;

	for ( i = 0 ;  i < STACK_TABLE_SIZE ; i ++ ) {
		stkTable[i].used = 0 ;
		stkTable[i].free = 0 ;
		stkTable[i].stack = NULL ;
	}
  
	for( stkPageLog = 0 ; (ThrPageSize>>stkPageLog) != 1 ; stkPageLog ++ ) ;
}

void
StkShutdown()
{
#if	0	/* for debug */
	int	i ;

	ThrPrintf( "stkTable\n" ) ;
	for ( i = 0 ; i < STACK_TABLE_SIZE ; i ++ ) {
		ThrPrintf( "%2d: %4d %4d\n",
				i, stkTable[i].used, stkTable[i].free ) ;
	}
#endif

	/*
	 *	munmap ?
	 */
}
