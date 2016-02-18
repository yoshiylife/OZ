/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<stdio.h>
#include	<fcntl.h>
#include	<malloc.h>
#include	"hash.h"
#include	"id.h"
#include	"class.h"

#define	TABSIZE		4096
#define	BUFSIZE		1024

extern	char	*OzClassPath ;

typedef	struct	ClassInfoEntryStr	ClassInfoEntryRec ;
typedef	struct	ClassInfoEntryStr*	ClassInfoEntry ;
struct	ClassInfoEntryStr	{
	HashHeadRec	hash ;
	OZ_ClassInfo	info ;
} ;

static	HashTable	ClassInfoTable = NULL ;

OZ_ClassInfo
ClassInfoLoad( OZ_ClassID aConfiguredClassID )
{
	OZ_ClassInfo	info = NULL ;
	int		fd = -1 ;
	int		total ;
	int		i ;
	char		fname[BUFSIZE] ;
	char		*offset ;

	sprintf( fname, "%s/%s/private.r", OzClassPath, IDtoStr(aConfiguredClassID,NULL) ) ;
	if ( (fd=open( fname, O_RDONLY )) < 0 ) {
		perror( "open" ) ;
		Errorf( "Can't open '%s' !!\n", fname ) ;
		goto error ;
	}

	if ( read( fd, &total, sizeof(total) ) != sizeof(total) ) {
		perror( "read" ) ;
		Errorf( "Can't read #total from file:'%s' !!\n", fname ) ;
		goto error ;
	}

	info = (OZ_ClassInfo)malloc(total) ;
	if ( info == NULL ) {
		perror( "malloc" ) ;
		Errorf( "Can't allocate memory for ClassInfo at file:'%s' !!\n", fname ) ;
		goto error ;
	}

	if ( read( fd, info, total ) != total ) {
		perror( "read" ) ;
		Errorf( "Can't read data from file:'%s' !!\n", fname ) ;
		free( info ) ;
		info = NULL ;
		goto error ;
	}

	for ( i = 0 ;i < info->number_of_parts ; i ++ ) {
		offset = (void *)info->parts[i] ;
		offset += (unsigned int)info ;
		info->parts[i] = (OZ_ClassPart)offset ;
	}

error:
	if ( fd >= 0 ) close( fd ) ;
	return( info ) ;
}

OZ_ClassInfo
ClassInfoGet( ClassID aConfiguredClassID )
{
	ClassInfoEntry	entry ;

	if ( ClassInfoTable == NULL ) ClassInfoTable = CreateHashTable( TABSIZE ) ;
	entry = (ClassInfoEntry)KeySearchHashTable( aConfiguredClassID, ClassInfoTable ) ;
	if ( entry == NULL ) {
		entry = (ClassInfoEntry)malloc( sizeof(ClassInfoEntryRec) ) ;
		if ( entry == NULL ) {
			perror( "malloc" ) ;
			Errorf( "ClassInfoGet: Can't malloc for ClassInfoEntry !!\n" ) ;
			return( NULL ) ;
		}
		entry->info = ClassInfoLoad( aConfiguredClassID ) ;
		if ( entry->info == NULL ) {
			free( entry ) ;
			return( NULL ) ;
		} else {
			entry->hash.id = aConfiguredClassID ;
			InsertIntoHashTable( &entry->hash, ClassInfoTable ) ;
		}
	}
	return( entry->info ) ;
}
