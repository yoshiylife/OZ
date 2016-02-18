/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	OZ++ debug statement support
 */
#ifndef	_OZ_DEBUG_H_
#define	_OZ_DEBUG_H_
#include "oz++/object-type.h"
typedef	struct	OZ_DebugInfoRec*	OZ_DebugInfo ;
struct	OZ_DebugInfoRec {
	int		size ;
	unsigned int	*debugFlags ;
} ;

extern	unsigned int	OzDebugFlags ;

extern	int
OzExecDebugCheck( OZ_Object this, OID vid, int part, void *info ) ;

extern	int
OzExecDebugMessage( OID, char *aFormat, ... ) ;

#define	OzDebugCheck( this, cid, part, info )	\
	(( OzDebugFlags & 0x80000000 || _oz_debug & 0x80000000 \
		|| ( (this) && (this)->head.g & 0x80000000 ) ) \
		? OzExecDebugCheck( this, cid, part, info ) : 0 )

/*
 *	Function Access Control type
 */
#define	OZ_AC_RECORD		0x01
#define	OZ_AC_CONSTRUCTOR	0x02
#define	OZ_AC_PUBLIC		0x04
#define	OZ_AC_PROTECTED		0x08
#define	OZ_AC_PRIVATE		0x10

#endif	!_OZ_DEBUG_H_
