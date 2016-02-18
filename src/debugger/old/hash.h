/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#if	!defined(_OZ_DEBUGGER_HASH_H)
#define	_OZ_DEBUGGER_HASH_H

typedef	struct	HashHeadStr	HashHeadRec ;
typedef	struct	HashHeadStr*	HashHead ;
struct	HashHeadStr {
	long long	id ;
	HashHeadRec	*prev ;
	HashHeadRec	*next ;
	HashHeadRec	**entry ;
} ;

typedef	struct	HashTableStr	HashTableRec ;
typedef	struct	HashTableStr*	HashTable ;
struct	HashTableStr {
	int		size ;
	HashHead	table[1] ;
} ;

extern	HashTable	CreateHashTable( int size ) ;
extern	void		InsertIntoHashTable( HashHead element, HashTable table ) ;
extern	HashHead	KeySearchHashTable( long long key, HashTable table ) ;

#endif	_OZ_DEBUGGER_HASH_H
