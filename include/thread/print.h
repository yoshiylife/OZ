/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_prn_print_h
#define	_prn_print_h
#include <sys/types.h>
#include <stdarg.h>

/*
 *	bit pattern of additional Format infomation
 *	       31                              0
 *		76543210765432107654321076543210
 *		                        -------- -> argument data size
 *		                --------	 -> radical base number/type
 *		 	--------		 -> pading character
 *		       ^			 -> <flags> '+'
 *		      ^ 			 -> <flags> ' '
 *		     ^  			 -> <flags> '#'
 *		    ^   			 -> lower(0)/upper(1) char's set
 *		   ^    			 -> reserve
 *		  ^     			 -> reserve
 *		 ^      			 -> reserve
 *		^       			 -> unsigned(0) / signed(1)
 */
typedef	union	{
	unsigned int	value ;
	struct	{
		unsigned	sign    : 1 ;
		unsigned	reserve : 3 ;
		unsigned	lower   : 1 ;
		unsigned	alt	: 1 ;
		unsigned	space   : 1 ;
		unsigned	plus    : 1 ;
		unsigned	pad	: 8 ;
		unsigned	type	: 8 ;
		unsigned	size	: 8 ;
	}	f ;
	struct	{
		unsigned char	flags ;
		unsigned char	pad ;
		unsigned char	base ;
		unsigned char	size ;
	} v ;
} PrnFlags ;

typedef	int	PRNOUT( void *aKey, const char *aData, size_t aSize ) ;
typedef	size_t	PRNEXT( char *, int, int, PrnFlags, va_list * ) ;
extern	int	PrnFormat( PRNOUT *, void *, const char *, va_list ) ;
extern	size_t	PrnString( char *, int, int, const char * ) ;
extern	size_t	PrnInteger( char *, int, int, PrnFlags, ... ) ;
extern	PRNEXT	*PrnExtend ;

#endif	!_prn_print_h
