/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/*
 *	OZ++ System Startup except for multithread system module
 *		Startup all modules with multithread.
 *		Load object image for OM, and go OM.
 */
/* unix system include */
#include <errno.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/shell.h"
#include "thread/timer.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "ct.h"
#include "ot.h"
#include "cl.h"
#include "conf.h"
#include "nif.h"
#include "pkif.h"
#include "proc.h"
#include "mem.h"
#include "dyload.h"

#undef	TIMER_PRELOAD
#undef	TIMER_BOOT
#undef	TIMER_GO

/*
 *	System calls
 */

/*
 *	C Library functions
 */

/*
 *	External Function Signature without include file
 */
extern	void	ThrLibcInit( int flag ) ;
extern	int	init_pikopiko() ;
extern	void	InitComm() ;
extern	void	InitCommBuff() ;
extern	int	InitCommCircuits() ;
extern	void	init_exectable() ;
extern	int	LoadImage( int oid ) ;
extern	int	Preload() ;

extern	int	DcInit( int ) ;
extern	int	DmInit( int ) ;
extern	int	DsInit( int ) ;
extern	int	DgInit( void ) ;

extern int	MyArchitectureType ;

static	void
gdbinit( pid_t pid, u_int exid )
{
	int	fd ;

	/* make .gdbinit */
	fd = OzLogFile( ".gdbinit", O_WRONLY|O_TRUNC|O_CREAT|O_SYNC, 0666 ) ;
	OzOutput( fd, "#%d\n", pid ) ;
	OzOutput( fd, "echo ===== OZ++ Executor Primitive Debugger =====\\n" );
	OzOutput( fd, "\n" ) ;
	OzOutput( fd, "echo %s/bin/executor\\n", OzRoot ) ;
	OzOutput( fd, "\n" ) ;
	OzOutput( fd, "symbol %s/bin/executor\n", OzRoot ) ;
	OzOutput( fd, "directory %s/src/executor\n", OzRoot ) ;
	OzOutput( fd, "cd %s/images/%06x\n", OzRoot, exid ) ;
	OzOutput( fd, "attach %d\n", pid ) ;
	OzClose( fd ) ;
}

/* Dummy */
static	int	test ;
int
OzOmStarted( int status )
{
	if ( test ) NifStarted( status ) ;
	else OzError( "Don't call OzOmStared()." ) ;
	return( 0 ) ;
}

static	int
go( char *name, int argc, char *argv[], int sline, int eline )
{
	int	oid ;
	int	ret ;
#if	defined(TIMER) && defined(TIMER_GO)
	int	tag ;
	tag = TimerStart() ;
#endif

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	test = ( argc > 2 ) ? 1 : 0 ;
	oid = OzStrtol( argv[1], 0, 0 ) ;

	/* Load object image for OM, and go OM. */
	ret = LoadImage( oid ) ;
	if ( ret < 0 ) OzError( "LoadImage(0x%x): loading failed.", oid ) ;
	else if ( ret ) OzError( "LoadImage(0x%x): exception raised.", oid ) ;
	if ( ! test ) NifStarted( ret ) ;

#if	defined(TIMER) && defined(TIMER_GO)
	TimerEnd( tag ) ;
#endif

	return( ret ) ;
}

static	int
preload( char *name, int argc, char *argv[], int sline, int eline )
{
#if	defined(TIMER) && defined(TIMER_PRELOAD)
	int	tag ;
	tag = TimerStart() ;
#endif
	if ( Preload() != 0 ) {
		OzError( "Preload() failed." ) ;
		return( -2 ) ;
	}
	OzShRemove( "preload", NULL ) ;
	OzShRemove( "boot", "preload" ) ;
	OzShAppend( "boot", "go", go,
		"<object number>", "go global object" ) ;
	OzShAlias( "boot", "go", "go" ) ;
#if	defined(TIMER) && defined(TIMER_PRELOAD)
	TimerEnd( tag ) ;
#endif
	return( 0 ) ;
}


