/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "switch.h"
#include "main.h"
#include "shell.h"
#include "thr.h"
#include "dyload.h"
#include "cl.h"
#include "oz++/ozlibc.h"

typedef	struct	{
	caddr_t		addr ;
	char		*name ;
	char		*file ;
	OZ_ClassID	cid ;
	int		desc ;
} Key ;

static	int
findAddr_sub( ClassCode code, Key *key )
{
	int	block ;
	if ( code->addr <= key->addr
		&& key->addr <= code->addr + code->size ) {
		key->cid = code->cid ;
		block = OzBlockSuspend() ;
		OzExecEnterMonitor( &code->lock ) ;
		key->addr = DlFindAddr( code, key->addr, &key->name ) ;
		OzExecExitMonitor( &code->lock ) ;
		OzUnBlockSuspend( block ) ;
		return( 0 ) ;
	} else return( -1 ) ; 
}

static	int
findLine_sub( ClassCode code, Key *key )
{
	int	block ;
	if ( code->addr <= key->addr
		&& key->addr <= code->addr + code->size ) {
		key->cid = code->cid ;
		block = OzBlockSuspend() ;
		OzExecEnterMonitor( &code->lock ) ;
		key->desc = DlFindLine( code, key->addr, &key->file ) ;
		OzExecExitMonitor( &code->lock ) ;
		OzUnBlockSuspend( block ) ;
		return( 0 ) ;
	} else return( -1 ) ; 
}

static	void
print( caddr_t aPC )
{
	Key	key ;
	char	*buff ;
	char	*ptr ;

	key.addr = aPC ;
	key.cid = 0 ;
	key.name = NULL ;
	if ( ClMapCode( findAddr_sub, &key ) == 0 ) {
		key.addr = DlFindAddr( NULL, aPC, &key.name ) ;
	}

	if ( key.name ) {
		OzOutput( -1, " in " ) ;
		buff = OzMalloc( OzStrlen(key.name) + 1 ) ;
		if ( buff == NULL ) ptr = key.name ;
		else {
			OzStrcpy( buff, key.name ) ;
			ptr = OzStrchr( buff, ':' ) ;
			if ( ptr ) *ptr = '\0' ;
			ptr = buff ;
		}
		if ( key.cid ) OzOutput( -1, "%016lx::%s", key.cid, ptr ) ;
		else OzOutput( -1, "<%s>", ptr ) ;
		if ( buff != NULL ) OzFree( buff ) ;
	}

	key.addr = aPC ;
	key.desc = 0  ;
	key.file = NULL  ;
	if ( ClMapCode( findLine_sub, &key ) == 0 ) {
		key.desc = DlFindLine( NULL, aPC, &key.file ) ;
	} else key.file = NULL ;

	if ( key.desc ) {
		if ( key.file ) OzOutput(-1, " at %s:%d", key.file, key.desc ) ;
		else OzOutput( -1, " (at %d)", key.desc ) ;
	}

	OzOutput( -1, "\n" ) ;
}

typedef	struct {
	OZ_ClassID	cid ;
	ClassCode	code ;
} CKey ;

static	int
methods_sub( ClassCode code, CKey *key )
{
	if ( code->cid == key->cid ) {
		/* Get ClassCode [Don't call ClGetCode()] */
		OzExecEnterMonitor( &code->lock ) ;
		if ( code->state == CL_LOADED ) {
			key->code = code ;
			code->ref_count ++ ;
		}
		OzExecExitMonitor( &code->lock ) ;
		return( 0 ) ;
	}
	return( 1 ) ;
}

static	int
methods( char *aStrCID )
{
	CKey	key ;
	int	i ;

	if ( aStrCID == NULL ) return( 1 ) ;

	key.cid = OzStrtoull( aStrCID, 0, 16 ) ;
	key.code = NULL ;

	if ( ClMapCode( methods_sub, &key ) == 0 ) {
		OzOutput( -1, "Not found class %16lx.\n",  key.cid ) ;
		return( -1 ) ;
	}
	if ( key.code == NULL ) {
		OzOutput( -1, "Not loaded class %16lx.\n",  key.cid ) ;
		return( -1 ) ;
	}

	for ( i = 0 ; i < key.code->fp_table->number_of_entry ; i ++ ) {
		OzOutput( -1, "0x%08x", key.code->fp_table->functions[i] ) ;
		print( (caddr_t)key.code->fp_table->functions[i] ) ;
	}
	ClReleaseCode( key.code ) ;

	return( 0 ) ;
}

void
_start()
{
	ShRemoveCmd( "methods" ) ;
	ShAppendCmd( "methods", "<class ID>", "list methods", methods ) ;
}
