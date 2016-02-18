/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>

/* multithread system include */
#include "thread.h"
#include "thread/signal.h"
#include "thread/stack.h"
#include "thread/breakpoint.h"

#define	PROT_RDWR	(PROT_READ|PROT_WRITE)
#define	SIGNAL		SIGTRAP
#define	MAX		100

/*
 *	system calls
 */
#if	!defined(SVR4)
extern	int	mprotect( caddr_t addr, size_t len, int prot ) ;
extern	caddr_t	mmap( caddr_t addr, size_t len, int prot, int flags,
			int fildes, off_t off ) ;
#endif	/* SVR4 */

extern	etext ;

static	u_long	trap =
#if	SIGNAL == SIGTRAP
	0x91d02001 ;
#endif
#if	SIGNAL == SIGILL
	0x00000000 ;
#endif
#if	0
static	u_long	nop = 0x01000000 ;
#endif

typedef	enum	{
	Error, NotB, Bicc, Bicca, Ba, Baa, Ticc, Ta, Call, Jmpl
} BranchType ;

static	BrkPoint	brkTable ;
static	BrkPoint	brkTableBreak ;
static	BrkPoint	brkFreePoints ;

static	BranchType
isBranch( u_long aCode, u_long aAddr, u_long *aNext )
{
	BranchType	ret = NotB ;
	signed long	offset ;
	union	{
		u_long	code ;
		struct	{
			unsigned	op:	2 ;
			unsigned	a:	1 ;
			unsigned	cond:	4 ;
			unsigned	op2:	3 ;
			unsigned	disp22:	22 ;
		} b ;
		struct	{
			unsigned	op:	2 ;
			unsigned	rd:	5 ;
			unsigned	op3:	6 ;
			unsigned	rs1:	5 ;
			unsigned	i:	1 ;
			unsigned	simm13:	13 ;
		} j ;
	} i ;

	i.code = aCode ;
	*aNext = 0 ;
	if ( i.b.op == 0 ) {
		if ( i.b.op2 == 2 || i.b.op2 == 6 || i.b.op2 == 7 ) {
			if ( i.b.cond == 8 ) ret = i.b.a ? Baa : Ba ;
			else ret = i.b.a ? Bicca : Bicc ;
			offset = 4 * ((int)(i.b.disp22 << 10) >> 10) ;
			*aNext = aAddr + offset ;
		}
	} else if ( i.b.op == 1 ) {
		ret = Call ;
		offset = (int)(i.code << 2) ;
		*aNext = aAddr + offset ;
	} else if ( i.j.op == 2 && i.j.op3 == 0x38 ) {
		ret = Jmpl ;
	}
	return( ret ) ;
}

static	u_long
brkPatch( caddr_t base, u_long addr, u_long code )
{
	u_long	org ;
	u_long	*ptr = (u_long *)addr ;

#if	0
	if ( addr < (u_long)&etext ) {
		ThrError( "brkPatch(): addr=0x%x < &etext.", addr ) ;
		return( 0 ) ;
	}
#endif

	if ( mprotect( base, ThrPageSize, PROT_RDWR|PROT_EXEC ) ) {
		ThrError( "brkPatch mprotect(base=0x%x,RDWR): %m.", base ) ;
		return( 0 ) ;
	}
	org = *ptr ;
	*ptr = code ;
	if ( mprotect( base, ThrPageSize, PROT_READ|PROT_EXEC ) ) {
		ThrError( "brkPatch mprotect(base=0x%x,READ): %m.", base ) ;
	}
	return( org ) ;
}

BrkPoint
brkStep( u_long code, u_long pc, u_long npc )
{
	BrkPoint	bps = NULL ;
	BrkPoint	bp ;
	u_long		bpc ;
	BranchType	type ;

	type = isBranch( code, pc, &bpc ) ;
	switch( type ) {
	case	Bicca	:
		bp = BrkInsert( npc ) ; bp->next = bps ; bps = bp ;
		bp = BrkInsert( npc+4 ) ; bp->next = bps ; bps = bp ;
		break ;
	case	Baa	:
		bp = BrkInsert( npc ) ; bp->next = bps ; bps = bp ;
		if ( bpc != npc ) {
			bp = BrkInsert( bpc ) ; bp->next = bps ; bps = bp ;
		}
		break ;
	case	Jmpl	:
		bp = BrkInsert( npc ) ; bp->next = bps ; bps = bp ;
		break ;
	case	Call	:
		if ( (u_long)&etext < bpc ) {
			bp = BrkInsert( bpc ) ; bp->next = bps ; bps = bp ;
		}
		bp = BrkInsert( pc+8 ) ; bp->next = bps ; bps = bp ;
		break ;
	default:
		bp = BrkInsert( npc ) ; bp->next = bps ; bps = bp ;
	}

	return( bps ) ;
}

