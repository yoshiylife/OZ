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
extern	void	sample() ;

extern	etext, edata, end ;

/*
 *	Dummy
 */
void	*OzExceptionAbort ;
void	OzExecRaise() { return ; }

void
startup()
{
	int	ret ;

	ThrLibcInit( 1 ) ;
	TimerInit(64);
	if ( ShInit() ) {
		OzError( "SHELL module initialize failed." ) ;
		exit( 6 ) ;
	}

	sample() ;
	OzShell( "sh", &ret ) ;
}
