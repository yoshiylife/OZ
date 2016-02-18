/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef	_THR_SIGNAL_H_
#define	_THR_SIGNAL_H_
/* unix system include */
#include <sys/types.h>
#if	defined(SVR4)
#include <ucontext.h>
#endif	/* SVR4 */
#include <signal.h>
/* multithread system include */
#include "thread/testandset.h"

/*
 * Don't include any other module
 */


/* Don't change file mode to non-block */
#define	LOGGING	2


/* if you debug signal, undefine following symbol */
#define	INLINE	inline extern


#if	defined(SVR4)
#define	sigispending(s)		(((s)->__sigbits[0]) | ((s)->__sigbits[1]))
#define	SIGSTACK( ss, oss )	sigaltstack( (ss), (oss) )
#define	SIGSTACK_FLAGS( ss )	(ss).ss_flags
typedef	struct regs			GREGS ;
#define	GREGS_PC(xxx)			((xxx).r_pc)
#define	GREGS_SP(xxx)			((xxx).r_sp)
#define	GREGS_NPC(xxx)			((xxx).r_npc)
#else	/* SVR4 */
#define	sigispending(s)		((s)[0])
#define	SIGSTACK( ss, oss )	sigstack( (ss), (oss) )
#define	SIGSTACK_FLAGS( ss )	(ss).ss_onstack
typedef	struct sigcontext		GREGS ;
#define	GREGS_PC(xxx)			((xxx).sc_pc)
#define	GREGS_SP(xxx)			((xxx).sc_sp)
#define	GREGS_NPC(xxx)			((xxx).sc_npc)
extern	int	sigstack( struct sigstack *nss, struct sigstack *oss ) ;
extern	int	mprotect( caddr_t addr, size_t len, int prot ) ;
#endif	/* SVR4 */


/*
 *	SPARC stack frame image
 */
typedef	struct	frame {
	/* local */
	int r_l0; int r_l1; int r_l2; int r_l3;
	int r_l4; int r_l5; int r_l6; int r_l7;

	/* in */
	int r_i0; int r_i1; int r_i2; int r_i3;
	int r_i4; int r_i5; int r_i6; int r_i7;

	/* out */
	int r_o0; int r_o1; int r_o2; int r_o3;
	int r_o4; int r_o5; int r_o6; int r_o7;
} frame_t ;


/*
 *	Public functions
 */
INLINE	int	SigBlock() ;
INLINE	void	SigUnBlock( int mask ) ;
extern	void	SigDisable() ;
extern	void	SigEnable() ;
extern	char	*SigName( int aSigNo ) ;
extern	char	*SigDetail( int aSigNo, int aCode ) ;
extern	void	SigPrintf( const char *aFormat, ... ) ;
extern	void	SigAbort( const char *aFormat, ... ) ;
extern	void	SigAction( int aSigNo, void (*aFunc)() ) ;
extern	void	SigUalarm( unsigned vticks, unsigned iticks ) ;
extern	void	SigPause() ;
extern	void	SigInitialize() ;
extern	void	SigShutdown() ;


/*
 *	Global variables
 */
extern	u_int	SigClockTicks ;
extern	u_int	SigClockTimes ;


/*
 *	No global variables, but need to inline statement
 */
extern	char		sigBlocking ;
extern	sigset_t	sigPending ;


/*
 *	No public functions, but need to inline statement
 */
extern	void		sigDispatch() ;


/*
 *	INLINE functions
 */
#ifdef	INLINE
INLINE	int
SigBlock()
{
	return(  TestAndSet( &sigBlocking ) ) ;
}

INLINE	void
SigUnBlock( int aMask )
{
	if ( aMask ) return ;
	sigBlocking = 0 ;
	if ( sigispending( &sigPending ) ) sigDispatch() ;
}
#else	!INLINE
extern	void	SigUnBlock( int ) ;
extern	int	SigBlock() ;
#endif	INLINE

#endif	!_THR_SIGNAL_H_
