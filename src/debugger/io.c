/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<unistd.h>
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<signal.h>
#include	<fcntl.h>
#include	<sys/param.h>
#include	<memory.h>
#include	<malloc.h>
#include	<errno.h>
#include	"debugChannel.h"
#include	"debugFunction.h"
#include	"id.h"
#include	"io.h"
#include	"ncl.h"
#include	<arpa/inet.h>
#include	<netdb.h>
#include	"oz++/type.h"

#undef	TEST

#if	defined(TEST)
#define	UNIX_PATHFMT	"/tmp/Dm%06xunix"
#else
#define	UNIX_PATHFMT	"/tmp/Dm%06x"
#endif
#define	WISH		"/usr/local/tcl7.3/bin/wish"
#define	LOOP	for(;;)
#define	OK	0
#define	NG	(-1)

extern	char	*OzRoot ;
extern	int	Mode ;

extern	void	Errorf( char *aFormat, ... ) ;

struct	Address		{
	int	domain ;
	int	proto ;
	int	size ;
	union	{
		struct	sockaddr	sa ;
		struct	sockaddr_un	un ;
		struct	sockaddr_in	in ;
	} addr ;
} ;

struct	Address	Server = { AF_UNIX } ;
BufferRec	SendBuffer = { 1024, NULL } ;
BufferRec	RecvBuffer = { 1024, NULL } ;
char		*OwnerIdent = NULL ;
char		*IPaddress = NULL ;
char		*PortNumber = NULL ;

int	Copy( const char *aSrcPath, const char *aDstPath ) ;

void
SigPipeHandler()
{
	Errorf( "Broken socket !!\n" ) ;
}

#if	0
int
OwnerDM( char *aOwner, char *aPort )
{
	int	port ;

	if ( aPort != NULL ) {
		struct	hostent	*host ;
		struct	utsname	name ;
		if ( aOwner == NULL ) {
			uname( &name ) ;
			aOwner = name.nodename ;
		}
		Server.domain = AF_INET ;
		Server.proto = IPPROTO_TCP ;
		Server.addr.in.sin_family = AF_INET ;
		if ( (host=gethostbyname(aOwner)) != NULL ) {
			Server.addr.in.sin_addr.s_addr = ((struct in_addr *)(host->h_addr))->s_addr ;
		} else Server.addr.in.sin_addr.s_addr = inet_addr( aOwner ) ;
                Server.addr.in.sin_port = (short)strtol( aPort, NULL, 0 ) ;
		Server.size = sizeof(Server.addr.in) ;
	} else {
		int	exid = strtol( aOwner, NULL, 0 ) ;
		Server.domain = AF_UNIX ;
		Server.proto = 0 ;
		Server.addr.un.sun_family = AF_UNIX ;
		sprintf( Server.addr.un.sun_path, UNIX_PATHFMT, exid ) ;
		Server.size = sizeof(Server.addr.un.sun_family) + strlen(Server.addr.un.sun_path) ;
	}

	port = socket( Server.domain, SOCK_STREAM, Server.proto ) ;
	if ( port < 0 ) {
		perror( "socket" ) ;
		Errorf( "Can't socket for owner port !!\n" ) ;
		goto error ;
	} else if ( connect( port, (struct sockaddr *)&Server.addr, Server.size ) ) {
		perror( "connect" ) ;
		Errorf( "Can't connect owner !!\n" ) ;
		close( port ) ;
		port = NG ;
		goto error ;
	}

/*
	if ( RequestDM( port, DM_EXECID, NULL, 0 ) != 0 ) {
		Errorf( "Error request(DM_EXECID) to DM !!\n" ) ;
		close( port ) ;
		port = NG ;
		goto error ;
	}
	if ( AnswerDM( port, NULL, &ownerID, NULL ) == NULL ) {
		Errorf( "Can't get executor id from %s@%s !!\n", aOwner, (aPort==NULL)?"Local":aPort ) ;
		close( port ) ;
		port = NG ;
		goto error ;
	}
*/

error:
	return( port ) ;
}

