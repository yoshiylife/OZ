/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	List Process
//
inline "C" {
#include "../src/executor/debugFunction.h"
}
class TestListProcess : Launchable
{
constructor:
	New
;
public:
	Initialize,
	Launch
;
protected:	/* instance */
	DC
;

	DebugChannel	DC ;
	char			Name[] ;

void
Initialize()
{
	Name = "TestListProcess" ;
	debug( 0, "%S::Initialize()\n", Name ) ;
	DC=>New() ;
}

void
New()
{
	Initialize() ;
	debug( 0, "%S::New()\n", Name ) ;
}

void
Launch()
{
	int		request ;
	int		head[] ;
	char	data[] ;

	length head = 2 ;

	try {
		DC->Open( Where() ) ;
	} except {
		default {
			debug( 0 , "%S::Launch Can't Open DebugChannel\n", Name ) ;
			return ;
		}
	}

	inline "C" {
		request = DM_PTABLE ;
	}
	head[0] = request ;
	head[1] = 0 ;
	try {
		DC->Send( head, data ) ;
	} except {
		default {
			debug( 0 , "%S::Launch Can't Send DebugChannel\n", Name ) ;
			try {
				DC->Close() ;
			} except {
				default {
					/* nothing */
				}
			}
			return ;
		}
	}
	if ( head[0] < 0 ) {
			debug( 0 , "%S::Launch Error Send DebugChannel\n", Name ) ;
			try {
				DC->Close() ;
			} except {
				default {
					/* nothing */
				}
			}
			return ;
	}

	try {
		data = DC->Recv( head ) ;
	} except {
		default {
			debug( 0 , "%S::Launch Can't Recv DebugChannel\n", Name ) ;
			try {
				DC->Close() ;
			} except {
				default {
					/* nothing */
				}
			}
			return ;
		}
	}

	inline "C" {
		int			i ;
		DmPTable	*table ;
		table = (DmPTable *)OZ_ArrayElement( data, char ) ;
		for ( i = 0 ; i < table->count ; i ++ ) {
			OzDebugf( "%04d %#08x %O %O %O %#08x %d\n",
				i,
				table->slot[i].entry,
				table->slot[i].pid,
				table->slot[i].callee,
				table->slot[i].caller,
				table->slot[i].t,
				table->slot[i].status ) ;
		}
	}

	DC->Close() ;
}

} // class TestListProcess [plist.oz]
