/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _DYLOAD_H_
#define _DYLOAD_H_

#include "cl.h"

#define DL_OK		0
#define DL_NG		1

typedef	struct DlInfoStr*	DlInfo ;
typedef	struct DlInfoStr	DlInfoRec ;
struct	DlInfoStr {
	const	char	*fname ;
		int	sline ;
	const	char	*sname ;
		void	*saddr ;
		void	*snext ;
} ;

extern	int	DlMapSymbolTable( int (func)(), void *arg ) ;
extern	int	DlInit() ;
extern	void	DlUnload(ClassCode code) ;
extern	int	DlDynamicLoad( ClassCode code, char *file ) ;
extern	int	DlRelocate( ClassCode code ) ;
extern	int	DlSymbolLoad( ClassCode code ) ;
extern	int	DlIsCore( caddr_t addr ) ;
extern	OZ_ClassID	DlIsClass( caddr_t addr ) ;
extern	void	*DlOpen( OZ_ClassID aCID ) ;
extern	int	DlClose( void *aHandle ) ;
extern	int	DlAddr( void *aHandle, caddr_t addr, DlInfo info ) ;
extern	caddr_t	DlSrc( void *aHandle, const char *aBaseName, int aLine ) ;
extern	caddr_t	DlSym( void *aHandle, const char *name ) ;
#if	0
extern	int	DlGet( void *handle, DlInfo *info ) ;
extern	int	DlType( void *handle, const char *type, DlInfo *info ) ;
#endif

#endif  _DYLOAD_H_