static	int
boot( char *name, int argc, char *argv[], int sline, int eline )
{
	int	status ;
	char	buf[64] ;

#if	defined(TIMER) && defined(TIMER_BOOT)
	int	tag ;
	tag = TimerStart() ;
#endif
	OzShRemove( "boot", NULL ) ;
	OzShRemove( "boot", "boot" ) ;

	/* OZ++ System module initialize */
	if ( MmInit() ) {
		OzError( "MEMORY module initialize failed." ) ;
		exit( 10 ) ;
	}
	if ( OtInit() ) {
		OzError( "OBJECT-TABLE module initialize failed." ) ;
		exit( 11 ) ;
	}
	if ( ClInit() ) {
		OzError( "CODE-LAYOUT module initialize failed." ) ;
		exit( 12 ) ;
	}
	if ( CtInit() ) {
		OzError( "CLASS-TABLE module initialize failed." ) ;
		exit( 13 ) ;
	}
	if ( CnfInit() ) {
		OzError( "CONFIG-REQ module initialize failed." ) ;
		exit( 14 ) ;
	}
	if ( PrInit() ) {
		OzError( "PROCESS module initialize failed." ) ;
		exit( 15 ) ;
	}
	InitComm();
	InitCommBuff() ;
	if ( InitCommCircuits() < 0 ) {
		OzError( "CIRCUITS module initialize failed." ) ;
		OzShutdownExecutor() ;
	}
	if ( DcInit( 20 ) ) {
		OzError( "DEBUG-CHANNEL module initialize failed." ) ;
		OzShutdownExecutor() ;
	}
	if ( DmInit( 20 ) ) {
		OzError( "DEBUG-MANAGER module initialize failed." ) ;
		OzShutdownExecutor() ;
	}
	if ( DsInit( 20 ) ) {
		OzError( "DEBUG-SUPPORT module initialize failed." ) ;
		OzShutdownExecutor() ;
	}
	if ( ! OzStandAlone ) {
		NifSetPortNumber();
		init_exectable();
		NifInit() ;
	}
	if ( DgInit() ) {
		OzError( "DEBUGGER module initialize failed." ) ;
		OzShutdownExecutor() ;
	}
	if ( PkInit() ) {
		OzError( "PIKOPIKO module initialize failed." ) ;
		OzShutdownExecutor() ;
	}
	if ( OzGIMonitor ) PkSwitch( 1 ) ;

#if	defined(TIMER) && defined(TIMER_BOOT)
	TimerEnd( tag ) ;
#endif
	OzShAppend( "boot", "preload", preload,
		"", "Preload classes etc..." ) ;
	OzShAlias( "boot", "preload", "preload" ) ;
	if ( argc == 2 ) {
		OzShell( "preload", &status ) ;
		if ( status == 0 ) {
			OzSprintf( buf, "go %s", argv[1] ) ;
			OzShell( buf, &status ) ;
		}
	}

	return( 0 ) ;
}

void
printer( int exid, int pid )
{
 struct utsname	host ;
	int	con ;
	int	log ;
	int	ret ;
	char	buf[BUFSIZ] ;

	OzUname( &host ) ;
	OzSprintf( buf, "OZ++ Executor Console: %06x(%d@%s)",
			exid, pid, host.nodename ) ;
	con = OzConsole( "xterm", "-title", buf,
			"-name", "Executor Console",
			OzIconify ? "-iconic" : NULL, NULL ) ;
	if ( con < 0 ) {
		OzError( "Can't open control terminal: %m." ) ;
		exit( 1 ) ;
	}
#if	0
	OzDup2( ret, CONSOLE ) ;
	OzClose( ret ) ;
#endif

	log = OzOpen( "ozlog", O_RDONLY, 0 ) ;
	if ( log < 0 ) {
		OzError( "Can't open 'ozlog': %m." ) ;
		exit( 2 ) ;
	}
#if	0
	OzDup2( ret, 0 ) ;
	OzClose( ret ) ;
#endif

#if	0
	OzPrintf( "Printer(ozlog) starting[%d].\n", ThrRunningThread->tid ) ;
#endif
	for (;;) {
		ret = OzRead( log, buf, BUFSIZ ) ;
		if ( ret > 0 ) ret = OzWrite( con, buf, ret ) ;
		if ( ret < 0 ) ThrPrintf( "Printer(ozlog): %m.\n" ) ;
		if ( ret == 0 ) OzSleep( 1 ) ;
		else if ( ret < 0 ) break ;
	}
#if	0
	OzPrintf( "Printer(ozlog) stoped[%d].\n", ThrRunningThread->tid ) ;
#endif
}

