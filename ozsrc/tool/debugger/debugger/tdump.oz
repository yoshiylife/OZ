/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

//
//	Dump Thread stack
//
inline "C" {
#include "../src/executor/debugFunction.h"
}
class TestDumpThreadStack : Launchable
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
	Name = "TestDumpThreadStack" ;
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
	long	id ;
	global ClassID	cid ;
	Input	input ;
	Number	number ;

	number => New() ;
	input => New( Name ) ;

	data = input->Get( "Class ID (impl)" ) ;
	id = number->Long( data ) ;
	inline "C" {
		cid = id ;
	}
	input->Delete() ;

	try {
		DC->Open( Where() ) ;
	} except {
		default {
			debug( 0, "%S::Launch Can't Open DebugChannel\n", Name ) ;
			return ;
		}
	}

	length head = 2 ;
	length data = 8 ;
	inline "C" {
		int		*head_ptr = OZ_ArrayElement(head,int) ;
		int		*data_ptr = (int *)OZ_ArrayElement(data,char) ;
		*head_ptr = DM_CCODE ;
		*(head_ptr+1) = 8 ;
		*data_ptr = cid >> 32 ;
		*(data_ptr+1) = cid & 0x0ffffffffLL ;
		/* for ( i = 0 ; i < 8 ; i ++ ) *(data_ptr ++) = *(cid_ptr ++) ; */
	}
	try {
		DC->Send( head, data ) ;
	} except {
		default {
			debug( 0, "%S::Launch Can't Send DebugChannel\n", Name ) ;
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
			debug( 0, "%S::Launch Error Send DebugChannel\n", Name ) ;
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
			debug( 0, "%S::Launch Can't Recv DebugChannel\n", Name ) ;
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

	if ( data ) {
		inline "C" {
			int		i ;
			DmCCode	*code ;
			code = (DmCCode *)OZ_ArrayElement( data, char ) ;
			OzDebugf( "%O: code=%#08x\n", cid, code->code ) ;
			OzDebugf( "%O: base=%#08x\n", cid, code->base ) ;
			OzDebugf( "%O: size=%#08x\n", cid, code->size ) ;
		}
	} else {
		inline "C" {
			OzDebugf( "%O: not found\n", cid ) ;
		}
	}

	DC->Close() ;
}

} // class TestDumpThreadStack [tdump.oz]
