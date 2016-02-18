/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	ResourceUsage
//
class ResourceUsage
{
constructor:
	New
;
public:
	CPU
;
	char	Name[] ;

void
New()
{
	Name = "ResourceUsage" ;
}

int
CPU( unsigned int aTime )
{
	unsigned int	tick ;
	unsigned int	count ;
	unsigned int	stamp ;
	unsigned int	usage ;
	inline "C" {
		extern	unsigned int OzSchedIdle ;
		stamp = OzSchedIdle ;
		tick = OzSleep( aTime ) ;
		if ( stamp > OzSchedIdle ) {
			count = OzSchedIdle ;
			count += (0xffffffff - stamp) ;
		} else count = OzSchedIdle - stamp ;
	}
	debug( 0, "%S::CPU tick:%u stamp:%u count:%u\n", Name,tick,stamp,count ) ;
	usage = 100 - (count * 100) / tick ;
	return( usage ) ;
}

} // class ResourceUsage [rusage.oz]
