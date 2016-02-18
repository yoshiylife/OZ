/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "oz++/ozlibc.h"
#include "switch.h"
#include "comm-hash.h"

extern	int	bzero( char *, int ) ;

/* commHash routines */

static	int	inline 
commHash_val(long long id, int mask)
{
	return((int)(id & mask));
}

commHashTable
CreateCommHash()
{
  commHashTable	h;
  commHashTableItem	p;

	if ((h = (commHashTable)OzMalloc(sizeof(commHashTableRec))) 
	    == (commHashTable)0)
	  return(0);
	if ((p = (commHashTableItem)OzMalloc(sizeof(commHashTableItemRec)*
					     COMM_HASH_INDEX_SIZE)) 
	    == (commHashTableItem)0) {
	  OzFree(h);
	  return(0);
	}
	h->size = COMM_HASH_INDEX_SIZE;
	h->mask = COMM_HASH_MASK;
	h->count = 0;
	h->table = p;
	bzero((char *)p, sizeof(commHashTableItemRec)*COMM_HASH_INDEX_SIZE);
	return(h);
}

static	int	
expand_commHashtable(commHashTable hash)
{
	commHashTableItem	new, old, oldend;

	if ((new = (commHashTableItem)OzMalloc(sizeof(commHashTableItemRec) *
			hash->size * 2)) == (commHashTableItem)0)
		return(0);
	bzero((char *)new, sizeof(commHashTableItemRec) * hash->size * 2);
	old = hash->table;
	oldend = old + hash->size;

	hash->table = new;
	hash->size *= 2;

	hash->mask <<= 1;
	hash->mask |= 1;
	hash->count = 0;

	/* rehash */
	for (new = old; new < oldend; new++)
		if (new->id)
			EnterCommHash(hash, new->id, new->val);
#if	1	/* for debug by yoshi */
	OzFree( old ) ;
#endif
	return(1);
}

int	
EnterCommHash(commHashTable hash, long long id,void *val)
{
	int	h;
#if 0
OzDebugf("EnterCommHash: start : entry %d , %08x%08x : %x\n",
	 hash->count,id,val);
#endif

	if (hash->count * 2 >= hash->size) {
		if (expand_commHashtable(hash) == 0)
			return(0);
	}

	h = commHash_val(id, hash->mask);

	for (;
	     (hash->table + h)->id != 0;
	     h = ((h + INDEX_HASH_SKIP) & hash->mask))
		;
	(hash->table + h)->id = id;
	(hash->table + h)->val = val;
	hash->count++;
	return(1);
}

void 
*SearchCommHash(commHashTable hash, long long id)
{
	int	h;

	h = commHash_val(id, hash->mask);
	for (;
	     (hash->table + h)->id != 0;
	     h = ((h + INDEX_HASH_SKIP) & hash->mask))
		if ((hash->table + h)->id == id)
			break;
#if	1	/* for debug by yoshi */
	h = (int)(hash->table + h)->val ;
	if ( h && h < 0x10000 ) abort() ;
	return( (void *)h ) ;
#else
	return((hash->table + h)->val);
#endif
}

void
RemoveCommHash(commHashTable hash, long long id)
{
  struct RemoveCommHashTable {
    long long id;
    void *val;
  } *table ;
  int h,i;
#if 0
OzDebugf("RemoveCommHash: start : entry %d\n",hash->count);
#endif

  h = commHash_val(id, hash->mask);

  table = (struct RemoveCommHashTable *)
    OzMalloc( sizeof(struct RemoveCommHashTable)*(1+(hash->size)/2) ) ;

  for(i=0; hash->table[h].id != 0;
      h = ((h+INDEX_HASH_SKIP) & hash->mask) )
    {
      if(hash->table[h].id != id)
	 {
	   table[i].id = hash->table[h].id;
	   table[i].val = hash->table[h].val;
	   i++;
	 }
      hash->table[h].id =0LL;
      hash->table[h].val=0;
      hash->count--;
    }

  if(i)
    for(i--; i>=0 ; i--)
      {
	EnterCommHash(hash,table[i].id,table[i].val);
      }

  OzFree( table ) ;
#if 0
OzDebugf("RemoveCommHash: end : entry %d\n",hash->count);
#endif
  return;
}

void
FreeCommHash(commHashTable hash)
{
	OzFree(hash->table);
	OzFree(hash);
}