inline	BrkPoint
brkFind( int bid )
{
	BrkPoint	bp ;

	for ( bp = brkTable ; bp < brkTableBreak ; bp ++ ) {
		if ( bp->status != brkFree && bp->bid == bid ) return( bp ) ;
	}

	return( NULL ) ;
}

inline	BrkPoint
brkSearch( u_long pc )
{
	BrkPoint	bp ;

	for ( bp = brkTable ; bp < brkTableBreak ; bp ++ ) {
		if ( bp->status != brkFree && bp->pc == pc ) return( bp ) ;
	}

	return( NULL ) ;
}

BrkPoint
BrkInsert( u_long pc )
{
 static	int		last_bid = 0 ;
	BrkPoint	bp ;
	int		i ;
	int		mask ;

	mask = SigBlock() ;
	bp = brkFreePoints ;
	if( bp == NULL ) {
		ThrError( "BrkInsert(0x%x): Table overflow[Max:%d].",pc,MAX ) ;
		goto error ;
	}
	brkFreePoints = bp->next ;

	i = last_bid ;
	do {
		if ( i == MAX ) i = 0 ;
	} while ( brkFind( ++ i ) ) ;
	last_bid = i ;

	bp->status = brkEnable ;
	bp->bid = i ;
	bp->base = (caddr_t)(pc & ~(ThrPageSize-1)) ;
	bp->pc = pc ;
	bp->code = brkPatch( bp->base, bp->pc, trap ) ;

error:
	SigUnBlock( mask ) ;
	return( bp ) ;
}

void
BrkRemove( BrkPoint bp )
{
	int		mask ;

	mask = SigBlock() ;
	if ( bp->status == brkEnable ) brkPatch( bp->base, bp->pc, bp->code ) ;
	bp->status = brkFree ;
	bp->next = brkFreePoints ;
	brkFreePoints = bp ;
	SigUnBlock( mask ) ;
}

int
BrkClear( u_long pc )
{
	BrkPoint	bp ;
	int		mask ;
	int		result = 0 ;

	mask = SigBlock() ;
	for ( bp = brkTable ; bp < brkTableBreak ; bp ++ ) {
		if ( bp->status != brkFree && bp->pc == pc ) {
			BrkRemove( bp ) ;
			result ++ ;
		}
	}
	SigUnBlock( mask ) ;

	return( result ) ;
}

int
BrkEnable( int bid )
{
	BrkPoint	bp ;
	int		mask ;
	int		result ;

	mask = SigBlock() ;
	bp = brkFind( bid ) ;
	if ( bp ) {
		if ( bp->status == brkDisable ) {
			brkPatch( bp->base, bp->pc, trap ) ;
			bp->status = brkEnable ;
			result = 0 ;
		} else result = 1 ;
	} else result = -1 ;
	SigUnBlock( mask ) ;

	return( result ) ;
}

int
BrkDisable( int bid )
{
	BrkPoint	bp ;
	int		mask ;
	int		result ;

	mask = SigBlock() ;
	bp = brkFind( bid ) ;
	if ( bp ) {
		if ( bp->status == brkEnable ) {
			brkPatch( bp->base, bp->pc, bp->code ) ;
			bp->status = brkDisable ;
			result = 0 ;
		} else result = 1 ;
	} else result = -1 ;
	SigUnBlock( mask ) ;

	return( result ) ;
}

int
BrkDelete( int bid )
{
	BrkPoint	bp ;
	int		mask ;
	int		result ;

	mask = SigBlock() ;
	bp = brkFind( bid ) ;
	if ( bp ) {
		BrkRemove( bp ) ;
		result = 0 ;
	} else result = -1 ;
	SigUnBlock( mask ) ;

	return( result ) ;
}

