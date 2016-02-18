/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_TIMER_H_
#define	_TIMER_H_

extern	int	TimerInit( int aMax ) ;
extern	int	TimerMark( int aTag ) ;
extern	int	TimerStart() ;
extern	int	TimerEnd( int aTag ) ;
extern	int	TimerFinish() ;

#endif	!_TIMER_H_
