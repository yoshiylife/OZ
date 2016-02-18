/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
/* multithread system include */
#include "thread.h"
#include "thread/signal.h"
#include "thread/monitor.h"
#include "thread/breakpoint.h"
#include "oz++/ozlibc.h"

/* executor include */
#include "thread/shell.h"

/*
 *	System calls
 */
#if	!defined(SVR4)
extern	void	*sbrk( int incr ) ;
#endif	/* SVR4 */

extern	etext, edata, end ;

static	OZ_MonitorRec	lock ;


/* AVL-Tree */
typedef	enum	{
	left=0,		/* Don't change */
	right=1,	/* Don't change */
	balanced
} Direct ;

typedef	enum	{
	false=0,	/* Don't change */
	true
} Boolean ;

typedef	struct	NodeStr*	Node ;
typedef	struct	NodeStr	{
	Node	child[2] ;	/* for AVL-Tree */
	Direct	balance ;	/* for AVL-Tree */
	Boolean	strict ;
		Boolean	alias ;
		char	*class ;
		char	*name ;
		char	*usage ;
		char	*comment ;
		ShCmd	command ;
} NodeStr ;

static	Node	Root ;

static	char*
strAlloc( char *str )
{
	char	*new ;

	if ( str ) {
		new = OzMalloc( OzStrlen(str) + 1 ) ;
		OzStrcpy( new, str ) ;
	} else new = NULL ;
	return( new ) ;
}

static	void
strFree( char *str )
{
	if ( str ) OzFree( str ) ;
}

static	void
strError( int mode, char *class, char *name )
{
	if ( mode ) {
		OzPrintf( "%s%s%s: Ambiguous command(%d).\n",
			class, name ? " " : "", name ? name : "", mode ) ;
	} else {
		OzPrintf( "%s%s%s: Command not found.\n",
			class, name ? " " : "", name ? name : "" ) ;
	}
}

static	int
strCompare( char *s1, char *s2 )
{
	int	ret ;

	if ( *s1 == '\0' ) ret = - *s2 ;
	else {
		if ( *s2 == '\0' ) ret = *s1 ;
		else ret = OzStrncmp( s1, s2, OzStrlen(s1) );
	}

	return( ret ) ;
}

static	int
compare( Node key, Node node )
{
	int	ret ;

	if ( key->strict == true ) ret = OzStrcmp( key->class, node->class ) ;
	else ret = strCompare( key->class, node->class ) ;
	if ( ret ) return( ret ) ;

	/* for alias */
	if ( key->alias == true && node->alias == true ) return( 0 ) ;
	if ( key->alias == true && node->alias == false ) return( -1 ) ;
	if ( key->alias == false && node->alias == true ) return( 1 ) ;

	/* not alias */
	if ( key->strict == true ) ret = OzStrcmp( key->name, node->name ) ;
	else ret = strCompare( key->name, node->name ) ;

	return( ret ) ;
}

static	Boolean
insert_rebalance( Node *aParent, Direct dir )
{
	Node	a = *aParent ;	/* Alias */
	Node	b ;		/* Alias */
	Node	c ;		/* Alias */
	Direct	opp = (dir == left) ? right : left ;

	if ( a->balance == balanced ) {
		a->balance = dir ;
		return( true ) ;
	} else if ( a->balance == opp ) {
		a->balance = balanced ;
		return( false ) ;
	}

	/* a->balance == dir */
	b = a->child[dir] ;
	if ( b->balance == dir ) {
		a->child[dir] = b->child[opp] ;
		b->child[opp] = a ;
		a->balance = b->balance = balanced ;
		*aParent = b ;
	} else if ( b->balance == opp ) {
		c = b->child[opp] ;
		b->child[opp] = c->child[dir] ;
		a->child[dir] = c->child[opp] ;
		c->child[dir] = b ;
		c->child[opp] = a ;
		b->balance = (c->balance != opp) ? balanced : dir ;
		a->balance = (c->balance != dir) ? balanced : opp ;
		c->balance = balanced ;
		*aParent = c ;
	} else OzError( "shell(AVL-Tree): FATAL ERROR rebalance" ) ;

	return( false ) ;
}

static	Boolean
insert( Node *aParent, Node *aNew )
{
	Node	p = *aParent ;	/* Aliase */
	Boolean	grown = true ;	/* Depth of tree is grown ? */

	if ( p ) {
		/* Compare Key & Rebalance tree */
		int	ret ;
		ret = compare( *aNew, p ) ;
		if ( ret == 0 ) {
			*aNew = NULL ;
			grown = false ;
			OzError( "shell(AVL-Tree): duplicate !!." ) ;
		} else {
			Direct	dir = ( ret < 0 ) ? left : right ;
			grown = insert( &p->child[dir], aNew ) ;
			if ( grown ) grown = insert_rebalance( aParent, dir ) ;
		}
	} else {
		/* Create Node */
		p = *aParent = OzMalloc( sizeof(NodeStr) ) ;
		if ( p ) {
			p->child[left] = p->child[right] = NULL ;
			p->balance = balanced ;
			p->strict = false ;
			p->alias = (*aNew)->alias ;
			p->class = strAlloc( (*aNew)->class ) ;
			p->name = strAlloc( (*aNew)->name ) ;
			p->usage = strAlloc( (*aNew)->usage ) ;
			p->comment = strAlloc( (*aNew)->comment ) ;
			p->command = (*aNew)->command ;
			*aNew = p ;
			grown = true ;
		} else {
			*aNew = NULL ;
			OzError( "shell(AVL_Tree) OzMalloc(): %m." ) ;
		}
	}

	return( grown ) ; 
}

static	Node
Insert( Node aKey )
{
	insert( &Root, &aKey ) ;
	return( aKey ) ;
}

static	Boolean
delete_rebalance( Node *aParent, Direct dir )
{
	Node	a = *aParent ;	/* Alias */
	Node	b ;		/* Alias */
	Node	c ;		/* Alias */
	Direct	opp = (dir == left) ? right : left ;

	if ( a->balance == balanced ) {
		a->balance = opp ;
		return( false ) ;
	} else if ( a->balance == dir ) {
		a->balance = balanced ;
		return( true ) ;
	}

	/* a->balance == opp */
	b = a->child[opp] ;
	if ( b->balance != dir ) {
		a->child[opp] = b->child[dir] ;
		b->child[dir] = a ;
		*aParent = b ;
		if ( b->balance == balanced ) {
			a->balance = opp ;
			b->balance = dir ;
			return( false ) ;
		} else {
			a->balance = b->balance = balanced ;
			return( true ) ;
		}
	} else {
		c = b->child[dir] ;
		a->child[opp] = c->child[dir] ;
		b->child[dir] = c->child[opp] ;
		c->child[dir] = a ;
		c->child[opp] = b ;
		a->balance = (c->balance != opp) ? balanced : dir ;
		b->balance = (c->balance != dir) ? balanced : opp ;
		c->balance = balanced ;
		*aParent = c ;
		return( true ) ;
	}
}