int
BrkContinue( Thread t )
{
	int		result = -1 ;
	BrkPoint	bp ;
	BrkPoint	bps ;
	int		mask ;
	int		signo ;
	GREGS		*gregs ;
	u_long		pc ;
	u_long		npc ;
	frame_t		*sp ;
	frame_t		*fp ;

	mask = SigBlock() ;

	if ( ! SIGSTACK_FLAGS( t->signal_stack ) ) {
		ThrError( "BrkContinue(0x%x): Not stop at breakpoint.", t ) ;
		goto error ;
	}

#if	defined(SVR4)
	sp = (frame_t *)t->context[1] ;
	pc = (u_long)t->context[2] ;
#else	/* SVR4 */
	sp = (frame_t *)t->context[2] ;
	pc = (u_long)t->context[3] ;
#endif	/* SVR4 */

	fp = (frame_t *)sp->r_i6 ;
	signo = fp->r_i0 ;
	gregs = (GREGS *)fp->r_i2 ;
	pc = GREGS_PC(*gregs) ;
	npc = GREGS_NPC(*gregs) ;
	if ( signo != SIGNAL ) {
		ThrError( "BrkContinue(0x%x): Not stop at breakpoint.", t ) ;
		goto error ;
	}

	bp = brkSearch( pc ) ;
	if ( bp == NULL ) {
		ThrError( "BrkContinue(0x%x): "
				"Not found breakpoint pc=0x%x.", t, pc ) ;
		goto error ;
	}

	if ( t->suspend_count != 1 ) {
		ThrError( "BrkContinue(0x%x): Can't resume now.", t ) ;
		goto error ;
	}
	thrDequeue( &thrSuspendThreads, t ) ;
	t->suspend_count -- ;
	t->status = READY ;
	thrEnqueue( &thrReadyThreads, t ) ;

	BrkDisable( bp->bid ) ;
	bps = brkStep( bp->code, pc, npc ) ;
	ThrRunningThread->status = WAIT_SUSPEND ;
	thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
	thrEnqueue( &t->suspend_waiters, ThrRunningThread ) ;
	thrSwitch( t ) ;
	BrkEnable( bp->bid ) ;
	do {
		bp = bps ;
		bps = bp->next ;
		BrkRemove( bp ) ;
	} while ( bps ) ;

	thrDequeue( &thrSuspendThreads, t ) ;
	t->suspend_count -- ;
	t->status = READY ;
	thrEnqueue( &thrReadyThreads, t ) ;

	result = 0 ;

error:
	SigUnBlock( mask ) ;
	return( result ) ;
}

static	void
brkHandlerSIGNAL( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */
	ThrPrintf( "%s on thread %d [0x%x]\n", SigName(signo),
			ThrRunningThread->tid, ThrRunningThread ) ;
	ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
	if ( sigBlocking ) {
		ThrError( "brkHandlerSIGNAL(): Blockinig signal at pc=0x%x.",
				GREGS_PC(*gregs) ) ;
		return ;
	}

	ThrRunningThread->suspend_count ++ ;
	ThrRunningThread->status = SUSPEND ;
	thrDequeue( &thrReadyThreads, ThrRunningThread ) ;
	thrEnqueue( &thrSuspendThreads, ThrRunningThread ) ;
	if ( ThrRunningThread->suspend_waiters ) thrWakeupWaiters() ;

	thrSwitch( thrReadyThreads ) ;		/* Don't call thrReschedule() */

	/*
	 * MOST IMPORTANT
	 * Following some lines don't remove becase to must be saved these.
	 */
	ThrPrintf( "RESUME thread %d [0x%x] from %s\n",
		ThrRunningThread->tid, ThrRunningThread, SigName(signo) ) ;
	ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
}

int
BrkMap( int (func)(), void *arg )
{
	BrkPoint	bp ;
	int		count = 0 ;
	int		mask ;

	for ( bp = brkTable ; bp < brkTableBreak ; bp ++ ) {
		mask = SigBlock() ;
		if ( bp->status != brkFree ) {
			if ( func( bp, arg ) == 0 ) count ++ ;
		}
		SigUnBlock( mask ) ;
	}

	return( count ) ;
}

void
BrkInitialize()
{
	int	i ;

	brkTable = (BrkPoint)stkAlloc( sizeof(BrkPointRec) * MAX ) ;
	brkFreePoints = NULL ;
	for ( i = 0 ; i < MAX ; i ++ ) {
		brkTable[i].next = brkFreePoints ;
		brkTable[i].status = brkFree ;
		brkFreePoints = brkTable + i ;
	}
	brkTableBreak = brkTable + i ;
	SigAction( SIGNAL, brkHandlerSIGNAL ) ;
}

void
BrkShutdown()
{
	SigAction( SIGNAL, SIG_DFL ) ;
	stkFree( (caddr_t)brkTable, sizeof(BrkPointRec) * MAX ) ;
}
