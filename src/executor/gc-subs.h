/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _GC_SUBS_H_
#define _GC_SUBS_H_

#include "oz++/object-type.h"

extern void GcMarkPointer            /* should be inline */
  (OZ_Header header, Fifo fifo, int conserv);
extern void GcTraversePointers(Fifo fifo);
extern void GcAdjustPointers(void *o, hashTable addr_table);
extern void GcCopyObject(void *from, void *to, int size);
extern void GcRegisterPointers(hashTable addr_table, void *ptr, int diff);

#endif _GC_SUBS_H_
