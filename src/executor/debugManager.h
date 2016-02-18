/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(__OZ_DEBUG_MANAGER__H)
#define	__OZ_DEBUG_MANAGER__H

typedef	void*	DmLabor ;

typedef	int	(*FnPtr)( DmLabor aSelf, void *aData, int aSize ) ;
typedef	struct	{
	int	No ;
	FnPtr	ptr ;
} FnEntry ;
typedef	struct	FnTableStr	FnTable ;
struct	FnTableStr	{
	int	max ;
	FnEntry	*entry ;
} FnTableStr ;

extern	FnTable	DmWorkTable ;

extern	void*	DmWork( DmLabor aSelf, int aSize ) ;
extern	int	DmOnExitAdd( DmLabor aSelf, int aRequest, void *aData, int aSize ) ;
extern	int	DmOnExitDel( DmLabor aSelf, int aRequest, void *aData, int aSize ) ;
extern	int	DmBusy( DmLabor aSelf ) ;
extern	void	DmReady( DmLabor aSelf ) ;

/* for IPA '94 Oct. Demo */
extern	int	DmGetServAddr( DmLabor aSelf, long long aOid ) ;
extern	int	DmGetInetPort( DmLabor aSelf ) ;

extern	int	DmGetClass( OID aCid ) ;
#endif	/* __OZ_DEBUG_MANAGER__H */
