/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<unistd.h>
#include	<stdio.h>
#include	<stdlib.h>
#include	<string.h>
#include	<fcntl.h>
#include	<memory.h>
#include	<malloc.h>
#include	<sys/param.h>
#include	"id.h"
#include	"print.h"
#include	"io.h"
#include	"name.h"
#include	"class.h"
#include	"code.h"
#include	"inst.h"
#include	"inspect.h"
#include	"debugChannel.h"
#include	"debugFunction.h"
#include	"ot.h"
#include	"oz++/type.h"

#define	LOOP	for(;;)
#define	OK	0
#define	NG	(-1)

#define	BUFSIZE		1024

#define	CASE(xXvAlUe,xXnAmE)	case xXvAlUe: xXnAmE = #xXvAlUe ; break

char	*CmdName ;
char	*OzRoot = NULL ;
char	*OzClassPath = NULL ;
int	OzSiteID = 0 ;
extern	char	*OwnerIdent ;
extern	char	*IPaddress ;
extern	char	*PortNumber ;
int	Interp = 0 ;
int	Class = 0 ;
int	Mode = 2 ;	/* 0 : File, 1 : Local, 2 : Nucleus */

int
OzError( char *aMsg )
{
	fprintf( stderr, aMsg ) ;
	fflush( stderr ) ;
	return( OK ) ;
}

void
Errorf( char *aFormat, ... )
{
	va_list	args ;

	if ( CmdName != NULL ) fprintf( stderr, "%s: ", CmdName ) ;
	va_start( args, aFormat ) ;
	vfprintf( stderr, aFormat, args ) ;
	va_end( args ) ;
	fflush( stderr ) ;
}


void
Usage()
{
	char	*cmdName = CmdName ;
	CmdName = NULL ;
	Errorf( "Usage: %s <Target ID>\n", cmdName ) ;
	exit( 1 ) ;
}

int
CmdLine( int argc, char *argv[] )
{
extern  char    *optarg ;
extern  int     optind, opterr ;
	char    ch, *ptr ;
	int	err = 0 ;
	int	exid ;

	while ( (ch=getopt( argc, argv, "X:FLN:RA:C:hH:iTl:" )) != EOF ) {
		switch( ch ) {
		case 'X' :
			exid = strtol( optarg, NULL, 16 ) ;
			Class = OpenLocal( exid ) ;
			if ( 0 <= Class ) {
				char	buf[MAXPATHLEN+1] ;
				sprintf( buf, "%s/images/%06x/classes",
						OzRoot, exid ) ;
				OzClassPath = strdup( buf ) ;
			} else Class = 0 ;
			break ;
		case 'F' :
			Mode = 0 ;	/* File Mode */
			break ;
		case 'L' :
			Mode = 1 ;	/* Local Mode */
			break ;
		case 'R' :		/* Ignore */
			break ;
		case 'i' :
			Interp = 1 ;
			break ;
		case 'A' :
		{
			char	*str ;
			str = strdup( optarg ) ;
			ptr = strchr( str, '@' ) ;
			if ( ptr ) {
				*ptr = '\0' ;
				PortNumber = str ;
				IPaddress  = ptr + 1 ;
			} else {
				free( str ) ;
				err ++ ;
			}
		}
			break ;
		case 'l' :
			OwnerIdent = optarg ;
			break ;
		case 'H' :
			OzRoot = optarg ;
			break ;
		case 'C' :
			OzClassPath = optarg ;
			break ;
		case 'T' :
			LineTclMode = 1 ;
			break ;
		case 'N' :
			CmdName = optarg ;
			break ;
		case 'h' :
			err ++ ;
			break ;
		default :
			Errorf( "Unknown option '%c'\n", ch ) ;
			err ++ ;
		}
		if ( err ) break ;
	}

	if ( err || argc < 1 || argc == optind ) Usage() ;

	return( optind ) ;
}

long long
ToID( int aSite, int aExec, int aBase )
{
	long long	id ;

	id = aSite ;
	id <<= 24 ; id |= aExec ;
	id <<= 24 ; id |= aBase ;
	return( id ) ;
}

int
DumpValue( int aPort, int aCount[3], void *aData, int aIndent )
{
	int	ret = NG ;
	int	total ;
	char	*data = NULL ;
	unsigned int	pointer_size ;
	unsigned int	value_size ;
	unsigned int	cond_size ;
	unsigned int	value_pos ;
	unsigned int	cond_pos ;
	OZ_Object	*pointer ;
	unsigned int	*value ;
	OZ_Condition	cond ;

	total = 0 ;
	pointer_size = aCount[0] * sizeof(void *) ;
	total += pointer_size ;
	total += (aCount[0] & 0x00000001) * sizeof(void *) ;
	value_pos = total ;
	value_size = aCount[1] & 0xfffffff8 ;
	total += value_size ;
	total += (aCount[1] & 0x00000007) ? 0x08 : 0x00 ;
	cond_pos = total ;
	cond_size = aCount[2] * sizeof(OZ_ConditionRec) ;
	total += cond_size ;

	data = malloc( total ) ;
	if ( data == NULL ) {
		Errorf( "Can't  allocate work memory(%d) !!\n", total ) ;
		goto error ;
	}
	pointer = (OZ_Object *)data ;
	value = (unsigned int *)(data + value_pos) ;
	cond = (OZ_Condition)(data + cond_pos) ;
	
	if ( (ret=ReadDM( aPort, aData, data, total )) != total ) goto error ;

#if	1
	if ( aCount[0] ) {
		printf( "%*s[Pointer]\n", aIndent, "" ) ;
		HexDump( 4, aData , pointer, pointer_size, aIndent+2 ) ;
	}
	if ( aCount[1] ) {
		printf( "%*s[Data   ]\n", aIndent, "" ) ;
		HexDump( 1, aData + value_pos, value, value_size, aIndent+2 ) ;
	}
	if ( aCount[2] ) {
		printf( "%*s[Zero   ]\n", aIndent, "" ) ;
		HexDump( 4, aData + cond_pos, cond, cond_size, aIndent+2 ) ;
	}
#else
	printf( "%*s[Pointers]%c", aIndent, "", aCount[0] ? '\n' : ' ' ) ;
	if ( aCount[0] ) HexDump( 4, aData , pointer, pointer_size, aIndent ) ;
	else printf( "*Nothing*\n" ) ;
	printf( "%*s[Data    ]%c", aIndent, "", aCount[1] ? '\n' : ' ' ) ;
	if ( aCount[1] ) HexDump( 1, aData + value_pos, value, value_size, aIndent ) ;
	else printf( "*Nothing*\n" ) ;
	printf( "%*s[Zero    ]%c", aIndent, "", aCount[2] ? '\n' : ' ' ) ;
	if ( aCount[2] ) HexDump( 4, aData + cond_pos, cond, cond_size, aIndent ) ;
	else printf( "*Nothing*\n" ) ;
#endif

	ret = total ;

error:
	if ( data != NULL ) free( data ) ;
	return( ret ) ;
}

