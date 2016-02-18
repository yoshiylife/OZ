/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* CAUTION */
/* このファイルではニュークリアス関連の関数を定義し、
 * 他のファイルのニュークリアスへの依存を排除する
 * ことを目的としている。
 */
#include	<stdio.h>
#include	<signal.h>
#include	<sys/utsname.h>
#include	<arpa/inet.h>
#include	<netdb.h>
#include	<memory.h>
#include	<errno.h>
#include	"ncl.h"

#define	DEBUG
#include "ncl/ncl_defs.h"
#include "ncl/ex_ncl_event.h"
#include "ncl/ncl_debugger.h"

/* #define	TEST */

#define	NG	(-1)
#define	OK	0
#define	TIMEOUT	10
#define	NCL_SERVNAME	NULL

/* debug */
#undef	DSP_NCLADDR
#undef	DSP_DMADDR
#undef	DSP_DMPEER

static	char	*NclServName = NCL_SERVNAME ;

static	struct	{
		int	status ;
	struct	utsname	name ;
	struct	in_addr	addr ;
} MyHost = { NG } ;

#if	defined(DSP_NCLADDR)||defined(DSP_DMADDR)||defined(DSP_DMPEER)
static	void
dspAddr( struct sockaddr *addr )
{
	struct sockaddr_in	*in ;
	struct sockaddr_un	*un ;

	if ( addr->sa_family == AF_UNIX ) {
		un = (struct sockaddr_un *)addr ;
		printf( "sun_family  : AF_UNIX\n" ) ;
		printf( "sun_path: %s\n", un->sun_path ) ;
	} else if ( addr->sa_family == AF_INET ) {
		in = (struct sockaddr_in *)addr ;
		printf( "sin_family  : AF_INET\n" ) ;
		printf( "sin_port: %u\n", in->sin_port ) ;
		printf( "sin_addr: %u %u %u %u\n",
				in->sin_addr.S_un.S_un_b.s_b1,
				in->sin_addr.S_un.S_un_b.s_b2,
				in->sin_addr.S_un.S_un_b.s_b3,
				in->sin_addr.S_un.S_un_b.s_b4
				) ;
	} else {
		in = (struct sockaddr_in *)addr ;
		printf( "family  : Unknown<%d>\n", addr->sa_family ) ;
		printf( "sin_family  : AF_INET\n" ) ;
		printf( "sin_port: %u\n", in->sin_port ) ;
		printf( "sin_addr: %u %u %u %u\n",
				in->sin_addr.S_un.S_un_b.s_b1,
				in->sin_addr.S_un.S_un_b.s_b2,
				in->sin_addr.S_un.S_un_b.s_b3,
				in->sin_addr.S_un.S_un_b.s_b4
				) ;
	}
}
#endif


static	int
setMyHost()
{
	struct	hostent		*host ;

	if ( uname( &MyHost.name ) < 0 ) {
		/* error */
		perror( "uname" ) ;
		return( NG ) ;
	}

	host = gethostbyname( MyHost.name.nodename ) ;
	if ( host == NULL ) {
		/* error */
		perror( "gethostbyname" ) ;
		return( NG ) ;
	} else MyHost.addr = *((struct in_addr *)(host->h_addr)) ;

	MyHost.status = OK ;

	return( OK ) ;
}


