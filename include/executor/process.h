/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_EXEC_PROCESS_H_)
#define	_EXEC_PROCESS_H_

extern int OzExecForkProcess
  (void (*pc)(), char fmt, int stackSize, int priority, unsigned int dflags,
   int nArg, ...);
extern	void		OzExecDetachProcess( int pid ) ;
extern	long long	OzExecJoinProcess( int pid ) ;
extern	void		OzExecAbortProcess( int pid ) ;

#endif	_EXEC_PROCESS_H_