int
OpenDM( OID aObjectID )
{
	static	int	init_flag = 0 ;
		int	ret = NG ;
		int	size ;
		int	port ;
		int	owner = NG ;
		OID	exid ;
	struct	Address	net ;

	if ( init_flag == 0 ) {
		signal( SIGPIPE, SigPipeHandler ) ;
		init_flag = 1 ;
	}

	if ( OwnerIdent != NULL ) owner = OwnerDM( OwnerIdent, NULL ) ;
	else {
		if ( PortNumber != NULL ) owner = OwnerDM( IPaddress, PortNumber ) ;
		else if ( EXECID(aObjectID) != 0 ) {
			char	buf[64] ;
			sprintf( buf, "0x%06x", EXECID(aObjectID) ) ;
			owner = OwnerDM( buf, NULL ) ;
		}
	}
	if ( owner < 0 ) goto error ;
	if ( RequestDM( owner, DM_EXECID, NULL, 0 ) != 0 ) {
		Errorf( "Error request(DM_EXECID) to DM !!\n" ) ;
		close( owner ) ;
		goto error ;
	}
	if ( AnswerDM( owner, NULL, &exid, NULL ) == NULL ) {
		Errorf( "Can't get executor id !!\n" ) ;
		close( owner ) ;
		goto error ;
	}
	if ( EXECID(exid) == EXECID(aObjectID) ) {
		ret = owner ;
		return( ret ) ;
	}

	if ( RequestDM( owner, DM_SERVPORT, &aObjectID, sizeof(aObjectID) ) != 0 ) {
		Errorf( "Error request(DM_SERVPORT) to DM !!\n" ) ;
		goto error ;
	}
	if ( AnswerDM( owner, NULL, &net.addr, &net.size ) == NULL ) {
		Errorf( "Can't resolve %s !!\n", IDtoStr( aObjectID, NULL ) ) ;
		goto error ;
	}

	if ( net.addr.sa.sa_family == AF_UNIX ) {
		net.domain = AF_UNIX ;
		net.proto = 0 ;
	} else {
		net.domain = AF_INET ;
		net.proto = IPPROTO_TCP ;
	}

	port = socket( net.domain, SOCK_STREAM, net.proto ) ;
	if ( port < 0 ) {
		perror( "socket" ) ;
		Errorf( "Can't socket for server !!\n" ) ;
		goto error ;
	}
	if ( connect( port, (struct sockaddr *)&net.addr, net.size ) ) {
		perror( "connect" ) ;
		Errorf( "Can't connect Executor 0x%06x !!\n", (int)EXECID(aObjectID) ) ;
		close( port ) ;
		goto error ;
	}

	ret = port ;

error:
	if ( owner >= 0 ) close( owner ) ;
	return( ret ) ;
}
#endif

int
OpenRemote( OID aObjectID )
{
 struct	sockaddr_in	addr ;
	int	port ;
	int	ret = NG ;

	port = OpenNcl( OwnerIdent ) ;
	if ( port < 0 ) {
		Errorf( "Can't open nuclues !!\n" ) ;
		goto error ;
	}
	ret = CallNcl( port, aObjectID, &addr ) ;
	if ( ret < 0 ) {
		Errorf( "Can't call nuclues !!\n" ) ;
		goto error ;
	}
	CloseNcl( port ) ;

	port = socket( AF_INET, SOCK_STREAM, IPPROTO_TCP ) ;
	if ( port < 0 ) {
		perror( "socket" ) ;
		Errorf( "Can't socket for server !!\n" ) ;
		goto error ;
	}
	if ( connect( port, (struct sockaddr *)&addr, sizeof(addr) ) ) {
		perror( "connect" ) ;
		Errorf( "Can't connect Executor 0x%06x !!\n", (int)EXECID(aObjectID) ) ;
		close( port ) ;
		goto error ;
	}

	ret = port ;

error:
	return( ret ) ;
}

