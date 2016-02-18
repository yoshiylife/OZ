/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
/* multithread system include */
#include "thread/thread.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "queue.h"
#include "channel.h"
#include "ot.h"
#include "executor/executor.h"
#include "executor/class-table.h"
#include "executor/code-layout.h"
#include "executor/method-invoke.h"
#include "executor/exception.h"
#include "executor/memory.h"
#include "executor/process.h"
#include "oz++/sysexcept.h"

#define SILENT_GC
#define VERRY_SILENT_GC
#define	GC_ALL

/*
 *	Declaration of System calls
 */

/*
 *	External Function Signature without include file
 */
extern	OZ_Object	OzExecCifLoad( char *path, Heap heap ) ;
extern	int		OzOmMemoryShortage() ;

/*
 *	Internal Function Signature
 */
#ifdef GCTEST
static	void	test_gc_daemon();
#endif /* GCTEST */

static	int
enum_files( const char *file, void (*func)() )
{
		int	result = -1 ;	/* counter of line */
		char	*buf = NULL ;
		int	fd = -1 ;
		int	line ;
		OID	cid ;
	struct	stat	fbuf ;
		char	*path ;
		char	*ptr ;
		char	*pbk ;

	if ( (fd=OzOpen( file, O_RDONLY )) < 0 ) {
		OzError( "Can't open '%s': %m.", file ) ;
		goto error ;
	}
	if ( OzFstat( fd, &fbuf) < 0 ) {
		OzError( "Can't get stat '%s': %m.", file ) ;
		goto error ;
	}
	if ( (buf=OzMalloc( fbuf.st_size+1 )) == NULL ) {
		OzError( "Can't allocate buffer size %d for '%s': %m.",
				fbuf.st_size+1, file ) ;
		goto error ;
	}
	if ( OzRead( fd, buf, fbuf.st_size ) != fbuf.st_size ) {
		OzError( "Can't read %d bytes from '%s': %m.",
				fbuf.st_size, file ) ;
		goto error ;
	}

	*(buf+fbuf.st_size) = '\n' ;
	ptr = buf ;
	pbk = ptr + fbuf.st_size ;
	line = 1 ;
	do {
		errno = 0 ;
		cid = OzStrtoull( ptr, &path, 16 ) ;
		if ( errno || *path != ':' ) {
			OzError( "Class ID in '%s' at %d.", file, line ) ;
			goto error ;
		}
		path ++ ;
		while( * ++ ptr != '\n' )  ;
		*ptr ++ = '\0'  ;
		(*func)( cid, path ) ;
		line ++ ;
	} while( ptr < pbk ) ;
	result = line - 1 ;

error:
	if ( 0 <= fd ) OzClose( fd ) ;
	if ( buf != NULL ) OzFree( buf ) ;
	return( result ) ;
}

/* Preload file description file name table */
static	struct	{
	char	*t ;
	char	*n ;
	void	(*f)() ;
} preloads[] = {
	/* Title	File name		Function */
	{ "codes",	"preload-codes",	OzOmPreloadCode },
	{ "classes",	"preload-classes",	OzOmPreloadRuntimeClassInfo },
#if	0
	{ "layouts",	"preload-layouts",	OzOmPreloadLayoutInfo },
#endif
	{ NULL,		NULL,			NULL }
} ;

int
Preload()
{
	OZ_ExceptionRec	e_rec ;
	int	result = -1 ;
	int	i ;

	OzExecInitializeExceptionHandler( &e_rec, 1 ) ;
	OzExecPutEidIntoCatchTable( &e_rec, OzExceptionAny ) ;
	OzExecRegisterExceptionHandlerFor( &e_rec ) ;
	if ( SETJMP(e_rec.jmp) == 0 ) {
		/* Preload ... */
		OzPrintf( "Preload: " ) ;
		for ( i = 0 ; preloads[i].t != NULL ; i ++ ) {
			OzPrintf( "%s", preloads[i].t ) ;
			result = enum_files( preloads[i].n, preloads[i].f ) ;
			if ( result < 0 ) {
				OzError( "%s failed.", preloads[i].t ) ;
				OzExecRaise( OzExceptionAbort, 0, 0 ) ;
			}
			OzPrintf( "(%d) ", result ) ;
		}
		OzPrintf( "Done.\n" ) ;
#ifdef GCTEST
		test_gc_daemon() ;
#endif /* GCTEST */
		result = 0 ;
	} else {
		result = -1 ;
	}
	OzExecUnregisterExceptionHandler() ;

	return( result ) ;
}