int
OpenNcl( const char *aNclHostName )
{

	int	port ;
	struct	sockaddr_in	NclAddr ;
	struct	hostent		*nclHost ;
	struct	servent		*nclServ ;

	NclAddr.sin_family = AF_INET ;

	if ( NclServName != NULL ) {
		nclServ = getservbyname( NclServName, "tcp" ) ;
		if ( nclServ == NULL ) {
			/* error */
			perror( "getservbyname" ) ;
			return( NG ) ;
		}
		NclAddr.sin_port = nclServ->s_port ;
	} else {
		NclAddr.sin_port = (unsigned short)PROVISIONAL_PORT ;
	}

	if ( aNclHostName == NULL ) {
		if ( MyHost.status == NG ) setMyHost() ;
		aNclHostName = MyHost.name.nodename ;
	}

	nclHost = gethostbyname( aNclHostName ) ;
	if ( nclHost == NULL ) {
		/* try */
		NclAddr.sin_addr.s_addr = inet_addr( aNclHostName ) ;
		if ( NclAddr.sin_addr.s_addr <= 0 ) {
			/* error */
			perror( "gethostbyname" ) ;
			return( NG ) ;
		}
	} else NclAddr.sin_addr.s_addr = ((struct in_addr *)(nclHost->h_addr))->s_addr ;

#if	defined(DSP_NCLADDR)
	printf( "Nucleus Service Address\n" ) ;
	dspAddr( (struct sockaddr *)&NclAddr ) ;
#endif

	port = socket( NclAddr.sin_family , SOCK_STREAM, IPPROTO_TCP ) ;
	if ( port < 0 ) {
		/* error */
		perror( "socket" ) ;
		return( NG ) ;
	}

	if ( connect( port, (struct sockaddr *)&NclAddr, sizeof(NclAddr) ) ) {
		/* error */
		perror( "connect" ) ;
		return( NG ) ;
	}

	return( port ) ;
}


int
CloseNcl( int aPort )
{
	if ( shutdown( aPort, 2 ) ) perror( "shutdown" ) ;
	if ( close(aPort) ) perror( "close" ) ;
	return( OK ) ;
}


static	void
timeOutHandler()
{
	fprintf( stderr, "NCL response TIME OUT !!\n" ) ;
}


int
CallNcl( int aNclPort, long long aExid, struct sockaddr_in *aInetAddr )
{
	int	ret ;
	char	*ptr ;
	struct	sigaction	act ;
	EventDataRec		packet ;
	DebugMent		debug ;

	memset( (char *)&packet, 0, sizeof(packet) ) ;
	packet.head.arch_id	= SPARC ;
	packet.head.event_num	= NCL_DEBUGGER_COMM ;
	packet.head.req_nclid	= MyHost.addr.s_addr ;
	packet.head.req_uid	= getuid() ;

	debug = (DebugMent)packet.data.data ;
	debug->deb_comm		= DEBUG_CONNECT ;
	ret = send( aNclPort, (char *)&packet, SZ_EventData, 0 ) ;
	if ( ret != SZ_EventData ) {
		/* error */
		perror( "send" ) ;
		return( NG ) ;
	}

	debug->deb_comm		= DEBUG_SOLUTADDR ;
	debug->data.so_addr.unknown_exid = aExid & 0xffffffffff000000ll;
	ret = send( aNclPort, (char *)&packet, SZ_EventData, 0 ) ;
	if ( ret != SZ_EventData ) {
		/* error */
		perror( "send" ) ;
		return( NG ) ;
	}

	act.sa_handler = timeOutHandler ;
	sigfillset( &act.sa_mask ) ;
#if	defined(SA_INTERRUPT)
	act.sa_flags = SA_RESETHAND | SA_INTERRUPT ;
#else
	act.sa_flags = SA_RESETHAND ;
#endif
	if ( sigaction( SIGALRM, &act, NULL ) ) {
		/* error */
		perror( "sigvec" ) ;
		return( NG ) ;
	}
	alarm( TIMEOUT ) ;
	ret = recv( aNclPort, (char *)&packet, SZ_EventData, 0 ) ;
	if ( ret != SZ_EventData ) {
		/* error */
		if ( errno != EINTR ) perror( "recv" ) ;
		return( NG ) ;
	}
	alarm( 0 ) ;
	if ( signal( SIGALRM, SIG_DFL ) == SIG_ERR ) {
		/* error */
		perror( "signal" ) ;
		return( NG ) ;
	}

	ptr = (char *)&packet.data.so_addr.address ;

#if	defined(DSP_DMADDR)
	printf( "DebugManager Service Address on Ex:0x%08x%08x\n",
		(u_long)(0xffffffff&(aExid>>32)), (u_long)(0xffffffff&aExid) ) ;
	dspAddr( (struct sockaddr *)ptr ) ;
#endif

	memcpy( (char *)aInetAddr, ptr, sizeof(struct sockaddr_in) ) ;
	aInetAddr->sin_port ++ ;

	if ( MyHost.status == NG ) setMyHost() ;
	return( MyHost.addr.s_addr == aInetAddr->sin_addr.s_addr ? 0 : 1 ) ;
}