int
OpenLocal( int aLocal )
{
 struct	sockaddr_un	addr ;
	int		size ;
	int		port ;
	int		ret = NG ;

	addr.sun_family = AF_UNIX ;
	sprintf( addr.sun_path, UNIX_PATHFMT, aLocal ) ;
	size = sizeof( addr.sun_family ) + strlen( addr.sun_path ) ;

	port = socket( AF_UNIX, SOCK_STREAM, 0 ) ;
	if ( port < 0 ) {
		perror( "socket" ) ;
		Errorf( "Can't socket for server !!\n" ) ;
		goto error ;
	}
	if ( connect( port, (struct sockaddr *)&addr, sizeof(addr) ) ) {
		perror( "connect" ) ;
		Errorf( "Can't connect Executor 0x%06x !!\n", aLocal ) ;
		close( port ) ;
		goto error ;
	}
	ret = port ;

error:
	return( ret ) ;
}

int
OpenFile( OID aObjectID )
{
	int	ret = NG ;
	int	exid = (aObjectID>>24)&0x0ffffff ;
	int	oid = aObjectID&0x0ffffff ;
	int	i ;
	char	base[BUFSIZ] ;
	char	file[BUFSIZ] ;
	char	work[BUFSIZ] ;

	sprintf( base, "images/%06x/objects/%06x", exid, oid ) ;
	strcpy( file, base ) ; strcat( file, ".tmp" ) ;
	if ( (ret=Copy( base, file )) < 0 ) {
		perror( "Copy" ) ;
		goto error ;
	}

	for ( i = 0 ; i < 999 ; i ++ ) {
		sprintf( file, "%s.%03d", base, i ) ;
		if ( access( file, F_OK ) < 0 ) break ;
	}
	if ( i == 1000 ) {
		unlink( file ) ;
		i = 999 ;
	}
	while ( i ) {
		sprintf( work, "%s.%03d", base, i ) ;
		-- i ;
		sprintf( file, "%s.%03d", base, i ) ;
		if ( rename( file, work ) ) {
			perror( "rename" ) ;
			goto error ;
		}
	}

	strcpy( file, base ) ; strcat( file, ".000" ) ;
	unlink( file ) ;
	if ( rename( base, file ) ) {
		perror( "rename" ) ;
		goto error ;
	}
	strcpy( file, base ) ; strcat( file, ".tmp" ) ;
	if ( rename( file, base ) ) {
		perror( "rename" ) ;
		goto error ;
	}

	ret = open( base, O_RDWR ) ;

error:
	return( ret ) ;
}

int
OpenDM( OID aObjectID )
{
	int	ret ;
	switch( Mode ) {
	case 0 : ret = OpenFile( aObjectID ) ; break ;
	case 1 : ret = OpenLocal( EXECID(aObjectID) ) ; break ;
	default: ret = OpenRemote( aObjectID ) ;
	}
	return( ret ) ;
}

void
CloseDM( int aPort )
{
	shutdown( aPort, 2 ) ;
	close( aPort ) ;
}

int
SendDM( int aPort, void *aData, int aSize )
{
	int	bytes ;
	int	size = aSize ;
	char	*data = aData ;

	do {
		bytes = send( aPort, data, size, 0 ) ;
		if ( bytes < 0 ) {
			Errorf( "send(aPort=%d,size=%d) error(%d)\n", aPort, size, errno ) ;
			perror( "SendDM" ) ;
			break ;
		}
		size -= bytes ;
		data += bytes ;
	} while( size ) ;

	return( aSize - size ) ;
}

int
RecvDM( int aPort, void *aData, int aSize )
{
	int	bytes ;
	int	size = aSize ;
	char	*data = aData ;

	do {
		bytes = recv( aPort, data, size, 0 ) ;
		if ( bytes < 0 ) {
			Errorf( "recv(aPort=%d,size=%d) error(%d)\n", aPort, size, errno ) ;
			perror( "RecvDM" ) ;
			break ;
		}
		size -= bytes ;
		data += bytes ;
	} while( size ) ;

	return( aSize - size ) ;
}

void*
GetBuffer( Buffer *aBuffer, int aSize )
{
	if ( aBuffer->data == NULL ) {
		if ( (aBuffer->data = malloc( aBuffer->size )) == NULL ) {
			Errorf( "Buffer malloc(%d) error(%d)\n", aSize, errno ) ;
			return( NULL ) ;
		}
	}
	if ( aBuffer->size < aSize ) {
		if ( (aBuffer->data = realloc( aBuffer->data, aSize )) == NULL ) {
			Errorf( "Buffer realloc(%d) error(%d)\n",
					aBuffer->size, errno ) ;
			return( NULL ) ;
		}
		aBuffer->size = aSize ;
	}
	return( aBuffer->data ) ;
}

