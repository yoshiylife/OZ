/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Convert value of shared ObjectStatus to string.
//
record
ObjectStatusName
{
/* no member */

char
Name( int aStatus )[]
{
	char	name[] ;

	switch( aStatus ) {
	case ObjectStatus::Frozen:
		name = "Frozen" ;
		break ;
	case ObjectStatus::Melting:
		name = "Melting" ;
		break ;
	case ObjectStatus::MeltingToStop:
		name = "MeltingToStop" ;
		break ;
	case ObjectStatus::Running:
		name = "Running" ;
		break ;
	case ObjectStatus::SwappedOut:
		name = "SwappedOut" ;
		break ;
	case ObjectStatus::CellingIn:
		name = "CellingIn" ;
		break ;
	case ObjectStatus::CellingInToStop:
		name = "CellingInToStop" ;
		break ;
	case ObjectStatus::OrderStopped:
		name = "OrderStopped" ;
		break ;
	case ObjectStatus::Closed:
		name = "Closed" ;
		break ;
	case ObjectStatus::Removed:
		name = "Removed" ;
		break ;
	default:
		name = "Unknown" ;
	}
	return( name ) ;
}

} // End of file: ObjectStatusName.oz
