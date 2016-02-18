/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_TESTANDSET_H_
#define	_TESTANDSET_H_
/*
 * Don't include any other module
 */

#ifndef	INLINE
#define	INLINE	inline extern
#endif	!INLINE

INLINE	unsigned int
TestAndSet( char *ptr )
{
	unsigned int	rval ;

	/* IMPORTANT 'volatile', Don't remove it */
	asm volatile ( "ldstub %1,%0" : "=r" (rval), "=m" (*ptr) : ) ;
	return( rval ) ;
}

INLINE	int
TestAndReset( char *ptr )
{
	int	rval ;
	/* IMPORTANT 'volatile', Don't remove it */
	asm volatile ( "clr %0;swap %1,%0" : "=r" (rval), "=m" (*ptr) : ) ;
	return( rval ) ;
}

#endif	!_TESTANDSET_H_
