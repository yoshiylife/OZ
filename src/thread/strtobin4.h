/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_strtobin4_)
#define	_strtobin4_

#include <sys/types.h>

#if	!defined(LONG_MIN)
#define	LONG_MIN	(-2147483647L-1L)
#endif
#if	!defined(LONG_MAX)
#define	LONG_MAX	2147483647L
#endif
#if	!defined(ULONG_MAX)
#define	ULONG_MAX	4294967295UL
#endif

extern	unsigned long
strtobin4( const u_char *str, u_char **ptr, int base, int sign ) ;

#endif	/* _strtobin4_ */
