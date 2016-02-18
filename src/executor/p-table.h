/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _P_TABLE_H_
#define _P_TABLE_H_

#define POINTER_TABLE_SIZE 1024

typedef struct _PointerTableRec {
  struct _PointerTableRec *next;
  int size;
  void *table[POINTER_TABLE_SIZE];
}PointerTableRec, *PointerTable;

extern PointerTable createPointerTable();
extern void *readPointerTable(PointerTable pt, int index);
extern int putPointerTable(PointerTable pt,void *entry);
extern void freePointerTable(PointerTable pt);

#endif /* _P_TABLE_H_ */
