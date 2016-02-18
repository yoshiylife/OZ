/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <a.out.h>
#include <link.h>
/* multithread system include */
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "dyload.h"
#include "oh-header.h"
#include "oh-impl.h"

#define	PROT_RDWR	(PROT_READ|PROT_WRITE)

#define TMP_MMAP

/*
 *	Declaration of System calls
 */
#if	!defined(SVR4)
extern	int	mprotect( caddr_t addr, size_t len, int prot ) ;
extern	int	munmap( caddr_t addr, size_t len ) ;
#endif	/* SVR4 */

/*
 *	Declaration of C Library functions
 */
#if	!defined(SVR4)
extern	int	strncasecmp( const char *s1, const char *s2, int n ) ;
#endif

typedef	struct DlHandleStr	DlHandleRec ;
typedef	struct DlHandleStr*	DlHandle ;
struct	DlHandleStr {
	struct	nlist	*symTable ;
	struct	nlist	*symBreak ;
	struct	nlist	*symNext ;
	ClassCode	code ;
	caddr_t		base ;
	size_t		size ;
} ;

typedef	struct	dlSymbol {
	HashHeaderRec	header;
		int	value ;
} dlSymbolRec, *dlSymbol ;

static	struct	nlist	*dlSymTable ;
static	struct	nlist	*dlSymBreak ;
static		char	*strs ;
static		int	dylog ;
static	OZ_MonitorRec	dylogLock ;
static	ExecHashTable	dlHashTable ;

/*
 *	Needed symbol
 */
long long
longop( long long a, long long b, long flag )
{
	switch ( flag ) {
	case 0 :	return ( a / b ) ;
	case 1 :	return ( a * b ) ;
	default:	return ( a % b ) ;
	}
}

unsigned long long
ulongop( unsigned long long a, unsigned long long b, unsigned long long flag )
{
	switch ( flag ) {
	case 0 :	return ( a / b ) ;
	case 1 :	return ( a * b ) ;
	default:	return ( a % b ) ;
	}
}

static	int
str_gcmp( char *s1, const char *s2 )
{
	char	c1 ;
	char	c2 ;
	do {
		c1 = *s1 ++ ;
		c2 = *s2 ++ ;
	} while ( c1 && c1 != ':' && c1 == c2 ) ;
	return( c1 == ':' ? 0 : c1 - c2 ) ;
}

static	int
make_dlHashTable( struct nlist *ptr, struct nlist *brk )
{
	int		count = 0 ;
	char		*n ;
	dlSymbol	s ;

	dlHashTable = OhCreateHashTable( 1024, OH_STRING ) ;
	if ( dlHashTable == NULL ) return( -1 ) ;

	do {
		if ( (ptr->n_type & N_EXT) == 0 ) continue ;
		n = ptr->n_un.n_name ;
		if ( ! OzExportAll && strncasecmp( n, "_oz", 3 ) ) {

			/* Exported symbol except for _Oz... */
			if ( ! strcmp( n, "__setjmp" ) ) ;
			else if ( ! strcmp( n, "_errno" ) ) ;

			else if ( n[0] == '.' ) ;
			else if ( n[0] == '_' && n[1] == '_' && n[2] == '_' ) {
				if ( strcmp( n, "___main" ) == 0 ) continue ;
			} else continue ;
		}
#if	0	/* for debug */
		OzDebugf( "0x%08x:%s\n", ptr->n_value, n ) ;
#endif
		s = (dlSymbol)OzMalloc( sizeof(dlSymbolRec) ) ;
		s->value = ptr->n_value ;
		OhInsertIntoHashTable( (HashHeader)s, n, dlHashTable ) ;
		count ++ ;
	} while( ++ ptr < brk ) ;
	return( count ) ;
}

