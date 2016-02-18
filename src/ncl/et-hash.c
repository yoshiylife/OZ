/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "exec_table.h"

/* Executor Table Hash routines						*/
/* this routine looks alike comm-hash routines, but different hash	*/
/* function is used							*/

ExecTable extbl;

static	int	inline 
ETHash_val(long long id, int mask)
{
	return((int)((id>>24) & mask));
}

void
OzInitETHash(ETHashTable h)
{
ETHashTableItem	p;

	h->size	= ET_HASH_INDEX_SIZE;
	h->mask	= ET_HASH_MASK;
	h->count = 0;
	bzero(h->table, sizeof(ETHashTableItemRec) * ET_HASH_INDEX_SIZE);
	return;
}

/* please check number of contensts in the hash table	*/
/* this routine does not expand hash table		*/
int	OzEnterETHash(ETHashTable hash, long long id, int val)
{
int	h;

	h = ETHash_val(id, hash->mask);

	for (; (hash->table + h)->id != 0;
	    h = ((h + INDEX_HASH_SKIP) & hash->mask));

	(hash->table + h)->id	= id;
	(hash->table + h)->val	= val;
	hash->count++;
	return(1);
}

#ifndef _NCL_CODE_
int	OzSearchETHash(ETHashTable hash, long long id)
{
int	h, prev_lock;

search_again:
	prev_lock = hash->lock;
	if(prev_lock & 0x01) { 
		OzYieldThread();
		goto search_again;
	}
	h = ETHash_val(id, hash->mask);
	for (; (hash->table + h)->id != 0;
	    h = ((h + INDEX_HASH_SKIP) & hash->mask)) {
		if ((hash->table + h)->id == id) {
			extbl[id].lastaccess = prev_lock;
			break;
		}
	}

	if(prev_lock == hash->lock) {
		if((hash->table + h)->id == id)
			return((hash->table + h)->val);
		else
			return(-1);
	}
	goto search_again;
}
#endif

int	OzSearchETHashNcl(ETHashTable hash, long long id)
{
int	h;

	h = ETHash_val(id, hash->mask);
	for (; (hash->table + h)->id != 0;
	    h = ((h + INDEX_HASH_SKIP) & hash->mask)) {
		if ((hash->table + h)->id == id)
			return((hash->table + h)->val);
	}

	return(-1);
}

void	OzRemoveETHash(ETHashTable hash, long long id)
{
struct {
	long long	id;
	int		val;
} table[ET_HASH_INDEX_SIZE];
int	h, i;

	h = ETHash_val(id, hash->mask);

	for(i=0; (hash->table+h)->id != 0;
	    h = ((h+INDEX_HASH_SKIP) & hash->mask)) {
		if((hash->table+h)->id != id) {
			table[i].id	= (hash->table+h)->id;
			table[i].val	= (hash->table+h)->val;
			i++;
		}
		(hash->table+h)->id	= 0;
		(hash->table+h)->val	= (-1);
		hash->count--;
	}

	for(i--; i>=0; i--) {
		OzEnterETHash(hash,table[i].id,table[i].val);
	}
	return;
}