static	Boolean
extractmax( Node *p, Node *q )
{
	Boolean	shrinked ;	/* Depth of tree is shrinked ? */

	if ( (*p)->child[right] == NULL ) {
		*q = *p ;
		*p = (*p)->child[left] ;
		shrinked = true ;
	} else {
		shrinked = extractmax( &((*p)->child[right]), q ) ;
		if ( shrinked ) shrinked = delete_rebalance( p, right ) ;
	}
	return( shrinked ) ;
}

static	Boolean
delete( Node *aParent, Node *aKey )
{
	Node	p = *aParent ;	/* Aliase */
	Boolean	shrinked ;	/* Depth of tree is shrinked ? */
	int	ret ;

	if ( p == NULL ) {
		*aKey = NULL ;
		return( false ) ;
	}

	/* Compare Key & Rebalance tree */
	ret = compare( *aKey, p ) ;
	if ( ret ) {
		Direct	dir = ( ret < 0 ) ? left : right ;
		shrinked = delete( &p->child[dir], aKey ) ;
		if ( shrinked ) shrinked = delete_rebalance( aParent, dir ) ;
		return( shrinked ) ;
	}

	/* Equal */
	**aKey = *p ;
	if ( p->child[left] == NULL ) {
		*aParent = p->child[right] ;
		strFree( p->class ) ;
		strFree( p->name ) ;
		strFree( p->usage ) ;
		strFree( p->comment ) ;
		OzFree( p ) ;
		shrinked = true ;
	} else {
		shrinked = extractmax( &(p->child[left]), &p ) ;
		p->child[left] = (*aParent)->child[left] ;
		p->child[right] = (*aParent)->child[right] ;
		p->balance = (*aParent)->balance ;
		strFree( (*aParent)->class ) ;
		strFree( (*aParent)->name ) ;
		strFree( (*aParent)->usage ) ;
		strFree( (*aParent)->comment ) ;
		OzFree( *aParent ) ;
		*aParent = p ;
		if ( shrinked ) shrinked = delete_rebalance( aParent, left ) ;
	}
	return( shrinked ) ;
}

static	Node
Delete( Node aKey )
{
	delete( &Root, &aKey ) ;
	return( aKey ) ;
}

static	int
Search( Node aKey, Node aNow, Node *aFound )
{
	int	ret ;

	while ( aNow ) {
		if ( (ret = compare( aKey, aNow )) ) {
			aNow = aNow->child[ret < 0 ? left : right] ;
			continue ;
		}
		ret ++ ;
		ret += Search( aKey, aNow->child[left], NULL ) ;
		ret += Search( aKey, aNow->child[right], NULL ) ;
		if ( aFound ) *aFound = aNow ;
		return( ret ) ;
	}
	return( 0 ) ;
}

static	void
comment( Node cmd, int mode )
{
	char	buf[256] ;

	if ( mode == 0 ) {
		if ( *cmd->name ) {
			if ( cmd->alias == true ) {
				OzSprintf( buf, "%s %s",
						cmd->class, cmd->usage ) ;
			} else {
				OzSprintf( buf, "  %s %s",
						cmd->name, cmd->usage ) ;
			}
		} else {
			OzSprintf( buf, "%s %s", cmd->class, cmd->usage ) ;
		}
		OzPrintf( "%-31s%s-- %s\n",
			buf, OzStrlen( buf ) > 31 ? " " : "\t", cmd->comment ) ;
	} else {
		OzPrintf( "%s%s%s %s -- %s\n",
				cmd->class,
				cmd->alias==false ? " " : "",
				cmd->alias==false ? cmd->name : "",
				cmd->usage,
				cmd->comment ) ;
	}
}

static	void
usage( Node cmd )
{
	OzPrintf( "%s\nUsage: %s%s%s %s\n", cmd->comment,
			cmd->class,
			cmd->alias==false ? " " : "",
			cmd->alias==false ? cmd->name : "",
			cmd->usage ) ;
}

static	void
list( Node p )
{
	if ( p->child[left] ) list( p->child[left] ) ;
	if ( p ) comment( p, 0 ) ;
	if ( p->child[right] ) list(  p->child[right] ) ;
}

static	void
list_classes( Node p )
{
	if ( p->child[left] ) list_classes( p->child[left] ) ;
	if ( p->name && *p->name == '\0' ) comment( p, 0 ) ;
	if ( p->child[right] ) list_classes(  p->child[right] ) ;
}

static	void
list_class( Node p, char *class )
{
	if ( p->child[left] ) list_class( p->child[left], class ) ;
	if ( OzStrcmp( p->class, class ) == 0 ) comment( p, 0 ) ;
	if ( p->child[right] ) list_class(  p->child[right], class ) ;
}

static	void
list_alias( Node p )
{
	if ( p->child[left] ) list_alias( p->child[left] ) ;
	if ( p->alias == true ) {
		OzPrintf( "%-23s\t-- %s\n", p->class, p->name ) ;
	}
	if ( p->child[right] ) list_alias(  p->child[right] ) ;
}

static	int
parse( char **ptr, char *(*argv[]) )
{
	int	cnt = 0 ;
	int	max = 16 ;
	char	*p = *ptr ;
	char	**v ;
	char	c ;

	if ( *argv == NULL ) {
		if ( (*argv = OzMalloc( sizeof(char *) * (max+1) )) == NULL ) {
			OzError( "parse OzMalloc(): %m." ) ;
			return( -1 ) ;
		}
	}

	for ( v = *argv, *v = NULL, c = *p ; c ; p ++, c = *p ) {

		/* skip space or chars in argument */
		if ( isspace( c ) || c == ';' ) {
			if ( *v ) {
				*p =  '\0' ;
				v ++ ;
			}
			if ( c == ';' ) break ;
			continue ;
		} else if ( *v ) continue ;

		/* save pointer to ahead of argument or process for quote */
		if ( c == '\'' && *(p+1) && *(p+1) != c ) {
			p ++ ;
			*v = p ;
			*(v+1) = NULL ;
			cnt ++ ;
			while ( * ++ p ) {
				if ( *p == c ) {
					c = *p = '\0' ;
					break ;
				}
			}
			if ( c ) break ;
		} else {
			*v = p ;
			*(v+1) = NULL ;
			cnt ++ ;
		}

		/* expand size of array to save pointer */
		if ( max <= cnt ) {
			max += 16 ;
			*argv = OzRealloc( *argv, sizeof(char *) * (max+1) ) ;
			if ( *argv == NULL ) {
				OzError( "parse OzRealloc(): %m." ) ;
				return( -1 ) ;
			}
		}
	}
	*ptr = (c == ';') ? p + 1 : p ;

	return( cnt ) ;
}

