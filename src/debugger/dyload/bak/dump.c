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
		key->desc = DlFindLine( code, key->addr ) ;
		OzExecExitMonitor( &code->lock ) ;
		OzUnBlockSuspend( block ) ;
		return( 0 ) ;
	} else return( -1 ) ; 
}

static	int
findFile_sub( ClassCode code, Key *key )
{
	int	block ;
	if ( code->addr <= key->addr
		&& key->addr <= code->addr + code->size ) {
		key->cid = code->cid ;
		block = OzBlockSuspend() ;
		OzExecEnterMonitor( &code->lock ) ;
		key->file = DlFindFile( code, key->addr ) ;
		OzExecExitMonitor( &code->lock ) ;
		OzUnBlockSuspend( block ) ;
		return( 0 ) ;
	} else return( -1 ) ; 
}

static	void
printPC( caddr_t aPC )
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

	OzOutput( -1, "0x%08x", aPC + 8 ) ;

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
		if ( key.cid ) OzOutput( -1, "%016lx->%s", key.cid, ptr ) ;
		else OzOutput( -1, "<%s>", ptr ) ;
		if ( buff != NULL ) OzFree( buff ) ;
	}

	key.file = DlFindFile( NULL, aPC ) ;

	key.addr = aPC ;
	key.desc = 0  ;
	if ( ClMapCode( findLine_sub, &key ) == 0 ) {
		key.desc = DlFindLine( NULL, aPC ) ;
	}

	if ( key.desc ) {
		if ( key.file ) OzOutput(-1, " at %s:%d", key.file, key.desc ) ;
		else OzOutput( -1, " at %d", key.desc ) ;
	}

	OzOutput( -1, "\n" ) ;
}

static	int
dump( char *addr )
{
	OZ_Thread	t ;
	void		*pc ;
	frame_t		*sp ;

	if ( addr == NULL ) return( 1 ) ;

	t = (void *)OzStrtoul( addr, 0, 16 ) ;

#if	#system(bsd)
	pc = (void *)t->context[3] ;
	sp = (frame_t *)t->context[2] ;
#endif
#if	#system(svr4)
	pc = (void *)t->context[2] ;
	sp = (frame_t *)t->context[1] ;
#endif
	printPC( pc ) ;
	do {
		pc = (void *)sp->r_i7 ;
		printPC( pc ) ;
		sp = (frame_t *)sp->r_i6 ;
		if ( sp == (frame_t *)sp->r_i6 ) break ;
	} while( sp->r_i6 && sp->r_i6 != 0xffffffff ) ;

	return( 0 ) ;
}

void
_start()
{
	ShRemoveCmd( "dump" ) ;
	ShAppendCmd( "dump", "<thread>", "dump thread stack", dump ) ;
}
