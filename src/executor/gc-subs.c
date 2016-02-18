/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* multithread system include */
#include "thread/thread.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "common.h"
#include "encode-subs.h"
#include "mem.h"
#include "gc-subs.h"
#include "executor/alloc.h" /* for OzExecObjectGetTop */
#include "oz++/type.h"


/*
 *	Prototype declaration for C Library functions
 */
extern	void	bcopy( char *s1, char *s2, int len ) ;

void GcMarkPointer(OZ_Header header, Fifo fifo, int conserv)
{
  if (header->h == LOCAL) /* ObjectPart */
    header = (OZ_Header)OzExecGetObjectTop((OZ_Object)header);
  MmMarkCell((Cell)((int)header - sizeof(CellRec)), fifo, conserv);
}

static void traverse_pointers_aux(OZ_AllocateInfo ainfo, Fifo fifo)
{
  OZ_Header *hp;
  int i;

  hp = (OZ_Header *)(ainfo + 1);
  for (i = 0; i < ainfo->number_of_pointer_protected; i++) {
    if (*hp)
      GcMarkPointer(*hp, fifo, 0);
    hp++;
  } 
  /* skip to private region */
  hp += (ainfo->number_of_pointer_protected & 1);
  hp += ainfo->data_size_protected / sizeof(OZ_Header *);
  for (i = 0; i < ainfo->zero_protected; i++)
    hp += (sizeof(OZ_ConditionRec) / sizeof(OZ_Header *));

  for (i = 0; i < ainfo->number_of_pointer_private; i++) {
    if (*hp)
      GcMarkPointer(*hp, fifo, 0);
    hp++;
  }
}

static void traverse_array(OZ_Header o, Fifo fifo)
{
  OZ_Header *hp;
  int i;

  if ((o->a != OZ_LOCAL_OBJECT) &&
      (o->a != OZ_STATIC_OBJECT) &&
      (o->a != OZ_ARRAY))
    return;
  hp = (OZ_Header *)(o + 1);
  for (i = 0; i < o->h; i++) {
    if (*hp)
      GcMarkPointer(*hp, fifo, 0);
    hp++;
  }
}

void GcTraversePointers(Fifo fifo)
{
  int i;
  OZ_Header o, all;

  while ((o = (OZ_Header)OzGetFifo(fifo))) {
    if (o->h == STATIC)
      traverse_pointers_aux((OZ_AllocateInfo)(o + 1), fifo);
    else if (o->h != RECORD)
      switch ((int)(o->d)) {
      case OZ_LOCAL_OBJECT:
	all = o;
	for (i = 0, o = all + 1; i < all->h; i++, o++)
	  traverse_pointers_aux(o->d, fifo);
	continue;
      case OZ_ARRAY:
	traverse_array(o, fifo);
	continue;
      case 0:
	continue;
      default:
	ThrPanic("GcTraversePointers: unknown type of header.");
      }
  }
}

/* inline */ static void adjust_pointer(OZ_Header *hp, hashTable addr_table)
{
  (unsigned int)(*hp) += OzSearchHash(addr_table, (void *)(*hp));
}

static void adjust_pointers_aux
  (OZ_AllocateInfo ainfo, hashTable addr_table)
{
  OZ_Header *hp;
  int i;

  hp = (OZ_Header *)(ainfo + 1);
  for (i = 0; i < ainfo->number_of_pointer_protected; i++) {
    if (*hp)
      adjust_pointer(hp, addr_table);
    hp++;
  } 
  /* skip to private region */
  hp += (ainfo->number_of_pointer_protected & 1);
  hp += ainfo->data_size_protected / sizeof(OZ_Header *);
  for (i = 0; i < ainfo->zero_protected; i++)
    hp += (sizeof(OZ_ConditionRec) / sizeof(OZ_Header *));

  for (i = 0; i < ainfo->number_of_pointer_private; i++) {
    if (*hp)
      adjust_pointer(hp, addr_table);
    hp++;
  }
}

static void adjust_array(OZ_Header o, hashTable addr_table)
{
  OZ_Header *hp;
  int i;

  if ((o->a != OZ_LOCAL_OBJECT) &&
      (o->a != OZ_STATIC_OBJECT) &&
      (o->a != OZ_ARRAY))
    return;
  hp = (OZ_Header *)(o + 1);
  for (i = 0; i < o->h; i++) {
    if (*hp)
      adjust_pointer(hp, addr_table);
    hp++;
  }
}

void GcAdjustPointers(void *ptr, hashTable addr_table)
{
  int i;
  OZ_Header o = (OZ_Header)ptr, all;

  if (o->h == STATIC)
    adjust_pointers_aux((OZ_AllocateInfo)(o + 1), addr_table);
  else if (o->h != RECORD)
    switch ((int)(o->d)) {
    case OZ_LOCAL_OBJECT:
      all = o;
      for (i = 0, o = all + 1; i < all->h; i++, o++)
	  adjust_pointers_aux(o->d, addr_table);
      break;
    case OZ_ARRAY:
      adjust_array(o, addr_table);
      break;
    case 0:
      break;
    default:
      ThrPanic("GcAdjustPointers: unknown type of header.");
    }
}


void GcCopyObject(void *from, void *to, int size)
{
  OZ_Header new = (OZ_Header)to;
  int diff = (unsigned int)to - (unsigned int)from, i;

  bcopy((char *)from, (char *)to, size);
  if (new->d == (void *)OZ_LOCAL_OBJECT) {
    for (i = 1; i <= new->h; i++)
      new[i].d += diff;
    new[0].t += diff;
  }
}

inline void register_pointer(hashTable addr_table, void *ptr, int diff)
{
  if (! (OzSearchHash(addr_table, ptr))) {
#if 0
OzDebugf("register 0x%0x with diff 0x%0x\n", ptr, diff);
#endif
    if (!OzEnterHash(addr_table, ptr, (void *)diff)) {
      ThrPanic("register_pointer hash full.");
    }
  }
}

void GcRegisterPointers(hashTable addr_table, void *ptr, int diff)
{
  int i;
  OZ_Header o = (OZ_Header)ptr, all;

  if (o->h == STATIC)
    register_pointer(addr_table, ptr, diff);
  else if (o->h != RECORD)
    switch ((int)(o->d)) {
    case OZ_LOCAL_OBJECT:
      all = o;
      for (i = 0, o = all + 1; i < all->h; i++, o++)
	register_pointer(addr_table, (void *)o, diff);
      break;
    case OZ_ARRAY:
      register_pointer(addr_table, ptr, diff);
      break;
    case 0:
      break;
    default:
      ThrPanic("GcRegisterPointers: unknown type of header.");
    }
}
