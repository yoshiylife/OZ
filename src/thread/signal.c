/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	Multithread system: UNIX signal handling module
 *
 */
/* unix system include */
#include <unistd.h>
#include <stdarg.h>
#include <sys/time.h>
/* multithread system include */
#include "thread/print.h"
#include "thread/signal.h"

/*
 * Don't include any other module
 */


#undef	DEBUG


#if	defined(SVR4)
#define	SIGBLOCK( set, oset )	sigprocmask( SIG_BLOCK, &(set), &(oset) )
#define	SIGSETMASK( set )	sigprocmask( SIG_SETMASK, &(set), NULL )
typedef	sigset_t		mask_t ;
#else	/* SVR4 */
#define	SIGBLOCK( set, oset )	( (oset) = sigblock( (set) ) )
#define	SIGSETMASK( set )	sigsetmask( (set) )
typedef	int			mask_t ;
extern	int	sigsetmask( int mask ) ;
extern	int	sigblock( int mask ) ;
#endif	/* SVR4 */


/*
 *	System calls
 */
#if	defined(SVR4)
typedef	struct	sigaction		act_t ;
#define	SIGACTION(x_sig,x_act,x_oact)	sigaction( (x_sig), (x_act), (x_oact) )
#define	ACTION_HANDLER(xxx)		((xxx).sa_sigaction)
#define	ACTION_MASK(xxx)		((xxx).sa_mask)
#define	ACTION_FLAGS(xxx)		((xxx).sa_flags)
#define	ACTION_FLAGS_DEFAULT		(SA_ONSTACK | SA_SIGINFO | SA_RESTART)
#define	SIGHANDLER		void (*)(int,siginfo_t *,void *)
#else	/* SVR4 */
extern	int	ualarm( unsigned, unsigned ) ;
extern	int	sigblock( int ) ;
extern	int	sigsetmask( int ) ;
extern	int	sigvec( int, struct sigvec *, struct sigvec * ) ;
extern	int	sigpause( int ) ;
typedef	struct	sigvec			act_t ;
#define	SIGACTION(x_sig,x_vec,x_ovec)	sigvec( (x_sig), (x_vec), (x_ovec) )
#define	ACTION_HANDLER(xxx)		((xxx).sv_handler)
#define	ACTION_MASK(xxx)		((xxx).sv_mask)
#define	ACTION_FLAGS(xxx)		((xxx).sv_flags)
#define	ACTION_FLAGS_DEFAULT		(SV_ONSTACK)
#define	SIGHANDLER		void (*)(int,int,struct sigcontext *,char *)
#endif	/* SVR4 */


/*
 *	Global variables
 */
u_int	SigClockTicks ;		/* clock ticks per second */
u_int	SigClockTimes ;		/* count up with tick */


/*
 *	Local variables
 */
static	mask_t	sigFillSet ;		/* use only read */
static	mask_t	sigEmptySet ;		/* use only read */
static	struct	{
	void	(*handler)() ;
	int	deferrable ;
} sigTable[NSIG+1] ;			/* signal dispatch setting table */
					/* first element not use */
/* Don't 'static' becase of inline */
char		sigBlocking ;		/* !zero: blocking signal now */
sigset_t	sigPending ;		/* Pending signal bits */


/*
 *	Debug flags (for runtime)
 */
#if	defined(DEBUG)
static	int	sigPendingTrace = 0 ;
static	int	sigBlockingTrace = 0 ;
#endif

static	void
sigError( const char *aFormat, ... )
{
	va_list	args ;
	va_start( args, aFormat ) ;
	SigPrintf( "*ERROR* %r\n", aFormat, args ) ;
	va_end( args ) ;
}

static	void
sigPanic( const char *aFormat, ... )
{
	va_list	args ;

	va_start( args, aFormat ) ;
	SigAbort( "*PANIC* %r\n", aFormat, args ) ;
	/* NOT REACHED */
	va_end( args ) ;
}

/*
 *	Deferred signal dispatch
 *	(Don't 'static' because of inline)
 */
void
sigDispatch()
{
	int	sig ;
	mask_t	oset ;
	void	(*handler)() ;

	SIGBLOCK( sigFillSet, oset ) ;
	for ( sig = 1 ; sig < NSIG ; sig ++ ) {	/* first element not use */
		if ( sigismember( &sigPending, sig ) ) {
#if	defined(DEBUG)
if ( sigPendingTrace ) SigPrintf( "Dispatch: %s\n", SigName(sig) ) ;
#endif
			sigdelset( &sigPending, sig ) ;
			handler = sigTable[sig].handler ;
			if ( handler ) handler( sig, 0, 0, 0 ) ;
			else {
				sigError( "sigDispatch(): "
					"Not found %s handler.", SigName(sig) );
			}
		}
	}
	SIGSETMASK( oset ) ;
}

