/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Convert value of shared OTObjectStatus to string.
//
record
OTObjectStatusName
{
/* no member */

char
Name( int aStatus )[]
{
	char	name[] ;

	switch( aStatus ) {
	case OTObjectStatus::OTReady:
		name = "OTReady" ;
		break ;
	case OTObjectStatus::OTQueue:
		name = "OTQueue" ;
		break ;
	case OTObjectStatus::OTStop:
		name = "OTStop" ;
		break ;
	default:
		name = "Unknown" ;
	}
	return( name ) ;
}

} // record OTObjectStatusName [.oz]
