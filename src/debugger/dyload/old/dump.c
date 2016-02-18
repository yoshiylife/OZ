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

typedef	struct	{
	int		id ;
	OZ_Thread	t ;
} TKey ;

static	int
dump_sub( OZ_Thread t, TKey *key )
{
	if ( t->id != key->id ) return( 1 ) ;
	if ( OzRunningThread == t ) {
		OzOutput( -1, "Don't dump myself\n" ) ;
		return( -1 ) ;
	}
	OzSuspendThread( t ) ;
	key->t = t ;
	return( 0 ) ;
}

static	int
dump( char *aStrTID, char *aFlag )
{
	TKey		key ;
	void		*pc ;
	frame_t		*sp ;

	if ( aStrTID == NULL ) return( 1 ) ;

	key.id = OzStrtol( aStrTID, 0, 0 ) ;

	if ( OzMapThreadTable( dump_sub, &key ) <= 0 ) {
		OzOutput( -1, "Not found thread %d.\n", key.id ) ;
		return( -1 ) ;
	}

#if	#system(bsd)
	pc = (void *)key.t->context[3] ;
	sp = (frame_t *)key.t->context[2] ;
#endif
#if	#system(svr4)
	pc = (void *)key.t->context[2] ;
	sp = (frame_t *)key.t->context[1] ;
#endif

	if ( key.t->signal_stack.ss_onstack && aFlag == NULL ) {
		sp = (frame_t *)sp->r_i6 ;
		OzOutput( -1, "[0x%08x] %s\n",
				key.t, OzStrsignal(sp->r_i0) ) ;
		pc = (void *)sp->r_i1 ;
		sp = (frame_t *)sp->r_i2 ;
		OzOutput( -1, "0x%08x", pc ) ; print( pc ) ;
	} else {
		OzOutput( -1, "[0x%08x]\n", key.t ) ;
		OzOutput( -1, "0x%08x", pc ) ; print( pc-8 ) ;
	}
	for (;;) {
		pc = (void *)sp->r_i7 ;
		sp = (frame_t *)sp->r_i6 ;
		if ( sp->r_i6 == 0 ) break ;
		OzOutput( -1, "0x%08x", pc+8 ) ; print( pc ) ;
	}

	OzResumeThread( key.t ) ;

	return( 0 ) ;
}

void
_start()
{
	ShRemoveCmd( "dump" ) ;
	ShAppendCmd( "dump", "<thread ID>", "dump thread stack", dump ) ;
}
