/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include	<stdio.h>
#include	<malloc.h>
#include	"hash.h"

HashTable
CreateHashTable( int size )
{
	int		i ;
	HashTable	table ;

	table = (HashTable)malloc( sizeof(HashTableRec) + (sizeof(HashHead) * (size - 1)) ) ;
	if ( table == NULL ) {
		perror( "malloc" ) ;
		Errorf( "Hash create: poor memory !!\n" ) ;
		exit( 1 ) ;
	}
	table->size = size;
	for ( i = 0 ; i < size ; i ++ ) table->table[i] = (HashHead)0 ;
	return( table ) ;
}

void
InsertIntoHashTable( HashHead element, HashTable table )
{
	HashHead	head ;
	int		index = element->id & (table->size - 1) ;
			/* i.e. int index = element->id % table->size; */

	if (index >= table->size) {
		Errorf( "Hash insert: index out of range.\n" ) ;
		exit(1);
	}

	if ( (head = table->table[index]) == 0 ) {
		table->table[index] = element ;
		element->next = element ;
		element->prev = element ;
	} else {
		head->prev->next = element ;
		element->prev = head->prev ;
		element->next = head ;
		head->prev = element ;
	}
	element->entry = &table->table[index] ;
}

HashHead
KeySearchHashTable( long long key, HashTable table )
{
	HashHead	element, first ;
	int		index = key & (table->size - 1) ;
			/* i.e. int index = key % table->size; */

	if (index >= table->size) {
		Errorf( "Hash search: index out of range.\n" ) ;
		exit(1);
	}

	if ( ! table->table[index] ) return( (HashHead)0 ) ;
	first = (HashHead)0 ;
	for ( element = table->table[index]; element != first; element = element->next ) {
		if ( ! first ) first = element ;
		if (key == element->id) return( element ) ;
	}

	return( (HashHead)0 ) ;
}

void
RemoveFromHashTable( HashHead element, HashTable table )
{
	if (element->next == element) {
		*element->entry = (HashHead)0 ;
		return ;
	}
	if ( element == *element->entry ) *element->entry = element->next ;

	element->prev->next = element->next;
	element->next->prev = element->prev;
}