static	int
print_status( Thread t, int *lines )
{
	GREGS	*gregs ;
	frame_t	*sp ;
	frame_t	*fp ;

	static	char	*status[] = {
		"",
		"CREATE",
		"READY",
		"RUNNING",
		"SUSPEND",
		"WAIT IO",
		"WAIT LOCK",
		"WAIT COND",
		"WAIT SUSPEND",
		"WAIT TIMER",
		"DEFUNCT"
	};

	lines[1] ++ ;
	if ( lines[1] < lines[0] || lines[2] < lines[1] ) return( 1 ) ;

#if	defined(SVR4)
	sp = (frame_t *)t->context[1] ;
#else	/* SVR4 */
	sp = (frame_t *)t->context[2] ;
#endif	/* SVR4 */

	OzPrintf( "%3d: [0x%x] %3d ", lines[1], t , t->tid ) ;
	if ( t != ThrRunningThread && SIGSTACK_FLAGS(t->signal_stack) ) {
		fp = (frame_t *)sp->r_i6 ;
		gregs = (GREGS *)fp->r_i2 ;
		if ( gregs ) {
			OzPrintf( "%s(%s)<pc=0x%x sp=0x%x addr=0x%x>\n", 
				SigName(fp->r_i0), SigDetail(fp->r_i0,fp->r_i1),
				GREGS_PC(*gregs), GREGS_SP(*gregs), fp->r_i3 ) ;
		} else OzPrintf( "%s(Defered)\n", SigName(fp->r_i0) ) ;
	} else {
		OzPrintf( "%s%s%.0d%s\n",
			status[t->status],
			t->suspend_count ? "(+" : "",
			t->suspend_count,
			t->suspend_count ? ")" : "" ) ;
	}

	return( 0 ) ;
}

static	int
check_stack( Thread t, int *lines )
{
	frame_t	*sp ;
	GREGS	*gregs ;
	u_int	rest ;

#if	defined(SVR4)
	sp = (frame_t *)t->context[1] ;
#else	/* SVR4 */
	sp = (frame_t *)t->context[2] ;
#endif	/* SVR4 */

	if ( SIGSTACK_FLAGS(t->signal_stack) ) {
		sp = (frame_t *)sp->r_i6 ;
		gregs = (GREGS *)sp->r_i2 ;
		if ( gregs ) sp = (frame_t *)GREGS_SP(*gregs) ;
	}

	rest = (char *)sp - t->stack ;

	if ( rest < 0x2000 ) {
		lines[1] ++ ;
		if ( lines[1] < lines[0] || lines[2] < lines[1] ) return( 1 ) ;
		OzPrintf( "%3d: [0x%08x] %3d rest = %u\n", t, t->tid, rest ) ;
	}

	return( 0 ) ;
}

typedef	struct	{
	int	tid ;
	Thread	t ;
	int	(*f)( Thread t ) ;
	int	s ;
	int	*lines ;
} TKey ;

static	int
operate( Thread t, TKey *key )
{
	if ( key->t ) return( -1 ) ;
	if ( t->tid == key->tid ) {
		key->t = t ;
		key->s = key->f( t ) ;
		return( 0 ) ;
	}
	return( 1 ) ;
}

static	int
print_monitor( Thread t, TKey *key )
{
	if ( key->t ) return( -1 ) ;
	if ( t->tid == key->tid ) {
		key->t = t ;
		if ( t->status == WAIT_LOCK ) {
			OzPrintf( "Locking thread %d\n",key->t->wait_ml->tid ) ;
			if ( (t = key->t->wait_ml->t) ) {
				do {
					print_status( t, key->lines ) ;
					t = t->next ;
				} while ( t != key->t->wait_ml->t ) ;
			}
		}
		return( 0 ) ;
	}
	return( 1 ) ;
}

static	int
print_condition( Thread t, TKey *key )
{
	if ( key->t ) return( -1 ) ;
	if ( t->tid == key->tid ) {
		key->t = t ;
		if ( t->status == WAIT_COND ) {
			if ( (t = *key->t->wait_cv) ) {
				do {
					print_status( t, key->lines ) ;
					t = t->next ;
				} while ( t != *key->t->wait_cv ) ;
			}
		}
		return( 0 ) ;
	}
	return( 1 ) ;
}

static	int
print_break( BrkPoint bp, void *notUsed )
{
	OzPrintf( "%d ", bp->bid ) ;
	OzPrintf( "%s ", (bp->status == brkEnable) ? "enable" : "disable" );
	OzPrintf( "0x%x", bp->pc ) ;
	OzPrintf( "\n") ;
	return( 0 ) ;
}

static	int
action( int argc, char **argv, int sline, int eline )
{
	int	result = 0 ;
	int	ret ;
	NodeStr	key ;
	Node	cmd ;
	char	*name ;
	char	*arg0 ;
	ShCmd	command ;

	key.strict = false ;
	key.alias = true ;
	key.class = argv[0] ;
	key.name = argv[1] ? argv[1] : "" ;
	OzExecEnterMonitor( &lock ) ;
	ret = Search( &key, Root, &cmd ) ;
	if ( ret <= 0 ) {
		key.alias = false ;
		ret = Search( &key, Root, &cmd ) ;
	}
	if ( ret == 1 ) {
		if ( cmd->alias == true ) {
			name = strAlloc( cmd->class ) ;
			arg0 = *argv = strAlloc( cmd->name )  ;
		} else {
			ret = OzStrlen(cmd->class) + OzStrlen(cmd->name) + 2 ;
			if ( (name = OzMalloc( ret )) ) {
				OzSprintf( name,"%s %s",cmd->class,cmd->name ) ;
			}
			argc -- ;
			argv ++ ;
			arg0 = *argv = strAlloc( cmd->name ) ;
		}
		command = cmd->command  ;
	} else {
		command = NULL ;
		name = NULL ;
		arg0 = NULL ;
		strError( ret, argv[0], key.alias == false ? argv[1] : NULL ) ;
	}
	OzExecExitMonitor( &lock ) ;
	if ( command ) {
		result = (*command)( name, argc, argv, sline, eline ) ;
		if ( *argv == NULL ) {
			OzExecEnterMonitor( &lock ) ;
			if ( Search( &key, Root, &cmd ) == 1 ) usage( cmd ) ;
			OzExecExitMonitor( &lock ) ;
		}
	} else result = -1 ;
	strFree( name ) ;
	strFree( arg0 ) ;

	return( result ) ;
}

