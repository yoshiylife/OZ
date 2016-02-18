/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(__OZ_DEBUG_CHANNEL__H)
#define	__OZ_DEBUG_CHANNEL__H

#define	DC_BUSY	1
#define	BUFF_INIT	(1024)
#define	BUFF_FREE	(-1)


typedef	void*	DC ;

typedef	struct	OzDcHeadStr*	OzDcHead ;
typedef	struct	OzDcHeadStr	OzDcHeadRec ;
struct	OzDcHeadStr	{
	union	{
		int	status ;
		int	request ;
	} type ;
	int	size ;
} ;
typedef	struct	OzDcDataStr*	OzDcData ;
typedef	struct	OzDcDataStr	OzDcDataRec ;
struct	OzDcDataStr	{
	OzDcHeadRec	head ;
	char		addr[1] ;
} ;
typedef	struct	OzDcBuffStr*	OzDcBuff ;
typedef	struct	OzDcBuffStr	OzDcBuffRec ;
struct	OzDcBuffStr	{
	int		size ;
	OzDcData	data ;
} ;


extern	int	DcInit( int aN ) ;
extern	DC	OzDcOpen( long long aID ) ;
extern	DC	OzDcAccept() ;
extern	void	OzDcClose( DC aDC ) ;
extern	int	OzDcSend( DC aDC, void *aData, int aNbyte ) ;
extern	int	OzDcRecv( DC aDC, void *aData, int aNbyte ) ;
extern	int	OzDcBegin( DC aDC ) ;
extern	int	OzDcEnd( DC aDC ) ;
extern	void*	OzDcSetBuff( OzDcBuff aBuff, int aSize ) ;

/* for IPA Oct. '94 Demo */
#define	DC_SIZE	32
#define	DC_UNIX 1
#define	DC_INET 2
extern	int	OzDcType( DC aDC, void *aBuff, int *aSize ) ;
extern	int	OzDcInet( void *aBuff, int *aSize ) ;
#endif	/* __OZ_DEBUG_CHANNEL__H */
