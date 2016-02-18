/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(__OZ__DEBUG_SUPPORT__H)
#define	__OZ__DEBUG_SUPPORT__H

#include <sys/types.h>

u_int	DsMaskProcess( u_int, OZ_Object ) ;
int	DsCheckException( int type ) ;
void	DsTrapException( int, OZ_ExceptionID, long long, char ) ;
int	DsCaptureDebugMessage( const char *aData, int aSize ) ;
int	DsCaptureException( const char *aData, int aSize ) ;
int	OzSetCaptureMessage( int fd ) ;
int	OzSetCaptureException( int fd ) ;
char	*DsExceptionName( int aValue ) ;

OZ_Array	OzFormat( const char *aFormat, ... ) ;

#endif	/* ! __OZ__DEBUG_SUPPORT__H */