int
LoadImage( int base )
{
 volatile int		result = -1 ;
	OID		oid ;
	int		pid ;
	int		stdIn ;
	int		stdOut ;
	int		stdErr ;
	char		path[32] ;
	ObjectTableEntry		entry ;
	OZ_MethodImplementationRec	imp ;
	OzRecvChannelRec		chan ;
	OZ_ExceptionRec			e_rec ;

	OzExecInitializeExceptionHandler( &e_rec, 1 ) ;
	OzExecPutEidIntoCatchTable( &e_rec, OzExceptionAny ) ;
	OzExecRegisterExceptionHandlerFor( &e_rec ) ;
	if ( SETJMP(e_rec.jmp) == 0 ) {
		/* Load object image */
		OzSprintf( path, "objects/%06x", base ) ;
		oid = OzExecutorID | (OID)base ;
		OzOmObjectTableDownLoad( oid , 0 ) ;
		entry = OtGetEntry( oid ) ;
		entry->object = OzExecCifLoad( path, entry->heap ) ;
		OzExecEnterMonitor( &entry->lock ) ;
		entry->flags = OT_LOADED ;
		entry->call_count ++ ;
		OzExecExitMonitor( &entry->lock ) ;
		OzExecFindMethodImplementation( &imp, entry->object, 1, 0 ) ;
		chan.caller = 0 ;
		chan.callee = oid ;
		chan.o = entry ;
		stdIn = ThrRunningThread->StdIn ;
		stdOut = ThrRunningThread->StdOut ;
		stdErr = ThrRunningThread->StdErr ;
		ThrRunningThread->channel = &chan ;
		ThrRunningThread->StdIn = 0 ;
		ThrRunningThread->StdOut = 1 ;
		ThrRunningThread->StdErr = 2 ;
		result = 1 ;
		pid = OzExecForkProcess( (void *)imp.function, 'v', 4096, 3, 0,
							1, entry->object ) ;
		ThrRunningThread->channel = NULL ;
		ThrRunningThread->StdIn = stdIn ;
		ThrRunningThread->StdOut = stdOut ;
		ThrRunningThread->StdErr = stdErr ;
		OzExecJoinProcess( pid ) ;
		result = 0 ;
	}
	OzExecUnregisterExceptionHandler() ;

	return( result ) ;
}

#ifdef GCTEST
/*
 * For testing gc
 */

static	int
test_gc_object( OID oid )
{
	OZ_ExceptionRec	e_rec ;
	volatile int	ret ;

#ifndef	GC_OM
	if ( (oid & 0x0ffffff) == 0x1 ) {
#ifndef SILENT_GC
		OzDebugf("test_gc_object: OM ignored\n");
#endif /* SILENT_GC */
		return( 1 ) ;
	}
#endif	!GC_OM

	OzExecInitializeExceptionHandler( &e_rec, 1 ) ;
	OzExecPutEidIntoCatchTable( &e_rec, OzExceptionObjectNotFound ) ;
	OzExecRegisterExceptionHandlerFor( &e_rec ) ;
	if ( SETJMP(e_rec.jmp) == 0 ) {
#ifndef SILENT_GC
		OzDebugf( "test_gc_object: <<< %O >>>\n", oid ) ;
#endif /* SILENT_GC */
		if ( (ret = OzOmObjectTableSuspend( oid )) >= 0 ) {
			OzOmGCollectObject( oid, ret ? 0 : 1 ) ;
			OzOmObjectTableResume( oid ) ;
		}
	} else if ( OzExecEidcmp(e_rec.eid,OzExceptionObjectNotFound) == 0 ) {
#ifndef SILENT_GC
		OzDebugf("test_gc_object: object not found.\n");
#endif /* SILENT_GC */
	} else {
		if ( 0 <= ret ) OzOmObjectTableResume( oid ) ;
#ifndef SILENT_GC
		OzDebugf("test_gc_object: some unexpected exception occured.\n");
#endif /* SILENT_GC */
		OzExecReRaise();
		/* NOT REACHED */
	}
	OzExecUnregisterExceptionHandler() ;
	return( 0 ) ;
}

