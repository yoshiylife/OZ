/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

inline "C" {
extern	int	errno ;
}
/*
 *	Get data one item with GUI.
 *
 */
class Test : Launchable
{
constructor:
	New
;
public:
	Initialize,
	Launch,
	Get,
	Shutdown,
	Delete
;

	int		wish ;

void
New( char title[] )
{
	int	fd ;
	int	err ;

	inline "C" {
		char	*argv[2] ;
		argv[0] = "wish" ;
		argv[1] = NULL ;
		fd = OzVspawn( "wish", argv ) ;
		err = errno ;
	}

	if ( fd < 0 ) {
		return ;
	}

	inline "C" {
		char	msg[256] ;
		OzSprintf( msg, "wm title . \"%s\"\n", OZ_ArrayElement(title,char) ) ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "frame .input -relief sunken\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "label .input.name -text Input\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "entry .input.value -relief sunken\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "pack .input.name .input.value -side left\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "pack .input\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "proc value { input } {\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "set val [$input get]\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "puts stdout [string length $val]\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "flush stdout\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "puts stdout $val\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "flush stdout\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "}\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = "bind .input.value <Return> \"value .input.value\"\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	wish = fd ;
}

char
Get( char label[] )[]
{
	int		fd = wish ;
	int		ret ;
	char	s[] ;

	inline "C" {
		char	msg[256] ;
		OzSprintf( msg, ".input.name configure -text \"%s\"\n", OZ_ArrayElement(label,char) ) ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}
	inline "C" {
		char	*msg = ".input.value delete 0 end\n" ;
		OzWrite( fd, msg, OzStrlen(msg) ) ;
	}

	inline "C" {
		char	buf[156] ;
		ret = OzRead( fd, buf, 156 ) ;
		if ( 0 < ret && buf[ret-1] == '\n' ) {
			buf[ret-1] = 0 ;
			ret = OzStrtol( buf, NULL, 0 ) ;
		}
		OzDebugf( "OzRead() = %d\n", ret ) ;
	}
	if ( ret < 0 ) return 0 ;
	length s = ret + 1 ;
	inline "C" {
		ret = OzRead( fd, OZ_ArrayElement(s,char), ret+1 ) ;
		if ( 0 < ret ) {
			if ( ((char*)OZ_ArrayElement(s,char))[ret-1] == '\n' ) {
				((char*)OZ_ArrayElement(s,char))[ret-1] = 0 ;
			}
		}
		OzDebugf( "OzRead() = %d\n", ret ) ;
	}
	if ( ret < 0 ) return 0 ;
	return( s ) ;
}

void
Shutdown( int how )
{
	int		fd ;

	fd = wish ;
	inline "C" {
		OzSleep( 5 ) ;
		OzShutdown( fd, how ) ;
	}
}

void
Delete()
{
	int	fd = wish ;
	inline "C" {
		int		ret ;
		char	*msg = "exit 0\n" ;
		ret = OzWrite( fd, msg, OzStrlen(msg) ) ;
		OzDebugf( "OzWrite() = %d, %m\n", ret ) ;
	}
	inline "C" {
		OzClose( fd ) ;
	}
}

void
Initialize()
{
}

void
Launch()
{
	Test	input ;
	char	buf[] ;
	input=>New( "Test for Input" ) ;
	detach fork input->Shutdown( 1 ) ;
	buf = input->Get( "Input" ) ;
	inline "C" {
		OzDebugf( "Input: %S\n", buf ) ;
	}
	input->Delete() ;
}

/* class: Input ***************************************************************/
}
