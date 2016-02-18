/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "oz++/ozlibc.h"
#include "switch.h"
#include "encode-subs.h"

/*
 *	Prototype declaration for C Library functions
 */
extern	void	bzero( char *s, int length ) ;

/* Fifo is a first-in first-out register of pointers to void.		*/
/* OzCreateFifo,OzPutFifo returns null when error occurs.		*/
/* First argument of OzPutFifo,OzGetFifo,OzFreeFifo is pointer to fifo.	*/

#define	FIFO_BLOCK_SIZE	1024


struct	fifo_block	{
	struct	fifo_block	*next;
	void	*entry[FIFO_BLOCK_SIZE];
};

struct	fifo	{
	int	count;
	struct	fifo_block	*head_block;
	int	head_index;
	struct	fifo_block	*tail_block;
	int	tail_index;
};

void	*OzCreateFifo()
{
	Fifo	fifo;

	fifo = (Fifo)OzMalloc(sizeof(struct fifo));
	fifo->count = 0;
	fifo->head_block = fifo->tail_block =
		(struct fifo_block *)OzMalloc(sizeof(struct fifo_block));
	fifo->tail_block->next = 0;
	fifo->head_index = fifo->tail_index = 0;
	return(fifo);
}

int	OzPutFifo(Fifo fifo, void *o)
{
	if (fifo->tail_index >= FIFO_BLOCK_SIZE) {
		fifo->tail_block->next =
		    (struct fifo_block *)OzMalloc(sizeof(struct fifo_block));
		fifo->tail_block = fifo->tail_block->next;
		fifo->tail_block->next = 0;
		fifo->tail_index = 0;
	}
	fifo->tail_block->entry[fifo->tail_index++] = o;
	fifo->count++;
	return(1);
}

void *OzGetFifo(Fifo fifo)
{
	void	*rval;

	if (fifo->count == 0)
		return(0);
	if (fifo->head_index >= FIFO_BLOCK_SIZE) {
		struct	fifo_block	*tmp;

		tmp = fifo->head_block;
		fifo->head_block = tmp->next;
		fifo->head_index = 0;
		OzFree(tmp);
	}
	rval = fifo->head_block->entry[fifo->head_index++];
	fifo->count--;
	if (fifo->count == 0) {
		fifo->head_index = 0;
		fifo->tail_index = 0;
	}
	return(rval);
}

void	OzFreeFifo(Fifo fifo)
{
	struct	fifo_block	*tmp;

	while ( (tmp = fifo->head_block) != NULL ) {
		fifo->head_block = tmp->next;
		OzFree(tmp);
	}
	OzFree(fifo);
}

/* Hash is an associative pair of (void *)key and (void *)value		*/
/* with hash-search functions.						*/
/* OzCreateHash,OzPutHash returns null when error occurs.		*/
/* First argument of OzPutHash,OzGetHash,OzFreeHash is pointer to hash	*/
/* table.								*/
/* OzSearchHash returns null to indicate NOT_FOUND.			*/

typedef	struct hashTableItemRec {
	void	*key, *val;
} hashTableItemRec, *hashTableItem;

typedef struct indexTableStr hashTableRec;

struct indexTableStr {
	int	size;
	int	mask;
	int	count;
	hashTableItem	table;
};

#define	INDEX_HASH_SIZE	1024
#define	INDEX_HASH_MASK	0x3ff
#define	INDEX_HASH_SKIP	39
#define	HASH_SHIFT	4

inline static	int	hash_val(void *addr, int mask)
{
	return(((unsigned)addr >> HASH_SHIFT) & mask);
}

void *OzCreateHash()
{
	hashTable	h;
	hashTableItem	p;

	if ((h = (hashTable)OzMalloc(sizeof(hashTableRec))) == (hashTable)0)
		return(0);
	if ((p = (hashTableItem)OzMalloc(sizeof(hashTableItemRec)*
			INDEX_HASH_SIZE)) == (hashTableItem)0) {
		OzFree(h);
		return(0);
	}
	h->size = INDEX_HASH_SIZE;
	h->mask = INDEX_HASH_MASK;
	h->count = 0;
	h->table = p;
	bzero((char *)p, sizeof(hashTableItemRec)*INDEX_HASH_SIZE);
	return(h);
}

static	int	expand_hashtable(hashTable hash)
{
	hashTableItem	new, old, oldend;

	if ((new = (hashTableItem)OzMalloc(sizeof(hashTableItemRec) *
			hash->size * 2)) == (hashTableItem)0) {
#if	1
		OzFree(hash->table);
#endif
		return(0);
	}
	bzero((char *)new, sizeof(hashTableItemRec) * hash->size * 2);
	old = hash->table;
	oldend = old + hash->size;

	hash->table = new;
	hash->size *= 2;
	hash->mask <<= 1;
	hash->mask |= 1;
	hash->count = 0;

	/* rehash */
	for (new = old; new < oldend; new++)
		if (new->key)
			OzEnterHash(hash, new->key, new->val);
#if	1
	OzFree(old);
#endif
	return(1);
}

int	OzEnterHash(hashTable hash, void *key, void *val)
{
	int	h;

	if (hash->count * 2 > hash->size)
		if (expand_hashtable(hash) == 0)
			return(0);
	h = hash_val(key, hash->mask);

	for (;
	     (hash->table + h)->key != 0;
	     h = ((h + INDEX_HASH_SKIP) & hash->mask))
		;
	(hash->table + h)->key = key;
	(hash->table + h)->val = val;
	hash->count++;
	return(1);
}

void *OzSearchHash(hashTable hash, void *key)
{
	int	h;

	h = hash_val(key, hash->mask);
	for (;
	     (hash->table + h)->key != 0;
	     h = ((h + INDEX_HASH_SKIP) & hash->mask))
		if ((hash->table + h)->key == key)
			break;
	return((hash->table + h)->val);
}

void OzFreeHash(hashTable hash)
{
	OzFree(hash->table);
	OzFree(hash);
}
