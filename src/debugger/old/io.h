/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_DEBUGGER_IO_H)
#define	_OZ_DEBUGGER_IO_H

#include "oz++/object-type.h"

#define	UNIX	0
#define	INET	1

typedef	struct	HeaderStr*	Header ;
typedef	struct	HeaderStr	HeaderRec ;
struct	HeaderStr	{
	union	{
		int	request ;
		int	status ;
	}		head ;
	int		size ;
} ;

typedef	struct	PacketStr*	Packet ;
struct	PacketStr	{
	HeaderRec	header ;
	char		body[1] ;
} ;

typedef	struct	BufferStr	Buffer ;
typedef	struct	BufferStr	BufferRec ;
struct	BufferStr	{
	int		size ;
	void		*data ;
} ;

extern	int
SendDM( int aPort, void *aData, int aSize ) ;

extern	int
RecvDM( int aPort, void *aData, int aSize ) ;

extern	void*
GetBuffer( Buffer *aBuffer, int aSize ) ;

extern	int
RequestDM( int aPort, int aRequest, void *aData, int aSize ) ;

extern	void*
AnswerDM( int aPort, int *aStatus, void *aData, int *aSize ) ;

extern	int
ReadDM( int aPort, void *aAddr, void *aData, int aSize ) ;

extern	int
DebugFlagsDM( int aPort, void *aAddr, unsigned int aDFlags ) ;

extern	int
OwnerDM( char *aOwner, char *aPort ) ;

extern	int
OpenDM( OID aID ) ;

extern	void
CloseDM( int aPort ) ;

extern	char*
AddrToName( void *aData, int aSize ) ;

extern	int
SearchObject( int aPort, int aIndex ) ;

#endif	_OZ_DEBUGGER_IO_H