static	unsigned
find_symbol( OZ_ImportedCodes imports, void *name )
{
	OZ_ExportedFunctions	exports ;
		dlSymbol	s ;
		int		i, j ;

	s = (dlSymbol)OhKeySearchHashTable( name, dlHashTable ) ;
	if ( s ) return( s->value ) ;

	if ( imports == NULL ) return( 0 ) ;
	name ++ ;
	for ( i = 0 ; i < imports->number ; i ++ ) {
		exports = ((ClassCode)imports->entry[i].code)->exported_funcs ;
		for ( j = 0 ; j < exports->number ; j ++ ) {
			if ( ! str_cmp(exports->entry[j].function_name, name) )
				return( (unsigned)exports->entry[j].function ) ;
		}
	}
	return( 0 ) ;
}

static	void
dump_reloc( struct reloc_info_sparc *reloc, struct nlist *nlist, char *strs )
{
	OzDebugf( "address:0x%08x index:%d %s type:%d addend:0x%08x\n",
			reloc->r_address,
			reloc->r_index,
			reloc->r_extern ? "EXTERN":"INTERN",
			reloc->r_type,
			reloc->r_addend ) ;
	OzDebugf( "symbol[%d] n_un:%d n_type:%d n_value: 0x%08x %s\n",
		reloc->r_index,
		nlist[reloc->r_index].n_un.n_strx,
		nlist[reloc->r_index].n_type,
		nlist[reloc->r_index].n_value,
		strs + nlist[reloc->r_index].n_un.n_strx ) ;
}

static	int
open_aout( const char *file )
{
	int	result = -1 ;
	int	size ;
	char	*path = NULL ;
	char	*full = NULL ;
	char	*ptr ;
	char	*next ;

	if ( (ptr=OzGetenv( "PATH" )) == NULL ) {
		OzError( "open_aout OzGetenv(PATH): %m." ) ;
		goto error ;
	}
	if ( (path=OzMalloc( OzStrlen(ptr) + 1 )) == NULL ) {
		OzError( "open_aout OzMalloc('%s'): %m.", ptr ) ;
		goto error ;
	}
	OzStrcpy( path, ptr ) ;

	size = 1 + OzStrlen(file) + 1 ;
	ptr = path ;
	if ( (full=OzMalloc( 1024 )) == NULL ) {
		OzError( "open_aout OzMalloc(1024): %m." ) ;
		goto error ;
	}
	do {
		if ( (next=OzStrchr( ptr, ':' )) != NULL ) *next = '\0' ;
		if ( (full=OzRealloc( full, OzStrlen(ptr) + size )) == NULL ) {
			OzError( "open_aout OzRealloc('%s' + %d): %m.",
					ptr, size ) ;
			goto error  ;
		}
		OzSprintf( full, "%s/%s", ptr, file ) ;
		if ( OzAccess( full, X_OK ) == 0 ) {
			result = OzOpen( full, O_RDONLY ) ;
			break ;
		}
		ptr = next + 1 ;
	} while ( next != NULL ) ;

error:
	if ( path != NULL ) OzFree( path ) ;
	if ( full != NULL ) OzFree( full ) ;
	return( result ) ;
}

static	int
check_version( int fd, int offset )
{
	int	result = -1 ;
	char	*buf = NULL ;
	int	size ;

	offset = (int)OzVersion - offset ;
	size = OzStrlen( OzVersion ) + 1 ;
	if ( (buf=OzMalloc( size )) == NULL ) {
		OzError( "check_version OzMalloc(%d): %m.", size ) ;
		goto error ;
	}
	if ( OzLseek( fd, offset, SEEK_SET ) < 0 ) {
		OzError( "check_version OzLseek"
				"(%d,%d,SEEK_SET): %m.", fd, offset ) ;
		goto error ;
	}
	if ( OzRead( fd, buf, size ) != size ) {
		OzError( "check_version OzRead(%d,,%d): %m.", fd, size ) ;
		goto error ;
	}
	result = OzStrcmp( OzVersion, buf ) ;

error:
	if ( buf != NULL ) OzFree( buf ) ;
	return( result ) ;
}