/*
 *	UNIX signal handling and deferring
 */
static	void
sigHandler( int sig,
#if	defined(SVR4)
		siginfo_t *sip, ucontext_t *uap
#else	/* SVR4 */
		int code, struct sigcontext *gregs, void *addr
#endif	/* SVR4 */
)
{
	void	(*handler)() ;
	u_int	work ;
#if	defined(SVR4)
	int	code ;
	void	*addr ;
	struct	regs	*gregs = (struct regs *)&(uap->uc_mcontext.gregs) ;
#endif	/* SVR4 */
	u_int	pc = GREGS_PC( *gregs ) ;
	u_int	sp = GREGS_SP( *gregs ) ;
#if	defined(SVR4)
	if ( sip ) {
		code = sip->si_code ;
		addr = sip->si_addr ;
	} else {
		code = 0 ;
		addr = NULL ;
	}
#endif	/* SVR4 */

	/* Count up clock tick */
	if ( sig == SIGALRM ) {
		work = SigClockTimes ;		/* IMPORTANT */
		work ++ ;			/* IMPORTANT */
		SigClockTimes = work ;		/* IMPORTANT */
	}

	if ( sigBlocking ) {
#if	defined(DEBUG)
if ( sigBlockingTrace ) SigPrintf( "Blocking: %s\n", SigName(sig) ) ;
#endif
#if	defined(DEBUG)
		if ( sigismember( &sigPending, sig ) ) {
			SigPrintf( "%s is already pending, in critical section "
				"at PC:0x%x SP:0x%x\n", SigName(sig), pc, sp ) ;
		}
#endif
		sigaddset( &sigPending, sig ) ;
		if ( ! sigTable[sig].deferrable ) {
			sigPanic( "%s(%s) is raised in critical section "
				"at pc=0x%x sp=0x%x addr=0x%x.", SigName(sig),
				SigDetail(sig,code), pc, sp, addr ) ;
		}
	} else {
		handler = sigTable[sig].handler ;
		if ( handler ) handler( sig, code, gregs, addr ) ;
		else {
			sigPanic( "sigHandler(): "
				"Not found %s handler.", SigName(sig) ) ;
		}
	}
}

void
SigDisable()
{
	SIGSETMASK( sigFillSet ) ;
}

void
SigEnable()
{
	SIGSETMASK( sigEmptySet ) ;
}

char*
SigName( int aSigNo )
{
#define	CASE(xXvAlUe,xXnAmE)	case xXvAlUe : xXnAmE = #xXvAlUe ; break 
	char	*name ;

	switch( aSigNo ) {
	CASE( SIGHUP, name ) ;	CASE( SIGINT, name ) ;	CASE( SIGQUIT, name ) ;
	CASE( SIGILL, name ) ;	CASE( SIGTRAP, name ) ;	CASE( SIGABRT, name ) ;
	CASE( SIGEMT, name ) ;	CASE( SIGFPE, name ) ;	CASE( SIGKILL, name ) ;
	CASE( SIGBUS, name ) ;	CASE( SIGSEGV, name ) ;	CASE( SIGSYS, name ) ;
	CASE( SIGPIPE, name ) ;	CASE( SIGALRM, name ) ;	CASE( SIGTERM, name ) ;
	CASE( SIGURG, name ) ;	CASE( SIGSTOP, name ) ;	CASE( SIGTSTP, name ) ;
	CASE( SIGCONT, name ) ;	CASE( SIGCHLD, name ) ;	CASE( SIGTTIN, name ) ;
	CASE( SIGTTOU, name ) ;	CASE( SIGPOLL, name ) ;	CASE( SIGXCPU, name ) ;
	CASE( SIGXFSZ, name ) ;	CASE( SIGVTALRM, name ) ;
	CASE( SIGPROF, name ) ;	CASE( SIGWINCH, name ) ;
	CASE( SIGUSR1, name ) ;	CASE( SIGUSR2, name ) ;
#if	defined(SIGLOST)
	CASE( SIGLOST,		name ) ;
#endif
#if	defined(SIGPWR)
	CASE( SIGPWR,		name ) ;
#endif
#if	defined(SIGWAITING)
	CASE( SIGWAITING,	name ) ;
#endif
#if	defined(SIGLWP)
	CASE( SIGLWP,		name ) ;
#endif
	default:
		name = "UNKNOWN" ;
	}

	return( name ) ;
}

