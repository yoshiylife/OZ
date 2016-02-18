/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debugger Laucher.	(and for local objet)
//
//		Tcl/Tk(7.3/3.4): $OZROOT/lib/gui/debugger2/dlauncher.tcl
//
// CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
class	DebuggerLauncher : Launchable
{
constructor:
	New
;
public:
	Initialize,
	Launch
;
protected:
	RecvWish, SendWish, WatchWish, Wish,
	Obj, Proc, Wait, Kill, EventLoop ;

	int			Wish ;
	Object		Obj ;
	void		@Proc ;

	unsigned long	CID ;
	int				CMD ;
	int				MODE ;
	char			Name[] ;
	char 			Public[] ;

void
Initialize()
{
	debug( 0, "DebuggerLauncher: Initialize()\n" ) ;
	Name = 0 ;
	Public = 0 ;
}

void
New( String name, String pid )
{
	Initialize() ;
	Name = (name ? name->Content() : 0) ;
	Public = (pid ? pid->Content() : 0) ;
}

void
WatchWish()
{
	int	ret ;
	int	status ;
	int	fd = Wish ;
	inline "C" {
		ret = OzWatch( fd, &status ) ;
		OzClose( fd ) ;
	}
	debug( 0, "DebuggerLauncher: WatchWish() ret = %d, status = %d\n",
			ret, status ) ;
}

int
SendWish( int wish, long cid, int cmd, int status ) : locked
{
	global Object	o ;
		Object		s ;
		int			ret ;

	o = cell ;
	s = Obj ;
	inline "C" {
		char	buf[128] ;
		OzSprintf( buf, "%08x%08x %c%c %016lx %#08x\n",
				(int)(cid>>32), (int)(cid&0x0ffffffffu),
				'0' + cmd, '0' + status, o, s ) ;
		ret = OzWrite( wish, buf, OzStrlen(buf) ) ;
		if ( ret < 0 ) OzDebugf( "DebuggerLauncher: SendWish() error %m\n" ) ;
	}
	return( ret ) ;
}

void
Wait( long cid, int cmd, void @p )
{
	try {
		join p ;
		if ( p == Proc ) SendWish( Wish, cid, cmd, 0 ) ;
	} except {
		default {
			if ( p == Proc ) SendWish( Wish, cid, 0, cmd ) ;
		}
	}
}

void
Kill( long cid )
{
	try {
		kill Proc ;
	} except {
		default {
		}
	}
}

Launchable
Convert()
{
	return(  narrow(Launchable,Obj) ) ;
}

int
RecvWish( int wish )
{
	int	ret ;
	long	cid ;
	int	cmd ;
	int	mode ;

	inline "C" {
		char	buf[512] ;
		char	c ;
		ret = OzRead( wish, buf, sizeof(buf) ) ;
		if ( ret < 0 ) {
			OzDebugf( "DebuggerLauncher: RecvWish() error %m\n" ) ;
			return( ret ) ;
		}
		c = buf[8] ;
		buf[8] = 0 ;
		cid = OzStrtol( buf, NULL, 16 ) ;
		cid <<= 32 ;
		buf[8] = c ;
		cid |= OzStrtol( buf+8, NULL, 16 ) & 0x0ffffffffu ;
		mode = OzStrtol( buf+17, NULL, 16 ) ;
		cmd = mode >> 16 ;
		mode &= 0x0ffff ;
	}
	CID = cid ;
	CMD = cmd ;
	MODE = mode ;
	return( ret ) ;
}

int
Command( long cid, int cmd, int mode )
{
	Launchable	obj ;
	switch ( cmd ) {
	case	1:
		inline "C" {
			extern	unsigned int	OzDebugFlags ;
			OZ_Object _obj =
				OzExecAllocateLocalObject( cid ) ;
			OZ_InstanceVariable_DebuggerLauncher( Obj ) =
				_obj - ( _obj -> head.e -1 ) ;
			OzDebugFlags = 0x81000000u ;
			OzDebugFlags |= 0x080 ;
			if ( mode & 0x0001 ) OzDebugFlags |= 0x001 ;
			if ( mode & 0x0010 ) OzDebugFlags |= 0x010 ;
			if ( mode & 0x0100 ) OzDebugFlags |= 0x008 ;
			if ( mode & 0x1000 ) OzDebugFlags |= 0x004 ;
		}
		obj = Convert() ;
		Proc = fork obj -> Initialize() ;
		detach fork Wait( CID, 1, Proc ) ;
		inline "C" {
			extern	unsigned int	OzDebugFlags ;
			OzDebugFlags = 0x0 ;
		}
		break ;
	case	2:
		inline "C" {
			extern	unsigned int	OzDebugFlags ;
			OzDebugFlags = 0x81000000u ;
			OzDebugFlags |= 0x080 ;
			if ( mode & 0x0001 ) OzDebugFlags |= 0x001 ;
			if ( mode & 0x0010 ) OzDebugFlags |= 0x010 ;
			if ( mode & 0x0100 ) OzDebugFlags |= 0x008 ;
			if ( mode & 0x1000 ) OzDebugFlags |= 0x004 ;
		}
		obj = Convert() ;
		Proc = fork obj -> Launch() ;
		detach fork Wait( CID, 2, Proc ) ;
		inline "C" {
			extern	unsigned int	OzDebugFlags ;
			OzDebugFlags = 0x0 ;
		}
		break ;
	case	3:
		SendWish( Wish, cid, 3, 0 ) ;
		break ;
	default:
		kill( Proc ) ;
	}
}

void
EventLoop()
{
	int	ret ;

	try {
		for (;;) {
			ret = RecvWish( Wish ) ;
			if ( ret <= 0 ) break ;
			Command( CID, CMD, MODE ) ;
		}
	} except {
		default {
			int	wish = Wish ;
			inline "C" {
				OzKill( wish, 9 ) ;
			}
		}
	}
}

void
Launch()
{
	int		wish ;
	char	n[] ;
	char	p[] ;

	n = Name ;
	p = Public ;

	inline "C" {
		int		ret ;
		char	*argv[6] ;

		argv[0] = "wish" ;
		argv[1] = "-f" ;
		argv[2] = "../../../lib/gui/debugger2/dlauncher.tcl" ;
		argv[3] = (n != NULL) ? OZ_ArrayElement(n,char) : NULL ;
		argv[4] = (p != NULL) ? OZ_ArrayElement(p,char) : NULL ;
		argv[5] = NULL ;
		wish = OzVspawn( "wish", argv ) ;
		if ( wish < 0 ) {
			OzDebugf("DebuggerLauncher: OzVspawn() error %d %m !!\n",wish);
			return ;
		}
	}
	Wish = wish ;

	detach fork WatchWish() ;
	detach fork EventLoop() ;
}

} // class DebuggerLauncher [dlauncher.oz]