int
DumpInstance0( int aPort, OZ_AllocateInfo aInfo, void *aData, int aIndent )
{
	int	ret = NG ;
	char	*data = aData ;
	int	count[3] ;

	count[0] = aInfo->number_of_pointer_protected ;
	count[1] = aInfo->data_size_protected ;
	count[2] = aInfo->zero_protected ;
	if ( count[0] || count[1] || count[2] ) {
		printf( "%*s----- Protected -----\n", aIndent, "" ) ;
		if ( (ret=DumpValue( aPort, count, data, aIndent)) < 0 ) goto error ;
	} else ret = 0 ;

	count[0] = aInfo->number_of_pointer_private ;
	count[1] = aInfo->data_size_private ;
	count[2] = aInfo->zero_private ;
	if ( count[0] || count[1] || count[2] ) {
		printf( "%*s----- Private   -----\n", aIndent, "" ) ;
		if ( (ret=DumpValue( aPort, count, data+ret, aIndent)) < 0 ) goto error ;
	}
	ret = OK ;

error:
	return( ret ) ;
}

#define	CEILING(vAlUe)	(((vAlUe)&0x07)?(((vAlUe)&~0x07)+0x08):(vAlUe))
int
DumpInstance( int aPort, OZ_ClassPart aPart, void *aData, int aIndent )
{
	int		ret = NG ;
	int		i ;
	int		total ;
	InstInfo	info ;
	InstName	inst ;
	char		*data = NULL ;
	char		value[BUFSIZE] ;

	info = InstInfoGet( Class, aPart->cid ) ;
	if ( info == NULL ) goto error ;

	total = aPart->info.number_of_pointer_protected * sizeof(void *) ;
	total += CEILING( total ) ;
	total += aPart->info.data_size_protected ;
	total += CEILING( total ) ;
	total += aPart->info.zero_protected * sizeof(OZ_ConditionRec) ;
	total += aPart->info.number_of_pointer_private * sizeof(void *) ;
	total += CEILING( total ) ;
	total += aPart->info.data_size_private ;
	total += CEILING( total ) ;
	total += aPart->info.zero_private * sizeof(OZ_ConditionRec) ;

	data = malloc( total ) ;
	if ( data == NULL ) {
		Errorf( "Can't allocate work memory(%d) !!\n", total ) ;
		goto error ;
	}
	
	if ( (ret=ReadDM( aPort, aData, data, total )) != total ) goto error ;

	inst = info->inst ;
	LineFlush() ;
	LinePrintf( aIndent, "----- Protected -----\n" ) ;
	for ( i = 0 ; i < info->protected ; i ++, inst ++ ) {
		sprintfValue( value, inst->type, data + inst->pos ) ;
		LinePrintf( aIndent, "%-30s : %s\n", inst->name, value ) ;
	}

	LinePrintf( aIndent, "----- Private   -----\n" ) ;
	for ( i = 0 ; i < info->private ; i ++, inst ++ ) {
		sprintfValue( value, inst->type, data + inst->pos ) ;
		LinePrintf( aIndent, "%-30s : %s\n", inst->name, value ) ;
	}

	ret = OK ;

error:
	if ( data != NULL ) free( data ) ;
	return( ret ) ;
}

int
DumpArrayObject( int aPort, OZ_Object aObject, int aIndent )
{
	int		i ;
	int		ret = NG ;
	int		total ;
	int		size ;
	int		type ;
	OZ_HeaderRec	head ;
	char		*addr ;
	char		data[BUFSIZE] ;

	if ( (ret=ReadDM( aPort, aObject, &head, sizeof(head) )) != sizeof(head) ) goto error ;

	LineFlush() ;
	LinePrintf( aIndent, "*Array*  Size: %u  #: %d  Type: ", head.e, head.h ) ;
	if ( head.a < 0x01000000ll ) {
		type = ArrayTypeSize( head.a ) ;
		LinePrintf( aIndent, "%s\n", ArrayTypeToName(head.a) ) ;
	} else {
		LinePrintf( aIndent, "RECORD[0x%s]\n", IDtoStr(head.a,NULL) ) ;
		Errorf( "I'm sorry, RECORD not implement !!\n" ) ;
		goto error ;
	}

	addr = (char *)(aObject + 1) ;
	total = head.h * type ;
	for ( i = 0 ; i < total ; i += size ) {
		size = (total - i) > BUFSIZE ? BUFSIZE : (total - i) ;
		if ( (ret=ReadDM( aPort, addr+i, data, size )) != size ) goto error ;
		HexDump( type, addr+i, data, size, aIndent+2 ) ;
	}

	ret = OK ;

error:
	return( ret ) ;
}