char*
SigDetail( int aSigNo, int aCode )
{
	char	*detail = NULL ;

	switch ( aSigNo ) {
	case SIGILL:
		switch ( aCode ) {
#if	defined(SVR4)
		case ILL_ILLOPC:
			detail = "illegal opcode" ; break ;
		case ILL_ILLOPN:
			detail = "illegal operand" ; break ;
		case ILL_ILLADR:
			detail = "illegal addressing mode" ; break ;
		case ILL_ILLTRP:
			detail = "illegal trap" ; break ;
		case ILL_PRVOPC:
			detail = "privileged opcode" ; break ;
		case ILL_PRVREG:
			detail = "privileged register" ; break ;
		case ILL_COPROC:
			detail = "co-processor error" ; break ;
		case ILL_BADSTK:
			detail = "internal stack error" ; break ;
#else	SVR4
		case ILL_ILLINSTR_FAULT:
			detail = "Illegal instruction" ; break ;
		case ILL_PRIVINSTR_FAULT:
			detail = "Privileged instruction violation" ; break ;
		case ILL_STACK:
			detail = "Bad stack" ; break ;
#endif	SVR4
		default: /* detail = NULL */
		}
		break ;
	case SIGFPE:
		switch ( aCode ) {
#if	defined(SVR4)
		case FPE_INTDIV:
			detail = "integer divide by zero" ; break ;
		case FPE_INTOVF:
			detail = "integer overflow" ; break ;
		case FPE_FLTDIV:
			detail = "floating point divide by zero" ; break ;
		case FPE_FLTOVF:
			detail = "floating point overflow" ; break ;
		case FPE_FLTUND:
			detail = "floating point underflow" ; break ;
		case FPE_FLTRES:
			detail = "floating point inexact result" ; break ;
		case FPE_FLTINV:
			detail = "invalid floating point operation" ; break ;
		case FPE_FLTSUB:
			detail = "subscript out of range" ; break ;
#else	SVR4
		case FPE_INTDIV_TRAP:
			detail = "Integer division by zero" ; break ;
		case FPE_FLTINEX_TRAP:
			detail = "IEEE floation pt inexact" ; break ;
		case FPE_FLTDIV_TRAP:
			detail = "IEEE floation pt division by zero" ; break ;
		case FPE_FLTUND_TRAP:
			detail = "IEEE floation pt underflow" ; break; 
		case FPE_FLTOPERR_TRAP:
			detail = "IEEE floation pt operand error" ; break ;
		case FPE_FLTOVF_TRAP:
			detail = "IEEE floation pt overflow" ; break ;
		case FPE_INTOVF_TRAP:
			detail = "Integer overflow" ; break ;
#endif	SVR4
		default: /* detail = NULL */
		}
		break ;
	case SIGBUS:
		switch ( aCode ) {
#if	defined(SVR4)
		case BUS_ADRALN:
			detail = "invalid address alignment" ; break ;
		case BUS_ADRERR:
			detail = "non-existent physical address" ; break ;
		case BUS_OBJERR:
			detail = "object specific hardware error" ; break ;
#else	SVR4
		case BUS_HWERR:
			detail = "Hardware bus error" ; break ;
		case BUS_ALIGN:
			detail = "Address alignment error" ; break ;
#endif	SVR4
		default: /* detail = NULL */
		}
		break ;
	case SIGSEGV:
#if	defined(SVR4)
		switch ( aCode ) {
		case SEGV_MAPERR:
			detail = "address not mapped to object" ; break ;
		case SEGV_ACCERR:
			detail = "invalid permissions for mapped object";break ;
		default: /* detail = NULL */
		}
#else	SVR4
		switch ( aCode ) {
		case SEGV_NOMAP:
			detail = "No mapping fault" ; break ;
		case SEGV_PROT:
			detail = "Protection fault" ; break ;
		default: /* detail = NULL */
		}
#endif	SVR4
		break ;
#if	defined(SVR4)
	case SIGTRAP:
		switch ( aCode ) {
		case TRAP_BRKPT:
			detail = "process breakpoint" ; break ;
		case TRAP_TRACE:
			detail = "process trace trap" ; break ;
		default: /* detail = NULL */
		}
		break ;
#else	SVR4
	case SIGEMT:
		switch ( aCode ) {
		case EMT_TAG:
			detail = "Tag overflow" ; break ;
		default: /* detail = NULL */
		}
		break ;
#endif	SVR4
	default:
		detail = "" ;
	}
	if ( detail == NULL ) detail = aCode ? "Unknown code" : "" ;

	return( detail ) ;
}

void
SigPrintf( const char *aFormat, ... )
{
	va_list	args ;
	mask_t	oset ;

	SIGBLOCK( sigFillSet, oset ) ;
	va_start( args, aFormat ) ;
	PrnFormat( (PRNOUT *)write, (void *)LOGGING, aFormat, args ) ;
	va_end( args ) ;
	SIGSETMASK( oset ) ;
}

