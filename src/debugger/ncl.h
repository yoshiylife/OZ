/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_DEBUGGER_NCL_H)
#define	_OZ_DEBUGGER_INET_H

#include	<sys/un.h>
#include	<sys/types.h>
#include	<sys/socket.h>
#include	<netinet/in.h>

extern	int	OpenNcl( const char *aNclHostName ) ;
extern	int	closeNcl( int aPort ) ;
extern	int	callNcl( int , long long, struct sockaddr_in * ) ;

#endif	/* ! _OZ_DEBUGGER_NCL_H */
