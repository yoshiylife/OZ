/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Reentrant convert string to binary 8 bytes
 *
 *	Specification reference: Japnese solaris 2.4
 *
 *		NOTIC: This moudle is independent of any other module
 *
 */
#include <stdio.h>
#include <errno.h>
#include <ctype.h>
#include "strtobin8.h"

#if	!defined(SVR4)
extern	int	tolower( int c ) ;
#endif

typedef	enum { false, true }	Boolean ;
typedef	unsigned long long	ullong ;
typedef	long long		llong ;

ullong
strtobin8( const u_char *str, u_char **ptr, int base, int sign )
{
	ullong	result_val = 0ULL ;		/* result value */
const	u_char	*result_ptr = str ;		/* result pointer */
	Boolean	minus = false ;			/* flag of negative value */

	Boolean	overflow = false ;		/* flag of overflow */
	ullong	overQ ;				/* overflow quotient limit */
	ullong	overR ;				/* overflow residual limit */
	ullong	overL ;				/* overflow limit value */

const	u_char	*p ;
	u_char	c ;

	/* Check parameter */
	if ( base < 0 || base == 1 || 36 < base ) {
		errno = EINVAL ;
		goto error ;
	}

	/* Skip white-space */
	while( isspace( *str ) ) str ++ ;
	if ( *str == '\0' ) goto error ;

	/* Check sign */
	if ( *str == '-' ) {
		minus = true ;
		str ++ ;
	} else if ( *str == '+' ) str ++ ;

	/* Set default base and skip "0x" or "0X" */
	if ( *str == '0' ) {
		str ++ ;
		c = tolower( *str ) ;
		if ( base == 0 || base == 16 ) {
			if ( c == 'x' && isxdigit( *(str+1) ) ) {
				str ++ ;
				base = 16 ;
			} else if ( base == 0 ) base = 8 ;
		}
		result_ptr = str ;
	}
	c = *(p = str) ;
 	if ( base == 0 ) base = 10 ;

	/* Set overflow limit value */
	if ( sign == true ) {
		if ( minus == true ) {
			overL = LLONG_MIN ;
			overQ = overL / base ;
			overR = overL % base ;
		} else {
			overL = LLONG_MAX ;
			overQ = overL / base ;
			overR = overL % base ;
		}
	} else {
		overL = ULLONG_MAX ;
		overQ = overL / base ;
		overR = overL % base ;
	}

	/* Parse and check overflow */
	for ( ; c != '\0' ; c = *(++ p) ) {
		if ( isdigit(c) ) c -= '0' ;
		else if ( isalpha(c) ) c = tolower(c) - 'a' + 10 ;
		else break ;
		if ( base <= c ) break ;
		if ( overflow == true ) continue ;
		if ( overQ < result_val || (overQ == result_val && overR < c) ){
			overflow = true ;
		} else {
			result_val *= (ullong)base ;
			result_val += c ;
		}
	}
	if ( p != (u_char *)str ) result_ptr = p ;
	if ( overflow == true ) {
		errno = ERANGE ;
		minus = false ;
		result_val = overL ;
	}

error:
	if ( ptr != NULL ) *ptr = (u_char *)result_ptr ;
	return( (minus == true) ? -result_val : result_val ) ;
}