/*
 *	Abort multithread system
 *
 */
void
SigAbort( const char *aFormat, ... )
{
 static	char	aborted[] = "\nsystem aborted.\n" ;
	act_t	action ;
	va_list	args ;
	int	i ;

	SIGSETMASK( sigFillSet ) ;

	/*
	 * disable UNIX signal handling completly
	 */
	SigUalarm( 0, 0 ) ;
	sigfillset( &ACTION_MASK(action) ) ;
	for ( i = 1 ; i <= NSIG ; i ++ ) {
		if ( i != SIGABRT && sigTable[i].handler ) {
			ACTION_HANDLER(action) = (SIGHANDLER)SIG_IGN ;
			SIGACTION( i, &action, NULL ) ;
		}
	}

	/*
	 * write full message to LOGGING only
	 */
	va_start( args, aFormat ) ;
	PrnFormat( (PRNOUT *)write, (void *)LOGGING, aFormat, args ) ;
	va_end( args ) ;
	write( LOGGING, aborted, sizeof(aborted)-1 ) ;
	abort() ;
	exit( 1 ) ;
}

/*
 *	Change signal action
 */
void
SigAction( int sig, void (*handler)(int) )
{
	act_t	action ;
	int	mask ;

	mask = SigBlock() ;

	if ( handler == SIG_IGN || handler == SIG_DFL ) {
		sigTable[sig].handler = NULL ;
		ACTION_HANDLER(action) = (SIGHANDLER)handler ;
		sigfillset( &ACTION_MASK(action) ) ;
	} else {
		sigTable[sig].handler = handler ;
		ACTION_HANDLER(action) = (SIGHANDLER)sigHandler ;
		sigfillset( &ACTION_MASK(action) ) ;
		ACTION_FLAGS(action) = ACTION_FLAGS_DEFAULT ;
	}

	if ( SIGACTION( sig, &action, NULL ) ) {
		sigError( "SigAction(%s) Not set handler: %m.", SigName(sig) );
	}

	SigUnBlock( mask ) ;
}

/*
 *	Set interval time
 */
void
SigUalarm( unsigned vticks, unsigned iticks )
{
	static	unsigned	unit = 1000000 ;
#if	defined(SVR4)
	struct	itimerval	val ;
	val.it_value.tv_sec =  0 ;
	val.it_value.tv_usec = vticks ? unit/vticks : 0 ;
	val.it_interval.tv_sec = 0 ;
	val.it_interval.tv_usec = iticks ? unit/iticks : 0 ;
	if ( setitimer( ITIMER_REAL, &val, NULL ) ) {
		sigError( "SigUalarm() Not set itimer: %m." ) ;
	}
#else	/* SVR4 */
	ualarm( vticks ? unit/vticks : 0 , iticks ? unit/iticks : 0 ) ;
#endif	/* SVR4 */
	SigClockTicks = iticks ;
}

void
SigPause()
{
#if	defined(SVR4)
	pause() ;
#else	/* SVR4 */
	sigpause( 0 ) ;
#endif	/* SVR4 */
}

/*
 *	Initialize unix signal handling module
 */
void
SigInitialize()
{
	int	i ;

	sigemptyset( &sigEmptySet ) ;
	sigfillset( &sigFillSet ) ;

	for ( i = 1 ; i <= NSIG ; i ++ ) {
		sigTable[i].handler = NULL ;
		sigTable[i].deferrable = 0 ;
	}

	sigTable[SIGALRM].deferrable = 1 ;
	sigTable[SIGCHLD].deferrable = 1 ;
	sigTable[SIGPOLL].deferrable = 1 ;
	sigTable[SIGTERM].deferrable = 1 ;
	sigTable[SIGINT ].deferrable = 1 ;
	sigTable[SIGPIPE].deferrable = 1 ;
	sigTable[SIGHUP ].deferrable = 1 ;

	SigClockTimes = 0 ;
}

/*
 *	Shutdown UNIX signal handling module
 */
void
SigShutdown()
{
	int	i ;
	mask_t	oset ;

	SIGBLOCK( sigFillSet, oset ) ;

	SigUalarm( 0, 0 ) ;
	for ( i = 1 ; i <= NSIG ; i ++ ) {
		if ( sigTable[i].handler ) SigAction( i, SIG_DFL ) ;
	}

	sigemptyset( &sigPending ) ;
	sigBlocking = 0 ;

	SIGSETMASK( oset ) ;
}

#if	0
void
SigUnBlock( int aMask )
{
	if ( aMask ) return ;
	sigBlocking = 0 ;
	if ( sigispending( &sigPending ) ) sigDispatch() ;
}

int
SigBlock()
{
	return(  TestAndSet( &sigBlocking ) ) ;
}
#endif