int
DlMapSymbolTable( int (func)(), void *arg )
{
	int	count = 0 ;
	int	ret ;
	struct	nlist	*symptr;

	for (symptr = dlSymTable; symptr < dlSymBreak; symptr++) {
		ret = func( symptr, arg ) ;
		if ( ret >= 0 ) count ++ ;
		if ( ret != 0 ) break ;
	}
	return( count ) ;
}

int
DlIsCore( caddr_t addr )
{
	extern	etext ;
	extern	edata ;
	extern	end ;

	if ( addr >= (caddr_t)&end ) return( 0 ) ;
	if ( addr < (caddr_t)&etext ) return( 1 ) ;
	if ( addr < (caddr_t)&edata ) return( 2 ) ;
	return( 3 ) ;
}

typedef	struct	{
	caddr_t		addr ;
	ClassCode	code ;
	OZ_ClassID	cid ;
} CKey ;

static	int
DlIsClass_sub( ClassCode code, CKey *key )
{
	int	result = 1 ;
	int	block ;

	block = ThrBlockSuspend() ;
	OzExecEnterMonitor( &code->lock ) ;
	if ( code->state == CL_LOADED
		&& code->addr <= key->addr
		&& key->addr <= code->addr + code->size ) {
		key->cid = code->cid ;
		result = 0 ;
	}
	OzExecExitMonitor( &code->lock ) ;
	ThrUnBlockSuspend( block ) ;
	return( result ) ;
}

OZ_ClassID
DlIsClass( caddr_t addr )
{
	CKey	key ;

	key.addr = addr ;
	key.cid = 0LL ;
	ClMapCode( DlIsClass_sub, &key ) ;

	return( key.cid ) ;
}

void	*
DlOpen( OZ_ClassID aCID )
{
	int		status = -1 ;
	DlHandle	handle ;

	if ( (handle=OzMalloc( sizeof(DlHandleRec) )) == NULL ) {
		OzError( "DlOpen(%016lx) OzMalloc: %m.", aCID ) ;
		goto error ;
	}
	handle->code = NULL ;
	if ( aCID == 0LL ) {
		extern	end ;
		handle->symTable = dlSymTable ;
		handle->symBreak = dlSymBreak ;
		handle->symNext = dlSymTable ;
		handle->base = 0 ;
		handle->size = (size_t)&end ;
	} else {
		handle->code = ClGetCode( aCID ) ;
		if ( DlSymbolLoad( handle->code ) != DL_OK ) {
			OzError( "OzDlOpen(%016lx)"
					": Can't load symbol.", aCID ) ;
			goto error ;
		}
		handle->symTable = handle->code->sym_nlist ;
		handle->symBreak = handle->code->sym_break ;
		handle->symNext = handle->code->sym_nlist ;
		handle->base = handle->code->addr ;
		handle->size = handle->code->size ;
	}
	status = 0 ;

error:
	if ( status && handle ) {
		if ( handle->code ) ClReleaseCode( handle->code ) ;
		OzFree( handle ) ;
		handle = NULL ;
	}
	return( (void *)handle ) ;
}

int
DlClose( void *aHandle )
{
	DlHandle	handle = aHandle ;

	if ( handle->code != NULL ) ClReleaseCode( handle->code ) ;
	OzFree( handle ) ;

	return( 0 ) ;
}

