/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Debug Function
//
//	Depend on executor's implimentation.
//
//	Refer to debugFuncton.[ch]
//
//	inherits:
//		Object
//
//	uses:
//		record	DmAllocateInfo.oz
//		record	DmClassID.oz
//		record	DmHeader.oz
//		record	DmOEntry.oz
//		record	DmOTableSlot.oz
//		record	DmObjectFlags.oz
//		record	DmObjectID.oz
//		record	DmObjectStatus.oz
//		record	DmPTableSlot.oz
//		record	DmProcessID.oz
//		record	DmProcessStatus.oz
//		record	DmTListSlot.oz
//		record	DmThreadStatus.oz
//
//	CAUTION
//	This source file is written in tabstop=4,hardtabs=8.
//
inline "C" {
#include "../src/executor/debugFunction.h"
}
//
class	DebugFunction
{
constructor:
	New
;
public:
	DmOTABLE,
	DmOGETENTRY,
	DmORELENTRY,
	DmOSUSPEND,
	DmORESUME,
	DmPTABLE,
	DmPKILL,
	DmTLIST,
	DmTSUSPEND,
	DmTRESUME
;

//
//	Private instance
//
char	Name[] ;	// Class Name (Ready only)

//
//	Constructor method
//
void
New()
{
	Name = "DebugFunction" ;
}

DmOTableSlot
DmOTABLE( DebugChannel aDChan )[]
{
	DmOTableSlot	result[] ;
		int			count ;
		int			request ;
		char		data[] ;

	inline "C" {
		request = DM_OTABLE ;
	}
	try {
		data = aDChan->Call( request, 0 ) ;
	} except {
		default {
			debug( 0 , "%S::DmOTABLE failure\n", Name ) ;
			raise ;
		}
	}
	inline "C" {
		DmOTable	*table ;
		table = (DmOTable *)OZ_ArrayElement( data, char ) ;
		count = table->count ;
	}
	length result = count ;
	inline "C" {
		DmOTable	*table ;
		int			i ;
		table = (DmOTable *)OZ_ArrayElement( data, char ) ;
		OzMemcpy( OZ_ArrayElement( result, char ), table->slot,
							table->count * sizeof(DmOTableSlot) ) ;
/*
		for ( i = 0 ; i < table->count ; i ++ ) {
			OzDebugf( "%04d: %O %O %d %d\n",
						i,
						table->slot[i].cid,
						table->slot[i].oid,
						table->slot[i].status,
						table->slot[i].flags ) ;
		}
*/
	}

	return( result ) ;
}

DmOEntry
DmOGETENTRY( DebugChannel aDChan, global Object aObj )
{
	DmOEntry	result ;
	int			request ;
	char		data[] ;
	char		args[] ;

	length args = 8 ;
	inline "C" {
		request = DM_OGETENTRY ;
		OzMemcpy( OZ_ArrayElement( args, char ), &aObj, 8 ) ;
	}
	try {
		data = aDChan->Call( request, args ) ;
		inline "C" {
			DmOEntry	*entry ;
			entry = (DmOEntry *)OZ_ArrayElement( data, char ) ;
			OzMemcpy( &result, &entry->entry, sizeof(result) ) ;
		}
	} except {
		default {
			debug( 0 , "%S::DmOGETENTRY failure\n", Name ) ;
			raise ;
		}
	}
	return( result ) ;
}

void
DmORELENTRY( DebugChannel aDChan, DmOEntry aEntry )
{
	unsigned int	entry ;
		int			request ;
		char		args[] ;

	length args = 4 ;
	entry = aEntry.entry ;
	inline "C" {
		request = DM_ORELENTRY ;
		OzMemcpy( OZ_ArrayElement( args, char ), &entry, 4 ) ;
	}
	try {
		aDChan->Call( request, args ) ;
	} except {
		default {
			debug( 0 , "%S::DmORELENTRY failure\n", Name ) ;
			raise ;
		}
	}
	return ;
}

void
DmOSUSPEND( DebugChannel aDChan, DmOEntry aEntry )
{
	unsigned int	entry ;
		int			request ;
		char		args[] ;

	length args = 4 ;
	entry = aEntry.entry ;
	inline "C" {
		request = DM_OSUSPEND ;
		OzMemcpy( OZ_ArrayElement( args, char ), &entry, 4 ) ;
	}
	try {
		aDChan->Call( request, args ) ;
	} except {
		default {
			debug( 0 , "%S::DmOSUSPEND failure\n", Name ) ;
			raise ;
		}
	}
	return ;
}

void
DmORESUME( DebugChannel aDChan, DmOEntry aEntry )
{
	unsigned int	entry ;
		int			request ;
		char		args[] ;

	length args = 4 ;
	entry = aEntry.entry ;
	inline "C" {
		request = DM_ORESUME ;
		OzMemcpy( OZ_ArrayElement( args, char ), &entry, 4 ) ;
	}
	try {
		aDChan->Call( request, args ) ;
	} except {
		default {
			debug( 0 , "%S::DmORESUME failure\n", Name ) ;
			raise ;
		}
	}
	return ;
}

DmPTableSlot
DmPTABLE( DebugChannel aDChan )[]
{
	DmPTableSlot	result[] ;
		int			count ;
		int			request ;
		char		data[] ;

	inline "C" {
		request = DM_PTABLE ;
	}
	try {
		data = aDChan->Call( request, 0 ) ;
	} except {
		default {
			debug( 0 , "%S::DmPTABLE failure\n", Name ) ;
			raise ;
		}
	}
	inline "C" {
		DmPTable	*table ;
		table = (DmPTable *)OZ_ArrayElement( data, char ) ;
		count = table->count ;
	}
	length result = count ;
	inline "C" {
		DmPTable	*table ;
		table = (DmPTable *)OZ_ArrayElement( data, char ) ;
		OzMemcpy( OZ_ArrayElement( result, char ), table->slot,
							table->count * sizeof(DmPTableSlot) ) ;
	}

	return( result ) ;
}

void
DmPKILL( DebugChannel aDChan, DmProcessID aProcID )
{
	int				request ;
	unsigned long	pid ;
	char			args[] ;

	length args = 8 ;
		pid = aProcID.Value ;
	inline "C" {
		request = DM_PKILL ;
		OzMemcpy( OZ_ArrayElement( args, char ), &pid, 8 ) ;
	}
	try {
		aDChan->Call( request, args ) ;
	} except {
		default {
			debug( 0 , "%S::DmPKILL failure\n", Name ) ;
			raise ;
		}
	}
	return ;
}

DmTListSlot
DmTLIST( DebugChannel aDChan, DmOEntry aEntry )[]
{
	DmTListSlot		result[] ;
	unsigned int	entry ;
		int			count ;
		int			request ;
		char		data[] ;
		char		args[] ;

	length args = 4 ;
	entry = aEntry.entry ;
	inline "C" {
		request = DM_TLIST ;
		OzMemcpy( OZ_ArrayElement( args, char ), &entry, 4 ) ;
	}
	try {
		data = aDChan->Call( request, args ) ;
	} except {
		default {
			debug( 0 , "%S::DmTLIST failure\n", Name ) ;
			raise ;
		}
	}
	inline "C" {
		DmTList		*list ;
		list = (DmTList *)OZ_ArrayElement( data, char ) ;
		count = list->count ;
	}
	length result = count ;
	inline "C" {
		DmTList		*list ;
		list = (DmTList *)OZ_ArrayElement( data, char ) ;
		OzMemcpy( OZ_ArrayElement( result, char ), list->slot,
							list->count * sizeof(DmTListSlot) ) ;
	}

	return( result ) ;
}

void
DmTSUSPEND( DebugChannel aDChan, unsigned int aThread )[]
{
	int		request ;
	char	data[] ;
	char	args[] ;

	length args = 4 ;
	inline "C" {
		request = DM_TSUSPEND ;
		OzMemcpy( OZ_ArrayElement( args, char ), &aThread, 4 ) ;
	}
	try {
		data = aDChan->Call( request, args ) ;
	} except {
		default {
			debug( 0 , "%S::DmTSUSPEND failure\n", Name ) ;
			raise ;
		}
	}

	return ;
}

void
DmTRESUME( DebugChannel aDChan, unsigned int aThread )[]
{
	int		request ;
	char	data[] ;
	char	args[] ;

	length args = 4 ;
	inline "C" {
		request = DM_TRESUME ;
		OzMemcpy( OZ_ArrayElement( args, char ), &aThread, 4 ) ;
	}
	try {
		data = aDChan->Call( request, args ) ;
	} except {
		default {
			debug( 0 , "%S::DmTRESUME failure\n", Name ) ;
			raise ;
		}
	}

	return ;
}

}
// End of file: DebugFunction.oz
