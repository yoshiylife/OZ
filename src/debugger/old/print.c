/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include "id.h"
#include "print.h"

#define	HEX_DATAN	16
#define	HEX_ADDRF	"0x%08x: "
#define	HEX_ADDRW	12
#define	HEX_DATAF	"%02x "
#define	HEX_DATAW	3
#define	HEX_SPACE	4
#define	FF		0x0ffu
#define	LBUFSIZ	1024

extern	void	Errorf( char *aFormat, ... ) ;

int	LineTclMode = 0 ;

int
sprintfValue( char *aBuffer, const char *aFormat, void *aData )
{
	int	ret = 0 ;
unsigned char	uc ;

	switch( *aFormat ) {
	case	'*':
	case	'O':
	case	'o':
		sprintf( aBuffer, "*0x%08x", *((unsigned int *)aData) ) ;
		break ;
	case	'@':
		sprintf( aBuffer, "@%d", *((int *)aData) ) ;
		break ;
	case	'f':
		sprintf( aBuffer, "%f", *((float *)aData ) ) ;
		break ;
	case	'd':
		sprintf( aBuffer, "%g", *((double *)aData ) ) ;
	case	'z':
		sprintf( aBuffer, "0x%08x.%d", *((unsigned int *)aData + 1), *((char *)aData) ) ;
		break ;
	case	'G':
		sprintf( aBuffer, "%s", IDtoStr(*((long long *)aData),NULL) ) ;
		break ;
	case	'L':
		sprintf( aBuffer, "0x%s", IDtoStr(*((long long *)aData),NULL) ) ;
		break ;
	case	'R':
		sprintf( aBuffer, "*0x%08x", (unsigned int *)aData ) ;
		break ;
	case	'l':
		Ltoa( *((long long *)aData), aBuffer ) ;
		break ;
	case	'i':
		sprintf( aBuffer, "%d", *((int *)aData) ) ;
		break ;
	case	'I':
		sprintf( aBuffer, "0x%08x", *((unsigned int *)aData) ) ;
		break ;
	case	's':
		sprintf( aBuffer, "%d", *((short *)aData) ) ;
		break ;
	case	'S':
		sprintf( aBuffer, "0x%04x", *((unsigned short *)aData) ) ;
		break ;
	case	'c':
		sprintf( aBuffer, "%d", *((char *)aData) ) ;
		break ;
	case	'C':
		uc = *((unsigned char *)aData ) ;
		if ( isprint( uc ) ) sprintf( aBuffer, "'%c'", uc ) ;
		else sprintf( aBuffer, "0x%02x", uc ) ;
		break ;
	default:
		Errorf( "Can't value type '%s' !!\n", aFormat ) ;
		goto error ;
	}

	ret = strlen( aBuffer ) ;

error:
	return( ret ) ;
}

static	char	LineBuffer[LBUFSIZ+3] ;
static	int	LineCurrPos = 0 ;

void
LinePutChar( int aChar )
{
	if ( LineCurrPos < LBUFSIZ ) LineBuffer[LineCurrPos++] = aChar ;
	if ( aChar == '\n' ) {
		if ( LineCurrPos < LBUFSIZ ) LineCurrPos -- ;
		if ( LineTclMode ) LineBuffer[LineCurrPos++] = 0x7d ;
		LineBuffer[LineCurrPos++] = '\n' ;
		LineBuffer[LineCurrPos] = '\0' ;
		fputs( LineBuffer, stdout ) ;
		fflush( stdout ) ;
		LineCurrPos = 0 ;
	}
	return ;
}

void
LineFlush()
{
	if ( LineCurrPos != 0 ) LinePutChar( '\n' ) ;
}

void
LinePutStr( int aIndent, char *aStr )
{
	if ( aIndent >= 0 && LineCurrPos == 0 ) {
		if ( LineTclMode ) LineBuffer[LineCurrPos++] = 0x7b ;
		else while( aIndent -- ) LineBuffer[LineCurrPos++] = ' ' ;
	}

	while( *aStr ) {
		if ( *aStr == '\n' ) {
			LinePutChar( *aStr ) ;
			break ;
		} else if ( LineCurrPos < LBUFSIZ ) LineBuffer[LineCurrPos++] = *aStr ;
		aStr ++ ;
	}
	if ( *aStr == '\n' && (* ++aStr != '\0') ) LinePutStr( aIndent, aStr ) ;

	return ;
}