int
DlAddr( void *aHandle, caddr_t addr, DlInfo dli )
{
	DlHandle	handle = aHandle ;
	struct	nlist	*p ;
	struct	nlist	*last ;
	struct	nlist	*snext ;
		int	s_flag ;
		int	l_flag ;
	unsigned long	sn_value ;
	unsigned long	ln_value ;
		char	*sname ;
		char	*fname ;
		short	sline ;

	if ( addr < handle->base
		|| handle->base + handle->size <= addr ) return( -1 ) ;

	s_flag = l_flag = 1 ;
	sn_value = ln_value = 0 ;
	sname = fname = NULL ;
	snext = NULL ;
	sline = 0 ;

	p = handle->symTable ;
	last = handle->symBreak ;
	for ( ; p < last ; p ++ ) {
		/* search symbol */
		if ( s_flag ) {
			if ( p->n_type & N_EXT || p->n_type == 0x24 ) {
				if ( (unsigned long)addr >= p->n_value ) {
					if ( p->n_value > sn_value ) {
						sn_value = p->n_value ;
						sname = p->n_un.n_name ;
						snext = p + 1 ;
					}
				} else s_flag = 0 ;
			}
		}
		/* search source */
		if ( l_flag ) {
			if ( p->n_type == 0x44 ) {
				if ( (unsigned long)addr >= p->n_value ) {
					if ( p->n_value >= ln_value ) {
						ln_value = p->n_value ;
						sline = p->n_desc ;
					}
				} else l_flag = 0 ;
			} else if ( p->n_type == 0x64 || p->n_type == 0x84 ) {
				fname = p->n_un.n_name ;
			}
		}
	}
#if	0
OzOutput( -1, "n_name=%s ", result.n_un.n_name ) ;
OzOutput( -1, "n_type=%d(0x%x) ", result.n_type, result.n_type ) ;
OzOutput( -1, "n_desc=%d(0x%x) ", result.n_desc, result.n_desc ) ;
OzOutput( -1, "n_value=%u(0x%x)\n", result.n_value, result.n_value ) ;
#endif

	dli->fname = fname ;
	dli->sline = sline ;
	dli->sname = sname ;
	dli->saddr = (caddr_t)ln_value ;
	dli->snext = snext ;
	return( 0 ) ;
}

caddr_t
DlSrc( void *aHandle, const char *aBaseName, int aLine )
{
	DlHandle	handle = aHandle ;
	struct	nlist	*p ;
	struct	nlist	*last ;
		caddr_t	result = NULL ;
		char	*bname = NULL ;

	p = handle->symTable ;
	last = handle->symBreak ;
	for ( ; p < last ; p ++ ) {
		if ( p->n_type == 0x44 ) {
			if ( p->n_desc != aLine ) continue ;
			if ( bname == NULL ) {
				if ( aBaseName == NULL ) {
					result = (caddr_t)p->n_value ;
					break ;
				}
			} else if ( str_cmp( bname, (char *)aBaseName ) == 0 ) {
				result = (caddr_t)p->n_value ;
				break ;
			}
		} else if ( p->n_type == 0x64 || p->n_type == 0x84 ) {
			bname = OzStrrchr( p->n_un.n_name, '/' ) ;
			if ( bname == NULL ) bname = p->n_un.n_name ;
		}
	}
#if	0
OzOutput( -1, "n_name=%s ", result.n_un.n_name ) ;
OzOutput( -1, "n_type=%d(0x%x) ", result.n_type, result.n_type ) ;
OzOutput( -1, "n_desc=%d(0x%x) ", result.n_desc, result.n_desc ) ;
OzOutput( -1, "n_value=%u(0x%x)\n", result.n_value, result.n_value ) ;
#endif

	return( result ) ;
}

caddr_t
DlSym( void *aHandle, const char *name )
{
	DlHandle	handle = aHandle ;
	struct	nlist	*p ;
	struct	nlist	*last ;
		caddr_t	result = NULL ;

	p = handle->symTable ;
	last = handle->symBreak ;
	for ( ; p < last ; p ++ ) {
		if ( p->n_type == 0x24 ) {
			if ( str_gcmp( p->n_un.n_name, name ) == 0 ) {
				result = (caddr_t)p->n_value ;
				break ;
			}
		}
	}
#if	0
OzOutput( -1, "n_name=%s ", result.n_un.n_name ) ;
OzOutput( -1, "n_type=%d(0x%x) ", result.n_type, result.n_type ) ;
OzOutput( -1, "n_desc=%d(0x%x) ", result.n_desc, result.n_desc ) ;
OzOutput( -1, "n_value=%u(0x%x)\n", result.n_value, result.n_value ) ;
#endif

	return( result ) ;
}

