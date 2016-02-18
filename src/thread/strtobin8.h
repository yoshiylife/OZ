/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_strtobin8_)
#define	_strtobin8_

#include <sys/types.h>

#if	!defined(LLONG_MIN)
#define	LLONG_MIN	(-9223372036854775807LL-1LL)
#endif
#if	!defined(LLONG_MAX)
#define	LLONG_MAX	9223372036854775807LL
#endif
#if	!defined(ULLONG_MAX)
#define	ULLONG_MAX	18446744073709551615ULL
#endif

extern	unsigned long long
strtobin8( const u_char *str, u_char **ptr, int base, int sign ) ;

#endif	/* _strtobin8_ */