int
RequestDM( int aPort, int aRequest, void *aData, int aSize )
{
	int	size ;
	Packet	packet ;

#if	0
printf( "RequestDM: Request = %d\n", aRequest ) ;
#endif

	size = sizeof(HeaderRec) + aSize ;
	packet = GetBuffer( &SendBuffer, size ) ;
	if ( packet == NULL ) {
		Errorf( "Send Buffer Error\n" ) ;
		exit( 1 ) ;
	}
	packet->header.head.request = aRequest ;
	packet->header.size = aSize ;
	if ( aSize ) memcpy( packet->body, aData, aSize ) ;

	if ( SendDM( aPort, packet, size ) != size ) {
		Errorf( "RequestDM(%d) Error\n", aRequest ) ;
		return( NG ) ;
	}

	return( OK ) ;
}

void*
AnswerDM( int aPort, int *aStatus, void *aData, int *aSize )
{
	int		ret = NG ;
	HeaderRec	header ;
	void		*data = NULL ;

	if ( RecvDM( aPort, &header, sizeof(header) ) != sizeof(header) ) {
		Errorf( "AnswerDM(Header) Error\n" ) ;
		goto error ;
	}

#if	0
printf( "AnswerDM: Status = %d\n", header.head.status ) ;
#endif

	if ( header.head.status < 0 ) {
		if ( aStatus != NULL ) *aStatus = header.head.status ;
		goto error ;
	}

	if ( aSize != NULL ) *aSize = header.size ;
	if ( aData != NULL ) data = aData ;
	else {
		data = GetBuffer( &RecvBuffer, header.size ) ;
		if ( data == NULL ) {
			Errorf( "Recv Buffer Error\n" ) ;
			exit( 1 ) ;
		}
	}
	if ( RecvDM( aPort, data, header.size ) != header.size ) {
		Errorf( "Answer(Body,size=%d) Error\n", header.size ) ;
		data = NULL ;
		goto error ;
	}

error:
	return( data ) ;
}

int
ReadSocket( int aPort, void *aAddr, void *aData, int aSize )
{
	int	ret = NG ;
	HeaderRec	header ;
	struct	{
		void	*addr ;
		int	size ;
	} args ;

	args.addr =  aAddr ;
	args.size = aSize ;
	if ( (ret=RequestDM( aPort, DM_READ, &args, sizeof(args))) != 0 ) goto error ;

	if ( RecvDM( aPort, &header, sizeof(header) ) != sizeof(header) ) {
		Errorf( "Answer(Header) Error\n" ) ;
		return( ret ) ;
	}

#if	0
printf( "ReadDM: Status = %d\n", header.head.status ) ;
#endif

	if ( header.head.status < 0 ) return( header.head.status ) ;

	if ( header.size > 0 ) {
		if ( RecvDM( aPort, aData, header.size ) != header.size ) {
			Errorf( "ReadDM(Body,size=%d) Error\n", header.size ) ;
			return( ret ) ;
		}
	}
	ret = header.size ;

error:
	return( ret ) ;
}

int
ReadFile( int aPort, void *aAddr, void *aData, int aSize )
{
	int	ret = NG ;

fprintf( stderr, "Addr: %#08x\n", aAddr ) ;
	if ( lseek( aPort, (off_t)aAddr, SEEK_SET ) < 0 ) {
		perror( "lseek" ) ;
		goto error ;
	}
	if ( (ret=read( aPort, aData, aSize )) != aSize ) {
		perror( "read" ) ;
		goto error ;
	}

error:
	return( ret ) ;
}

int
ReadDM( int aPort, void *aAddr, void *aData, int aSize )
{
	int	ret ;
	if ( Mode ) ret = ReadSocket( aPort, aAddr, aData, aSize ) ;
	else ret = ReadFile( aPort, aAddr, aData, aSize ) ;
	return( ret ) ;
}