int
DlDynamicLoad( ClassCode code, char *file )
{
		int	result = DL_NG ;
		int	fd = -1 ;
		caddr_t	buff = NULL ;
		size_t	size = 0 ;
		char	*strs ;
		int	len ;
	struct	nlist	*symTable ;
	struct	nlist	*symBreak ;
	struct	nlist	*symPtr ;
	struct	exec	exec ;
		char	*sname ;

	struct	link_dynamic	*DYNAMIC = NULL ;
	OZ_FunctionPtrTable	fp_table = NULL ;
	OZ_ImportedCodes	imported_codes = NULL ;
	OZ_ExportedFunctions	exported_funcs = NULL ;
	OZ_DebugInfo		debugInfo = NULL ;
	OZ_FunctionPtr		start = NULL ;

	if ( (fd = OzOpen( file,O_RDONLY )) < 0 ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"OzOpen(): %m.", code->cid, file ) ;
		goto error ;
	}
	if ( OzRead( fd, &exec, sizeof(exec) ) != sizeof(exec) ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"OzRead(exec): %m.", code->cid, file ) ;
		goto error ;
	}
	code->size = exec.a_text + exec.a_data ;
	code->addr = mmap( 0, code->size, PROT_RDWR|PROT_EXEC,
					MAP_PRIVATE, fd,N_TXTOFF(exec) ) ;
	if ( (int)code->addr == -1 ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"mmap(exec): %m.", code->cid, file ) ;
		code->addr = NULL ;
		goto error ;
	}
	if ( mprotect( code->addr, exec.a_text, PROT_READ|PROT_EXEC ) == -1 ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"mprotect(text): %m.", code->cid, file ) ;
		goto error ;
	}
	len = OzStrlen( file ) + 1 ;
	code->sym_fname = (char *)OzMalloc( len ) ;
	if ( code->sym_fname ) OzMemcpy( code->sym_fname, file, len ) ;

	if ( OzLseek( fd, N_STROFF(exec), SEEK_SET ) == -1 ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"OzLseek(N_STROFF): %m.", code->cid, file ) ;
		goto error ;
	}
	if ( OzRead( fd, &len, sizeof(len) ) != sizeof(len) ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"OzRead(len): %m.", code->cid, file ) ;
		goto error ;
	}
	size = exec.a_syms + len ;
#ifdef TMP_MMAP
	buff = mmap(0,size,PROT_RDWR,MAP_PRIVATE,fd,N_SYMOFF(exec)) ;
	if ( (int)buff == -1 ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"mmap(syms): %m.", code->cid, file ) ;
		buff = NULL ;
		goto error ;
	}
#else
	buff = OzMalloc( size ) ;
	if ( buff == NULL ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"OzMalloc(syms): %m.", code->cid, file ) ;
		goto error ;
	}
	if ( OzLseek( fd, N_SYMOFF(exec), SEEK_SET ) == -1 ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"OzLseek(N_SYMOFF): %m.", code->cid, file ) ;
		goto error ;
	}
	if ( OzRead( fd, buff, size ) != size ) {
		OzError( "DlDynamicLoad(%016lx,%s) "
				"OzRead(syms): %m.", code->cid, file ) ;
		goto error ;
	}
