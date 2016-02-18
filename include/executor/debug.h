/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_EXEC_DEBUG_H_)
#define	_OZ_EXEC_DEBUG_H_

#include	"executor/executor.h"

typedef	struct	OZ_DmClassQueueEltStr	*OZ_DmClassQueueElt ;
typedef	struct	OZ_DmClassRequestRec	{
	ClassID			cid ;
	int			status ;
	OZ_DmClassQueueElt	queue_elt ;
} OZ_DmClassRequestRec, *OZ_DmClassRequest ;

extern	OZ_DmClassRequest OzDmClassRequest() ;
extern	void OzDmClassRequestReply( int aStatus, OZ_DmClassRequest aRequest ) ;

#endif	/* _OZ_EXEC_DEBUG_H_ */
