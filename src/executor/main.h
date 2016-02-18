/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _MAIN_H_
#define _MAIN_H_

extern	char		*OzVersion ;
extern	char		*OzRoot ;
extern  long long	OzExecutorID ;
extern	int	        OzStandAlone ;
extern  int		OzHeapSize ;
extern	int		OzThreadMax ;
extern	int		OzClockTicks ;
extern	int		OzGIMonitor ;
extern	int		OzForkShell ;
extern	int		OzDaemon ;
extern	int		OzArgc ;
extern	char		**OzArgv ;
extern	int		OzDebugging ;
extern	int		OzExportAll ;
extern	int		OzIconify ;

#endif  _MAIN_H_