#endif
	symTable = (struct nlist *)buff ;
	strs = (char *)(buff + N_STROFF(exec)-N_SYMOFF(exec)) ;
	symBreak = symTable + exec.a_syms / sizeof(struct nlist) ;
	for ( symPtr = symTable ; symPtr < symBreak ; symPtr ++ ) {
		if ( (symPtr->n_type & N_DATA) == 0 ) continue ;
		sname = strs + symPtr->n_un.n_strx ;
		if ( DYNAMIC == NULL
			&& str_cmp(sname,"__DYNAMIC" ) == 0 ) {
			DYNAMIC = (struct link_dynamic *)
					(code->addr + symPtr->n_value) ;
		}
		if ( fp_table == NULL
			&& str_cmp(sname,"__OZ_FunctionPtrTableRec") == 0 ) {
			fp_table = (OZ_FunctionPtrTable)
					(code->addr + symPtr->n_value) ;
		}
		if ( imported_codes == NULL
			&& str_cmp(sname,"__OZ_ImportedCodesRec") == 0 ) {
			imported_codes = (OZ_ImportedCodes)
						(code->addr + symPtr->n_value) ;
		}
		if ( exported_funcs == NULL
			&& str_cmp(sname,"__OZ_ExportedFunctionsRec") == 0 ) {
			exported_funcs = (OZ_ExportedFunctions)
						(code->addr + symPtr->n_value) ;
		}
		if ( debugInfo == NULL
			&& str_cmp(sname,"__OZ_DebugInfoRec") == 0 ) {
			debugInfo = (OZ_DebugInfo)
					(code->addr + symPtr->n_value) ;
		}
		if ( start == NULL
			&& str_cmp(sname,"__start") == 0 ) {
			start = (OZ_FunctionPtr)(code->addr + symPtr->n_value) ;
		}
	}
	if ( DYNAMIC != NULL ) code->DYNAMIC = DYNAMIC ;
	if ( fp_table != NULL ) code->fp_table = fp_table ;
	if ( imported_codes != NULL ) code->imported_codes = imported_codes ;
	if ( exported_funcs != NULL ) code->exported_funcs = exported_funcs ;
	if ( debugInfo != NULL ) code->debugInfo = debugInfo ;
	if ( start != NULL && code->fp_table != NULL ) {
		code->fp_table->number_of_entry = 1 ;
		code->fp_table->functions[0] = start ;
	}

	OzExecEnterMonitor( &dylogLock ) ;
	OzOutput( dylog, "add-symbol-file %s 0x%08x\n", file, code->addr ) ;
	OzExecExitMonitor( &dylogLock ) ;
	result = DL_OK ;
error:
#ifdef TMP_MMAP
	if ( buff != NULL ) munmap( buff, size ) ;
#else
	if ( buff != NULL ) OzFree( buff ) ;
#endif
	if ( 0 <= fd ) OzClose( fd ) ;
	if ( result != DL_OK ) {
		if ( code->addr != NULL ) munmap( code->addr, code->size ) ;
	}
	return( result ) ;
}

int
DlRelocate( ClassCode code )
{
		int			result = 0 ;
	struct	link_dynamic_2		*ld_2 ;
	struct	reloc_info_sparc	*reloc ;
	struct	reloc_info_sparc	*relend ;
	struct	nlist			*nlist ;
	struct	nlist			*sym ;
		OZ_ImportedCodes	importedCodes ;
		caddr_t			base ;
		char			*strs ;
		char			*name ;
		unsigned		value ;
		unsigned		*addr ;

	base = code->addr ;
	if ( base == 0 ) {
		OzError( "DlRelocate(%016lx): No loaded code.", code->cid ) ;
		result = 1 ;
		goto error ;
	}
	importedCodes = code->imported_codes ;
	ld_2 = (struct link_dynamic_2 *)(base+(int)code->DYNAMIC->ld_un.ld_2) ;
	reloc = (struct reloc_info_sparc *)(code->addr + ld_2->ld_rel) ;
	relend = (struct reloc_info_sparc *)(code->addr + ld_2->ld_hash) ;
	nlist = (struct nlist *)(code->addr + ld_2->ld_stab) ;
	strs = (char *)(code->addr + ld_2->ld_symbols) ;

	for ( ; reloc < relend ; reloc ++ ) {
		if ( reloc->r_extern ) {
			sym = nlist + reloc->r_index ;
			if ( (sym->n_type & N_TYPE) == N_UNDF ) {
				name = strs + sym->n_un.n_strx ;
				value = find_symbol( importedCodes, name ) ;
				if (value == 0) {
				  OzError( "Undefined symbol '%s'.", name ) ;
				  result = 1 ;
				  continue ;
				}
			} else value = (unsigned)base + sym->n_value ;
		} else if ( reloc->r_index == 0 ) {
			value = (unsigned)base ;
		} else {
			dump_reloc( reloc, nlist, strs ) ;
			result = 1 ;
			continue;
		}
		addr = (unsigned *)(base + reloc->r_address) ;
		switch ( reloc->r_type ) {
		case RELOC_32:
			*addr += value ;
			break ;
		case RELOC_JMP_SLOT:
			*addr++ = 0x03000000 | (value >> 10) ;
			*addr = 0x81c06000 | (value & 0x3ff) ;
			break ;
		case RELOC_GLOB_DAT:
			*addr = value ;
			break ;
		default:
			dump_reloc( reloc, nlist, strs ) ;
			result = 1 ;
		}
	}

error:
	if ( result ) OzError( "DlRelocate(%016lx) failed.", code->cid ) ;
	return( result ) ;
}