int
DebugFlagsFile( int aPort, void *aAddr, unsigned int aDFlags )
{
	int	ret = NG ;

	if ( lseek( aPort, (off_t)aAddr, SEEK_SET ) < 0 ) {
		perror( "lseek" ) ;
		goto error ;
	}
	if ( (ret=write( aPort, (void *)&aDFlags, 4 )) != 4 ) {
		perror( "write" ) ;
		goto error ;
	}

error:
	return( ret ) ;
}

int
DebugFlagsSocket( int aPort, void *aAddr, unsigned int aDFlags )
{
	int	ret = NG ;
	HeaderRec	header ;
	struct	{
		void		*addr ;
		int		size ;
		unsigned int	dflags ;
	} args ;

	args.addr =  aAddr ;
	args.size = 4 ;
	args.dflags = aDFlags ;
	if ( (ret=RequestDM( aPort, DM_WRITE, &args, sizeof(args))) != 0 ) goto error ;

	if ( RecvDM( aPort, &header, sizeof(header) ) != sizeof(header) ) {
		Errorf( "Answer(Header) Error\n" ) ;
		return( ret ) ;
	}

#if	0
printf( "ReadDM: Status = %d\n", header.head.status ) ;
#endif

	if ( header.head.status < 0 ) return( header.head.status ) ;

	if ( header.size > 0 ) {
		if ( RecvDM( aPort, NULL, header.size ) != header.size ) {
			Errorf( "ReadDM(Body,size=%d) Error\n", header.size ) ;
			return( ret ) ;
		}
	}
	ret = header.size ;

error:
	return( ret ) ;
}

int
DebugFlagsDM( int aPort, void *aAddr, unsigned int aDFlags )
{
	int	ret ;
	if ( Mode ) ret = DebugFlagsSocket( aPort, aAddr, aDFlags ) ;
	else ret = DebugFlagsFile( aPort, aAddr, aDFlags ) ;
	return( ret ) ;
}

int
GetClassDM( int aPort, OID id )
{
	int	ret = NG ;
	int	size ;
	HeaderRec	header ;

	if ( (ret=RequestDM( aPort, DM_CGET, &id, sizeof(id))) != 0 ) goto error ;

	if ( RecvDM( aPort, &header, sizeof(header) ) != sizeof(header) ) {
		Errorf( "Answer(Header) Error\n" ) ;
		return( ret ) ;
	}

#if	0
printf( "ReadDM: Status = %d\n", header.head.status ) ;
#endif

	if ( header.head.status < 0 ) return( header.head.status ) ;

	if ( header.size > 0 ) {
		if ( RecvDM( aPort, NULL, header.size ) != header.size ) {
			Errorf( "ReadDM(Body,size=%d) Error\n", header.size ) ;
			return( ret ) ;
		}
	}
	ret = header.size ;

error:
	return( ret ) ;
}

int
SpawnWish( char *aScripts )
{
	int	i ;
	int	pid ;
	int	sv[2];
	socketpair(AF_UNIX, SOCK_STREAM, 0, sv );

	pid = fork() ;
	if ( pid < 0 ) {
		perror( "fork" ) ;
		Errorf( "Can't vfork for wish !!\n" ) ;
		close( sv[0] ) ;
		close( sv[1] ) ;
		return( -1 ) ;
	} else if ( pid == 0 ) {
		dup2( sv[1], 0 );
		dup2( sv[1], 1 );
		for( i = 3; i < NOFILE ; i++ ) close( i ) ;
		execlp( WISH, "wish", "-f", aScripts, 0 ) ;
		perror( "execlp" ) ;
		exit( 1 ) ;
	}

	close( sv[1] ) ;

	return( sv[0] ) ;
}

char*
AddrToName( void *aData, int aSize )
{
static	char			buf[64] ;
	struct	hostent		*host ;
	union	{
		struct	sockaddr	sa ;
		struct	sockaddr_in	in ;
	} *addr = aData ;

	if ( addr->sa.sa_family == AF_UNIX ) {
		sprintf( buf, "%*s", aSize-sizeof(addr->sa.sa_family), addr->sa.sa_data ) ;
	} else {
		if ( (host=gethostbyaddr( &addr->in.sin_addr, aSize, AF_INET )) != NULL ) {
			sprintf( buf, "%d@%s", addr->in.sin_port, host->h_name ) ;
		} else {
			sprintf( buf, "%d@%s", addr->in.sin_port, inet_ntoa( addr->in.sin_addr ) ) ;
		}
	}
	return( buf ) ;
}

