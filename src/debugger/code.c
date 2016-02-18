/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<stdio.h>
#include	<string.h>
#include	<unistd.h>
#include	<sys/types.h>
#include	<fcntl.h>
#include	<malloc.h>
#include	<a.out.h>
#include	"hash.h"
#include	"id.h"
#include	"io.h"
#include	"code.h"

#define	TABSIZE		4096
#define	BUFSIZE		1024

extern	char	*OzClassPath ;
extern	int	Class ;

typedef	struct	ClassCodeSymbolStr	ClassCodeSymbolRec ;
typedef	struct	ClassCodeSymbolStr*	ClassCodeSymbol ;
struct	ClassCodeSymbolStr	{
		int	n ;
	struct	nlist	*nlist ;
		char	*strs ;
} ;
typedef	struct	ClassCodeSymbolEntryStr		ClassCodeSymbolEntryRec ;
typedef	struct	ClassCodeSymbolEntryStr*	ClassCodeSymbolEntry ;
struct	ClassCodeSymbolEntryStr	{
	HashHeadRec	hash ;
	ClassCodeSymbol	symbol ;
} ;

static	HashTable	ClassCodeSymbolTable = NULL ;

ClassCodeSymbol
ClassCodeSymbolLoad( int aClass, ClassID aRunTimeClassID )
{
		int	fd = -1 ;
		int	i ;
		int	size ;
	ClassCodeSymbol	symbol = NULL ;
	struct	exec	exec;
	struct	nlist	*symPtr ;
	struct	nlist	*symEnd;
		char	fname[BUFSIZE] ;

	sprintf( fname, "%s/%s/private.o", OzClassPath, IDtoStr(aRunTimeClassID,NULL) ) ;

	symbol = (ClassCodeSymbol)malloc( sizeof(ClassCodeSymbolRec) ) ;
	if ( symbol == NULL ) {
		perror( "malloc" ) ;
		Errorf( "Can't allocate header for file:'%s' !!\n", fname ) ;
		goto error ;
	}

	symbol->nlist = NULL ;
	symbol->strs = NULL ;

	if ( access( fname, R_OK ) && aClass ) {
		if ( GetClassDM( aClass, aRunTimeClassID ) ) {
			Errorf( "Can't get '%s' !!\n", fname ) ;
			goto error ;
		}
	}

	if ( (fd=open( fname, O_RDONLY )) < 0 ) {
		perror( "open" ) ;
		Errorf( "Can't open '%s' !!\n", fname ) ;
		goto error ;
	}

	if ( read( fd, &exec, sizeof(exec) ) != sizeof(exec) ) {
		perror( "read" ) ;
		Errorf( "Can't read exec from '%s' !!\n", fname ) ;
		goto error ;
	}

	symbol->nlist = (struct nlist *)malloc( exec.a_syms ) ;
	if ( symbol->nlist == NULL ) {
		perror( "malloc" ) ;
		Errorf( "Can't allocate memory for symbols at file:'%s' !!\n", fname ) ;
		goto error ;
	}

	symbol->n = exec.a_syms / sizeof(struct nlist) ;
	symEnd = symbol->nlist + symbol->n ;

	if ( lseek( fd, N_SYMOFF(exec), SEEK_SET ) < 0 ) {
		perror( "lseek" ) ;
		Errorf( "Can't lseek to symbol infomation at file:'%s' !!\n", fname ) ;
		goto error ;
	}

	if ( read( fd, symbol->nlist, exec.a_syms ) != exec.a_syms ) {
		perror( "read" ) ;
		Errorf( "Can't read to symbol infomation from file:'%s' !!\n", fname ) ;
		goto error ;
	}

	if ( read( fd, &size, sizeof(size) ) != sizeof(size) ) {
		perror( "read" ) ;
		Errorf( "Can't read #size symbol name from file:'%s' !!\n", fname ) ;
		goto error ;
	}

	symbol->strs = (char *)malloc( size ) ;
	if ( symbol->strs == NULL ) {
		perror( "malloc" ) ;
		Errorf( "Can't malloc symbol name at file:'%s' !!\n", fname ) ;
		goto error ;
	}

	size -= sizeof( size ) ;
	if ( read( fd, symbol->strs + sizeof(size), size ) != size ) {
		perror( "read" ) ;
		Errorf( "Can't read symbol name from file:'%s' !!\n", fname ) ;
		goto error ;
	}

	for ( symPtr = symbol->nlist ; symPtr < symEnd; symPtr ++ ) {
		if ( symPtr->n_un.n_strx == 0 ) symPtr->n_un.n_name = 0 ;
		else symPtr->n_un.n_name = symbol->strs + symPtr->n_un.n_strx ;
	}

	close(fd ) ;
	return( symbol ) ;

error:
	if ( symbol != NULL ) {
		if ( symbol->nlist != NULL ) free( symbol->nlist ) ;
		if ( symbol->strs != NULL ) free( symbol->strs ) ;
		free( symbol ) ;
	}
	if ( fd > 0 ) close( fd ) ;
	return( NULL ) ;
}

