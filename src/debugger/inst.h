/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_DEBUGGER_INST_H)
#define	_OZ_DEBUGGER_INST_H

#include	"executor/executor.h"

typedef	struct	InstNameStr*	InstName ;
typedef	struct	InstNameStr	InstNameRec ;
struct	InstNameStr	{
	char	*name ;
	int	pos ;
	int	size ;
	char	*type ;
} ;

#define	SIZEOF_INSTINFO(xxx)	(sizeof(InstInfoRec) + sizeof(InstNameRec) * (xxx-1))
typedef	struct	InstInfoStr	InstInfoRec ;
typedef	struct	InstInfoStr*	InstInfo ;
struct	InstInfoStr	{
	int		total ;
	int		protected ;
	int		private ;
	InstNameRec	inst[1] ;
} ;

extern	InstInfo	InstInfoGet( int aClass, OZ_ClassID aRunTimeClassID ) ;

#endif	_OZ_DEBUGGER_INST_H
