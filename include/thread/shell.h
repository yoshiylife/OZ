/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_SHELL_H_
#define	_SHELL_H_

typedef	int	(*ShCmd)( char *name, int argc, char *argv[], int, int ) ;

extern	int	ShInit() ;
extern	int	OzShAppend( char *aClass, char *aName,
			ShCmd aCommand, char *aArgUsage, char *aComment ) ;
extern	ShCmd	OzShRemove( char *aClass, char *aName ) ;
extern	int	OzShAlias( char *aClass, char *aName, char *aAlias ) ;
extern	int	OzShell( char *aCmdLine, int *status ) ;

#endif	!_SHELL_H_