static	void
shell( int mode, int argc, char *argv[], int sline, int eline )
{
	int	c ;
	char	**v ;
	int	i ;
	int	tty = -1 ;
	char	buf[64] ;

	c = argc ;
	if ( (v = OzMalloc( sizeof(char *) * (argc+1) )) == NULL ) {
		OzError( "%s: OzMalloc(): %m", argv[0] ) ;
		goto error ;
	}
	for ( i = 0 ; i <= argc ; i ++ ) v[i] = argv[i] ;
	if ( 0 <= mode ) {
		OzSprintf( buf, "Shell: %d(%d)",
			OzGetpid(), ThrRunningThread->tid ) ;
		tty = OzCreateKterm( buf, mode ) ;
		if ( tty < 0 ) goto error ;
		OzSetStdIn( tty ) ;
		OzSetStdOut( tty ) ;
		OzSetStdErr( tty ) ;
	}
	if ( c == 2 && OzStrcmp( v[0], "-c" ) == 0 ) OzShell( v[1], &i ) ;
	else action( c, v, sline, eline ) ;
	if ( v ) OzFree( v ) ;

error:
	for ( i = 0 ; i < argc ; i ++ ) strFree( argv[i] ) ;
	if ( argv ) OzFree( argv ) ;
	if ( tty > 0 ) OzClose( tty ) ;
}

static	void
sh( int iconic )
{
	int	tty ;
	int	ret ;
	int	status ;
	char	buf[257] ;

	OzSprintf( buf, "Shell: %d(%d)", OzGetpid(), ThrRunningThread->tid ) ;

#if	0
	tty = OzConsole( "xterm", "-title", buf,
			iconic ? "-iconic" : NULL, NULL ) ;
#else
	tty = OzCreateKterm( buf, iconic ) ;
#endif

	OzSetStdIn( tty ) ;
	OzSetStdOut( tty ) ;
	OzSetStdErr( tty ) ;
	for (;;) {
		OzPrintf( "shell:" ) ;
		ret = OzReadLine( buf, 256 ) ;
		if ( ret < 0 ) {
			OzPrintf( "OzReadLine(): %m\n" ) ;
			ThrExit() ;
		} else if ( ret == 0 ) OzShell( "quit", &status ) ;
		buf[ret] = '\0' ;
		ret = OzShell( buf, &status ) ;
	}
	/* NOT REACHED */

	return ;
}

static	void
thrHandlerSIGINT( int signo, int code, GREGS *gregs, void *addr )
{
	/* CAUTION	SIGINT Deferrable
	 * Debugger refer signo, code, gregs, addr by stack.
	 * Signal handler keep these variables on registers(arguments).
	 */
	ThrPrintf( "%s on thread %d [0x%x]\n", SigName(signo),
			ThrRunningThread->tid, ThrRunningThread ) ;
	if ( gregs ) {
		ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
	}

	ThrFork( (void (*))sh, 0, MAX_PRIORITY, 1, 0 ) ;

	/*
	 * MOST IMPORTANT
	 * Following some lines don't remove becase to must be saved these.
	 */
	ThrPrintf( "RESUME thread %d [0x%x] from %s\n",
		ThrRunningThread->tid, ThrRunningThread, SigName(signo) ) ;
	if ( gregs ) {
		ThrPrintf( "code=%d pc=0x%x sp=0x%x addr=0x%x.\n",
			code, GREGS_PC(*gregs), GREGS_SP(*gregs), addr ) ;
	}
}

int
OzShAppend( char *aClass, char *aName, ShCmd aCommand,
					char *aArgUsage, char *aComment )
{
	int	result = -1 ;
	NodeStr	key ;
	Node	new ;

	key.strict = true ;
	key.alias = false ;
	key.class = aClass ;
	key.name = aName ;
	key.comment = aComment ;
	key.usage = aArgUsage ;
	key.command = aCommand ;

	OzExecEnterMonitor( &lock ) ;
	if ( (new = Insert( &key )) ) {
		result = 0 ;
	} else {
		OzError( "OzShAppend(): Command '%s %s'isn't appended.",
				key.class, key.name ) ;
	}
	OzExecExitMonitor( &lock ) ;

	return( result ) ;
}

int
OzShAlias( char *aClass, char *aName, char *aAlias )
{
	int	result = -1 ;
	int	ret ;
	NodeStr	key ;
	Node	cmd ;
	char	*name = NULL ;

	OzExecEnterMonitor( &lock ) ;

	key.strict = true ;
	key.alias = false ;
	key.class = aClass ;
	key.name = aName ;

	if ( (ret = Search( &key, Root, &cmd )) != 1 ) {
		strError( ret, aClass, aName ) ;
		goto error ;
	}
	name = OzMalloc( OzStrlen(key.class)+OzStrlen(key.name)+2 ) ;
	if ( name == NULL ) {
		OzError( "OzShAlias OzMalloc(): %m." ) ;
		goto error ;
	}
	OzSprintf( name, "%s %s", key.class, key.name ) ;
	key.alias = true ;
	key.class = (char *)aAlias ;
	key.name = name ;
	key.usage = cmd->usage ;
	key.comment = cmd->comment ;
	key.command = cmd->command ;
	if ( (cmd = Insert( &key )) == NULL ) {
		OzError( "OzShAlias(): "
			"Alias '%s'isn't appended.", key.class ) ;
		goto error ;
	}
	result = 0 ;

error:
	if ( name ) OzFree( name ) ;
	OzExecExitMonitor( &lock ) ;

	return( result ) ;
}

ShCmd
OzShRemove( char *aClass, char *aName )
{
	ShCmd	result = NULL ;
	NodeStr	key ;
	Node	old ;

	key.strict = true ;
	key.alias = aName ? false : true ;
	key.class = aClass ;
	key.name = aName ? aName : "" ;

	OzExecEnterMonitor( &lock ) ;
	old = Delete( &key ) ;
	if ( old ) result = old->command ;
	OzExecExitMonitor( &lock ) ;

	return( result ) ;
}