void
DlUnload( ClassCode code )
{
        if ( code->sym_fname ) OzFree( code->sym_fname ) ;
        if ( code->sym_nlist ) OzFree( code->sym_nlist ) ;
        if ( code->sym_strs ) OzFree( code->sym_strs ) ;
        munmap( code->addr, code->size ) ;
        /* OzDebugf( "DlUnLoad: %#08x\tunload\n", code->addr); */
}


int
DlSymbolLoad( ClassCode code )
{
	struct	exec	exec ;
	struct	nlist	*ptr ;
	struct	nlist	*last ;
		int	fd ;
		int	len ;
		char	file[64] ;

	OzSprintf( file, "classes/%016lx/private.o", code->cid ) ;
	if ( (fd=OzOpen( file, O_RDONLY )) < 0 ) {
		OzError( "DlSymbolLoad(%016lx) "
				"OzOpen('%s'): %m.", code->cid, file ) ;
		return DL_NG ;
	}
	OzRead( fd, &exec, sizeof(exec) ) ;
	exec.a_syms = exec.a_syms ;
	code->sym_nlist = (struct nlist *)OzMalloc( exec.a_syms ) ;
	if ( code->sym_nlist == 0 ) {
		OzError( "DlSymbolLoad(%016lx) '%s' sym_table "
			"OzMalloc(%d): %m.", code->cid, file, exec.a_syms ) ;
		return DL_NG ;
	}
	OzLseek( fd, N_SYMOFF(exec), SEEK_SET ) ;
	OzRead( fd, code->sym_nlist, exec.a_syms ) ;
	last = code->sym_nlist + exec.a_syms / sizeof(struct nlist) ;
	code->sym_break = last ;

	OzRead( fd, &len, sizeof(len) ) ;
	code->sym_strs = (char *)OzMalloc( len ) ;
	if ( code->sym_strs == 0 ) {
		OzError( "DlSymbolLoad(%016lx) '%s' sym_strs "
			"OzMalloc(%d): %m.", code->cid, file, len ) ;
		OzFree( code->sym_nlist ) ;
		code->sym_nlist = 0 ;
		return DL_NG ;
	}
	OzRead( fd, code->sym_strs + sizeof(len), len - sizeof(len) ) ;
	for ( ptr = code->sym_nlist ; ptr < last ; ptr ++ ) {
		ptr->n_value = (unsigned long)code->addr + ptr->n_value;
		if ( ptr->n_un.n_strx == 0 ) ptr->n_un.n_name = 0 ;
		else ptr->n_un.n_name = code->sym_strs + ptr->n_un.n_strx ;
	}
	OzClose( fd ) ;
	return DL_OK ;
}

