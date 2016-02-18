/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_STACK_H_
#define	_STACK_H_
/* unix system include */
#include <sys/types.h>

/*
 * Don't include any other module
 */


extern	caddr_t	stkAlloc( size_t size ) ;
extern	void	stkFree( caddr_t addr, size_t size ) ;
extern	void	StkInitialize() ;
extern	void	StkShutdown() ;

#endif	!_STACK_H_