int
OzShell( char *cmdLine, int *status )
{
	int	result = -1 ;
	int	argc ;
	char	**argv ;
	int	sline ;
	int	eline ;
	char	*cbuf ;
	char	*ptr ;
	char	*p ;
	int	i ;
	Thread	t ;

	cbuf = strAlloc( (char *)cmdLine ) ;
	ptr = OzStrcpy( cbuf, cmdLine ) ;
	argv = NULL ;
	while ( *ptr ) {
		argc = parse( &ptr, &argv ) ;
		if ( argc == 0 ) continue ;
		else if ( argc < 0 ) break ;
		if ( *argv[argc-1] == ':' ) {
			p = argv[argc-1] + 1 ;
			sline = OzStrtol( p, &p, 0 ) ;
			if ( *p == ',' ) eline = OzStrtol( p+1, NULL, 0 ) ;
			else eline = 0x7fffffff ;
			argv[argc-1] = NULL ;
			argc -- ;
			if ( argc == 0 ) continue ;
		} else {
			sline = 0 ;
			eline = 0x7fffffff ;
		}
		if ( *argv[argc-1] == '&' && *(argv[argc-1]+1) == '\0' ) {
			argc -- ;
			if ( argc == 0 ) continue ;
			for ( i = 0 ; i < argc ; i ++ ) {
				argv[i] = strAlloc( argv[i] ) ;
			}
			argv[i] = NULL ;
			t = ThrFork( shell, 0, OzGetPriority(),
					5, -1, argc, argv, sline, eline ) ;
			if ( t ) {
				argv = NULL ;
				OzPrintf( "[0x%x] %d\n", t, t->tid ) ;
				result = 0 ;
			} else {
				for ( i = 0 ; i < argc ; i ++ ) {
					strFree( argv[i] ) ;
				}
				OzPrintf( "fork failed.\n" ) ;
			}
		} else {
			*status = action( argc, argv, sline, eline ) ;
			result = 0 ;
		}
	}
	if ( argv ) OzFree( argv ) ;
	strFree( cbuf ) ;

	return( result ) ;
}

static	int
shCmdShell( char *name, int argc, char *argv[], int sline, int eline )
{
	int	c ;
	char	**v ;
	int	i ;

	if ( argc == 1 ) ThrFork( sh, 0, OzGetPriority(), 1, 0 ) ;
	else {
		v = OzMalloc( sizeof(char *) * argc ) ;
		c = argc - 1 ;
		for ( i = 0 ; i < c ; i ++ ) v[i] = strAlloc( argv[i+1] ) ;
		ThrFork( shell, 0, OzGetPriority(), 5, 0, c, v, sline, eline ) ;
	}

	return( 0 ) ;
}