static	int
dyload( char *name, int argc, char *argv[], int sline, int eline )
{
	ClassCodeRec		code ;
	OZ_FunctionPtrTableRec	start ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	code.cid = 0 ;
	start.number_of_entry = 0 ;
	code.imported_codes = NULL ;
	code.fp_table = &start ;
	if ( DlDynamicLoad( &code, argv[1] ) != DL_OK ) {
		OzOutput( -1, "dyload: %m\n" ) ;
		return( -1 ) ;
	}
	if ( DlRelocate( &code ) ) {
		OzOutput( -1, "dyload: relocation failure\n" ) ;
		DlUnload( &code ) ;
		return( -1 ) ;
	}
	if ( start.number_of_entry != 0 ) {
		start.functions[0]() ;
	}

	return( 0 ) ;
}

int
DlInit()
{
	struct	exec	exec ;
	struct	nlist	*ptr ;
		int	result = -1 ;
		int	fd = -1 ;
		int	size ;

	OzInitializeMonitor( &dylogLock ) ;

	/* Logging dynamic load infomation */
	if ( (dylog=OzLogFile("dylog",O_WRONLY|O_TRUNC|O_CREAT,0666)) < 0 ) {
		OzError( "Can't open dylog: %m." ) ;
		goto error ;
	}

	/* Load symbol from executor a.out image file */
	if ( OzStrchr( OzArgv[0], '/' ) ) fd = OzOpen( OzArgv[0], O_RDONLY ) ;
	else fd = open_aout( OzArgv[0] ) ;
	if ( fd < 0 ) {
		OzError( "Invalid program name '%s': %m.", OzArgv[0] ) ;
		goto error ;
	}
	if ( OzRead( fd, &exec, sizeof(exec) ) != sizeof(exec) ) {
		OzError( "Can't read exec area from executor: %m." ) ;
		goto error ;
	}
	if ( (dlSymTable=(struct nlist *)OzMalloc( exec.a_syms )) == NULL ) {
		OzError( "Can't allocate buffer for executor symbol: %m." ) ;
		goto error ;
	}
	dlSymBreak = dlSymTable + exec.a_syms / sizeof(struct nlist) ;
	if ( OzLseek( fd, N_SYMOFF(exec), SEEK_SET ) < 0 ) {
		OzError( "Can't lseek to executor symbol area: %m." ) ;
		goto error ;
	}
	if ( OzRead( fd, dlSymTable, exec.a_syms ) != exec.a_syms ) {
		OzError( "Can't read symbol area from executor: %m." ) ;
		goto error ;
	}
	if ( OzRead( fd, &size, sizeof(size) ) != sizeof(size) ) {
		OzError( "Can't read size area from executor: %m." ) ;
		goto error ;
	}
	if ( (strs=(char *)OzMalloc( size )) == NULL ) {
		OzError( "Can't allocate buffer for executor strings: %m." ) ;
		goto error ;
	}
	size = size - sizeof(size) ;
	if ( OzRead( fd, strs + sizeof(size), size ) != size ) {
		OzError( "Can't read strings area from executor: %m." ) ;
		goto error ;
	}
	for ( ptr = dlSymTable ; ptr < dlSymBreak ; ptr ++ ) {
		ptr->n_un.n_name = strs + ptr->n_un.n_strx ;
	}
	result = make_dlHashTable( dlSymTable, dlSymBreak ) ;
	if ( result < 0 ) {
		OzError( "DlInit: Can't make hash table to export." ) ;
		goto error ;
	}
	OzPrintf( "DlInit: %d symbols exported.\n", result ) ;

	if ( check_version( fd, N_TXTADDR(exec) ) != 0 ) {
		OzError( "DlInit: Inconsitent executor's a.out image." ) ;
		goto error ;
	}
	OzShAppend( "boot", "dyload", dyload, "<file name>",
		"dynamic load" ) ;
	result = 0 ;

error:
	if ( fd >= 0 ) OzClose( fd ) ;
	return( result ) ;
}