#if	defined(TEST)

#include	<stdlib.h>
#include	<string.h>

int
echo( struct sockaddr *aAddr )
{
	int		port ;
	struct	{
			int	request ;
			int	size ;
			char	buf[12] ;
		} data ;
	char	*test = "0123456789" ;

	port = socket( aAddr->sa_family, SOCK_STREAM, (aAddr->sa_family==AF_INET)?IPPROTO_TCP:0 ) ;
	if ( port < 0 ) {
		/* error */
		perror( "socket" ) ;
		return( NG ) ;
	}

	if ( connect( port, aAddr, sizeof(*aAddr) ) ) {
		/* error */
		perror( "connect" ) ;
		return( NG ) ;
	}

#if	defined(DSP_DMPEER)
{
	int	i ;
struct sockaddr	addr ;
	printf( "DebugManager Peer Address\n" ) ;
	i = sizeof(addr) ;
	memset( &addr, 0, i ) ;
	if ( getsockname( port, &addr, &i ) >= 0 ) dspAddr( &addr ) ;
	else perror("getsockname");
}
#endif


	data.request = 0 ;
	data.size = 11 ;
	strcpy( data.buf, test ) ;

	printf( "send: %s\n", data.buf ) ;

	if( write( port, &data, sizeof(data) ) < 0 ) {
		perror( "write" ) ;
		return( OK ) ;
	}

	memset( data.buf, 0 , 12 ) ;

	if( read( port, &data, sizeof(data) ) < 0 ) {
		perror( "read" ) ;
		return( OK ) ;
	}

	printf( "recv: %s\n", data.buf ) ;

	return( OK ) ;
}


void
Usage( const char *aCmdName )
{
	fprintf( stderr, "Usage: %s [-a <host>] [-s <siteID>] <ExID>\n", aCmdName ) ;
	exit( 1 ) ;
}


int
main(int argc, char *argv[])
{
extern	char	*optarg ;
extern	int	optind, opterr ;
	int	nclPort ;
	char	*cmdName ;
	char	*nclHost = NULL ;
	char	ch, *ptr ;
	int	err = 0 ;
long	long	ll ;
long	long	id = 0x0001000000000000LL ;
struct sockaddr	addr ;
	char	buf[256] ;


	for ( ptr = argv[0] + strlen( argv[0] ) ; ptr != argv[0] ; -- ptr ) {
		if ( *ptr == '/' ) {
			++ ptr ;
			break ;
		}
	}
	cmdName = ptr ;

	while ( (ch=getopt( argc, argv, "a:hs:" )) != EOF ) {
		switch( ch ) {
		case 'a' :
			nclHost = optarg ;
			break ;
		case 'h' :
			err ++ ;
			break ;
		case 's' :
			id = (long long)strtol( optarg, NULL, 0 ) ;
			id <<= 48 ;
			break ;
		default :
			fprintf( stderr, "Unknown option '%c'\n", ch ) ;
			err ++ ;
		}
		if ( err ) break ;
	}

	if ( err || argc <= 1 || argc != (optind+1) ) Usage( cmdName ) ;

	ll = (long long)strtol( argv[optind], NULL, 0 ) ;
	id |= (ll<<24) ;

	printf( "Connect Executor 0x%08x%08x\n",
			(u_long)(0xffffffff&(id>>32)), (u_long)(0xffffffff&id) ) ;

	if ( (nclPort=openNcl( nclHost )) < 0 ) {
		fprintf( stderr, "openNcl error !!\n" ) ;
		exit( 2 ) ;
	}

	if ( callNcl( nclPort, id, &addr ) < 0 ) {
		closeNcl( nclPort ) ;
		fprintf( stderr, "callNcl error !!\n" ) ;
		exit( 2 ) ;
	}

	if ( echo( &addr ) < 0 ) fprintf( stderr, "echo error !!\n" ) ;

	printf( "HIT RETURN KEY !!\n" ) ;
	gets( buf ) ;

	closeNcl( nclPort ) ;

	return( 0 ) ;
}

#endif	TEST