int
DumpStaticObject( int aPort, OZ_Object aObject, int aIndent )
{
	int			i ;
	int			ret = NG ;
	int			size ;
	OZ_HeaderRec		head ;
	OZ_AllocateInfoRec	info ;
	OZ_ClassInfo		class ;

	if ( (ret=ReadDM( aPort, aObject, &head, sizeof(head) )) != sizeof(head) ) goto error ;

	LineFlush() ;

	LinePrintf( aIndent, "*Static*  Size: %u  ConfigID: %s\n", head.e, IDtoStr(head.a,NULL) ) ;

	class = ClassInfoGet( Class, head.a ) ;
	if ( class == NULL ) goto error ;

	LinePrintf( aIndent, "                              "
					" --- Protected ----  --- Private ----\n" ) ;
	LinePrintf( aIndent, "      ObjectType CompiledVersionID  "
					"[PNum   Size  Zero] [PNum   Size  Zero]\n" ) ;
	LinePrintf( aIndent, "        %+8d 0x%s ", head.h, IDtoStr(class->parts[0]->cid,NULL) ) ;
	LinePrintf( aIndent, "[%5u %5u %5u] [%5u %5u %5u]\n",
				class->parts[0]->info.number_of_pointer_protected,
				class->parts[0]->info.data_size_protected,
				class->parts[0]->info.zero_protected,
				class->parts[0]->info.number_of_pointer_private,
				class->parts[0]->info.data_size_private,
				class->parts[0]->info.zero_private ) ;
	DumpInstance( aPort, class->parts[0], ((OZ_AllocateInfo)(aObject+1) + 1), aIndent + 2 ) ;
	ret = OK ;

error:
	return( ret ) ;
}

int
DumpObjectPart( int aPort, OZ_ClassInfo aClass, OZ_Header aHead, int aIndent )
{
	int			ret = NG ;

	LineFlush() ;

	LinePrintf( aIndent, "                                     "
					" --- Protected ----  --- Private ----\n" ) ;
	LinePrintf( aIndent, "PartNo ObjectType CompiledVersionID  "
					"[PNum   Size  Zero] [PNum   Size  Zero]\n" ) ;
	LinePrintf( aIndent, "%6d   %+8d 0x%s ", aHead->e, aHead->h, IDtoStr(aHead->a,NULL) ) ;
	LinePrintf( aIndent, "[%5u %5u %5u] [%5u %5u %5u]\n",
				aClass->parts[aHead->e]->info.number_of_pointer_protected,
				aClass->parts[aHead->e]->info.data_size_protected,
				aClass->parts[aHead->e]->info.zero_protected,
				aClass->parts[aHead->e]->info.number_of_pointer_private,
				aClass->parts[aHead->e]->info.data_size_private,
				aClass->parts[aHead->e]->info.zero_private ) ;
	DumpInstance( aPort, aClass->parts[aHead->e], ((OZ_AllocateInfo)aHead->d) + 1, aIndent + 2 ) ;

	ret = OK ;

error:
	return( ret ) ;
}

