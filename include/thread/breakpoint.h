/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_BREAKPOINT_H_
#define	_BREAKPOINT_H_
/* multithread system include */
#include "thread/thread.h"

/*
 * Don't include any other module
 */


typedef	enum	{
	brkFree, brkEnable, brkDisable
} BrkStatus ;

typedef	struct BrkPointStr*	BrkPoint ;
typedef	struct BrkPointStr	BrkPointRec ;
struct	BrkPointStr	{
	BrkStatus	status ;
	BrkPoint	next ;
	int		bid ;
	caddr_t		base ;
	u_long		pc ;
	u_long		code ;
} ;

extern	BrkPoint	BrkInsert( u_long pc ) ;
extern	void		BrkRemove( BrkPoint bp ) ;
extern	int		BrkClear( u_long pc ) ;
extern	int		BrkEnable( int bid ) ;
extern	int		BrkDisable( int bid ) ;
extern	int		BrkDelete( int bid ) ;
extern	int		BrkContinue( Thread t ) ;
extern	int		BrkMap( int (func)(), void *arg ) ;
extern	void		BrkInitialize() ;
extern	void		BrkShutdown() ;

#endif	_BREAKPOINT_H_
