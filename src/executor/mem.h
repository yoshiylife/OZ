/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef _MEM_H_
#define _MEM_H_
/* multithread system include */
#include "thread/monitor.h"

#include "encode-subs.h"
#include "executor/memory.h"

#define INTERIOR_POINTERS            0
#define INTERIOR_POINTERS_ON_STACK   1

#define ESTIMATE_OVERHEAD

typedef struct CellStr *Cell;
typedef struct CellStr CellRec;

struct CellStr {
  Cell b_prev;
  Cell b_next;
  unsigned int flags;
  int pad;
};

typedef struct HeapBlockStr *HeapBlock;
typedef struct HeapBlockStr HeapBlockRec;

struct HeapBlockStr {
  int size;
  HeapBlock b_prev;
  HeapBlock b_next;
  Cell used;
  Cell free;
  int pad;
};

typedef struct BlockEntryStr *BlockEntry;
typedef struct BlockEntryStr BlockEntryRec;

struct BlockEntryStr {
  HeapBlock blk_list;
};

typedef struct HeapStr *Heap;
typedef struct HeapStr HeapRec;

#define SHIFT            3
/* HB_TABLE_SIZE must be (getpagesize() / (1 << SHIFT)). */
#define HB_TABLE_SIZE    512

struct HeapStr {
  BlockEntryRec blk_table[HB_TABLE_SIZE];
  unsigned int heap_top;
  unsigned int heap_bottom;
  unsigned int heap_size;
  unsigned int heap_used;
#ifdef ESTIMATE_OVERHEAD
  int ncell;
  int nblk;
#endif
  OZ_MonitorRec lock;
  int gc_ing;
  OZ_ConditionRec decode_end;
  int decoding;
};

#define GCMARK           0x01
#define USED             0x02
#define CONSERV          0x04
#define MANUAL_MARK      0x08
inline extern int MmGetManualMark(Cell cell)
{
  return (cell->flags & MANUAL_MARK);
}
inline extern void MmSetManualMark(Cell cell)
{
  cell->flags |= MANUAL_MARK;
}

inline extern void MmBlockGc(Heap heap)
{
  OzExecEnterMonitor(&(heap->lock));
  heap->decoding++;
  OzExecExitMonitor(&(heap->lock));
}

inline extern void MmUnBlockGc(Heap heap)
{
  OzExecEnterMonitor(&(heap->lock));
  heap->decoding--;
  if (heap->decoding == 0)
    OzExecSignalCondition(&(heap->decode_end));
  OzExecExitMonitor(&(heap->lock));
}

/* I/F w/i executor */

extern int    MmInit(void);
extern Heap   MmCreateHeap(void);
extern char * MmAlloc(Heap h, int *size);
extern void   MmFree(Heap heap, char *ptr, unsigned int size);
extern void   MmDestroyHeap(Heap h);
extern int    PageSize;
extern unsigned int mem_short;
extern void MmCheckMemory(unsigned int size);
extern void MmMarkCell /* should be inline */
  (Cell cell, Fifo fifo, int conserv);
extern void MmMarkRegion
  (void *top, void *bottom, Fifo fifo, Heap h, int iflg);
extern void MmSweepHeap(Heap h, hashTable addr_table, int compact);
extern void MmDecrHeap(int size);
extern void MmReportHeap(Heap h);
extern void MmReportHeapGlobal(void);
extern void MmCompactHeap(Heap h, hashTable addr_table);

#endif !_MEM_H_