static	int
infCmdVersion( char *name, int argc, char *argv[], int sline, int eline )
{
	OzPrintf( "OZ++ Executor %s %s\n",
			OzVersion, OzStandAlone?"Local":"Remote" ) ;
	return( 0 ) ;
}

static	int
infCmdOzroot( char *name, int argc, char *argv[], int sline, int eline )
{
	OzPrintf( "OZROOT:%s\n", OzRoot ) ;
	return( 0 ) ;
}

static	int
infCmdParam( char *name, int argc, char *argv[], int sline, int eline )
{
	OzPrintf( "Thread max:%d, Clock ticks:%d/second"
			", Object heap size:%dKbytes\n",
			OzThreadMax, OzClockTicks, OzHeapSize/1024 ) ;
	return( 0 ) ;
}

static	int
infCmdId( char *name, int argc, char *argv[], int sline, int eline )
{
	pid_t	pid ;
	int	sid ;
	int	eid ;

	pid =  OzGetpid() ;
	sid = (OzExecutorID >> 48) & 0x0ffff ;
	eid = (OzExecutorID >> 24) & 0x0ffffff ;
	OzPrintf( "Process ID:%d, Executor ID:%04x %06x, Arch ID:%04x\n",
		pid, sid, eid, MyArchitectureType ) ;

	return( 0 ) ;
}

void
startup()
{
	pid_t	pid ;
	u_int	exid ;
	u_int	site ;
	int	status ;
	char	*display ;

	ThrLibcInit( OzDebugging ) ;

	/* setup Executor-ID. */
	if ( ! OzStandAlone ) {
		/* Get Executor-ID from Necleus */
		if ( NifGetFirstPacketFromNcl() <= 0 ) {
			OzError( "Can't receive Executor-ID from Necleus." ) ;
			OzShutdownExecutor() ;
		}
	}

	infCmdVersion( NULL, 0, NULL, 0, 0 ) ;

	pid = OzGetpid() ;
	site = (OzExecutorID >> 48) & 0x0ffff ;
	exid = (OzExecutorID >> 24) & 0x0ffffff ;
	display = OzGetenv( "DISPLAY" ) ;

	gdbinit( pid, exid ) ;

#ifdef TIMER
	TimerInit(64);
#endif /* TIMER */
	if ( ShInit() ) {
		OzError( "SHELL module initialize failed." ) ;
		exit( 6 ) ;
	}

	OzShell( "info core", &status ) ;

	if ( DlInit() ) {
		OzError( "DYLOAD module initialize failed." ) ;
		exit( 7 ) ;
	}

	OzShAppend( "boot", "", NULL, "", "Boot OZ++ system commands" ) ;
	OzShAppend( "boot", "boot", boot, "[<object number>]",
		"Boot OZ++ System and go <object number>" ) ;
	OzShAlias( "boot", "boot", "boot" ) ;

	OzShAppend( "info", "id", infCmdId, "",
		"Print executor unix process id") ;
	OzShAppend( "info", "version", infCmdVersion, "",
		"Print executor version" ) ;
	OzShAppend( "info", "ozroot", infCmdOzroot, "",
		"Print executor OZROOT" ) ;
	OzShAppend( "info", "param", infCmdParam, "",
		"Print thread max" ) ;

	OzShell( "info param", &status ) ;
	OzShell( "info id", &status ) ;
	OzShell( "info ozroot", &status ) ;

	if ( display == NULL ) OzGIMonitor = 0 ;
	if ( ! OzDaemon ) {
		if ( display == NULL ) {
			OzError( "Can't get enviroment DISPLAY." ) ;
			OzShutdownExecutor() ;
		} else ThrFork( printer, 0, MAX_PRIORITY, 2, exid, pid ) ;
	}

	if ( OzForkShell ) OzShell( "sh", &status ) ;
	else OzShell( "boot 1", &status ) ;
}