int
DumpLocalObject( int aPort, OZ_Object aObject, int aIndent )
{
	int			i ;
	int			ret = NG ;
	int			size ;
	OZ_Header		top ;
	OZ_HeaderRec		head ;
	OZ_ObjectAll		all = NULL ;
	OZ_Object		obj ;
	OZ_ClassInfo		class ;

	if ( (ret=RequestDM( aPort, DM_OGETTOP, &aObject, sizeof(aObject) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, &top, NULL ) == NULL ) goto error ;

	if ( (ret=ReadDM( aPort, top, &head, sizeof(head) )) != sizeof(head) ) goto error ;

	LineFlush() ;
	LinePrintf( aIndent, "*Local*  Size: %u  #: %d  ConfigID: %s\n",
				head.e, head.h, IDtoStr(head.a,NULL) ) ;

	class = ClassInfoGet( Class, head.a ) ;
	if ( class == NULL ) goto error ;
	LinePrintf( aIndent, "-ConfigContents-\n" ) ;
	for ( i = 0 ; i < class->number_of_parts ; i ++ ) {
		LinePrintf( aIndent, "%s\n", IDtoStr(class->parts[i]->cid,NULL) ) ;
	}

	if ( head.h > 0 ) {
		size = sizeof(OZ_HeaderRec) * ( head.h ) ;
		all = (OZ_ObjectAll)malloc( size ) ;
		if ( all == NULL ) {
			Errorf( "Can't allocate work memory(%d) !!\n", size ) ;
			goto error ;
		}
		if ( (ret=ReadDM( aPort,top+1, all, size )) != size ) goto error ;
	} else goto error ;

	for ( i = 0 ; i < head.h ; i ++ ) DumpObjectPart( aPort, class, all->head+i, aIndent ) ;
	ret = OK ;

error:
	if ( all != NULL ) free( all ) ;
	return( ret ) ;
}

int
DumpObject( int aPort, OZ_Object aObject, int aPart )
{
	int			ret = NG ;
	OZ_HeaderRec		head ;

	if ( (ret=ReadDM( aPort, aObject, &head, sizeof(head) )) != sizeof(head) ) goto error ;

	switch( head.h  ) {
	case	LOCAL:
		ret = DumpLocalObject( aPort, aObject, 0 ) ;
		break ;
	case	STATIC:
		ret = DumpStaticObject( aPort, aObject, 0 ) ;
		break ;
	case	RECORD:
		Errorf( "I'm sorry, not implement RECORD !!\n" ) ;
		break ;
	default:
		if ( 0 < head.h ) ret = DumpArrayObject( aPort, aObject, 0 ) ;
		else Errorf( "Unknown Object type %d !!\n", head.h ) ;
	}

error:
	return( ret ) ;
}

int
SuspendGlobal( int aPort, OID aTarget, DmOEntry *aEntry )
{
	int	ret = NG ;

	if ( (ret=RequestDM( aPort, DM_OGETENTRY, &aTarget, sizeof(aTarget) )) != 0 ) {
		Errorf( "Error request(DM_OGETENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, aEntry, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	if ( (ret=RequestDM( aPort, DM_OSUSPEND, &aEntry->entry, sizeof(aEntry->entry) )) != 0 ) {
		Errorf( "Error request(DM_OSUSPEND) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't suspend %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	return( OK ) ;
}

int
ResumeGlobal( int aPort, OID aTarget, DmOEntry *aEntry )
{
	int	ret = NG ;

	if ( (ret=RequestDM( aPort, DM_ORESUME, &aEntry->entry, sizeof(aEntry->entry) )) != 0 ) {
		Errorf( "Error request(DM_ORESUME) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't resume %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	if ( (ret=RequestDM( aPort, DM_ORELENTRY, &aEntry->entry, sizeof(aEntry->entry) )) != 0 ) {
		Errorf( "Error request(DM_ORELENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't release %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	return( OK ) ;
}

int
CmdDumpThreadStack( int aPort, Thread aTarget, int aIndent )
{
	int	ret = NG ;
	struct	{
		void	*addr ;
		char	name[1] ;
		int	size ;
	} *sym ;
	ThreadRec	t ;
	unsigned long	sp ;
	unsigned long	pc ;
	unsigned long	self ;
static	struct	regs_in {
		int	r_l0; int	r_l1; int	r_l2; int	r_l3; int	r_l4;
		int	r_l5; int	r_l6; int	r_l7;
		int	r_i0; int	r_i1; int	r_i2; int	r_i3; int	r_i4;
		int	r_i5; int	r_i6; int	r_i7;
	} cpu ;
	unsigned long addr ;
	char	*cp ;

	if ( aTarget == 0 ) {
		char	buf[256] ;
		fprintf( stderr, "Thread Address ? " ) ;
		gets( buf ) ;
		aTarget = (Thread)strtol( buf, NULL, 0 ) ;
		if ( aTarget == 0 ) {
			Errorf( "Give me Thread Address !!\n" ) ;
			exit ( 1 ) ;
		}
	}

	if ( (ret=RequestDM( aPort, DM_TSUSPEND, &aTarget, sizeof(aTarget) )) != 0 ) {
		aTarget = NULL ;
		goto error ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		aTarget = NULL ;
		goto error ;
	}

	if ( (ret=ReadDM( aPort, aTarget, &t, sizeof(t) )) != sizeof(t) ) goto error ;

	LineFlush() ;
	LinePrintf( aIndent,	"JMPBUF on:%08x sm:%08x sp:%08x pc:%08x npc:%08x psr:%08x\n"
				"       g1:%08x o0:%08x wb:%08x\n",
				t.context[0], t.context[1], t.context[2], t.context[3],
				t.context[4], t.context[5], t.context[6], t.context[7],
				t.context[8] ) ;

	for ( sp = (unsigned long)t.context[2], pc = (unsigned long)t.context[3] ;
			/* Nothing */ ;
			sp = (unsigned long)cpu.r_i6, pc = (unsigned long)cpu.r_i7 ) {
	
		if ( (ret=ReadDM( aPort, (void *)sp, &cpu, sizeof(cpu) )) != sizeof(cpu) ) goto error ;

		if ( ! cpu.r_i6 ) break ;

		self = cpu.r_i0 ;
		addr = pc ;
		addr += 8 ;
		if ( (ret=RequestDM( aPort, DM_SSEARCH, &addr, sizeof(addr) )) != 0 ) goto error ;
		if ( (sym=AnswerDM( aPort, &ret, NULL, NULL )) == NULL ) goto error ;
		if ( addr < 0x0fffffff || cpu.r_i0 == 0 ) {
			cp = strchr( sym->name, ':' ) ;
			if ( cp ) *cp = '\0' ;
			LinePrintf( 0, "\n0x%08x <%s>\n", addr, sym->name ) ;
		} else {
			int		i ;
			OZ_HeaderRec	head ;
			char		*name = NULL ;
			ClassID		cid ;
			OZ_ClassInfo	class ;
			int		part ;
			DmCCode		code ;
			char		symName[BUFSIZE] ;

#if	0
			if ( (ret=ReadDM(aPort,(void *)cpu.r_i0,&head,sizeof(head))) != sizeof(head) ) {
				Errorf( "Can't read header !!\n" ) ;
				break ;
			}
			if ( head.h == -2 ) {
				OZ_Header	h = (OZ_Header)cpu.r_i0 ;
				h -= (head.e + 1 );
				if ( (ret=ReadDM( aPort, h, &head, sizeof(head) )) != sizeof(head) ) {
					Errorf( "Can't read top !!\n" ) ;
					break ;
				}
			}
			LinePrintf( 0, "\n" ) ;
			class = ClassInfoGet( Class, head.a ) ;
			addr = pc + 8 ;
			for ( i = 0 ; i < class->number_of_parts ; i ++ ) {
				cid = class->parts[i]->cid ;

				if ( (ret=RequestDM( aPort, DM_CCODE, &cid, sizeof(cid) )) != 0 ) {
					Errorf( "Can't request DM_CCODE to DM !!\n" ) ;
					break ;
				}
				if ( AnswerDM( aPort, &ret, &code, NULL ) == NULL ) continue ;
				if ( code.base <= pc && pc <= code.base + code.size ) {
					if ( (cp=ClassCodeSymbolSearch(Class,cid,code.base,&addr)) != NULL ) {
						name = cp ;
						part = i ;
					}
				}
			}
#else
			LinePrintf( 0, "\n" ) ;
			addr = pc + 8 ;
			if ( (ret=RequestDM( aPort, DM_CGETID, &addr, sizeof(addr) )) != 0 ) {
				Errorf( "Can't request DM_CGETID to DM !!\n" ) ;
				break ;
			}
			if ( AnswerDM( aPort, &ret, &cid, NULL ) == NULL ) {
				name = NULL ;
			} else {
				if ( (ret=RequestDM( aPort, DM_CCODE, &cid, sizeof(cid) )) != 0 ) {
					Errorf( "Can't request DM_CCODE to DM !!\n" ) ;
					break ;
				}
				if ( AnswerDM( aPort, &ret, &code, NULL ) == NULL ) continue ;
				if ( code.base <= pc && pc <= code.base + code.size ) {
					if ( (cp=ClassCodeSymbolSearch(Class,cid,code.base,&addr)) != NULL ) {
						name = cp ;
						part = i ;
					}
				}
			}
#endif

			if ( name ) {
				strcpy( symName, name+4 ) ;
				cp = strchr( symName, ':' ) ;
				if ( cp ) *cp = '\0' ;
				if ( head.h >= 0 ) {
#if	0
					LinePrintf( 0, "0x%08x %s 0x%08x %s\n",
							pc + 8, symName, self,
							IDtoStr( class->parts[part]->cid, NULL ) ) ;
#else
					LinePrintf( 0, "0x%08x %s 0x%08x %s\n",
							pc + 8, symName, self,
							IDtoStr( cid, NULL ) ) ;
#endif
				} else {
					LinePrintf( 0, "0x%08x %s 0x%08x\n", pc+8, symName,self ) ;
				}
			} else LinePrintf( 0, "?????????? \n" ) ;

		} ;
		LinePrintf( 0,	"l0:%08x l1:%08x l2:%08x l3:%08x l4:%08x l5:%08x l6:%08x l7:%08x\n",
				cpu.r_l0, cpu.r_l1, cpu.r_l2, cpu.r_l3,
				cpu.r_l4, cpu.r_l5, cpu.r_l6, cpu.r_l7 ) ;
		LinePrintf( 0,	"i0:%08x i1:%08x i2:%08x i3:%08x i4:%08x i5:%08x i6:%08x i7:%08x\n",
				cpu.r_i0, cpu.r_i1, cpu.r_i2, cpu.r_i3,
				cpu.r_i4, cpu.r_i5, cpu.r_i6, cpu.r_i7 ) ;
	}
	LinePrintf( 0, "\n" ) ;
	ret = OK ;

error:
	if ( aTarget ) {
		if ( (ret=RequestDM( aPort, DM_TRESUME, &aTarget, sizeof(aTarget) )) == 0 ) {
			AnswerDM( aPort, &ret, NULL, NULL ) ;
		}
	}
	return ;
}

void
CmdDumpGlobalObject( int aPort, OID aTarget )
{
	int		ret ;
	int		i ;
	DmOEntry	entry ;
	OZ_ClassInfo	class ;

	SuspendGlobal( aPort, aTarget, &entry ) ;

	LinePrintf( 0, "Object-ID: %s  Status: %d\n", IDtoStr(aTarget,NULL), entry.status ) ;
	LinePrintf( 0, "Entry-Address: 0x%08x  Object-Address: 0x%08x\n", entry.entry, entry.object ) ;

	LinePrintf( 0, "*Global*  Size: %d  #: %d  ConfigID: %s\n",
				entry.size, entry.parts, IDtoStr(entry.cid,NULL) ) ;

	class = ClassInfoGet( Class, entry.cid ) ;
	LinePrintf( 0, "RuntimeClassID    CompiledClassID\n" ) ;
	for ( i = 0 ; i < class->number_of_parts ; i ++ ) {
		LinePrintf( 0, "%s ", IDtoStr(class->parts[i]->cid,NULL) ) ;
		LinePrintf( 0, " %s\n", IDtoStr(class->parts[i]->compiled_vid,NULL) ) ;
	}

	if ( Interp ) {
		char	buf[BUFSIZE] ;
		int	base ;
		LOOP {
			fprintf( stderr, "Object Address ? " ) ;
			gets( buf ) ;
			base = strtol( buf, NULL, 0 ) ;
			if ( ! base ) break ;
			DumpObject( aPort, (OZ_Object)base, -1 ) ;
		}
	} else DumpObject( aPort, entry.object, -1 ) ;

	ResumeGlobal( aPort, aTarget, &entry ) ;
}

void
CmdDumpProcess( int aPort, OID aTarget )
{
	int	ret ;
	int	curr ;
	int	next ;
	DmLink	link ;
	OzRecvChannel	rchan ;
	Thread	t ;
	ThreadRec	thread ;

	if ( (ret=RequestDM( aPort, DM_LGETROOT, &aTarget, sizeof(aTarget) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, &link, NULL ) == NULL ) goto error ;

	curr = aPort ;
	for( rchan = link.chan.rchan, t = link.t ; rchan && t ; rchan = link.chan.rchan, t = link.t ) {
		printf( "Callee=0x%s, ", IDtoStr(link.callee,NULL) ) ;
		printf( "Caller=0x%s, ", IDtoStr(link.caller,NULL) ) ;
		printf( "Thread=0x%08x, RChan=0x%08x\n", t, link.chan.rchan ) ;
		CmdDumpThreadStack( curr, t, 0 ) ;
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
	if ( (ret=RequestDM( curr, DM_TRESUME, &t, sizeof(t) )) != 0 ) goto error ;
	if ( AnswerDM( curr, &ret, NULL, NULL ) == NULL ) goto error ;
	printf( "%s\n", TStatToName( thread.status ) ) ;
	if ( curr != aPort ) close( curr ) ;

error:

}

void
CmdListGlobalObject( int aPort )
{
	int		ret ;
	DmOTable	*table ;
	int		i ;
 const char		*n ;
	
	if ( (ret=RequestDM( aPort, DM_OTABLE, NULL, 0 )) != 0 ) goto error ;
	if ( (table=AnswerDM( aPort, &ret, NULL, NULL )) == NULL ) goto error ;

	LineFlush() ;
	for ( i = 0 ; i < table->count ; i ++ ) {
		LinePrintf( 0, "%s ", IDtoStr(table->slot[i].oid,NULL) ) ;
		LinePrintf( 0, "%s ", IDtoStr(table->slot[i].cid,NULL) ) ;
		if ( table->slot[i].flags & OT_SUSPEND ) n = "SUSPEND" ;
		else n = ObjectStatusToName( table->slot[i].status ) ;
		LinePrintf( 0, "%s\n", n ) ;
	}

error:

}

void
CmdListProcess( int aPort )
{
	int		ret ;
	DmPTable	*table ;
	int		i ;
	
	if ( (ret=RequestDM( aPort, DM_PTABLE, NULL, 0 )) != 0 ) goto error ;
	if ( (table=AnswerDM( aPort, &ret, NULL, NULL )) == NULL ) goto error ;

	LineFlush() ;
	for ( i = 0 ; i < table->count ; i ++ ) {
		LinePrintf( 0, "%s ", IDtoStr(table->slot[i].pid,NULL) ) ;
		LinePrintf( 0, "%s ", IDtoStr(table->slot[i].caller,NULL) ) ;
		LinePrintf( 0, "%s ", IDtoStr(table->slot[i].callee,NULL) ) ;
		LinePrintf( 0, "[0x%08x] ", table->slot[i].t ) ;
		LinePrintf( 0, "%s\n", ProcStatusToName(table->slot[i].status) ) ;
	}

error:

}

void
CmdListObjectThreads( int aPort, OID aTarget )
{
	DmOEntry	entry ;
	DmTList		*list ;
	int		i ;
	int		ret ;

	if ( (ret=RequestDM( aPort, DM_OGETENTRY, &aTarget, sizeof(aTarget) )) != 0 ) {
		Errorf( "Error request(DM_OGETENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, &entry, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	if ( (ret=RequestDM( aPort, DM_TLIST, &entry.entry, sizeof(entry.entry) )) != 0 ) goto error ;
	if ( (list=AnswerDM( aPort, &ret, NULL, NULL )) == NULL ) goto error ;

	/* LinePrintf( 0, "ProcessID        ForkedByObject   ThreadID   ThreadStatus\n" ) ; */
	for ( i = 0 ; i < list->count ; i ++ ) {
		LinePrintf( 0, "0x%08x ", list->slot[i].t ) ;
		LinePrintf( 0, "%s ", IDtoStr(list->slot[i].pid,NULL) ) ;
		LinePrintf( 0, "%s ", IDtoStr(list->slot[i].caller,NULL) ) ;
		LinePrintf( 0, "%s ", TStatToName(list->slot[i].status) ) ;
		if ( list->slot[i].suspend_count > 1 ) LinePrintf( 0, "%d", list->slot[i].suspend_count ) ;
		LinePrintf( 0, "\n" ) ;
	}

error:
	if ( (ret=RequestDM( aPort, DM_ORELENTRY, &entry.entry, sizeof(entry.entry) )) != 0 ) {
		Errorf( "Error request(DM_ORELENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't release %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}
}

void
ProcessStatus( int aPort, OID aTarget )
{
	int	ret ;
	int	curr ;
	int	next ;
	DmLink	link ;
	OzRecvChannel	rchan ;
	Thread	t ;
	ThreadRec	thread ;

	if ( (ret=RequestDM( aPort, DM_LGETROOT, &aTarget, sizeof(aTarget) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, &link, NULL ) == NULL ) goto error ;

	curr = aPort ;
	for( rchan = link.chan.rchan, t = link.t ; rchan && t ; rchan = link.chan.rchan, t = link.t ) {
#if	0
		LinePrintf( 0, "Callee: 0x%s ", IDtoStr(link.callee,NULL) ) ;
		LinePrintf( 0, "Caller: 0x%s ", IDtoStr(link.caller,NULL) ) ;
		LinePrintf( 0, "Thread: 0x%08x RChan: 0x%08x\n", t, link.chan.rchan ) ;
#endif

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
	if ( (ret=RequestDM( curr, DM_TRESUME, &t, sizeof(t) )) != 0 ) goto error ;
	if ( AnswerDM( curr, &ret, NULL, NULL ) == NULL ) goto error ;
	if ( thread.suspend_count <= 1 ) {
		if ( thread.status == SUSPEND ) thread.status = READY ;
		LinePrintf( 0, "Status: %s\n", TStatToName( thread.status ) ) ;
	} else LinePrintf( 0, "Status: <%s> %d\n", TStatToName( thread.status ), thread.suspend_count ) ;
	if ( curr != aPort ) close( curr ) ;

error:

}


void
CmdLoggin( int aPort, OID aTarget )
{
	DmOEntry	entry ;
	DmTList		*list ;
	int		i ;
	int		ret ;

	if ( (ret=RequestDM( aPort, DM_OGETENTRY, &aTarget, sizeof(aTarget) )) != 0 ) {
		Errorf( "Error request(DM_OGETENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, &entry, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	if ( (ret=RequestDM( aPort, DM_GLOGON, &entry.entry, sizeof(entry.entry) )) != 0 ) goto error ;
	if ( (list=AnswerDM( aPort, &ret, NULL, NULL )) == NULL ) goto error ;

error:

	if ( (ret=RequestDM( aPort, DM_ORELENTRY, &entry.entry, sizeof(entry.entry) )) != 0 ) {
		Errorf( "Error request(DM_ORELENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}

	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't release %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}
	sigpause(0) ;
}

void
CmdGlobalStep( int aPort, OID aTarget )
{
	int		ret ;
	int		i ;
	DmOEntry	entry ;
	DmGTrace	trace ;
	OZ_ClassInfo	class ;
	struct	{
		ObjectTableEntry	entry ;
		int			mode ;
		int			max ;
	} trace_args ;
	void	*handle ;
	char	buf[BUFSIZE] ;

	if ( (ret=RequestDM( aPort, DM_OGETENTRY, &aTarget, sizeof(aTarget) )) != 0 ) {
		Errorf( "Error request(DM_OGETENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, &entry, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	LinePrintf( 0, "Object-ID: %s  Status: %d\n", IDtoStr(aTarget,NULL), entry.status ) ;
	LinePrintf( 0, "Entry-Address: 0x%08x  Object-Address: 0x%08x\n", entry.entry, entry.object ) ;

	LinePrintf( 0, "*Global*  Size: %d  #: %d  ConfigID: %s\n",
				entry.size, entry.parts, IDtoStr(entry.cid,NULL) ) ;

	trace_args.entry = entry.entry ;
	trace_args.mode = TRACE_STEP|TRACE_CALLEE|TRACE_ENTRY|TRACE_RETURN|TRACE_EXCEPTION|TRACE_ERROR ;
	trace_args.max = 1 ;
	if ( (ret=RequestDM( aPort, DM_GTRACE, &trace_args, sizeof(trace_args) )) != 0 ) {
		Errorf( "Error request(DM_GTRACE) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, &handle, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	LOOP {
		if ( Interp ) LinePrompt( "Step[HIT Return-key] ?" ) ;
		else LinePrompt( "CMD>>" ) ;
		LineGets( buf, BUFSIZE ) ;
		if ( strlen(buf) != 0 ) break ;
		if ( (ret=RequestDM( aPort, DM_GSTEP, &handle, sizeof(handle) )) != 0 ) {
			Errorf( "Error request(DM_GCONT) to DM !!\n" ) ;
			exit( 1 ) ;
		}
		AnswerDM( aPort, &ret, &trace, NULL ) ;
		if ( ret < 0 ) LinePrintf( 0, "None\n" ) ;
		else {
			LinePrintf( 0, "Time: %19.19s %d\n", ctime(&trace.tp.tv_sec), trace.tp.tv_usec ) ;
			LinePrintf( 0, "Mode: %s Type: %s Phase: %s\n",
					TraceModeToName(trace.phase),
					TraceTypeToName(trace.phase),
					TracePhaseToName(trace.phase) ) ;
			LinePrintf( 0, "Process-ID: %s ", IDtoStr(trace.pid,NULL) ) ;
			LinePrintf( 0, "Caller: %s ", IDtoStr(trace.caller,NULL) ) ;
			LinePrintf( 0, "Callee: %s\n", IDtoStr(trace.callee,NULL) ) ;
			LinePrintf( 0, "Class: %s ", IDtoStr(trace.cvid,NULL) ) ;
			LinePrintf( 0, "Slot1: %d ", trace.slot1 ) ;
			LinePrintf( 0, "Slot2: %d\n", trace.slot2 ) ;
			LinePrintf( 0, "Self: 0x%08x ", trace.self ) ;
			if ( entry.head < (OZ_Header)trace.self
				&& (OZ_Header)trace.self <= entry.head+entry.parts ) {
				LinePrintf( 0, "LOCAL\n" ) ;
			} else {
				LinePrintf( 0, "GLOBAL\n" ) ;
			}
		}
	}

	if ( (ret=RequestDM( aPort, DM_GCONT, &handle, sizeof(handle) )) != 0 ) {
		Errorf( "Error request(DM_GCONT) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't continue %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	if ( (ret=RequestDM( aPort, DM_ORELENTRY, &entry.entry, sizeof(entry.entry) )) != 0 ) {
		Errorf( "Error request(DM_ORELENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't release %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}
}

void
CmdGlobalTrace( int aPort, OID aTarget, int aMax )
{
	int		ret ;
	int		i ;
	DmOEntry	entry ;
	DmGTrace	trace ;
	OZ_ClassInfo	class ;
	struct	{
		ObjectTableEntry	entry ;
		int			mode ;
		int			max ;
	} trace_args ;
	void	*handle ;
	char	buf[BUFSIZE] ;

	if ( aMax == 0 ) aMax = 100 ;

	if ( (ret=RequestDM( aPort, DM_OGETENTRY, &aTarget, sizeof(aTarget) )) != 0 ) {
		Errorf( "Error request(DM_OGETENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, &entry, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	LinePrintf( 0, "Object-ID: %s  Status: %d\n", IDtoStr(aTarget,NULL), entry.status ) ;
	LinePrintf( 0, "Entry-Address: 0x%08x  Object-Address: 0x%08x\n", entry.entry, entry.object ) ;

	LinePrintf( 0, "*Global*  Size: %d  #: %d  ConfigID: %s\n",
				entry.size, entry.parts, IDtoStr(entry.cid,NULL) ) ;

	trace_args.entry = entry.entry ;
	trace_args.mode = TRACE_LOG|TRACE_CALLEE|TRACE_CALLER ;
	trace_args.mode |= TRACE_ENTRY|TRACE_RETURN|TRACE_EXCEPTION|TRACE_ERROR ;
	trace_args.max = aMax ;
	if ( (ret=RequestDM( aPort, DM_GTRACE, &trace_args, sizeof(trace_args) )) != 0 ) {
		Errorf( "Error request(DM_GTRACE) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, &handle, NULL ) == NULL ) {
		Errorf( "Not found %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

LOOP {
	i = 0 ;
	if ( Interp ) LinePrompt( "Trace[HIT Return-key] ?" ) ;
	else LinePrompt( "CMD>>" ) ;
	LineGets( buf, BUFSIZE ) ;
	if ( strlen(buf) ) break ;
	LOOP {
		if ( (ret=RequestDM( aPort, DM_GSTEP, &handle, sizeof(handle) )) != 0 ) {
			Errorf( "Error request(DM_GCONT) to DM !!\n" ) ;
			exit( 1 ) ;
		}
		AnswerDM( aPort, &ret, &trace, NULL ) ;
		if ( ret < 0 ) {
			if ( ret == -2 ) LinePrintf( 0, "Overflow\n" ) ;
			break ;
		} else {
			i = ret ;
			LinePrintf( 0, "Time: %19.19s %d\n", ctime(&trace.tp.tv_sec), trace.tp.tv_usec ) ;
			LinePrintf( 0, "Mode: %s Type: %s Phase: %s\n",
					TraceModeToName(trace.phase),
					TraceTypeToName(trace.phase),
					TracePhaseToName(trace.phase) ) ;
			LinePrintf( 0, "Process-ID: %s ", IDtoStr(trace.pid,NULL) ) ;
			LinePrintf( 0, "Caller: %s ", IDtoStr(trace.caller,NULL) ) ;
			LinePrintf( 0, "Callee: %s\n", IDtoStr(trace.callee,NULL) ) ;
			LinePrintf( 0, "Class: %s ", IDtoStr(trace.cvid,NULL) ) ;
			LinePrintf( 0, "Slot1: %d ", trace.slot1 ) ;
			LinePrintf( 0, "Slot2: %d\n", trace.slot2 ) ;
			LinePrintf( 0, "Self: 0x%08x ", trace.self ) ;
			if ( entry.head < (OZ_Header)trace.self
				&& (OZ_Header)trace.self <= entry.head+entry.parts ) {
				LinePrintf( 0, "LOCAL\n" ) ;
			} else {
				LinePrintf( 0, "GLOBAL\n" ) ;
			}
		}
	}
}

	if ( (ret=RequestDM( aPort, DM_GCONT, &handle, sizeof(handle) )) != 0 ) {
		Errorf( "Error request(DM_GCONT) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't continue %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	if ( (ret=RequestDM( aPort, DM_ORELENTRY, &entry.entry, sizeof(entry.entry) )) != 0 ) {
		Errorf( "Error request(DM_ORELENTRY) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( AnswerDM( aPort, &ret, NULL, NULL ) == NULL ) {
		Errorf( "Can't release %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}
}

void
CmdKillProcess( int aPort, OID aTarget )
{
	int	ret ;

	if ( (ret=RequestDM( aPort, DM_PKILL, &aTarget, sizeof(aTarget) )) != 0 ) goto error ;
	if ( AnswerDM( aPort, &ret, &link, NULL ) == NULL ) goto error ;
error:
}

#if 0
void
CmdServPort( OID aTarget )
{
	int	ret = NG ;
	int	owner = NG ;
	int	size ;
	char	*data ;

	if ( OwnerIdent != NULL ) owner = OwnerDM( OwnerIdent, NULL ) ;
	else {
		if ( PortNumber != NULL ) owner = OwnerDM( IPaddress, PortNumber ) ;
		else if ( EXECID(aTarget) != 0 ) {
			char	buf[64] ;
			sprintf( buf, "0x%06x", EXECID(aTarget) ) ;
			owner = OwnerDM( buf, NULL ) ;
		}
	}
	if ( owner < 0 ) goto error ;

	if ( (ret=RequestDM( owner, DM_SERVPORT, &aTarget, sizeof(aTarget) )) != 0 ) {
		Errorf( "Error request(DM_SERVPORT) to DM !!\n" ) ;
		exit( 1 ) ;
	}
	if ( (data=AnswerDM( owner, &ret, NULL, &size )) == NULL ) {
		Errorf( "Can't resolve %s !!\n", IDtoStr( aTarget, NULL ) ) ;
		exit( 1 ) ;
	}

	LinePrintf( 0, "%s\n", AddrToName( data, size ) ) ;

error:
}
#endif

#define	CMDNAME_LENGTH		15
#define	CMDNAME_OBJDUMP		0
#define	CMDNAME_PROCDUMP	1
#define	CMDNAME_OBJLIST		2
#define	CMDNAME_PROCLIST	3
#define	CMDNAME_TLIST		4
#define	CMDNAME_OBJINSPECT	5
#define	CMDNAME_PROCSTAT	6
#define	CMDNAME_TDUMP		7
#define	CMDNAME_OBJLOG		8
#define	CMDNAME_GSTEP		9
#define	CMDNAME_GTRACE		10
#define	CMDNAME_DMPORT		11
#define	CMDNAME_PKILL		12
static	char	*CmdNameTable = "objdump        "
				"procdump       "
				"objlist        "
				"proclist       "
				"tlist          "
				"objinspect     "
				"procstat       "
				"tdump          "
				"objlog         "
				"gstep          "
				"gtrace         "
				"dmport         "
				"pkill          " ;

int
main( int argc, char *argv[] )
{
	int	argind ;
	int	port = NG ;
	char	*cmdName ;
	char	*first ;
	char	*ptr ;
	OID	id ;

	for ( ptr = argv[0] + strlen( argv[0] ) ; ptr != argv[0] ; -- ptr ) {
		if ( *ptr == '/' ) {
			++ ptr ;
			break ;
		}
	}
	CmdName = ptr ;

	if ( OzRoot == NULL ) {
		OzRoot = getenv( "OZROOT" ) ;
		if ( OzRoot == NULL ) {
			Errorf( "Oh my god, please setenv OZROOT !!\n" ) ;
			exit( 1 ) ;
		}
	}

	argind = CmdLine( argc, argv ) ;
	if ( argind >= argc ) Usage() ;

	first = argv[argind++] ;
	id = StrToID( 0, 0, first, NULL ) ;
	if ( id == 0 ) {
		Errorf( "Invalid target: '%s'\n", argv[argind] ) ;
		exit( 1 ) ;
	}

	if ( OzClassPath == NULL ) {
		int	exid = (id>>24)&0x0ffffff ;
		char	buf[MAXPATHLEN+1] ;
		sprintf( buf, "%s/images/%06x/classes", OzRoot, exid ) ;
		OzClassPath = strdup( buf ) ;
	}

	OzSiteID = SITEID( id ) ;

	if ( OzSiteID == 0 ) {
		int	fd ;
		int	size ;
		char	buf[BUFSIZE] ;
		sprintf( buf, "%s/etc/site-id", OzRoot ) ;
		fd = open( buf, O_RDONLY ) ;
		size = read( fd, buf, BUFSIZE-1 ) ;
		close( fd ) ;
		if ( size <= 0 ) {
			Errorf( "Oh my god, please %s !!\n", buf ) ;
			exit( 1 ) ;
		}
		buf[size] = 0 ;
		OzSiteID = strtol( buf, NULL, 16 ) ;
		id = StrToID( OzSiteID, 0, first, NULL ) ;
	}

	if ( chdir( OzRoot ) ) {
		perror( "chdir" ) ;
		exit( 1 ) ;
	}

	if ( (port=OpenDM( id )) < 0 ) {
		Errorf( "Invalid executor id: 0x%06x\n", EXECID(id) ) ;
		exit( 1 ) ;
	}

	cmdName = strstr( CmdNameTable, CmdName ) ;
	if ( cmdName == NULL ) {
		Errorf( "debugger: Illegal Command Name !!\n" ) ;
		return( 1 ) ;
	}

	switch( (cmdName-CmdNameTable)/CMDNAME_LENGTH ) {
	case	CMDNAME_OBJDUMP:
		CmdDumpGlobalObject( port, id ) ;
		break ;
	case	CMDNAME_PROCDUMP:
		CmdDumpProcess( port, id ) ;
		break ;
	case	CMDNAME_OBJLIST:
		CmdListGlobalObject( port ) ;
		break ;
	case	CMDNAME_PROCLIST:
		CmdListProcess( port ) ;
		break ;
	case	CMDNAME_TLIST:
		CmdListObjectThreads( port, id ) ;
		break ;
	case	CMDNAME_OBJINSPECT:
		CmdInspect( port, id, argv+argind, argc-argind ) ;
		break ;
	case	CMDNAME_PROCSTAT:
		ProcessStatus( port, id ) ;
		break ;
	case	CMDNAME_TDUMP:
	{
		Thread	t = NULL ;
		if ( argind < argc ) t = (Thread)strtol( argv[argind++], NULL, 0 ) ;
		else t = (Thread)(int)(id & 0x0ffffffu) ;
		CmdDumpThreadStack( port, t, 0 ) ;
	}
		break ;
	case	CMDNAME_OBJLOG:
		CmdLoggin( port, id ) ;
		break ;
	case	CMDNAME_GSTEP:
		CmdGlobalStep( port, id ) ;
		break ;
	case	CMDNAME_GTRACE:
	{
		int	i = 0 ;
		if ( argind < argc ) i = (int)strtol( argv[argind++], NULL, 0 ) ;
		CmdGlobalTrace( port, id, i ) ;
	}
		break ;
	case	CMDNAME_PKILL:
		CmdKillProcess( port, id ) ;
		break ;
	}

	if ( port >= 0 ) CloseDM( port ) ;

	return( 0 ) ;
}
