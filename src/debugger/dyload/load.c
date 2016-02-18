/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "switch.h"
#include "main.h"
#include "shell.h"
#include "executor/exception.h"
#include "channel.h"
#include "oz++/sysexcept.h"
#include "cl.h"
#include "ct.h"
#include "oz++/ozlibc.h"

static	ClassLayout
LoadLayout_sub( OZ_ClassID cid )
{
	ClassLayout	result ;
	OZ_ExceptionRec	e_rec ;

	OzExecInitializeExceptionHandler( &e_rec, 1 ) ;
	OzExecPutEidIntoCatchTable( &e_rec, OzExceptionAny ) ;
	OzExecRegisterExceptionHandlerFor( &e_rec ) ;
	if ( SETJMP(e_rec.jmp) == 0 ) {
		result = ClGetLayout( cid ) ;
	} else {
		OzExecHandlingException( &e_rec ) ;
		result = NULL ;
	}
	OzExecUnregisterExceptionHandler() ;

	return( result ) ;
}

static	int
LoadLayout( char *aStrCID )
{
	ClassLayout	layout ;
	OZ_ClassID	cid ;

	if ( aStrCID == NULL ) return( 1 ) ;

	if ( OzStrlen( aStrCID ) < 16 ) {
		cid = OzExecutorID | OzStrtoul( aStrCID, 0, 16 ) ;
	} else {
		cid = OzStrtoull( aStrCID, 0, 16 ) ;
	}

	layout = LoadLayout_sub( cid ) ;
	if ( layout == NULL ) {
		OzOutput( -1, "Not found layout %016lx.\n",  cid ) ;
		return( -1 ) ;
	}
	ClReleaseLayout( layout ) ;
	return( 0 ) ;
}

static	OZ_Class
LoadClass_sub( OZ_ClassID cid )
{
	OZ_Class	result ;
	OZ_ExceptionRec	e_rec ;

	OzExecInitializeExceptionHandler( &e_rec, 1 ) ;
	OzExecPutEidIntoCatchTable( &e_rec, OzExceptionAny ) ;
	OzExecRegisterExceptionHandlerFor( &e_rec ) ;
	if ( SETJMP(e_rec.jmp) == 0 ) {
		result = CtGetClass( cid ) ;
	} else {
		OzExecHandlingException( &e_rec ) ;
		result = NULL ;
	}
	OzExecUnregisterExceptionHandler() ;

	return( result ) ;
}

static	int
LoadClass( char *aStrCID )
{
	OZ_Class	class ;
	OZ_ClassID	cid ;

	if ( aStrCID == NULL ) return( 1 ) ;

	if ( OzStrlen( aStrCID ) < 16 ) {
		cid = OzExecutorID | OzStrtoul( aStrCID, 0, 16 ) ;
	} else {
		cid = OzStrtoull( aStrCID, 0, 16 ) ;
	}

	class = LoadClass_sub( cid ) ;
	if ( class == NULL ) {
		OzOutput( -1, "Not found class %016lx.\n",  cid ) ;
		return( -1 ) ;
	}
	CtReleaseClass( class ) ;
	return( 0 ) ;
}

void
_start()
{
	OzShRemoveCmd( "load-layout" ) ;
	OzShAppendCmd( "load-layout", "<class id>", "load layout", LoadLayout );
	OzShRemoveCmd( "load-class" ) ;
	OzShAppendCmd( "load-class", "<class id>", "load class", LoadClass );
}
