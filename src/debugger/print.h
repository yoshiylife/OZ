/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_DEBUGGER_PRINT_H)
#define	_OZ_DEBUGGER_PRINT_H

extern	int	LineTclMode ;

extern	int	sprintfValue( char *aBuffer, const char *aFormat, void *aData ) ;

extern	void	LineFlush() ;
extern	void	LinePrintf( int aIndent, char *aFormat, ... ) ;
extern	void	LinePutStr( int aIndent, char *aStr ) ;
extern	void	LinePutChar( int aChar ) ;
extern	void	LinePrompt( char *aFormat, ... ) ;
extern	char*	LineGets( char *aBuffer, int aSize ) ;

extern	void
HexDump( int aWidth, void *aAddr, void *aData, unsigned aSize, int aIndent ) ;

extern	void
CharHexDump( void *aAddr, void *aData, unsigned aSize, int aIndent ) ;

#endif	_OZ_DEBUGGER_PRINT_H
