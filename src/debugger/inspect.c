/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<memory.h>
#include	<malloc.h>
#include	"id.h"
#include	"name.h"
#include	"print.h"
#include	"io.h"
#include	"class.h"
#include	"code.h"
#include	"inst.h"
#include	"inspect.h"
#include	"debugChannel.h"
#include	"debugFunction.h"
#include	"oz++/type.h"

#define	LOOP	for(;;)
#define	OK	0
#define	NG	(-1)
#define	CASE(xXvAlUe,xXnAmE)	case xXvAlUe: xXnAmE = #xXvAlUe ; break
#define	BUFSIZE		1024	/* Must be times by 8 */

extern	int	OzSiteID ;
extern	int	Class ;
extern	int	Mode ;

ArrayTypeSize( int aType )
{
	int size;

	switch( aType ) {
	case OZ_CHAR:
		size = 1;
		break;
	case OZ_SHORT:
		size = 2;
		break;
	case OZ_INT: 
	case OZ_FLOAT: 
	case OZ_ARRAY:
	case OZ_LOCAL_OBJECT: 
	case OZ_STATIC_OBJECT:
		size = 4;
		break;
	case OZ_DOUBLE: 
	case OZ_LONG_LONG: 
	case OZ_GLOBAL_OBJECT:
		size = 8;
		break;
	case OZ_RECORD:
	/* must be implemented */
		size = 0 ;
	}
	return( size ) ;
}

