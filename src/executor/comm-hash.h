/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _COMM_HASH_H_
#define _COMM_HASH_H_

/* hash routines for communication.
* hash table is an associative list of message-Id(64bit) and pointer */
#define	COMM_HASH_INDEX_SIZE	1024
#define COMM_HASH_MASK          0x3ff
#define INDEX_HASH_SKIP         37

typedef	struct _commHashTableItemRec {
  long long id;
  void	*val;
} commHashTableItemRec, *commHashTableItem;

typedef struct _commHashTableRec {
	int	size;
	int	mask;
	int	count;
	commHashTableItem	table;
} commHashTableRec, *commHashTable;

extern commHashTable CreateCommHash();
extern int  EnterCommHash(commHashTable hash, long long id, void *val);
extern void *SearchCommHash(commHashTable hash, long long id);
extern void RemoveCommHash(commHashTable hash, long long id);
extern void FreeCommHash(commHashTable hash);

#endif /* _COMM_HASH_H_ */