static	int
shCmdHelp( char *name, int argc, char *argv[], int sline, int eline )
{
	int	ret ;
	NodeStr	key ;
	Node	cmd ;

	if ( argc > 3 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	OzExecEnterMonitor( &lock ) ;
	if ( argc <= 1 ) list_classes( Root ) ;
	else if ( argc == 2 ) {
		if ( OzStrcmp( argv[1], "all" ) == 0 ) list( Root ) ;
		else {
			key.strict = false ;
			key.alias = true ;
			key.class = argv[1] ;
			key.name = "" ;
			ret = Search( &key, Root, &cmd ) ;
			if ( ret <= 0 ) {
				key.alias = false ;
				ret = Search( &key, Root, &cmd ) ;
			}
			if ( ret == 1 ) {
				if ( key.alias == true ) usage( cmd ) ;
				else list_class( Root, cmd->class ) ;
			} else strError( ret, argv[1], NULL ) ;
		}
	} else {
		key.strict = false ;
		key.alias = false ;
		key.class = argv[1] ;
		key.name = argv[2] ;
		ret = Search( &key, Root, &cmd ) ;
		if ( ret == 1 ) usage( cmd ) ;
		else strError( ret, argv[1], argv[2] ) ;
	}
	OzExecExitMonitor( &lock ) ;

	return( 0 ) ;
}

static	int
shCmdAlias( char *name, int argc, char *argv[], int sline, int eline )
{
	NodeStr	key ;
	Node	cmd ;
	int	ret ;

	if ( argc == 3 || 5 <= argc ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	OzExecEnterMonitor( &lock ) ;
	if ( argc == 1 ) list_alias( Root ) ;
	else if ( argc == 2 ) {
		key.strict = false ;
		key.alias = true ;
		key.class = argv[1] ;
		key.name = "" ;
		ret = Search( &key, Root, &cmd ) ;
		if ( ret == 1 ) OzPrintf( "%s\n", cmd->name ) ;
		else strError( ret, argv[1], NULL ) ;
	}
	OzExecExitMonitor( &lock ) ;
	if ( argc == 4 ) ret = OzShAlias( argv[2], argv[3], argv[1] ) ;
	else ret = 0 ;

	return( ret ) ;
}

static	int
shCmdEcho( char *name, int argc, char *argv[], int sline, int eline )
{
	int	i ;

	if ( 2 <= argc ) OzPrintf( "%s", argv[1] ) ;
	for ( i = 2 ; i < argc ; i ++ ) {
		OzPrintf( " %s", argv[i] ) ;
	}
	OzPrintf( "\n" ) ;

	return( 0 ) ;
}

static	int
shCmdExec( char *name, int argc, char *argv[], int sline, int eline )
{
	int	ret ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	ret = OzSystem( argv[1], argv+1 ) ;
	if ( ret < 0 ) {
		OzPrintf( "%s: fork failed.\n", name ) ;
		return( ret ) ;
	}

	return( 0 ) ;
}

static	int
shCmdQuit( char *name, int argc, char *argv[], int sline, int eline )
{
	int	stdIn = OzGetStdIn() ;
	int	stdOut = OzGetStdOut() ;
	int	stdErr = OzGetStdErr() ;

	OzClose( stdIn ) ;
	if ( stdIn != stdOut ) OzClose( stdOut ) ;
	if ( stdIn != stdErr ) OzClose( stdErr ) ;
	if ( stdIn != stdErr && stdOut != stdErr ) OzClose( stdErr ) ;
	ThrExit() ;
	/* NOT REACHED */

	return( 0 ) ;
}

static	int
thrCmdYield( char *name, int argc, char *argv[], int sline, int eline )
{
	if ( argc != 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	ThrYield() ;

	return( 0 ) ;
}

static	int
thrCmdSleep( char *name, int argc, char *argv[], int sline, int eline )
{
	int	seconds ;

	if ( argc >= 3 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2 ) {
		seconds = OzStrtol( argv[1], NULL, 0 ) ;
		if ( seconds <= 0 ) {
			*argv = NULL ;
			return( -1 ) ;
		}
	} else seconds = 1 ;

	ThrSleep( seconds ) ;

	return( 0 ) ;
}

static	int
thrCmdList( char *name, int argc, char *argv[], int sline, int eline )
{
	int	lines[3] ;

	if ( argc != 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	lines[0] = sline ;
	lines[1] = 0 ;
	lines[2] = eline ;
	ThrMapTable( print_status, lines ) ;

	return( lines[1] ) ;
}

static	int
thrCmdSuspend( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.f = ThrSuspend ;
	for ( i = 1 ; i < argc ; i ++ ) {
		key.tid = OzStrtol( argv[i], NULL, 0 ) ;
		key.t = NULL ;
		key.s = 0 ;
		ThrMapTable( operate, &key ) ;
		if ( ! key.t ) OzPrintf( "%d: No such thread\n", key.tid ) ;
		if ( key.s < 0 ) OzPrintf( "%d: Can't suspend\n", key.tid ) ;
	}

	return( 0 ) ;
}

static	int
thrCmdResume( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.f = ThrResume ;
	for ( i = 1 ; i < argc ; i ++ ) {
		key.tid = OzStrtol( argv[i], NULL, 0 ) ;
		key.t = NULL ;
		key.s = 0 ;
		ThrMapTable( operate, &key ) ;
		if ( ! key.t ) OzPrintf( "%d: No such thread\n", key.tid ) ;
		if ( key.s < 0 ) OzPrintf( "%d: Can't Resume\n" ) ;
	}

	return( 0 ) ;
}

static	int
thrCmdKill( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.f = ThrKill ;
	for ( i = 1 ; i < argc ; i ++ ) {
		key.tid = OzStrtol( argv[i], NULL, 0 ) ;
		key.t = NULL ;
		key.s = 0 ;
		ThrMapTable( operate, &key ) ;
		if ( ! key.t ) OzPrintf( "%d: No such thread\n", key.tid ) ;
		if ( key.s < 0 ) OzPrintf( "%d: Can't Kill\n" ) ;
	}

	return( 0 ) ;
}

static	int
thrCmdAbort( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.f = ThrAbortThread ;
	for ( i = 1 ; i < argc ; i ++ ) {
		key.tid = OzStrtol( argv[i], NULL, 0 ) ;
		key.t = NULL ;
		key.s = 0 ;
		ThrMapTable( operate, &key ) ;
		if ( ! key.t ) OzPrintf( "%d: No such thread\n", key.tid ) ;
		if ( key.s < 0 ) OzPrintf( "%d: Can't Abort\n" ) ;
	}

	return( 0 ) ;
}

static	int
thrCmdStop( char *name, int argc, char *argv[], int sline, int eline )
{
	int	status ;
	char	buf[256] ;

	if ( argc >= 3 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2 ) status = OzStrtol( argv[1], NULL, 0 ) ;
	else status = 0 ;

	OzPrintf( "%s: Realy (yes)?", name ) ;
	if ( OzReadLine( buf, 256 ) != 1 ) return( -2 ) ;

	ThrStop( status ) ;
	/* NOT REACHED */

	return( 0 ) ;
}

static	int
thrCmdNice( char *name, int argc, char *argv[], int sline, int eline )
{
	int	nice ;
	int	prio ;

	if ( argc >= 3 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2 ) nice = OzStrtol( argv[0], 0, 0 ) ;
	else nice = 1 ;
	prio = OzGetPriority() ;
	prio -= nice ;
	OzSetPriority( prio ) ;

	return( 0 ) ;
}

static	int
thrCmdIdle( char *name, int argc, char *argv[], int sline, int eline )
{
	int	seconds ;
	int	idle ;

	if ( argc >= 3 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2 ) {
		seconds = OzStrtol( argv[1], NULL, 0 ) ;
		if ( seconds <= 0 ) {
			*argv = NULL ;
			return( -1 ) ;
		}
	} else seconds = 1 ;

	idle = ThrIdle( seconds ) ;
	OzPrintf( "%d\n", idle ) ;

	return( 0 ) ;
}

static	int
thrCmdChkstk( char *name, int argc, char *argv[], int sline, int eline )
{
	int	lines[3] ;

	if ( argc != 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	lines[0] = sline ;
	lines[1] = 0 ;
	lines[2] = eline ;
	ThrMapTable( check_stack, NULL ) ;
	return( lines[1] ) ;
}

static	int
thrCmdMonitor( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	lines[3] ;

	if ( argc != 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	lines[0] = sline ;
	lines[1] = 0 ;
	lines[2] = eline ;
	key.tid = OzStrtol( argv[1], NULL, 0 ) ;
	key.t = NULL ;
	key.s = 0 ;
	key.lines = lines ;
	ThrMapTable( print_monitor, &key ) ;
	return( 0 ) ;
}

static	int
thrCmdCondition( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	lines[3] ;

	if ( argc != 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	lines[0] = sline ;
	lines[1] = 0 ;
	lines[2] = eline ;
	key.tid = OzStrtol( argv[1], NULL, 0 ) ;
	key.t = NULL ;
	key.s = 0 ;
	key.lines = lines ;
	ThrMapTable( print_condition, &key ) ;
	return( 0 ) ;
}

static	int
brkCmdList( char *name, int argc, char *argv[], int sline, int eline )
{
	if ( argc != 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( BrkMap( print_break, NULL ) == 0 ) {
		OzPrintf( "No breakpoints\n" ) ;
	}

	return( 0 ) ;
}

static	int
brkCmdBreak( char *name, int argc, char *argv[], int sline, int eline )
{
	u_long		addr ;
	BrkPoint	bp ;

	if ( argc != 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	addr = OzStrtoul( argv[1], NULL, 0 ) ;
	bp = BrkInsert( addr ) ;
	if ( bp == NULL ) {
		OzPrintf( "%s: Can't set breakpoint at 0x%x.\n", name, addr ) ;
		return( -1 ) ;
	} else {
		OzPrintf( "breakpoint %d at 0x%x.\n", bp->bid, addr ) ;
		return( 0 ) ;
	}
}

static	int
brkCmdClear( char *name, int argc, char *argv[], int sline, int eline )
{
	u_long		addr ;

	if ( argc != 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	addr = OzStrtoul( argv[1], NULL, 0 ) ;
	if ( BrkClear( addr ) < 0 ) {
		OzPrintf( "%s: Can't clear breakpoint at 0x%x.\n",name,addr ) ;
		return( -1 ) ;
	}
	return( 0 ) ;
}

static	int
brkCmdDelete( char *name, int argc, char *argv[], int sline, int eline )
{
	int	bid ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	for ( i = 1 ; i < argc ; i ++ ) {
		bid = OzStrtol( argv[i], NULL, 0 ) ;
		if ( BrkDelete( bid ) ) {
			OzPrintf("%s: Can't delete breakpoint %d.\n",name,bid);
			return( -1 ) ;
		}
	}
	return( 0 ) ;
}

static	int
brkCmdEnable( char *name, int argc, char *argv[], int sline, int eline )
{
	int	bid ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	for ( i = 1 ; i < argc ; i ++ ) {
		bid = OzStrtol( argv[i], NULL, 0 ) ;
		if ( BrkEnable( bid ) ) {
			OzPrintf("%s: Can't enable breakpoint %d.\n",name,bid);
			return( -1 ) ;
		}
	}
	return( 0 ) ;
}

static	int
brkCmdDisable( char *name, int argc, char *argv[], int sline, int eline )
{
	int	bid ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	for ( i = 1 ; i < argc ; i ++ ) {
		bid = OzStrtol( argv[i], NULL, 0 ) ;
		if ( BrkDisable( bid ) ) {
			OzPrintf("%s: Can't disable breakpoint %d.\n",name,bid);
			return( -1 ) ;
		}
	}
	return( 0 ) ;
}

static	int
brkCmdContinue( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.f = BrkContinue ;
	for ( i = 1 ; i < argc ; i ++ ) {
		key.tid = OzStrtol( argv[i], NULL, 0 ) ;
		key.t = NULL ;
		key.s = 0 ; 
		ThrMapTable( operate, &key ) ;
		if ( key.t == NULL ) OzPrintf("%d: No such thread.\n",key.tid) ;
		else if ( key.s ) OzPrintf("%d: Can't continue.\n", key.tid ) ;
	}

	return( 0 ) ;
}

static	int
thrCmdDebug( char *name, int argc, char *argv[], int sline, int eline )
{
	int	debug = -1 ;

	if ( argc > 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2  ) {
		if ( OzStrcmp( argv[1], "on" ) == 0
			|| OzStrcmp( argv[1], "1" ) == 0 ) debug = 1 ;
		if ( OzStrcmp( argv[1], "off" ) == 0
			|| OzStrcmp( argv[1], "0" ) == 0 ) debug = 0 ;
		if ( debug < 0 ) {
			*argv = NULL ;
			return( -1 ) ;
		}
		if ( OzGetDebug() == debug ) OzPrintf( "Already" ) ;
		else {
			OzPrintf( "Set" ) ;
			OzSetDebug( debug ) ;
		}
	} else {
		debug = OzGetDebug() ;
		OzPrintf( "Now" ) ;
	}
	OzPrintf( " debug message %s\n", debug ? "on" : "off" ) ;

	return( 0 ) ;
}

static	int
thrCmdTick( char *name, int argc, char *argv[], int sline, int eline )
{
	int	vticks ;
	int	iticks ;

	if ( argc > 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2  ) {
		iticks = OzStrtol( argv[1], NULL, 0 ) ;
		OzPrintf( "Set" ) ;
		vticks = SigClockTicks ;
		SigUalarm( vticks, iticks ) ;
	} else OzPrintf( "Now" ) ;
	OzPrintf( " ticks %d(/second)\n", SigClockTicks ) ;

	return( 0 ) ;
}

static	void
dump_frame( frame_t *sp )
{
	OzPrintf( "local: %08x %08x %08x %08x %08x %08x %08x %08x\n",
			sp->r_l0, sp->r_l1, sp->r_l2, sp->r_l3,
			sp->r_l4, sp->r_l5, sp->r_l6, sp->r_l7 ) ;
	OzPrintf( "in   : %08x %08x %08x %08x %08x %08x %08x %08x\n",
			sp->r_i0, sp->r_i1, sp->r_i2, sp->r_i3,
			sp->r_i4, sp->r_i5, sp->r_i6, sp->r_i7 ) ;
	OzPrintf( "out  : %08x %08x %08x %08x %08x %08x %08x %08x\n",
			sp->r_o0, sp->r_o1, sp->r_o2, sp->r_o3,
			sp->r_o4, sp->r_o5, sp->r_o6, sp->r_o7 ) ;
}

static	int
dump_stack( Thread t )
{
	int	signo ;
	int	code ;
	GREGS	*gregs ;
	void	*pc ;
	frame_t	*sp ;
	frame_t	*fp ;
	void	*addr = NULL ;

	if ( t == ThrRunningThread ) {
		OzError( "thread %d Running.", t->tid ) ;
		return( -1 ) ;
	}

#if	defined(SVR4)
	pc = (void *)t->context[2] ;
	sp = (frame_t *)t->context[1] ;
#else	/* SVR4 */
	pc = (void *)t->context[3] ;
	sp = (frame_t *)t->context[2] ;
#endif	/* SVR4 */

	if ( SIGSTACK_FLAGS(t->signal_stack) ) {
		fp = (frame_t *)sp->r_i6 ;
		signo = fp->r_i0 ;
		code = fp->r_i1 ;
		gregs = (GREGS *)fp->r_i2 ;
		if ( gregs ) {
			pc = (void *)GREGS_PC(*gregs) ;
			sp = (frame_t *)GREGS_SP(*gregs) ;
		}
		addr = (void *)fp->r_i3 ;
		OzPrintf( "%s(%s) addr:%08x ",
			SigName( signo ), SigDetail( signo, code ), addr ) ;
	}

	OzPrintf( "pc:%08x sp:%08x\n", pc, sp ) ;
	for (;;) {
		if ( t->stack_bottom < (caddr_t)sp ) {
			OzPrintf( "STACK UNDERFLOW\n" ) ;
			break ;
		}
		if ( (caddr_t)sp < t->stack ) {
			OzPrintf( "STACK OVERFLOW\n" ) ;
			break ;
		}
		dump_frame( sp ) ;
		pc = (void *)sp->r_i7 ;
		sp = (frame_t *)sp->r_i6 ;
		if ( sp->r_i6 == 0 ) break ;
		OzPrintf( "pc:%08x sp:%08x\n", pc+8, sp ) ;
	}
	return( 0 ) ;
}

static	int
thrCmdFrame( char *name, int argc, char *argv[], int sline, int eline )
{
	TKey	key ;
	int	i ;

	if ( argc <= 1 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	key.f = dump_stack ;
	for ( i = 1 ; i < argc ; i ++ ) {
		key.tid = OzStrtol( argv[i], NULL, 0 ) ;
		key.t = NULL ;
		key.s = 0 ; 
		ThrMapTable( operate, &key ) ;
		if ( key.t == NULL ) OzPrintf("%d: No such thread.\n",key.tid) ;
		else if ( key.s ) OzPrintf("%d: Can't print.\n", key.tid ) ;
	}

	return( 0 ) ;
}

static	int
infCmdCore( char *name, int argc, char *argv[], int sline, int eline )
{
	OzPrintf( "Core etext:0x%x, edata:0x%x, end:0x%x(0x%x)\n",
			&etext, &edata, &end, sbrk(0) ) ;
	return( 0 ) ;
}

int
ShInit()
{
	OzInitializeMonitor( &lock ) ;

	Root = NULL ;

	/* Builtin shell commands */
	OzShAppend( "shell", "", NULL, "", "Builtin shell commands" ) ;
	OzShAppend( "shell", "shell", shCmdShell,
			"<command>",
			"Fork new thread and terminal for shell" ) ;
	OzShAppend( "shell", "help", shCmdHelp,
			"[<class> [<name>]]",
			"Print commands" ) ;
	OzShAppend( "shell", "alias", shCmdAlias,
			"<name> <class> <command>",
			"Assign <class> <command> to the alias <name>" ) ;
	OzShAppend( "shell", "echo", shCmdEcho,
			"...",
			"Echo argumetns" ) ;
	OzShAppend( "shell", "exec", shCmdExec,
			"<unix command>",
			"Executoe the first argument as <unix command>" ) ;
	OzShAppend( "shell", "quit", shCmdQuit,
			"",
			"Quit shell" ) ;
	OzShAlias( "shell", "shell",	"sh" ) ;
	OzShAlias( "shell", "help",	"help" ) ;
	OzShAlias( "shell", "alias",	"alias" ) ;
	OzShAlias( "shell", "echo",	"echo" ) ;
	OzShAlias( "shell", "exec",	"exec" ) ;
	OzShAlias( "shell", "quit",	"quit" ) ;

	/* Thread operation commands */
	OzShAppend( "thread", "", NULL, "", "Thread operation commands" ) ;
	OzShAppend( "thread", "yield", thrCmdYield,
			"",
			"Yield execution to another thread" ) ;
	OzShAppend( "thread", "sleep", thrCmdSleep,
			"[<time>]",
			"Suspend execution for <time> seconds" ) ;
	OzShAppend( "thread", "list", thrCmdList,
			"",
			"Print status of threads" ) ;
	OzShAppend( "thread", "suspend", thrCmdSuspend,
			"<thread id> [<thread id> [...]]",
			"Suspend execution of threads" ) ;
	OzShAppend( "thread", "resume", thrCmdResume,
			"<thread id> [<thread id> [...]]",
			"Resume execution of threads" ) ;
	OzShAppend( "thread", "kill", thrCmdKill,
			"<thread id> [<thread id> [...]]",
			"Link suspended thread to free list" ) ;
	OzShAppend( "thread", "abort", thrCmdAbort,
			"<thread id> [<thread id> [...]]",
			"Set abort flag of threads" ) ;
	OzShAppend( "thread", "stop", thrCmdStop,
			"[<status>]",
			"Stop scheduler with the <status>" ) ;
	OzShAppend( "thread", "nice", thrCmdNice,
			"[<number>]",
			"Set current thread's priority" ) ;
	OzShAppend( "thread", "idle", thrCmdIdle,
			"[<time>]",
			"Count executoion of idle thread for <time> seconds" ) ;
	OzShAppend( "thread", "chkstk", thrCmdChkstk,
			"",
			"Check stack rest size of all threads" ) ;
	OzShAppend( "thread", "monitor", thrCmdMonitor,
			"<thread id>",
			"Print threads to wait same monitor" ) ;
	OzShAppend( "thread", "condition", thrCmdCondition,
			"<thread id>",
			"Print threads to wait same condition" ) ;
	OzShAppend( "thread", "frame", thrCmdFrame,
			"<thread id>",
			"Print all stack frame of <thread id>" ) ;

	OzShAlias( "thread", "yield",		"yield" ) ;
	OzShAlias( "thread", "sleep",		"sleep" ) ;
	OzShAlias( "thread", "list",		"ts" ) ;
	OzShAlias( "thread", "suspend",		"suspend" ) ;
	OzShAlias( "thread", "resume",		"resume" ) ;
	OzShAlias( "thread", "kill",		"kill" ) ;
	OzShAlias( "thread", "abort",		"abort" ) ;
	OzShAlias( "thread", "stop",		"stop" ) ;
	OzShAlias( "thread", "stop",		"exit" ) ;
	OzShAlias( "thread", "nice",		"nice" ) ;
	OzShAlias( "thread", "idle",		"idle" ) ;
	OzShAlias( "thread", "chkstk",		"cs" ) ;
	OzShAlias( "thread", "monitor",		"monitor" ) ;
	OzShAlias( "thread", "condition",	"condition" ) ;

	/* Breakpoint commands */
	OzShAppend( "breakpoint", "", NULL, "", "Breakpoint commands" ) ;
	OzShAppend( "breakpoint", "list", brkCmdList,
			"",
			"Print all breakpoints" ) ;
	OzShAppend( "breakpoint", "break", brkCmdBreak,
			"<address>",
			"Set breakpoint at <address>" ) ;
	OzShAppend( "breakpoint", "clear", brkCmdClear,
			"<address>",
			"Clear all breakpoint at <address>" ) ;
	OzShAppend( "breakpoint", "enable", brkCmdEnable,
			"<breakpoint id>",
			"Enable breakpoint" ) ;
	OzShAppend( "breakpoint", "disable", brkCmdDisable,
			"<breakpoint id>",
			"Disable breakpoint" ) ;
	OzShAppend( "breakpoint", "delete", brkCmdDelete,
			"<breakpoint id>",
			"Delete breakpoint" ) ;
	OzShAppend( "breakpoint", "continue", brkCmdContinue,
			"<thread id>",
			"Continue execution <thread id> from breakpoint" ) ;

	OzShAlias( "breakpoint", "list",	"breaks" ) ;
	OzShAlias( "breakpoint", "break",	"break" ) ;
	OzShAlias( "breakpoint", "clear",	"clear" ) ;
	OzShAlias( "breakpoint", "enable",	"enable" ) ;
	OzShAlias( "breakpoint", "disable",	"disable" ) ;
	OzShAlias( "breakpoint", "delete",	"delete" ) ;
	OzShAlias( "breakpoint", "continue",	"continue" ) ;
	
	OzShAppend( "set", "", NULL, "", "Set parameter commands" ) ;
	OzShAppend( "set", "debug", thrCmdDebug, "[on|off]",
			"Set debug message on/off" ) ;
	OzShAppend( "set", "tick", thrCmdTick, "[<ticks>]",
			"Set tick <ticks>(/second)" ) ;

	OzShAppend( "info", "", NULL, "", "Information commands" ) ;
	OzShAppend( "info", "core", infCmdCore,
		"", "Print executor core address" ) ;

	SigAction( SIGINT, thrHandlerSIGINT ) ;

	return( 0 ) ;
}