int
SubObjectGetEntry( int aPort, int aExecID, char *arg )
{
	int		ret ;
	DmOEntry	entry ;
	OID		oid ;

	oid = StrToID( OzSiteID, aExecID, arg, NULL ) ;
	if ( oid == 0 ) {
		Errorf( "Invalid Global Object ID '%s' !!\n", arg ) ;
		goto error ;
	}

	if ( (ret=RequestDM( aPort, DM_OGETENTRY, &oid, sizeof(oid) )) != 0 ) {
		Errorf( "Error request(DM_OGETENTRY) to DM !!\n" ) ;
		goto error ;
	}
	if ( AnswerDM( aPort, &ret, &entry, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", arg ) ;
		goto error ;
	}

	LinePrintf( 0, "Status: %d\n", entry.status ) ;
	LinePrintf( 0, "Entry-Address: 0x%08x\n", entry.entry ) ;
	LinePrintf( 0, "Object-Address: 0x%08x\n", entry.object ) ;

	LinePrintf( 0, "Size: %d\n", entry.size ) ;
	LinePrintf( 0, "Parts: %d\n", entry.parts ) ;
	LinePrintf( 0, "ConfigID: %s\n", IDtoStr(entry.cid,NULL) ) ;
	return( OK ) ;

error:
	return( NG ) ;
}

int
SubObjectRelEntry( int aPort, char *arg )
{
	int			ret ;
	ObjectTableEntry	entry ;

	entry = (ObjectTableEntry)strtol( arg, NULL, 0 ) ;

	if ( (ret=RequestDM( aPort, DM_ORELENTRY, &entry, sizeof(entry) )) != 0 ) {
		Errorf( "Error request(DM_ORELENTRY) to DM !!\n" ) ;
		goto error ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't release %s !!\n", arg ) ;
		goto error ;
	}
	return( OK ) ;

error:
	return( NG ) ;
}

int
SubObjectSuspend( int aPort, char *arg )
{
	int			ret ;
	ObjectTableEntry	entry ;

	entry = (ObjectTableEntry)strtol( arg, NULL, 0 ) ;

	if ( (ret=RequestDM( aPort, DM_OSUSPEND, &entry, sizeof(entry) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) goto error ;
	return( OK ) ;

error:
	return( NG ) ;
}

int
SubObjectResume( int aPort, char *arg )
{
	int			ret ;
	ObjectTableEntry	entry ;

	entry = (ObjectTableEntry)strtol( arg, NULL, 0 ) ;

	if ( (ret=RequestDM( aPort, DM_ORESUME, &entry, sizeof(entry) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) goto error ;
	return( OK ) ;

error:
	return( NG ) ;
}

int
ConvertClass( int aPort, OZ_ObjectAll aObjectAll, ClassID aClassID )
{
	OZ_HeaderRec	head ;
	OZ_Header	parts = NULL ;
	int		size ;
	int		part = 0 ;
	int		ret ;

	if ( (ret=ReadDM( aPort, aObjectAll, &head, sizeof(head) )) != sizeof(head) ) {
		Errorf( "Can't read object[0x%08x] header(head) !!\n", aObjectAll ) ;
		goto error ;
	}

	size = sizeof(OZ_HeaderRec) * head.h ;
	parts = (OZ_Header)malloc( size ) ;
	if ( parts == NULL ) {
		Errorf( "Can't malloc(%d) for parts header !!\n", size ) ;
		goto error ;
	}
	if ( (ret=ReadDM( aPort, aObjectAll->head + 1, parts, size )) != size ) {
		Errorf( "Fatal ReadDM(0x%08x,%d) for parts header !!\n", aObjectAll->head + 1, size ) ;
		goto error ;
	}

	for ( part = head.h - 1 ; part ; part -- ) {
		if ( parts[part].a == aClassID ) break ;
	}

error:
	if ( parts ) free( parts ) ;
	return( part ) ;
}

int
SubObjectConfig( int aPort, char *arg )
{
	int		ret = NG ;
	int		i ;
	char		*all = NULL ;
	OZ_Object	object ;
	OZ_HeaderRec	top ;
	OZ_Header	parts = NULL ;
	OZ_ClassInfo	class ;

	object = (OZ_Object)strtol( arg, NULL, 0 ) ;
	if ( ! Mode ) object = (OZ_Object)SearchObject( aPort, (int)object ) ;

	if ( (ret=ReadDM( aPort, object, &top, sizeof(top) )) != sizeof(top) ) {
		Errorf( "Can't read object[0x%08x] header(top) !!\n", object ) ;
		goto error ;
	}

	switch( top.h ) {
	case	LOCAL:
		object -= ( top.e + 1 ) ;
		if ( ! Mode ) all = (char *)object ;
		if ( (ret=ReadDM( aPort, object, &top, sizeof(top) )) != sizeof(top) ) goto error ;
		LinePrintf( 0, "LOCAL  ConfigID: %s  Size: %u  Parts: %d\n",
				IDtoStr(top.a,NULL), top.e, top.h ) ;
		break ;
	case	STATIC:
		LinePrintf( 0, "STATIC  ConfigID: %s  Size: %u  Parts: 1\n",
				IDtoStr(top.a,NULL), top.e ) ;
		break ;
	case	RECORD:
		LinePrintf( 0, "RECORD  Size: %u\n", top.e ) ;
		return( OK ) ;
		break ;
	default:
		if ( top.h >= 0 ) {
			LinePrintf( 0, "ARRAY  Size: %u  Elements: %d  Type: ",
					top.e, top.h ) ;
			if ( top.a < 0x01000000ll ) {
				LinePrintf( 0, "%s ", ArrayTypeToName(top.a) ) ;
			} else {
				LinePrintf( 0, "%s ", IDtoStr(top.a,NULL) ) ;
			}
			LinePrintf( 0, "%d\n", (top.e-sizeof(top))/top.h ) ;
		} else {
			LinePrintf( 0, "UNKNOWN  Size: %u\n", top.e ) ;
		}
		return( OK ) ;
	}

	LineFlush() ;
	LinePrintf( 0, "                                       "
					" -- Protected ---  -- Private  ---\n" ) ;
	LinePrintf( 0, "P-No RuntimeClassID   CompiledClassID  "
					"PNum   Size  Zero PNum   Size  Zero\n" ) ;
	class = ClassInfoGet( Class, top.a ) ;
	if ( class == NULL ) {
		Errorf( "Can't get ClassInfo ConfigID: '%s' !!\n", IDtoStr(top.a,NULL) ) ;
		goto error ;
	}

	if ( top.h < 0 ) {
		/* static object */
		/* make pseudo head */
		OZ_StaticObject	obj = (OZ_StaticObject)object ;
		parts = &top ;
		top.h = 1 ;
		top.e = 0 ;
		top.a = class->parts[0]->compiled_vid ;
		top.d = (void *)&(obj->info) ;
	} else {
		/* local object */
		int	size = sizeof(OZ_HeaderRec) * ( top.h ) ;
		parts = (OZ_Header)malloc( size ) ;
		if ( parts == NULL ) {
			Errorf( "Can't malloc(%d) for parts header !!\n", size ) ;
			goto error ;
		}
		object ++ ;
		if ( (ret=ReadDM( aPort, object, parts, size )) != size ) {
			Errorf( "Fatal ReadDM(0x%08x,%d) for parts header !!\n", object, size ) ;
			goto error ;
		}
	}

	for ( i = 0 ; i < top.h ; i ++ ) {
		OZ_AllocateInfoRec	info ;
		LinePrintf( 0, "%4d %s ", i, IDtoStr(class->parts[i]->cid,NULL) ) ;
		LinePrintf( 0, "%s ", IDtoStr(parts[i].a,NULL) ) ;
		if ( (ret=ReadDM( aPort, all + (int)parts[i].d, &info, sizeof(info) )) != sizeof(info) ) {
			Errorf( "Fatal ReadDM(0x%08x,%d) for parts allocInfo !!\n",
									parts[i].d, sizeof(info) ) ;
			goto error ;
		}
		LinePrintf( 0, "%5u %5u %5u %5u %5u %5u\n",
				info.number_of_pointer_protected,
				info.data_size_protected,
				info.zero_protected,
				info.number_of_pointer_private,
				info.data_size_private,
				info.zero_private ) ;
	}
	ret = OK ;

error:
	if ( parts != NULL && parts != &top ) free( parts ) ;
	return( ret ) ;
}

int
SubObjectInstanceSize( int aPort, OZ_AllocateInfo aInfo )
{
	int			total = NG ;
	int			ret ;
	OZ_AllocateInfoRec	info ;

	if ( (ret=ReadDM( aPort, aInfo, &info, sizeof(info) )) != sizeof(info) ) {
		Errorf( "Fatal ReadDM(0x%08x,%d) for parts allocInfo !!\n", aInfo, sizeof(info) ) ;
		goto error ;
	}

	total = info.number_of_pointer_protected * sizeof(void *) ;
	if ( total & 7 ) total += (8 - total%8) ;
	total += info.data_size_protected ;
	if ( total & 7 ) total += (8 - total%8) ;
	total += info.zero_protected * sizeof(OZ_ConditionRec) ;

	total += info.number_of_pointer_private * sizeof(void *) ;
	if ( total & 7 ) total += (8 - total%8) ;
	total += info.data_size_private ;
	if ( total & 7 ) total += (8 - total%8) ;
	total += info.zero_private * sizeof(OZ_ConditionRec) ;

error:
	return( total ) ;
}

int
SubObjectInstance( int aPort, char *aObject, char *aClass, char *aPart )
{
	int		ret = NG ;
	OZ_Object	object ;
	OZ_HeaderRec	head ;
	int		i ;
	int		total ;
	InstInfo	info ;
	InstName	inst ;
	void		*addr ;
	int		part = 0 ;
	ClassID		cid = 0 ;

	if ( aClass ) cid = (ClassID)StrToID( 0, 0, aClass, NULL ) ;
	if ( aPart ) part = (int)strtol( aPart, NULL, 0 ) ;

	object = (OZ_Object)strtol( aObject, NULL, 0 ) ;
	if ( ! Mode ) object = (OZ_Object)SearchObject( aPort, (int)object ) ;

	if ( ReadDM( aPort, object, &head, sizeof(head) ) != sizeof(head) ) {
		Errorf( "Can't read object[0x%08x] header(head) !!\n", object ) ;
		goto error ;
	}

	if ( head.h == LOCAL ) {
		char 		*all = NULL ;
		OZ_ObjectPart	obj ;
		object -= (head.e+1) ;
		if ( ! Mode ) all = (char *)object ;
		object += (part+1) ;
		if ( ReadDM( aPort, object, &head, sizeof(head) ) != sizeof(head) ) {
			Errorf( "Fatal ReadDM(0x%08x,%d) for parts header !!\n", object, sizeof(head) ) ;
			goto error ;
		}
		obj = (OZ_ObjectPart)(all + (int)head.d) ;
		addr = &obj->mem ;
		total = SubObjectInstanceSize( aPort, &obj->info ) ;
		if ( total < 0 ) goto error ;
	} else if ( head.h == STATIC ) {
		OZ_StaticObject	obj = (OZ_StaticObject)object ;
		addr = &obj->mem ;
		total = SubObjectInstanceSize( aPort, &obj->info ) ;
		if ( total < 0 ) goto error ;
		part = -1 ;
	} else if ( head.h == RECORD ) {
		Errorf( "Oh, I'm sorry. Not yet implement RECORD !!\n" ) ;
		addr = head.d ;
		total = head.e - sizeof(head) ;
	} else if ( head.h >= 0 ) {
		/* array */
		/* make pseudo head */
		OZ_Array	obj = (OZ_Array)object ;
		addr = &obj->mem ;
		total = head.e - sizeof(head) ;
	} else {
		Errorf( "Oh, my god, I don't known type: %d !!\n", head.h ) ;
		goto error ;
	}

	if ( head.h == LOCAL || head.h == STATIC ) {
		char	*data ;
		char	value[BUFSIZE] ;
		info = InstInfoGet( Class, cid ) ;
		if ( info == NULL ) goto error ;

		data = malloc( total ) ;
		if ( data == NULL ) {
			Errorf( "Can't allocate work memory(%d) !!\n", total ) ;
			goto error ;
		}
		if ( ReadDM( aPort, addr, data, total ) != total ) {
			Errorf( "Fatal ReadDM(0x%08x,%d) instance data !!\n", addr, total ) ;
			free( data ) ;
			goto error ;
		}

		inst = info->inst ;
		LinePrintf( 0, "%-20s %5d %5d %-20s %d %#08x\n",
				(head.h == LOCAL) ? "-LOCAL-" : "-STATIC-",
					part,
					total,
					IDtoStr(head.a,NULL),
					info->total, head.g ) ;
		for ( i = info->protected+info->private ; i ; i --, inst ++ ) {
			sprintfValue( value, inst->type,
				(inst->type[0] == 'R' ? addr : data)
					 + inst->pos ) ;
			LinePrintf( 0, "%-20s %5d %5d %-20s %s\n",
					inst->name,
					inst->pos,
					inst->size,
					inst->type,
					value ) ;
		}
	} else {
		char	data[BUFSIZE] ;

		LinePrintf( 0, "%-20s %5d %5d %-20s %d\n",
					"-ARRAY-",
					0,
					total,
					ArrayTypeToName(head.a),
					head.h ) ;

		if ( head.a == OZ_RECORD ) {
			int	size = (head.e-sizeof(head))/head.h ;
			for ( i = 0 ; i < head.h ; i ++, addr += size ) {
				LinePrintf( 0, "%#08x: %#08x\n", addr, addr ) ;
			}
		} else {
			int	type ;
			int	size ;
			type = ArrayTypeSize( head.a ) ;
			total = head.h * type ;
			for ( i = 0 ; i < total ; i += size ) {
				size = (total - i) > BUFSIZE ? BUFSIZE : (total - i) ;
				if ( ReadDM( aPort, addr+i, data, size ) != size ) goto error ;
				HexDump( type, addr+i, data, size, 0 ) ;
			}
		}
	}

	ret = OK ;

error:
	return( ret ) ;
}

int
SubProcessAttach( int aPort, int aExID, char *aProcessID )
{
	int	ret = NG ;
	int	curr ;
	int	next ;
	OID	pid ;
	DmLink	link ;
	OzRecvChannel	rchan ;
	Thread	t ;
	ThreadRec	thread ;

	pid = StrToID( OzSiteID, aExID, aProcessID, NULL ) ;
	if ( pid == 0 ) goto error ;

	curr = aPort ;

	if ( (ret=RequestDM( curr, DM_LGETROOT, &pid, sizeof(pid) )) != 0 ) goto error ;
	if ( AnswerDM( curr, &ret, &link, NULL ) == NULL ) goto error ;

	for( rchan = link.chan.rchan, t = link.t ; rchan && t ; rchan = link.chan.rchan, t = link.t ) {
		LinePrintf( 0, "Callee: %s ", IDtoStr(link.callee,NULL) ) ;
		LinePrintf( 0, "Caller: %s ", IDtoStr(link.caller,NULL) ) ;
		LinePrintf( 0, "Thread: 0x%08x RChan: 0x%08x\n", t, link.chan.rchan ) ;
		if ( (ret=RequestDM( curr, DM_LGETNEXT, &rchan, sizeof(rchan) )) != 0 ) goto error ;
		if ( AnswerDM( curr, &ret, &link, NULL ) == NULL ) break ;
		if ( link.t != NULL ) {
			if ( (ret=RequestDM( curr, DM_TRESUME, &t, sizeof(t) )) != 0 ) goto error ;
			if ( AnswerDM( curr, &ret, NULL, NULL ) == NULL ) goto error ;
		} else {
			next = OpenDM( link.callee ) ;
			if ( next < 0 ) goto error ;
			if ( (ret=RequestDM( next, DM_LGETFIND,
					&link.chan.msgID, sizeof(link.chan.msgID) )) != 0 ) goto error ;
			if ( AnswerDM( next, &ret, &link, NULL ) == NULL ) {
				close( next ) ;
				break ;
			}

			if ( (ret=RequestDM( curr, DM_TRESUME, &t, sizeof(t) )) != 0 ) goto error ;
			if ( AnswerDM( curr, &ret, NULL, NULL ) == NULL ) goto error ;

			if ( curr != aPort ) close( curr ) ;
			curr = next ;
		}
	}
	if ( (ret=ReadDM( curr, t, &thread, sizeof(thread)  )) != sizeof(thread) ) goto error ;
	if ( thread.suspend_count <= 1 ) {
		if ( thread.status == SUSPEND ) thread.status = READY ;
		LinePrintf( 0, "Status: %s\n", TStatToName( thread.status ) ) ;
	} else LinePrintf( 0, "Status: <%s> %d\n", TStatToName( thread.status ), thread.suspend_count ) ;
	LinePrintf( 0, "Handle: %d 0x%08x\n", curr, t ) ;
	ret = OK ;

error:
	return( ret ) ;
}

int
SubProcessDetach( int aPort, char *aHandle, char *aThread )
{
	int	ret = NG ;
	int	handle = strtol( aHandle, NULL, 0 ) ;
	Thread	t = (Thread)strtol( aThread, NULL, 0 ) ;
	if ( (ret=RequestDM( handle, DM_TRESUME, &t, sizeof(t) )) != 0 ) goto error ;
	if ( AnswerDM( handle, &ret, NULL, NULL ) == NULL ) goto error ;
	if ( aPort != handle ) close( handle ) ;
	ret = OK ;
error:
	return( ret ) ;
}

int
SubThreadSuspend( int aPort, char *arg )
{
	int		ret ;
	Thread	t ;

	t = (Thread)strtol( arg, NULL, 0 ) ;

	if ( (ret=RequestDM( aPort, DM_TSUSPEND, &t, sizeof(t) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) goto error ;
	return( OK ) ;

error:
	return( NG ) ;
}

int
SubThreadResume( int aPort, char *arg )
{
	int		ret ;
	Thread	t  ;

	t = (Thread)strtol( arg, NULL, 0 ) ;

	if ( (ret=RequestDM( aPort, DM_TRESUME, &t, sizeof(t) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) goto error ;
	return( OK ) ;

error:
	return( NG ) ;
}

int
SubThreadList( int aPort, char *arg )
{
	ObjectTableEntry	entry ;
	DmTList		*list ;
	int		i ;
	int		ret ;

	entry = (ObjectTableEntry)strtol( arg, NULL, 0 ) ;

	if ( (ret=RequestDM( aPort, DM_TLIST, &entry, sizeof(entry) )) != 0 ) goto error ;
	if ( (list=AnswerDM( aPort, &ret, NULL, NULL )) == NULL ) goto error ;

	/* LinePrintf( 0, "ProcessID        ForkedByObject   ThreadID   ThreadStatus\n" ) ; */
	for ( i = 0 ; i < list->count ; i ++ ) {
		LinePrintf( 0, "0x%08x ", list->slot[i].t ) ;
		LinePrintf( 0, "%s ", IDtoStr(list->slot[i].pid,NULL) ) ;
		LinePrintf( 0, "%s ", IDtoStr(list->slot[i].caller,NULL) ) ;
		if ( list->slot[i].suspend_count <= 1 ) {
			LinePrintf( 0, "%s ", TStatToName(list->slot[i].status) ) ;
		} else {
			LinePrintf( 0, "%s:%d ",
					TStatToName(list->slot[i].status),
					list->slot[i].suspend_count ) ;
		}
		LinePrintf( 0, "\n" ) ;
	}
	return( OK ) ;

error:
	return( NG ) ;
}

int
RecordDump( int aPort, InstInfo aInfo, char *data )
{
	int		ret = NG ;
	int		i ;
	InstName	inst ;
	char		value[BUFSIZE] ;

	inst = aInfo->inst ;
	for ( i = aInfo->total ; i ; i --, inst ++ ) {
		if ( inst->type[0] == 'R' ) {
			InstInfo	info ;
			ClassID		cid = (ClassID)StrToID( 0, 0,
						inst->type+1, NULL ) ;

			info = InstInfoGet( Class, cid ) ;
			if ( info == NULL ) goto error ;
			LinePrintf( 0, "%-20s %5d %5d %-20s %d\n",
					inst->name,
					inst->pos,
					inst->size,
					inst->type,
					info->total) ;
			RecordDump( aPort, info, data + inst->pos ) ;
		} else {
			sprintfValue( value, inst->type, data + inst->pos ) ;
			LinePrintf( 0, "%-20s %5d %5d %-20s %s\n",
					inst->name,
					inst->pos,
					inst->size,
					inst->type,
					value ) ;
		}
	}

	ret = OK ;

error:
	return( ret ) ;
}

int
SubRecord( int aPort, char *aRecord, char *aClass )
{
	int		ret = NG ;
	int		i ;
	InstInfo	info ;
	InstName	inst ;
	void		*addr ;
	char		*data ;
	int		size ;
	ClassID		cid = (ClassID)StrToID( 0, 0, aClass, NULL ) ;
	char		value[BUFSIZE] ;

	addr = (void *)strtol( aRecord, NULL, 0 ) ;

	info = InstInfoGet( Class, cid ) ;
	if ( info == NULL ) goto error ;
	inst = info->inst+info->total-1 ;
	size = inst->pos + inst->size ;

	data = malloc( size ) ;
	if ( data == NULL ) {
		Errorf( "Can't allocate work memory(%d) !!\n", size ) ;
		goto error ;
	}
	if ( (ret=ReadDM( aPort, addr, data, size )) != size ) {
		Errorf( "Can't read record[0x%08x] (%d) !!\n", addr, size ) ;
		goto error ;
	}

	inst = info->inst ;
	LinePrintf( 0, "%-20s %5d %5d %-20s %d\n",
			"-Record-", 0, size, aClass, info->total ) ;
	RecordDump( aPort, info, data + inst->pos ) ;

	ret = OK ;

error:
	return( ret ) ;
}

int
SubObjectDebug( int aPort, char *aObject, char *aPart, char *aDFlags )
{
	int		ret = NG ;
	OZ_Object	object ;
	OZ_HeaderRec	head ;
	unsigned int	dflags ;
	void		*addr ;

	object = (OZ_Object)strtol( aObject, NULL, 0 ) ;
	if ( ! Mode ) object = (OZ_Object)SearchObject( aPort, (int)object ) ;
	dflags = (unsigned int)strtol( aDFlags, NULL, 0 ) ;

	if ( (ret=ReadDM( aPort, object, &head, sizeof(head) )) != sizeof(head) ) {
		Errorf( "Can't read object[0x%08x] header(head) !!\n", object ) ;
		goto error ;
	}

	if ( head.h == LOCAL || head.h == STATIC ) {
		OZ_ObjectPart	obj ;
		int		part = (int)strtol( aPart, NULL, 0 ) ;
		if ( head.h == LOCAL ) {
			object -= head.e ;
			object += part ;
		}
		if ( (ret=DebugFlagsDM( aPort, &(object->head.g), dflags )) != sizeof(dflags) ) {
			Errorf( "Fatal DebugFlagsDM(0x%08x) for parts header !!\n", object ) ;
			goto error ;
		}
	}
	ret = OK ;

error:
	return( ret ) ;
}

int
SubArray( int aPort, char *aObject, char *aStartIndex, char *aEndIndex )
{
	int		ret = NG ;
	OZ_Object	object ;
	OZ_HeaderRec	head ;
	int		i, j, k ;
	int		total ;
	int		size ;
	int		sindex, eindex, count ;
	char		data[BUFSIZE] ;
	char		*addr ;
	char		*cp ;

	object = (OZ_Object)strtol( aObject, NULL, 0 ) ;
	if ( ! Mode ) object = (OZ_Object)SearchObject( aPort, (int)object ) ;

	if ( (ret=ReadDM( aPort, object, &head, sizeof(head) )) != sizeof(head) ) {
		Errorf( "Can't read object[0x%08x] header(head) !!\n", object ) ;
		goto error ;
	}

	if ( head.h < 0 ) {
		Errorf( "Isn't array object[%#08x] !!\n", object ) ;
		goto error ;
	}

	total = head.e - sizeof(head) ;
	if ( aStartIndex ) {
		sindex = (int)strtol( aStartIndex, NULL, 0 ) ;
		if ( head.h <= sindex  ) {
			Errorf( "Over index of array[%#08x] !!\n", object ) ;
			goto error ;
		}
		if ( aEndIndex ) {
			eindex = (int)strtol( aEndIndex, NULL, 0 ) ;
			if ( eindex < 0 ) eindex = head.h -1 ;
			if ( head.h <= eindex  ) {
				Errorf( "Over index of array[%#08x] !!\n", object ) ;
				goto error ;
			}
		} else eindex = sindex ;
	} else {
		sindex = 0 ;
		eindex = head.h -1 ;
	}
	count = eindex - sindex + 1 ;
	addr = (char *)(object + 1) ;
	LinePrintf( 0, "%-20s %5d %5d %-20s %d\n",
				"-ARRAY-",
				0,
				total,
				ArrayTypeToName(head.a),
				head.h ) ;

	if ( head.a == OZ_RECORD ) {
		size = (head.e-sizeof(head))/head.h ;
		addr += size * sindex ;
		for ( i = 0 ; i < count ; i ++, addr += size ) {
			LinePrintf( 0, "%#08x: *%#08x\n", addr, addr ) ;
		}
	} else {
		int	work ;
		size = ArrayTypeSize( head.a ) ;
		total = size * count ;
		addr += size * sindex ;
		for ( i = 0 ; i < total ; i += work ) {
			work = (total - i) > BUFSIZE ? BUFSIZE : (total - i) ;
			if ( (ret=ReadDM( aPort, addr+i, data, work )) != work ) goto error ;
			for ( j = 0 ; j < work ; j += size ) {
				LinePrintf( 0, "%#08x: ", addr+i+j ) ;
				cp = data + j ;
				if ( head.a == OZ_LOCAL_OBJECT
					|| head.a == OZ_STATIC_OBJECT
					|| head.a == OZ_ARRAY ) {
					LinePrintf( 0, "*0x" ) ;
				} else if ( head.a == OZ_GLOBAL_OBJECT ) {
					/* Nothing */;
				} else {
					LinePrintf( 0, "0x" ) ;
				}
				for ( k = 0, cp = data + j ; k < size ; k ++, cp ++ ) {
					LinePrintf( 0, "%02.2x", 0x0ff & *cp ) ;
				}
				LinePrintf( 0, "\n" ) ;
			}
		}
	}

	ret = OK ;

error:
	return( ret ) ;
}

int
SubHead( int aPort, char *aObject )
{
	int		ret = NG ;
	int		flag ;
	OZ_Object	object ;
	OZ_HeaderRec	head ;
	void		*addr ;

	if ( *aObject == '@' ) {
		flag = 1 ;
		object = (OZ_Object)strtol( aObject+1, NULL, 0 );
	} else {
		flag = 0 ;
		object = (OZ_Object)strtol( aObject, NULL, 0 );
	}
	if ( ! Mode ) object = (OZ_Object)SearchObject( aPort, (int)object ) ;

	if ( (ret=ReadDM( aPort, object, &head, sizeof(head) )) != sizeof(head) ) {
		Errorf( "Can't read object[0x%08x] header(head) !!\n", object ) ;
		goto error ;
	}

	if ( flag && head.h == LOCAL ) {
		object -= (head.e+1) ;
		if ( (ret=ReadDM( aPort, object, &head, sizeof(head) )) != sizeof(head) ) {
			Errorf( "Can't read object[0x%08x] header(head) !!\n", object ) ;
			goto error ;
		}
	}
	if ( head.h == LOCAL ) {
		LinePrintf( 0, "LOCAL %d %u %s %#08x\n",
			head.h, head.e, IDtoStr(head.a,NULL), head.g ) ;
	} else if ( head.h == STATIC ) {
		LinePrintf( 0, "STATIC %d %u %s %#08x\n",
			head.h, head.e, IDtoStr(head.a,NULL), head.g ) ;
	} else if ( flag ) {
		LinePrintf( 0, "OBJECT %d %u %s %#08x\n",
			head.h, head.e, IDtoStr(head.a,NULL), head.g ) ;
	} else {
		LinePrintf( 0, "ARRAY %d %u %s\n",
			head.h, head.e, ArrayTypeToName(head.a) ) ;
	}
	ret = OK ;

error:
	return( ret ) ;
}

int
SubID( int aExID )
{
	OID	id ;
	id = StrToID( OzSiteID, aExID , "0", NULL ) ;
	LinePrintf( 0, "%s\n", IDtoStr(id,NULL) ) ;
	return( 0 ) ;
}

int
SubType( char *aClass, char *aIndex )
{
	int		ret = -1 ;
	InstInfo	info ;
	InstName	inst ;
	ClassID		cid ;
	int		index ;

	if ( aClass ) cid = (ClassID)StrToID( 0, 0, aClass, NULL ) ;
	else goto error ;

	if ( aIndex ) index = strtol( aIndex, NULL, 16 )  ;
	else goto error ;

	info = InstInfoGet( Class, cid ) ;
	if ( info == 0 ) goto error ;

	if ( 0 <= index && index < info->total ) {
		inst = info->inst + index ;
		LinePrintf( 0, "%-20s %5d %5d %-20s\n",
			inst->name, inst->pos, inst->size, inst->type ) ;
	} else goto error ;
	ret = 0 ;

error:
	return( ret ) ;
}

#define	CMDNAME_LENGTH		15
#define	CMDNAME_GETENTRY	0
#define	CMDNAME_RELENTRY	1
#define	CMDNAME_SUSPEND		2
#define	CMDNAME_RESUME		3
#define	CMDNAME_CONFIG		4
#define	CMDNAME_INSTANCE	5
#define	CMDNAME_ATTACH		6
#define	CMDNAME_DETACH		7
#define	CMDNAME_TSUSPEND	8
#define	CMDNAME_TRESUME		9
#define	CMDNAME_TLIST		10
#define	CMDNAME_RECORD		11
#define	CMDNAME_ODEBUG		12
#define	CMDNAME_ARRAY		13
#define	CMDNAME_HEAD		14
#define	CMDNAME_ID		15
#define	CMDNAME_TYPE		16
#define	CMDNAME_QUIT		17
static	char	*CmdNameTable = "getentry       "
				"relentry       "
				"suspend        "
				"resume         "
				"config         "
				"instance       "
				"attach         "
				"detach         "
				"tsuspend       "
				"tresume        "
				"tlist          "
				"record         "
				"odebug         "
				"array          "
				"heady          "
				"id             "
				"type           "
				"quit           " ;

int
CmdInspect( int aPort, OID aTarget, char *aArgv[], int aArgc )
{
static	char	*space = " \t:" ;
	int	ret ;
	char	buf[256] ;
	char	*cmdName ;
	char	*token ;

	LOOP {
		LinePrompt( "CMD>>" ) ;
		if ( LineGets( buf, 256 ) == NULL ) break ;
		cmdName = strtok( buf, space ) ;
		if ( cmdName == NULL ) continue ;

		cmdName = strstr( CmdNameTable, cmdName ) ;
		if ( cmdName == NULL ) {
			Errorf( "Invalid command name: '%s' !!\n", buf ) ;
			continue ;
		}

		token = strtok( NULL, space ) ;

		switch( (cmdName-CmdNameTable)/CMDNAME_LENGTH ) {
		case	CMDNAME_GETENTRY:
			ret = SubObjectGetEntry( aPort, EXECID(aTarget), token ) ;
			break ;
		case	CMDNAME_RELENTRY:
			ret = SubObjectRelEntry( aPort, token ) ;
			break ;
		case	CMDNAME_SUSPEND:
			ret = SubObjectSuspend( aPort, token ) ;
			break ;
		case	CMDNAME_RESUME:
			ret = SubObjectResume( aPort, token ) ;
			break ;
		case	CMDNAME_CONFIG:
			ret = SubObjectConfig( aPort, token ) ;
			break ;
		case	CMDNAME_INSTANCE:
			ret = SubObjectInstance( aPort, token, strtok(NULL,space), strtok(NULL,space) ) ;
			break ;
		case	CMDNAME_ATTACH:
			ret = SubProcessAttach( aPort, EXECID(aTarget), token );
			break ;
		case	CMDNAME_DETACH:
			ret = SubProcessDetach( aPort, token, strtok(NULL,space) ) ;
			break ;
		case	CMDNAME_TSUSPEND:
			ret = SubThreadSuspend( aPort, token ) ;
			break ;
		case	CMDNAME_TRESUME:
			ret = SubThreadResume( aPort, token ) ;
			break ;
		case	CMDNAME_TLIST:
			ret = SubThreadList( aPort, token ) ;
			break ;
		case	CMDNAME_RECORD:
			ret = SubRecord( aPort, token, strtok(NULL,space) ) ;
			break ;
		case	CMDNAME_ODEBUG:
			ret = SubObjectDebug( aPort, token, strtok(NULL,space), strtok(NULL,space) ) ;
			break ;
		case	CMDNAME_ARRAY:
			ret = SubArray( aPort, token, strtok(NULL,space), strtok(NULL,space) ) ;
			break ;
		case	CMDNAME_HEAD:
			ret = SubHead( aPort, token ) ;
			break ;
		case	CMDNAME_ID:
			ret = SubID( EXECID(aTarget) ) ;
			break ;
		case	CMDNAME_TYPE:
			ret = SubType( token, strtok(NULL,space) ) ;
			break ;
		case	CMDNAME_QUIT:
			return( OK ) ;
			break ;
		}
		if ( ret < 0 ) LinePrintf( 0, "!Error\n" ) ;
	}

error:
	return( NG ) ;
}
