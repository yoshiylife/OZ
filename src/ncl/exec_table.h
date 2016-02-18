/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _EXEC_TABLE_H_
#define _EXEC_TABLE_H_

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

/* hash routines for executor table.					*/
/* hash table is an associative list of message-Id(64bit) and pointer	*/
#define EXEC_TABLE_SIZE         1024

/* ET_HASH_INDEX_SIZE==EXEC_TABLE_SIZE*2	*/
#define	ET_HASH_INDEX_SIZE	2048
#define ET_HASH_MASK		0x7ff
#define INDEX_HASH_SKIP		37

typedef	struct _ETHashTableItemRec {
	long long	id;
	int		val;
} ETHashTableItemRec, *ETHashTableItem;

typedef struct _ETHashTableRec {
	int	lock;
	int	size;
	int	mask;
	int	count;
	ETHashTableItemRec	table[ET_HASH_INDEX_SIZE];
} ETHashTableRec, *ETHashTable;

typedef struct _ExecTableRec {
	long long		exid;
	struct sockaddr_in	addr;
	int			lastaccess;
	enum { ET_LOCAL, ET_INSITE, ET_OUTSITE } location;
} ExecTableRec, *ExecTable;

extern void OzInitETHash(ETHashTable hash);
extern int  OzEnterETHash(ETHashTable hash, long long id, int val);
extern int  OzSearchETHash(ETHashTable hash, long long id);
extern void OzRemoveETHash(ETHashTable hash, long long id);

#endif /* _EXEC_TABLE_H_ */
