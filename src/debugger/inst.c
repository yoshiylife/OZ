/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<unistd.h>
#include	<stdio.h>
#include	<string.h>
#include	"id.h"
#include	"io.h"
#include	"hash.h"
#include	"inst.h"

#define	TABSIZE		4096
#define	BUFSIZE		1024

extern	char	*OzClassPath ;
extern	int	Class ;

typedef	struct	InstInfoEntryStr	InstInfoEntryRec ;
typedef	struct	InstInfoEntryStr*	InstInfoEntry ;
struct	InstInfoEntryStr	{
	HashHeadRec	hash ;
	InstInfo	info ;
} ;

static	HashTable	InstInfoTable = NULL ;

InstInfo
InstInfoLoad( int aClass, OZ_ClassID aRunTimeClassID )
{
static	char	*space = " \t\n" ;
	FILE	*fp ;
	char	fname[BUFSIZE] ;
	char	lbuf[BUFSIZE] ;
	char	*p ;
	int	i ;
	InstInfo	table = NULL ;

	sprintf( fname, "%s/%s/private.d", OzClassPath, IDtoStr(aRunTimeClassID,NULL) ) ;

	if ( access( fname, R_OK ) && aClass ) {
		if ( GetClassDM( aClass, aRunTimeClassID ) ) {
			Errorf( "Can't get '%s' !!\n", fname ) ;
			goto error ;
		}
	}

	if ( (fp=fopen( fname, "r" )) == NULL ) {
		perror( "fopen" ) ;
		Errorf( "Can't open '%s' !!\n", fname ) ;
		goto error ;
	}

	if ( fgets( lbuf, BUFSIZE, fp ) == NULL || sscanf( lbuf, "%d", &i ) != 1 ) {
		perror( "fgets" ) ;
		Errorf( "Can't read #total record in file '%s' !!\n", fname ) ;
		goto error ;
	}

	table = (InstInfo)malloc( SIZEOF_INSTINFO(i) ) ;
	if ( table == NULL ) {
		perror( "malloc" ) ;
		Errorf( "Can't malloc(%d) InstInfo at file '%s' !!\n", SIZEOF_INSTINFO(i), fname ) ;
		goto error ;
	}

	if ( sscanf( lbuf, "%d%d%d", &table->total, &table->protected, &table->private ) != 3 ) {
		perror( "sscanf" ) ;
		free( table ) ;
		table = NULL ;
		goto error ;
	}

	for ( i = 0 ; i < table->total ; i ++ ) {
		if ( fgets( lbuf, BUFSIZE, fp ) == NULL ) {
			perror( "fgets" ) ;
			Errorf( "Can't read at line %d in file '%s' !!\n", i+2, fname ) ;
			break ;
		}
		table->inst[i].name = NULL ;
		table->inst[i].type = NULL ;
		if ( (p = strtok( lbuf, space )) == NULL ) {
			Errorf( "Can't take out name token at line %d in file '%s' !!\n", i+2, fname ) ;
			break ;
		}
		if ( (table->inst[i].name=strdup(p)) == NULL ) {
			perror( "strdup" ) ;
			Errorf( "Can't allocate name at line %d in file '%s' !!\n", i+2, fname ) ;
			break ;
		}

		if ( (p = strtok( NULL, space )) == NULL ) {
			Errorf( "Can't take out pos token at line %d in file '%s' !!\n", i+2, fname ) ;
			break ;
		}
		table->inst[i].pos = strtol(p,NULL,0) ;

		if ( (p = strtok( NULL, space )) == NULL ) {
			Errorf( "Can't take out size token at line %d in file '%s' !!\n", i+2, fname ) ;
			break ;
		}
		table->inst[i].size = strtol(p,NULL,0) ;

		if ( (p = strtok( NULL, space )) == NULL ) {
			Errorf( "Can't take out type token at line %d in file '%s' !!\n", i+2, fname ) ;
			break ;
		}
		if ( (table->inst[i].type=strdup(p)) == NULL ) {
			perror( "strdup" ) ;
			Errorf( "Can't allocate type at line %d in file '%s' !!\n", i+2, fname ) ;
			break ;
		}
	}
	if ( i != table->total ) {
		while( -- i ) {
			free ( table->inst[i].name ) ;
			free ( table->inst[i].type ) ;
		}
		free( table ) ;
		table = NULL ;
		goto error ;
	}

error:
	if ( fp != NULL ) fclose( fp ) ;
	return( table ) ;
}

void
InstInfoUnLoad( InstInfo aInfo )
{
	int	i ;

	if ( aInfo != NULL ) {
		i = aInfo->total ;
		while( i -- ) {
			free( aInfo->inst[i].name ) ;
			free( aInfo->inst[i].type ) ;
		}
		free( aInfo ) ;
	}
}

InstInfo
InstInfoGet( int aClass, OZ_ClassID aRunTimeClassID )
{
	InstInfoEntry	entry ;

	if ( InstInfoTable == NULL ) InstInfoTable = CreateHashTable( TABSIZE ) ;
	entry = (InstInfoEntry)KeySearchHashTable( aRunTimeClassID, InstInfoTable ) ;
	if ( entry == NULL ) {
		entry = (InstInfoEntry)malloc( sizeof(InstInfoEntryRec) ) ;
		if ( entry == NULL ) {
			perror( "malloc" ) ;
			Errorf( "InstInfoGet: Can't malloc for InstInfoEntry !!\n" ) ;
			return( NULL ) ;
		}
		entry->info = InstInfoLoad( aClass, aRunTimeClassID ) ;
		if ( entry->info == NULL ) {
			free( entry ) ;
			return( NULL ) ;
		} else {
			entry->hash.id = aRunTimeClassID ;
			InsertIntoHashTable( &entry->hash, InstInfoTable ) ;
		}
	}
	return( entry->info ) ;
}