int
SearchObject( int aPort, int aIndex )
{
	int		ret = NG ;
	int		diff ;
	int		index = 0 ;
	off_t		offset = 8 ;
	OZ_HeaderRec	top ;

	LOOP {
		if ( lseek( aPort, offset, SEEK_SET ) < 0 ) {
			perror( "lseek" ) ;
			goto error ;
		}
		if ( (ret=read( aPort, &top, sizeof(top) )) != sizeof(top) ) {
			perror( "read(top)" ) ;
			goto error ;
		}
		if ( top.h > 0 && (int)top.d != OZ_ARRAY ) diff = top.h + 1 ;
		else diff = 1 ;
		if ( index <= aIndex && aIndex < index+diff ) {
			ret = offset + (aIndex - index) * sizeof(OZ_HeaderRec) ;
			break ;
		}
		index += diff ;
		offset += top.e ;
	}

error:
	return( ret ) ;
}

static
int
ReadBlock( int fd, char *buf, int nbyte )
{
	int	ret = nbyte ;	/* Normal */
	char	*bufbrk = buf + nbyte ;
	int	size ;

	for ( bufbrk = buf + nbyte ; buf < bufbrk ; buf += size ) {
		size = read( fd, buf, bufbrk-buf ) ;
		if ( size <= 0 ) {
			ret = -1 ;	/* Abnormal */
			break ;
		}
	}
	return( ret ) ;
}

/*	file copy	*/
int
Copy( const char *aSrcPath, const char *aDstPath )
{
	int	ret = -1 ;	/* Abnormal */
	int	src = -1 ;	/* Not yet open */
	int	dst = -1 ;	/* Not yet open */
	void	*buf = NULL ;	/* Not yet allocate */
	long	blocks ;
	int	bsize ;
	off_t	size = 0 ;
 struct	stat	srcStat ;
 struct	stat	dstStat ;

	/* Get file info. and Check */
	if ( stat( aSrcPath, &srcStat ) < 0 ) goto error ;
	if ( ! S_ISREG(srcStat.st_mode) ) {
		errno = EISDIR ;
		goto error ;
	}
	if ( stat( aDstPath, &dstStat ) == 0 ) {
		if ( srcStat.st_dev == dstStat.st_dev
			&& srcStat.st_ino == dstStat.st_ino ) {
			errno = EINVAL ;
			goto error ;
		}
		if ( ! S_ISREG(dstStat.st_mode) ) {
			errno = EEXIST ;
			goto error ;
		}
	}

	/* Open source file */
	if ( (src=open( aSrcPath, O_RDONLY, 0 )) < 0 ) goto error ;

	/* Create destination file */
	if ( (dst=creat( aDstPath, srcStat.st_mode ) ) < 0 ) goto error ;

	/* For performance */
	bsize = srcStat.st_blksize ;
	blocks = srcStat.st_size / bsize ;

	/* alocate read buffer */
	if ( (buf=(void *)malloc( bsize )) == NULL ) goto error ;

	/* Block copy except last block */
	while( blocks ) {
		if ( ReadBlock( src, buf, bsize ) < 0 ) goto error ;
		if ( write( dst, buf, bsize ) != bsize ) goto error ;
		size += bsize ;
		blocks -- ;
	}

	/* Last one block byte copy */
	if ( size < srcStat.st_size ) {
		bsize = srcStat.st_size - size ;
		if ( ReadBlock( src, buf, bsize ) < 0 ) goto error ;
		if ( write( dst, buf, bsize ) != bsize ) goto error ;
		size += bsize ;
	}

	ret = size ;	/* Normal */

 error:
	if ( src >= 0 ) close( src ) ;
	if ( dst >= 0 ) {
		close( dst ) ;
		if ( ret < 0 ) unlink( aDstPath ) ;
	}
	if ( buf != NULL ) free( buf ) ;
	return( ret ) ;
}
