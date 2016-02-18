/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Reentrant print with format
 *
 *	NOTICE: This module is independent of any other module.
 *		You must be use <stdarg.h> in this file.
 *
 *	format: %[<flags>][<width>][.<precision>][<size>]<type>
 */
#include <stdio.h>
#include <unistd.h>
#include <ctype.h>
#include <stdarg.h>
#include <memory.h>
#include <string.h>
#include <errno.h>
#include <math.h>
#include <floatingpoint.h>
#include "thread/print.h"

/*
 * Don't include any other module
 */

/* to convert errno to error message */
extern	int	sys_nerr ;
extern	char	*sys_errlist[] ;

/* Extend format */
PRNEXT	*PrnExtend = NULL ;

/* Internal type */
typedef	enum	{
	false=0,
	true
} Boolean ;

typedef	long long		large ;			/* 8bytes integer */
typedef	unsigned long long	ularge ;

/* Internal constant strings */
static	const	char	null[] = "(null)" ;
static	const	char	unknown[] = "Unknown " ;
static	const	char	SI[] = { 0x1b, 0x24, 0x42, 0x00 } ;
static	const	char	SO[] = { 0x1b, 0x28, 0x4a, 0x00 } ;
static	const	char	lower_cset[] = "0123456789abcdefghijklmnopqrstuvwxyz" ;
static	const	char	upper_cset[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ" ;

#define	TRUE		1
#define	FALSE		0

/* check jis shiftin code */
static	Boolean
shiftin( const char *aString )
{
	if ( *aString == SI[0] && *(++ aString) ) {
		if ( *aString == SI[1] && *(++ aString) ) {
			if ( *aString == SI[2] ) return( true ) ;
		}
	}
	return( false ) ;
}

/* length of string for jis code, euc code, and except '%' */
static	size_t
length( const char *aString )
{
	const	char	*s = aString ;

	/* jis code */
	if ( *s == 0x1b && shiftin( s ) == true ) {
		s = strstr( s + 3, SO ) ;	/* search jis shift out codes */
		s += ( s != NULL ? 3 : strlen(aString) ) ;

	/* euc code */
	} else if ( !isascii( *s ) ) {
		do s ++ ; while ( *s && !isascii(*s) ) ;

	/* ascii code except '%' */
	} else {
		do {
			s ++ ;
			if ( *s == 0x1b && shiftin( s ) == true ) break ;
		} while ( *s && *s != '%' ) ;
	}

	return( s - aString ) ;
}

/*
 *	Output string to buffer
 *	if aPrecision is -1, use default precision.
 *	it mean to justify on left that aWidth is minus.
 */
size_t
PrnString(
	char	*aBuffer,			/* output buffer */
	int	aWidth, int aPrecision,		/* format infomation */
	const	char	*aString 		/* input buffer */
)
{
	char	*pbuf = aBuffer ;
	Boolean	left = false ;
	size_t	len ;

	if ( aWidth < 0 ) {
		/* justify on left */
		aWidth = - aWidth ;
		left = true ;
	}

	/* length of string */
	if ( aString ) len = strlen( aString ) ;
	else {
		/* print null pointer */
		aString = null ;
		len = sizeof(null) - 1 ;
	}

	/* trim string */
	if ( aPrecision != -1 && aPrecision < len ) {
		len = aPrecision ;
		if ( aString == null ) aString = "" ;
	}
		
	/* output */
	aWidth -= len ;
	if (left == false && aWidth > 0 ) while( aWidth -- ) *pbuf ++ = ' ' ;
	if ( len < 16 ) while( len -- ) *pbuf ++ = *aString ++ ;
	else {
		memcpy( pbuf, aString, len ) ;
		pbuf += len ;
	}
	if ( left == true && aWidth > 0 ) while( aWidth -- ) *pbuf ++ = ' ' ;

	/* be convenient for use to call this function directly */
	*pbuf = '\0' ;

	return( pbuf - aBuffer ) ;
}

/*
 *	Output integer to buffer
 *	if aPrecision is -1, use default precision.
 *	it mean to justify on left tha aWidth is minus.
 */
size_t
PrnInteger(
	char		*aBuffer,		/* output buffer */
	int		aWidth, int aPrecision,	/* format infomation */
	PrnFlags	aFlags,			/* additional infomation */
	...					/* input buffer */
)
{
	va_list	args ;
 const	char	*cset ;
	char	*pbuf = aBuffer ;
	char	work[BUFSIZ] ;
	char	*w ;
	size_t	len ;
	size_t	base ;
	char	pad ;
	Boolean	left = false ;
	Boolean	minus = false ;
	Boolean	zero = false ;
	ularge	u ;

	pad = aFlags.v.pad ;
	base = aFlags.v.base ;

	/* Get integer value */
	va_start( args, aFlags ) ;
	if ( aFlags.f.sign ) {
		large	s ;
		switch( aFlags.v.size ) {
		case	2: s = (large)va_arg( args, short ) ; break ;
		case	8: s = va_arg( args, large ) ; break ;
		default  : s = (large)va_arg( args, int ) ;
		}
		if ( s < 0 ) {
			minus = true ;
			u = - s ;
		} else u = s ;
	} else {
		switch( aFlags.v.size ) {
		case	2: u = (ularge)va_arg( args, unsigned short ) ; break ;
		case	8: u = va_arg( args, ularge ) ; break ;
		default  : u = (ularge)va_arg( args, unsigned int ) ;
		}
	}
	va_end( args ) ;

	if ( aWidth < 0 ) {
		/* justify on left */
		aWidth = - aWidth ;
		left = true ;
	}

	/* select character set */
	cset = aFlags.f.lower ? lower_cset : upper_cset ;

	/* default precision */
	if ( aPrecision == -1 ) aPrecision = 1 ;

	if ( u == 0 ) zero = true ;
	base %= sizeof(lower_cset) - 1 ;
	w = work + sizeof(work) - 1 ;
	len = 0 ;
	while( u > 0 ) {
		*w -- = cset[u % base ] ;
		u /= base ;
		aWidth -- ;
		aPrecision -- ;
		len ++ ;
	}

	if ( aFlags.f.alt && base == 8 && aPrecision <= 0 ) {
		*w -- = '0' ;
		aWidth -- ;
		len ++ ;
	}
	if ( aPrecision > 0 ) {
		aWidth -= aPrecision ;
		while( aPrecision -- ) {
			*w -- = '0' ;
			len ++ ;
		}
	}
	if ( aFlags.f.alt && base == 16 && zero == false ) aWidth -= 2 ;
	if ( minus == true || aFlags.f.plus || aFlags.f.space ) -- aWidth ;

	if ( left == false && pad == ' ' && aWidth > 0 ) {
		while( aWidth -- ) *pbuf ++ = pad ;
	}

	if ( minus == true ) *pbuf ++ = '-' ;
	else if ( aFlags.f.plus ) *pbuf ++ = '+' ;
	else if ( aFlags.f.space ) *pbuf ++ = ' ' ;

	if ( aFlags.f.alt && base == 16 && zero == false ) {
		*pbuf ++ = '0' ;
		*pbuf ++ = cset[33] ;
	}
	if ( left == false && pad == '0' && aWidth > 0 ) {
		while( aWidth -- ) *pbuf ++ = pad ;
	}
	len = work + sizeof(work) - 1 - w ;
	w ++ ;
	if ( len < 16 ) while( len -- ) *pbuf ++ = *w ++ ;
	else {
		memcpy( pbuf, w, len ) ;
		pbuf += len ;
	}
	if ( left == true && aWidth > 0 ) while( aWidth -- ) *pbuf ++ = ' ' ; 

	/* be convenient for use to call this function directly */
	*pbuf = '\0' ;

	return( pbuf - aBuffer ) ;
}


/*
 *	print args with format
 */
#define	OUTPUT(key,data,size)	\
	if ( (ret=aOutPut( key, data, size )) < 0 ) return( ret ) ;\
	else n += ret ;
int
PrnFormat( PRNOUT *aOutPut, void *aKey, const char *aFormat, va_list args )
{
 const	char		*f = aFormat ;
	Boolean		stop ;		/* up level loop break flag */
	Boolean		left ;		/* Justify string on left flag */

	int		n = 0 ;		/* Count of output bytes */
	char		type ;		/* format type */
	int		width ;		/* field width */
	int		prec ;		/* field precision */
	PrnFlags	flags ;	/* format infomation */

	char		*ptr ;
	double		number ;
	PRNEXT		*extend = PrnExtend ;	/* IMPORTANT */

	size_t		len ;
	int		ret ;
	char		buf[BUFSIZ] ;	/* temporary buffer */

	while( *f != '\0' ) {

		/* preceding character output and skip */
		if ( *f != '%' ) {
			len = length( f ) ;
			OUTPUT( aKey, f, len ) ;
			f += len ;
			continue ;
		}

		f ++ ;

		/* '%' output */
		if ( *f == '%' ) {
			OUTPUT( aKey, f, 1 ) ;
			f ++ ;
			continue ;
		}

		/* Check <flags> */
		left = FALSE ;
		flags.f.space = FALSE ;				/* default */
		flags.f.plus = FALSE ;
		flags.f.alt = FALSE ;
		flags.v.pad = ' ' ;				/* default */
		stop = false ;
		do {
			switch ( *f ) {
			case '-': left = TRUE ; break ;
			case '+': flags.f.plus = TRUE ; break ;
			case ' ': flags.f.space = TRUE ; break ;
			case '#': flags.f.alt = TRUE ; break ;
			case '0': flags.v.pad = '0' ; break ;
			default : stop = true ;
			}
			if ( stop == true ) break ;
			else f ++ ;
		} while ( stop == false ) ;
		if ( left == TRUE ) flags.v.pad = ' ' ;

		/* Get <width> */
		width = 0 ;					/* default */
		if ( *f == '*' ) {
			width = va_arg( args, int ) ;
			if ( width < 0 ) {
				left = TRUE ;
				width = - width ;
			}
			f ++ ;
		} else {
			while( isdigit( *f ) ) {
				width *= 10 ;
				width += *f ++ - '0' ;
			}
		}

		/* Get <precision> */
		prec = -1 ;					/* default */
		if ( *f == '.' ) {
			f ++ ;
			if ( *f == '*' ) {
				prec = va_arg( args, int ) ;
				if ( prec < 0 ) prec = -1 ;
				f ++ ;
			} else if ( isdigit( *f ) ) {
				prec = 0 ;
				while( isdigit( *f) ) {
					prec *= 10 ;
					prec += *f ++ - '0' ;
				}
			}
		}

		/* Check <size> (default data size is 4bytes)*/
		flags.v.size = 4 ;		/* data size is 2bytes */
		stop = false ;
		do {
			switch( *f ) {
			case 'h': flags.v.size = 2 ; f ++ ; break ;
			case 'l': flags.v.size = 8 ; f ++ ; break ;
			default : stop = true ;
			}
		} while ( stop == false ) ;

	/* <type> */
	type = *f ;
	if ( *f ) f ++ ;
	switch( type ) {
	case 'd': case 'i':
		flags.f.sign = TRUE ;
		flags.v.base = 10 ;
		if ( left == true ) width = - width ;
		switch( flags.v.size ) {
		case	2:
			len = PrnInteger( buf, width, prec, flags.value,
					va_arg( args, short) ) ;
			break ;
		case	8:
			len = PrnInteger( buf, width, prec, flags.value,
					va_arg( args, large) ) ;
			break ;
		default  :
			len = PrnInteger( buf, width, prec, flags.value,
					va_arg( args, int) ) ;
		}
		OUTPUT( aKey, buf, len ) ;
		break ;
	case 'b': case 'o': case  'u': case 'x': case 'X':
		flags.f.sign = FALSE ;
		flags.f.space = FALSE ;
		if ( left ) width = - width ;
		switch( type ) {
		case 'b': flags.v.base = 2  ; break ;
		case 'o': flags.v.base = 8  ; break ;
		case 'u': flags.v.base = 10 ; break ;
		case 'x': flags.v.base = 16 ; flags.f.lower = TRUE ; break ;
		case 'X': flags.v.base = 16 ; flags.f.lower = FALSE ; break ;
		}
		switch( flags.v.size ) {
		case	2:
			len = PrnInteger( buf, width, prec, flags.value,
					va_arg( args, short) ) ;
			break ;
		case	8:
			len = PrnInteger( buf, width, prec, flags.value,
					va_arg( args, large) ) ;
			break ;
		default  :
			len = PrnInteger( buf, width, prec, flags.value,
					va_arg( args, int) ) ;
		}
		OUTPUT( aKey, buf, len ) ;
		break ;
	case 'f':
		ptr = buf ;
		{
			int	i ;
			int	decpt ;
			int	sign ;
			char	work[BUFSIZ] ;
			number = va_arg( args, double ) ;
			if ( prec == -1 ) prec = 6 ;
			fconvert( number, prec, &decpt, &sign, work ) ;
			if ( sign ) *ptr ++ = '-' ;
			if ( decpt <= 0 ) {
				*ptr ++ = '0' ;
				*ptr ++ = '.' ;
				while ( decpt ++ ) *ptr ++ ='0' ;
				for ( i = 0 ; i <= prec ; i ++ )
					*ptr ++ = work[i] ;
				len = ptr - buf ;
			} else {
				i = 0 ;
				while( decpt -- ) *ptr ++ = work[i++] ;
				*ptr ++ = '.' ;
				while( work[i] ) *ptr ++ = work[i++] ;
				len = ptr - buf ;
			}
		}
		OUTPUT( aKey, buf, len ) ;
		break ;
	case 'e':
		ptr = buf ;
		{
			int	i ;
			int	decpt ;
			int	sign ;
			char	work[BUFSIZ] ;
			number = va_arg( args, double ) ;
			if ( prec == -1 ) prec = 7 ;
			econvert( number, prec, &decpt, &sign, work ) ;
			if ( sign ) *ptr ++ = '-' ;
			i = 0 ;
			*ptr ++ = work[i++] ;
			*ptr ++ = '.' ;
			while( work[i] ) *ptr ++ = work[i++] ;
			*ptr ++ = 'e' ;
			decpt -- ;
			if ( decpt < 0 ) {
				*ptr ++ = '-' ;
				decpt = - decpt ;
			} else {
				*ptr ++ = '+' ;
			}
			if ( (decpt/100)%10 ) *ptr ++ = '0' + ((decpt/100)%10) ;
			*ptr ++ = '0' + ((decpt/10)%10) ;
			*ptr ++ = '0' + (decpt%10) ;
			len = ptr - buf ;
		}
		OUTPUT( aKey, buf, len ) ;
		break ;
	case 'g': case 'E': case 'G':
		break ;
	case 'c':
		if ( width > 16 ) memset( buf+1, ' ', width-1 ) ;
		else if ( width > 1 ) {
			len = width - 1 ;
			ptr = buf + 1 ;
			while ( len -- ) *ptr ++ = ' ' ;
		} else width = 1 ;
		if ( left ) {
			buf[0] = (char)va_arg( args, int ) ;
			OUTPUT( aKey, buf, width ) ;
		} else  {
			buf[width] = (char)va_arg( args, int ) ;
			OUTPUT( aKey, buf+1, width ) ;
		}
		break ;
	case 's':
		if ( left ) width = - width ;
		len = PrnString( buf, width, prec, va_arg( args, char *) ) ;
		OUTPUT( aKey, buf, len ) ;
		break ;
	case 'p':
		ptr = va_arg( args, void * ) ;
		flags.f.sign = FALSE ;
		flags.v.base = 16 ;
		flags.f.lower = TRUE ;
		flags.f.alt = TRUE ;
		len = PrnInteger( buf, width, prec, flags.value, ptr ) ;
		OUTPUT( aKey, buf, len ) ;
		break ;
	case 'r':
		ptr = va_arg( args, char * ) ;
		len = PrnFormat( aOutPut, aKey, ptr, va_arg(args, va_list) ) ;
		break ;
	case 'm':
		if ( 0 <= errno && errno <= sys_nerr ) {
			if ( left ) width = - width ;
			len = PrnString( buf, width, -1, sys_errlist[errno] ) ;
			OUTPUT( aKey, buf, len ) ;
		} else {
			len = PrnString( buf, 0, -1, unknown ) ;
			OUTPUT( aKey, buf, len ) ;

			flags.f.sign = TRUE ;
			flags.v.base = 10 ;
			flags.f.plus = TRUE ;
			len = PrnInteger( buf, 0, -1, flags.value, errno ) ; 
			OUTPUT( aKey, buf, len ) ;
		}
		break ;
	default :
		flags.f.type = type ;
		if ( extend ) {
			len = extend( buf, width, prec, flags.value, &args ) ;
			OUTPUT( aKey, buf, len ) ;
		}
	}

	} /* while( *f ) */

	return( n ) ;
}