typedef	struct	OtListStr*	OtList ;
typedef	struct	OtListStr	OtListRec ;
struct	OtListStr	{
	OtList		b_prev ;
	OtList		b_next ;
	OID		oid ;
} ;

static	int
OtEnque( ObjectTableEntry aEntry, OtList *aHead )
{
	OtList	list ;
	if ( aEntry->object && aEntry->flags & OT_LOADED && aEntry->oid ) {
		list = (OtList)OzMalloc( sizeof(OtListRec) ) ;
		if ( list ) {
			list->oid = aEntry->oid ;
			InsertQueueBinary( list, *aHead ) ;
			return( 0 ) ;
		}
	}
	return( 1 ) ;
}

static	OID
OtDeque( OtList *aHead )
{
	OID	oid ;
	OtList	list ;
	if ( *aHead == NULL ) oid = 0 ;
	else {
		list = *aHead ;
		oid = list->oid ;
		RemoveQueueBinary( list, *aHead ) ;
		OzFree( list ) ;
	}
	return( oid ) ;
}

static	void
test_gc()
{
	OtList	list ;
	OID	oid ;

	InitQueueBinary( list ) ;
	OtMapObjectTable( OtEnque, &list ) ;
	while( (oid=OtDeque( &list )) ) test_gc_object( oid ) ;
}

static void test_gc_all()
{
#ifdef TIMER_GC
	int tag ;
#endif /* TIMER_GC */

#ifndef SILENT_GC
	OzDebugf("gc_daemon: ********* start *******\n");
#endif /* SILENT_GC */
#ifdef TIMER_GC
	tag = TimerStart() ;
#endif /* TIMER_GC */

	test_gc() ;

#ifndef VERRY_SILENT_GC
	MmReportHeapGlobal() ;
#endif /* VERRY_SILENT_GC */

#ifdef GC_ALL
#ifndef SILENT_GC
	OzDebugf( "gc_daemon: gc-ing classes\n" ) ;
#endif /* SILENT_GC */
	OzOmGCollectClassInfo() ;
#ifndef SILENT_GC
	MmReportHeapGlobal() ;
	OzDebugf( "gc_daemon: gc-ing layouts\n" ) ;
#endif /* SILENT_GC */
	OzOmGCollectLayoutInfo() ;
#ifndef SILENT_GC
	MmReportHeapGlobal() ;
	OzDebugf( "gc_daemon: gc-ing codes\n" ) ;
#endif /* SILENT_GC */
	OzOmGCollectCodes();
#ifndef SILENT_GC
	MmReportHeapGlobal() ;
#endif /* SILENT_GC */
#endif /* GC_ALL */

#ifdef TIMER_GC
	TimerEnd( tag ) ;
#endif /* TIMER_GC */
#ifndef SILENT_GC
	OzDebugf("gc_daemon: *********  end  *******\n");
#endif /* SILENT_GC */
}

static void test_gc_daemon_aux()
{
	while ( 1 ) {
		OzOmMemoryShortage() ;
		OzOmEnterGC() ;
		OzDebugf( "GarbageCollection..." ) ;
		test_gc_all() ;
		OzDebugf( "done\n" ) ;
		OzOmExitGC() ;
	}
}

static void test_gc_daemon()
{
	OZ_Thread t ;
	t = ThrFork( test_gc_daemon_aux, 0, 3, 0 ) ;
}

#endif /* GCTEST */
