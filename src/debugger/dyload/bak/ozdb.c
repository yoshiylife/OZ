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

#define	FACTOR	64

typedef	struct	{
	caddr_t	addr ;
	char	*file ;
} Slot ;

typedef	struct	{
	int	free ;
	int	used ;
	Slot	*slot ;
} Table ;

static	int
ozdb_nop( ClassCode code, int dummy )
{
	return( 0 ) ;
}

#if	0
	OzOutput( tty, "echo %016lx in 0x%08x...\n", code->cid, code->addr ) ;
#endif
	OzOutput( tty, "add-symbol-file %s 0x%08x\n",
			code->sym_file, code->addr ) ;
#if	0
	OzOutput( tty, "echo done.\\n\n" ) ;
#endif

static	int
update_subs( ClassCode code, Table *table )
{
	int	result = -1 ;

	if ( table->free == 0 ) {
		Slot	*new ;
		new = OzRealloc( sizeof(Slot) * (table->used + FACTOR) ) ;
		if ( new == NULL ) {
			OzOutput( -1, "OzRealloc: %m\n" ) ;
			goto error ;
		}
		table->slot = new ;
		table->free += FACTOR ;
	}
	table->slot[table->used].addr = code->addr ;
	table->slot[table->used].file = code->sym_file ;
	table->free -- ;
	table->used ++ ;
	result = 0 ;

error:
	return( result ) ;
}

static	int
update()
{
	int	result = -1 ;
	char	*ptr = NULL ;
	int	fd = -1 ;
	Table	table ;
	int	count ;

	table.slot = OzMalloc( sizeof(Slot) * FACTOR ) ;
	if ( table.slot == NULL ) {
		OzOutput( -1, "OzMalloc: %m\n" ) ;
		goto error ;
	}
	table.free = FACTOR ;
	table.used = 0 ;
	ClMapCode( ozdb_subs, (void *)&table ) ;

	ptr = OzMalloc( OzStrlen(OzHome) + 7 + 1 ) ;
	if ( ptr == NULL ) {
		OzOutput( -1, "OzMalloc: %m\n" ) ;
		goto error ;
	}
	OzSprintf( ptr, "%s/.dylog", OzHome ) ;
	fd = OzOpen( ptr, O_WRONLY|O_TRUNC|O_CREAT,0666 ) ;
	if ( fd < 0 ) {
		OzOutput( -1, "OzOpen(%s): %m\n", ptr ) ;
		goto error ;
	}
	ClMapCode( ozdb_subs, (void *)fd ) ;
	OzOutput( fd, "echo done.\\n\n" ) ;
	OzOutput( fd, "attach %d\n", OzUnixPID ) ;
	OzClose( fd ) ; fd = -1 ;
	result = 0  ;

error:
	if ( fd > 0 ) OzClose( fd ) ;
	if ( ptr != NULL ) OzFree( ptr ) ;
	if ( table.slot != NULL ) OzFree( table.slot ) ;
	return( result ) ;
}

static	int
ozdb()
{
	int	result = -1 ;
	char	*ptr = NULL ;
	char	*argv[10] ;
	char	title[64] ;
	int	fd = -1 ;
	int	count ;

	ptr = OzMalloc( OzStrlen(OzHome) + 6 + 1 ) ;
	if ( ptr == NULL ) {
		OzOutput( -1, "OzMalloc: %m\n" ) ;
		goto error ;
	}
	OzSprintf( ptr, "%s/.ozdb", OzHome ) ;
	fd = OzOpen( ptr, O_WRONLY|O_TRUNC|O_CREAT,0666 ) ;
	if ( fd < 0 ) {
		OzOutput( -1, "OzOpen(%s): %m\n", ptr ) ;
		goto error ;
	}
	OzOutput( fd, "echo ===== ozdb =====\\n\n" ) ;
	OzOutput( fd, "set prompt (ozdb)\n" ) ;
	OzOutput( fd, "symbol %s/bin/executor\n", OzRoot ) ;
	OzOutput( fd, "directory %s/src/executor\n", OzRoot ) ;
	count = ClMapCode( ozdb_nop, 0 ) ;
	OzOutput( fd, "echo Loading %d classes...\n", count ) ;
	ClMapCode( ozdb_subs, (void *)fd ) ;
	OzOutput( fd, "echo done.\\n\n" ) ;
	OzOutput( fd, "attach %d\n", OzUnixPID ) ;
	OzClose( fd ) ; fd = -1 ;

	OzSprintf( ptr, "-cd=%s", OzHome ) ;
	OzSprintf( title, "Executor debugger (%06x)",
			(int)((OzExecutorID>>24)&0x0ffffff) ) ;
	argv[0] = "kterm" ;
	argv[1] = "-title" ;
	argv[2] = title,
	argv[3] = "-e" ;
	argv[4] = "/usr/local/gdb-4.15.1/gdb/gdb" ;
	argv[5] = ptr ;
	argv[6] = "-nx" ;
	argv[7] = "-command=.ozdb" ;
	argv[8] = NULL ;
	fd = OzVspawn( "kterm", argv ) ;
	result = 0  ;

error:
	if ( fd > 0 ) OzClose( fd ) ;
	if ( ptr != NULL ) OzFree( ptr ) ;
	return( result ) ;
}


void
_start()
{
	ShRemoveCmd( "ozdb" ) ;
	ShAppendCmd( "ozdb", "", "fork ozdb with another terminal", ozdb ) ;
}
