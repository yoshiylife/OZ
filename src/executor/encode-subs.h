/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _ENCODE_SUBS_H_
#define _ENCODE_SUBS_H_

typedef struct fifo *Fifo;

extern void *OzCreateFifo(void);
extern int OzPutFifo(Fifo fifo, void *o);
extern void *OzGetFifo(Fifo fifo);
extern void OzFreeFifo(Fifo fifo);

typedef struct indexTableStr *hashTable;

extern void *OzCreateHash(void);
extern int OzEnterHash(hashTable hash, void *key, void *val);
extern void *OzSearchHash(hashTable hash, void *key);
extern void OzFreeHash(hashTable hash);

#endif  _ENCODE_SUBS_H_