ClassCodeSymbol
ClassCodeSymbolGet( int aClass, ClassID aRunTimeClassID )
{
	ClassCodeSymbolEntry	entry ;

	if ( ClassCodeSymbolTable == NULL ) ClassCodeSymbolTable = CreateHashTable( TABSIZE ) ;
	entry = (ClassCodeSymbolEntry)KeySearchHashTable( aRunTimeClassID, ClassCodeSymbolTable ) ;
	if ( entry == NULL ) {
		entry = (ClassCodeSymbolEntry)malloc( sizeof(ClassCodeSymbolEntryRec) ) ;
		if ( entry == NULL ) {
			perror( "malloc" ) ;
			Errorf( "ClassCodeSymbolGet: Can't malloc for ClassCodeSymbolEntryRec !!\n" ) ;
			return( NULL ) ;
		}
		entry->symbol = ClassCodeSymbolLoad( aClass, aRunTimeClassID ) ;
		if ( entry->symbol == NULL ) {
			free( entry ) ;
			return( NULL ) ;
		} else {
			entry->hash.id = aRunTimeClassID ;
			InsertIntoHashTable( &entry->hash, ClassCodeSymbolTable ) ;
		}
	}
	return( entry->symbol ) ;
}

char*
ClassCodeSymbolSearch( int aClass, ClassID aRunTimeClassID, unsigned long base, unsigned long *aRelAddr )
{
	struct	nlist	*symPtr ;
	struct	nlist	*symEnd;
	ClassCodeSymbol	symbol ;
		char	*name = NULL ;
	unsigned	near = base ;
	unsigned	addr = *aRelAddr ;
		char	*cp ;

#if	0
fprintf( stderr, "Addr = 0x%08x\n", addr ) ;
#endif

	symbol = ClassCodeSymbolGet( aClass, aRunTimeClassID ) ;
	if ( symbol == NULL ) goto error ;

	symEnd = symbol->nlist + symbol->n ;
	for ( symPtr = symbol->nlist ; symPtr < symEnd; symPtr ++ ) {
		if ( symPtr->n_type & N_EXT || symPtr->n_type == 0x24 ) {
#if	0
fprintf( stderr, "%08x:%02x %04x %s\n", near, symPtr->n_type, symPtr->n_desc, name ) ;
#endif
			if ( addr == (symPtr->n_value+base) ) {
				near = (symPtr->n_value+base) ;
				name = symPtr->n_un.n_name ;
				break ;
			} else if ( addr > (symPtr->n_value+base) ) {
				if ( (symPtr->n_value+base) > near ) {
					near = (symPtr->n_value+base) ;
					name = symPtr->n_un.n_name ;
				}
			}
		}
	}
	if ( name != NULL ) *aRelAddr = near ;

error:
	return( name ) ;
}