void
LinePrintf( int aIndent, char *aFormat, ... )
{
	char	buf[LBUFSIZ] ;
	va_list	args ;

	va_start( args, aFormat ) ;
	vsprintf( buf, aFormat, args ) ;
	va_end( args ) ;

	LinePutStr( aIndent, buf ) ;

	return ;
}

void
LinePrompt( char *aFormat, ... )
{
	char	buf[LBUFSIZ] ;
	va_list	args ;

	va_start( args, aFormat ) ;
	vsprintf( buf, aFormat, args ) ;
	va_end( args ) ;

	if ( LineTclMode ) {
		fputc( '!', stdout ) ;
		fputs( buf, stdout ) ;
		fputc( '\n', stdout ) ;
		fflush( stdout ) ;
	} else fputs( buf, stderr ) ;

	return ;
}

char*
LineGets( char *aBuffer, int aSize )
{
	int	len ;
	char	*buff ;

	buff = fgets( aBuffer, aSize, stdin ) ;
	if ( buff ) {
		len = strlen(buff) ;
		if ( buff[len-1] == '\n' ) buff[len-1] = '\0' ;
	}

	return( buff ) ;
}

void
CharHexDump( void *aAddr, void *aData, unsigned aSize, int aIndent )
{
	char		*addr = aAddr ;
	char		*ptr = aData ;
	char		*dspA, *dspB ;
	int		nbyte ;
	unsigned	termn ;
	char		lbuf[HEX_ADDRW + HEX_DATAN * ( HEX_DATAW + 1 ) + HEX_SPACE + 1] ;
  
	LineFlush() ;
	nbyte = 0 ;
	while( nbyte < aSize ) {
		(void)memset( lbuf, ' ', sizeof(lbuf)-1 ) ; lbuf[sizeof(lbuf)-1] = '\0' ;
		(void)sprintf( lbuf, HEX_ADDRF, addr + nbyte ) ;
		dspA = lbuf + HEX_ADDRW ;
		dspB = dspA + HEX_DATAN * HEX_DATAW + HEX_SPACE ;
		for ( termn = 0 ; termn < HEX_DATAN && nbyte < aSize ; termn ++, nbyte ++ ) {
			(void)sprintf( dspA, HEX_DATAF, *ptr & FF ) ;
			dspA += strlen( dspA ) ;
			*dspA = ' ' ;
			*dspB = isprint( *ptr ) ? *ptr : '.' ;
			dspB ++ ;
			ptr ++ ;
		}
		LinePutStr( aIndent, lbuf ) ;
		LineFlush() ;
	}
}

void
HexDump( int aWidth, void *aAddr, void *aData, unsigned aSize, int aIndent )
{

	if ( aWidth % 2 == 0 && aWidth <= 8 ) {
		int	i ;
		char	*addr = aAddr ;
		char	*data = aData ;
		int	count = aSize / aWidth ;
		int	nitem = 16 / aWidth ;
		for ( i = 0 ; i < count ; i ++, addr += aWidth, data += aWidth ) {
			if ( i % nitem == 0 ) {
				LineFlush() ;
				LinePrintf( aIndent, "0x%08x: ", addr ) ;
			}
			if ( aWidth == 8 )
				LinePrintf( aIndent, "0x%s", IDtoStr( *( (long long *)data ), NULL ) ) ;
			else if ( aWidth == 4 )
				LinePrintf( aIndent, "0x%08x", *( (int *)data ) ) ;
			else if ( aWidth == 2 )
				LinePrintf( aIndent, "0x%04x", *( (short *)data ) ) ;
			if ( i % nitem == (nitem -1) ) LineFlush() ;
			else LinePutChar( ' ' ) ;
		}
		if ( i % nitem ) LineFlush() ;
	} else CharHexDump( aAddr, aData, aSize, aIndent ) ;
}
