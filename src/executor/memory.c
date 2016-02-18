/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdio.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <fcntl.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "mem.h"
#include "queue.h"
#include "fault-q.h"
#include "encode-subs.h"
#include "gc-subs.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"


#undef  SHOW_GC_RESULT
#define SILENT_GC
#define VERRY_SILENT_GC

/*
 *	Declaration of System calls
 */
#if	!defined(SVR4)
extern	int	munmap( caddr_t addr, int len ) ;
#endif	/* SVR4 */

extern	void	bzero( char *b, int length ) ;

static void init_gc_context();
static void register_dbcmds();
int MmInit()
{
  init_gc_context();
  register_dbcmds();
  return( 0 );
}

/*
 * Heap routines.
 */

static unsigned int mem_short;
static OZ_MonitorRec heap_size_lock;
static unsigned int heap_size;

Heap MmCreateHeap()
{
  int i;
  Heap h = (Heap)OzMalloc(sizeof(HeapRec));

  h->heap_top = 0;
  h->heap_bottom = 0;
  h->heap_size = 0;
  h->heap_used = 0;
#ifdef ESTIMATE_OVERHEAD
  h->ncell = h->nblk = 0;
#endif ESTIMATE_OVERHEAD
  for (i = 0; i < HB_TABLE_SIZE; i++)
    h->blk_table[i].blk_list = (HeapBlock)0;
  OzInitializeMonitor(&(h->lock));
  h->gc_ing = 0;
  h->decoding = 0;
  OzExecInitializeCondition(&(h->decode_end), 0);
  return(h);
}

/*
 *     Reporting for Debug
 */

static unsigned int get_heap_size();
unsigned int OzFreeMemory() /* I/F w/ OM */
{
  unsigned int size = get_heap_size();
  return (size * 100 / OzHeapSize);
}

void MmReportHeapGlobal()
{
  OzOutput(-1,"Total    : %d (not released) * 100 / %d (limit) = %d\n",
	   get_heap_size(), OzHeapSize, OzFreeMemory());
}

void MmReportHeap(Heap h)
{
  OzOutput(-1,"This heap: %d (not free/sweeped) %d (not released)\n",
	   h->heap_used, h->heap_size);
#ifdef ESTIMATE_OVERHEAD
  OzOutput(-1,"This heap: number of cells  = %d (%d bytes overhead)\n", h->ncell,
	   h->ncell * sizeof(CellRec));
  OzOutput(-1,"This heap: number of blocks = %d (%d bytes overhead)\n", h->nblk,
	   h->nblk * sizeof(HeapBlockRec));
  {
    int i, ncell, nused, per;
    HeapBlock hb;
    Cell cell;

    for (i = 0, ncell = 0, nused = 0; i < HB_TABLE_SIZE; i++)
      if ((hb = h->blk_table[i].blk_list) != 0)
	do {
	  ncell += ((ThrPageSize - sizeof(HeapBlockRec))
		    / (hb->size + sizeof(CellRec)));
	  if ((cell = hb->used) != 0)
	    do {
	      nused++;
	    } while ((cell = cell->b_next) != hb->used);
	} while ((hb = hb->b_next) != h->blk_table[i].blk_list);
    per = ncell ? ((nused * 100) / ncell) : 100;
    OzOutput(-1,"This heap: percentage of used cells = %d\n", per);
  }
#endif ESTIMATE_OVERHEAD
  /* ReportHeapGlobal(); */
}

/*
 *     Heap Management Routines
 */

static unsigned int get_heap_size()
{
  unsigned int size;

  OzExecEnterMonitor(&heap_size_lock);
  size = heap_size;
  OzExecExitMonitor(&heap_size_lock);
  return size;
}

void MmDecrHeap(int size)
{
  OzExecEnterMonitor(&heap_size_lock);
  heap_size -= size;
  OzExecExitMonitor(&heap_size_lock);
}

inline static int is_large(int size)
{
  if (size + sizeof(HeapBlockRec) + sizeof(CellRec) > ThrPageSize)
    return 1;
  return 0;
}

#if 0 /* These two functions below are only for debug. */
void check_block(HeapBlock hb, int minus_one)
{
  int ncell, nused = 0, nfree = 0;
  Cell cell;
  
  ncell = ((ThrPageSize - sizeof(HeapBlockRec))
	    / (hb->size + sizeof(CellRec)));
  if ((cell = hb->used) != 0)
    do {
      nused++;
    } while ((cell = cell->b_next) != hb->used);
  if ((cell = hb->free) != 0)
    do {
      nfree++;
    } while ((cell = cell->b_next) != hb->free);
  if ((!minus_one) && ((ncell - nused - nfree) != 0))
    abort();
  if (minus_one && ((ncell - nused - nfree) != 1))
    abort();
}

void check_blocks(HeapBlock hb)
{
  HeapBlock first = hb;

  do {
    check_block(hb, 0);
  } while ((hb = hb->b_next) != first);
}
#endif

inline static void append_cell(Cell *cell_list, Cell cell)
{
  InsertQueueBinary(cell, *cell_list);
}

inline static Cell remove_first_cell(Cell *cell_list)
{
  Cell cell = *cell_list;
  if (cell) {
    RemoveQueueBinary(cell, *cell_list);
  }
  return cell;
}

inline static void remove_cell(Cell *cell_list, Cell cell)
{
  RemoveQueueBinary(cell, *cell_list);
}

inline static void append_blk(HeapBlock *blk_list, HeapBlock blk)
{
  InsertQueueBinary(blk, *blk_list);
  *blk_list = blk; /* link in reversed order */
}

inline static void remove_blk(HeapBlock *blk_list, HeapBlock blk)
{
  RemoveQueueBinary(blk, *blk_list);
}

static void update_heap_region(Heap h, HeapBlock hb)
{
  unsigned int bottom;

  if (! is_large(hb->size))
    bottom = (unsigned int)hb + ThrPageSize;
  else
    bottom = (unsigned int)hb + sizeof(HeapBlockRec) + sizeof(CellRec)
      + hb->size;
  if (! h->heap_top) {
    h->heap_top = (unsigned int)hb;
    h->heap_bottom = bottom;
  } else if ((unsigned int)hb < h->heap_top)
    h->heap_top = (unsigned int)hb;
  else if (bottom > h->heap_bottom)
    h->heap_bottom = bottom;
  if (! h->heap_top) {
    h->heap_top = (unsigned int)hb;
    h->heap_bottom = bottom;
  } else if ((unsigned int)hb < h->heap_top)
    h->heap_top = (unsigned int)hb;
  else if (bottom > h->heap_bottom)
    h->heap_bottom = bottom;
}

static HeapBlock get_block(Heap h, unsigned int size)
{
  HeapBlock hb;
  int cnt, cell_size;
  Cell prev, cell, next;

  h->heap_size += ThrPageSize;
  hb = (HeapBlock)mmap(0, ThrPageSize, PROT_READ | PROT_WRITE,
		       MAP_PRIVATE, ThrDevZero, 0);
#ifdef ESTIMATE_OVERHEAD
  h->nblk++;
#endif ESTIMATE_OVERHEAD
  bzero((char *)hb, ThrPageSize);
  hb->size = cell_size = size;
  cell_size += sizeof(CellRec);
  prev = (Cell)(hb + 1); 
  append_cell(&(hb->free), prev);
  for (cnt = 1; ; cnt++) {
    cell = (Cell)((unsigned int)prev + cell_size);
    next = (Cell)((unsigned int)cell + cell_size);
    if ((unsigned int)next > ((unsigned int)hb + ThrPageSize))
      break;
    append_cell(&(hb->free), cell);
    prev = cell;
  }
#if 0
  OzDebugf("get_block: addr = 0x%08x, size = %d, cells = %d\n", hb, cell_size,
	   cnt);
#endif
  update_heap_region(h, hb);
  return hb;
}

static void *xmalloc_large(Heap h, unsigned int size)
{
  HeapBlock hb;
  unsigned int total;
  Cell cell;
  int block;
  void *result;

  total = size + sizeof(HeapBlockRec) + sizeof(CellRec);
  MmCheckMemory(total);
  block = ThrBlockSuspend();
  OzExecEnterMonitor(&(h->lock));
  h->heap_size += total;
  hb = (HeapBlock)mmap(0, total, PROT_READ | PROT_WRITE,
		       MAP_PRIVATE, ThrDevZero, 0);
#ifdef ESTIMATE_OVERHEAD
  h->nblk++;
#endif ESTIMATE_OVERHEAD
  bzero((char *)hb, total);
  hb->size = size;
  update_heap_region(h, hb);
  cell = (Cell)((unsigned int)hb + sizeof(HeapBlockRec));
#ifdef ESTIMATE_OVERHEAD
  h->ncell++;
#endif ESTIMATE_OVERHEAD
  append_cell(&(hb->used), cell);
  append_blk(&(h->blk_table[HB_TABLE_SIZE - 1].blk_list), hb);
#if 0
  OzDebugf("xmalloc_large: block addr = 0x%08x, cell = 0x%08x, size = %d\n",
	   hb, cell, size);
#endif
  cell->flags |= USED;
  result = (void *)(cell + 1);
  OzExecExitMonitor(&(h->lock));
  ThrUnBlockSuspend(block);
  return result;
}

/*
 *     Mechanism of Interaction with OM
 */

static FaultQueueRec gc_request_queue;
static OZ_MonitorRec gc_count_lock;
static int gc_count;

static void init_gc_context()
{
  OzInitializeMonitor(&heap_size_lock);
  heap_size = 0;

  FqInitializeFaultQueue(&gc_request_queue);
  OzInitializeMonitor(&gc_count_lock);
  mem_short = (OzHeapSize / 10) * 7;
  gc_count = 0;
}

void OzOmEnterGC()
{
  int block;

  block = ThrBlockSuspend();
  OzExecEnterMonitor(&gc_count_lock);
  gc_count++;
  OzExecExitMonitor(&gc_count_lock);
  ThrUnBlockSuspend(block);
}

void OzOmExitGC()
{
  int block, result;

  block = ThrBlockSuspend();
  OzExecEnterMonitor(&gc_count_lock);
  result = --gc_count;
  OzExecExitMonitor(&gc_count_lock);
  ThrUnBlockSuspend(block);
}

struct GC_RequestRec {
  FaultQueueElementRec fault_elt;
  int type;
};

int OzOmMemoryShortage()
{
  int val;
  struct GC_RequestRec *gc_req
    = (struct GC_RequestRec *)FqReceiveRequest(&gc_request_queue);
  val = gc_req->type;
  OzFree(gc_req);
  return val;
}

static void request_gc()
{
  struct GC_RequestRec *gc_req;
  int block, result;

  block = ThrBlockSuspend();
  OzExecEnterMonitor(&gc_count_lock);
  gc_req = (struct GC_RequestRec *)OzMalloc(sizeof(struct GC_RequestRec));
  gc_req->type = 1; /* 1 indicates 'Do GC'. */
  result = FqEnqueueRequestOnce((FaultQueueElement)gc_req, &gc_request_queue);
#ifndef VERRY_SILENT_GC
if (result) OzDebugf("request_gc: requested\n");
#endif /* VERRY_SILENT_GC */
  OzExecExitMonitor(&gc_count_lock);
  ThrUnBlockSuspend(block);
}

static int is_gcing()
{
  int block, result = 0;

  block = ThrBlockSuspend();
  OzExecEnterMonitor(&gc_count_lock);
  if (gc_count > 0)
    result = 1;
  OzExecExitMonitor(&gc_count_lock);
  ThrUnBlockSuspend(block);
  return result;
}

/*
 *     Trigger for GC Request
 */

void MmCheckMemory(unsigned int size)
{
  int block;

  block = ThrBlockSuspend();
  OzExecEnterMonitor(&heap_size_lock);
  if (! (heap_size + size > mem_short)) {
    heap_size += size;
    OzExecExitMonitor(&heap_size_lock);
    ThrUnBlockSuspend(block);
    return;
  }
#if 0
  OzExecExitMonitor(&heap_size_lock);
  ThrUnBlockSuspend(block);
#endif
  if (! is_gcing())
    request_gc();
#if 0
  block = ThrBlockSuspend();
  OzExecEnterMonitor(&heap_size_lock);
#endif
  if (heap_size + size > OzHeapSize) {
    OzError("MmCheckMemory: fatal error --- cannot collect enough memory");
    OzExecExitMonitor(&heap_size_lock);
    ThrUnBlockSuspend(block);
    OzExecRaise(OzExceptionNoMemory, 0, 0);
  }
  heap_size += size;
  OzExecExitMonitor(&heap_size_lock);
  ThrUnBlockSuspend(block);
}

/*
 *    Routines for Marking
 */

/* static */ Cell quicktest(unsigned int val, Heap h, int iflag)
{
  unsigned int page_aligned, i, large = 0, total = 0;
  HeapBlock hb;
  Cell cell;

  if (val < h->heap_top || h->heap_bottom < val)
    return 0;
  page_aligned = (val & ~(ThrPageSize - 1));
  for (i = 0; i < HB_TABLE_SIZE - 1; i++)
    if ((hb = h->blk_table[i].blk_list) != 0)
      do {
	if ((unsigned int)hb == page_aligned)
	  goto check_carefully;
      } while ((hb = hb->b_next) != h->blk_table[i].blk_list);
  if ((hb = h->blk_table[HB_TABLE_SIZE - 1].blk_list) != 0)
    do {
      total = hb->size + sizeof(HeapBlockRec) + sizeof(CellRec);
      if ((unsigned int)hb <= val && val <= ((unsigned int)hb + total)) {
	large = 1;
	goto check_carefully;
      }
    } while ((hb = hb->b_next) != h->blk_table[HB_TABLE_SIZE - 1].blk_list);
  return 0;
 check_carefully:
  if (large) {
    unsigned int top = (unsigned int)hb + sizeof(HeapBlockRec)
                     + sizeof(CellRec);

    if ((iflag && (top <= val && val <= (unsigned int)hb + total))
	|| ((! iflag) && (top == val))) {
      cell = (Cell)(hb + 1);
      if (cell->flags & USED)
	return cell;
      else
	return 0;
    } else
      return 0;
  } else {
    int offset = val - (unsigned int)hb - sizeof(HeapBlockRec);
    unsigned int cell_size = hb->size + sizeof(CellRec);

    if (offset <= 0)
      return 0;
    if ((iflag && ((offset % cell_size) < sizeof(CellRec)))
	|| ((! iflag) && ((offset % cell_size) != sizeof(CellRec))))
      return 0;
    cell = (Cell)((unsigned int)hb + sizeof(HeapBlockRec)
		  + ((offset / cell_size) * cell_size));
    if (cell->flags & USED)
      return cell;
    else
      return 0;
  }
}

void MmMarkCell(Cell cell, Fifo fifo, int conserv)
{
  if (! cell)
    return;
  if (conserv)
    cell->flags |= CONSERV;
  if (cell->flags & GCMARK)
    return;
  cell->flags |= GCMARK;
  OzPutFifo(fifo, (void *)((unsigned int)cell + sizeof(CellRec)));
}

void MmMarkRegion
  (void *top, void *bottom, Fifo fifo, Heap h, int iflg)
{
  unsigned int *ptr;

#if 0
  OzDebugf("check_region: start addr = 0x%08x, end addr = 0x%08x\n",
	   top, bottom);
#endif
  for (ptr = (unsigned int *)top; ptr < (unsigned int *)bottom; ptr++) {
    Cell cell = quicktest(*ptr, h, iflg);

#if 0
  #if 0
    if (cell) {
  #endif
      OzDebugf("check_region: addr = 0x%08x, content = 0x%08x", ptr, *ptr);
      OzDebugf(" --- %s", cell ? "OK" : "NG");
      if (cell)
	OzDebugf(" (0x%08x)", cell);
      OzDebugf("\n");
  #if 0
    }
  #endif
#endif
    if (cell)
      MmMarkCell(cell, fifo, 1);
  }
}

/*
 *    Routines for Sweeping
 */

typedef struct GC_ResultRec {
  unsigned int sweeped_cells;
  unsigned int released_blocks;
  unsigned int sweeped_bytes;
  unsigned int released_bytes;
} GC_ResultRec, *GC_Result;

typedef struct GarbageRec {
  void *hb_or_cell;
  unsigned int size;
} GarbageRec, *Garbage;

static void sweep_block
  (Heap h, HeapBlock hb, GC_Result result, hashTable addr_table, int compact)
{
  Cell cell, next, last;
  int flg = 1;

#if 0
  OzDebugf("sweep_block: block addr = 0x%08x, size = %d\n", hb, hb->size);
#endif
  if ((cell = hb->used) != 0)
    for (last = hb->used->b_prev; flg; cell = next) {
      if (cell == last)
	flg--;
      next = (cell->b_next && cell->b_next != cell) ? cell->b_next : 0;
      if (! (cell->flags & GCMARK)) {
#if 0
	OzDebugf("sweep_block: cell = 0x%08x, size = %d\n", cell, hb->size);
#endif
	remove_cell(&(hb->used), cell);
	cell->flags &= ~USED;
	append_cell(&(hb->free), cell);
#ifdef SHOW_GC_RESULT
	result->sweeped_cells++;
	result->sweeped_bytes += hb->size;
#endif SHOW_GC_RESULT
	h->heap_used -= hb->size;
#ifdef ESTIMATE_OVERHEAD
	h->ncell--;
#endif ESTIMATE_OVERHEAD
     } else {
       if (compact)
	 GcAdjustPointers((void *)(cell + 1), addr_table);
       cell->flags &= ~GCMARK;
       cell->flags &= ~CONSERV;
      }
    }
}

void MmSweepHeap(Heap h, hashTable addr_table, int compact)
{
  int i, garbage_size, to_be_updated = 0;
  HeapBlock hb, last, next;
  GC_ResultRec result;

  result.sweeped_cells = 0;
  result.sweeped_bytes = 0;
  result.released_blocks = 0;
  result.released_bytes = 0;

  for (i = 0; i < HB_TABLE_SIZE; i++) {
    int flg = 1;

    if ((hb = h->blk_table[i].blk_list) != 0)
      for (last = h->blk_table[i].blk_list->b_prev; flg; hb = next) {
	if (hb == last)
	  flg--;
	next = (hb->b_next && hb->b_next != hb) ? hb->b_next : 0;
	sweep_block(h, hb, &result, addr_table, compact);
	if (! hb->used) {
	  if (is_large(hb->size))
	    garbage_size = sizeof(HeapBlockRec) + sizeof(CellRec) + hb->size;
	  else
	    garbage_size = ThrPageSize;
	  if (h->heap_top == (unsigned int)hb
	      || h->heap_bottom == (unsigned int)hb + garbage_size)
	    to_be_updated = 1;
	  remove_blk(&(h->blk_table[i].blk_list), hb);
#if 0
	  OzDebugf("gc: block (0x%08x) was released\n", hb);
	  OzDebugf("gc: size of released heap = %d\n", garbage_size);
#endif
#ifdef SHOW_GC_RESULT
	  result.released_blocks++;
	  result.released_bytes += garbage_size;
#endif SHOW_GC_RESULT
	  h->heap_size -= garbage_size;
	  MmDecrHeap(garbage_size);
#ifdef ESTIMATE_OVERHEAD
	  h->nblk--;
#endif ESTIMATE_OVERHEAD
/*
 *   It takes much cost to free(munmap) all garbage blocks and 
 *   re-allocate(mmap) blocks when they are needed. Why don't you
 *   preserve some.
 */
	  (void)munmap((caddr_t)hb, garbage_size);
	}
      }
  }
  if (to_be_updated) {
    unsigned int top = 0, bottom = 0, total;

    for (i = 0; i < HB_TABLE_SIZE - 1; i++)
      if ((hb = h->blk_table[i].blk_list) != 0)
	do {
	  if (top == 0 || (unsigned int)hb < top)
	    top = (unsigned int)hb;
	  if (bottom == 0 || bottom < (unsigned int)hb + ThrPageSize)
	    bottom = (unsigned int)hb + ThrPageSize;
	} while ((hb = hb->b_next) != h->blk_table[i].blk_list);
    if ((hb = h->blk_table[HB_TABLE_SIZE - 1].blk_list) != 0)
      do {
	total = hb->size + sizeof(HeapBlockRec) + sizeof(CellRec);
	if (top == 0 || (unsigned int)hb < top)
	  top = (unsigned int)hb;
	if (bottom == 0 || bottom < (unsigned int)hb + total)
	  bottom = (unsigned int)hb + total;
      } while ((hb = hb->b_next) != h->blk_table[HB_TABLE_SIZE - 1].blk_list);
    h->heap_top = top;
    h->heap_bottom = bottom;
  }
#ifdef SHOW_GC_RESULT
  OzDebugf("gc: sweeped %d cells (%db). released %d blocks (%db)\n",
	   result.sweeped_cells, result.sweeped_bytes,
	   result.released_blocks, result.released_bytes);
  MmReportHeap(h);
#endif SHOW_GC_RESULT
}

/***
 ***      Two Pointers Compaction Algorithm
 ***/

typedef enum {PTR_FREE, PTR_USED} PtrStatus;

struct cptr {
  HeapBlock block, b_orig;
  Cell cell, c_orig;
  PtrStatus status;
};

/* inline */void cptr_make
  (struct cptr *ptr, HeapBlock hb, Cell cell, PtrStatus status)
{
  ptr->block = ptr->b_orig = hb;
  ptr->cell = ptr->c_orig = cell;
  ptr->status = status;
}

/* inline */int cptr_advance_bottom(struct cptr *ptr)
{
  do {
    do {
      if (ptr->cell) {
	if ((ptr->cell->flags & GCMARK) && !(ptr->cell->flags & CONSERV))
	  return 1;
	else
	  ptr->cell = ptr->cell->b_prev;
      } else
	break;
    } while (ptr->cell != ptr->c_orig);
    ptr->block = ptr->block->b_prev;
    ptr->cell = ptr->c_orig = ptr->block->used->b_prev;
  } while (ptr->block != ptr->b_orig);
  return 0;
}

/* inline */int cptr_advance_top(struct cptr *ptr, struct cptr *bottom)
{
  if (ptr->block == bottom->block)
      return(0);
  do {
    if (ptr->status == PTR_USED) {
      do {
	if (ptr->cell) {
	  if (! (ptr->cell->flags & GCMARK))
	    return 1;
	  else
	    ptr->cell = ptr->cell->b_next;
	} else
	  break;
      } while (ptr->cell != ptr->c_orig);
      ptr->status = PTR_FREE;
    }
    if ((ptr->cell = ptr->c_orig = ptr->block->free))
      return(1);
    ptr->block = ptr->block->b_next;
    ptr->status = PTR_USED;
    ptr->cell = ptr->c_orig = ptr->block->used;
  } while ((ptr->block != ptr->b_orig) && (ptr->block != bottom->block));
  return 0;
}

void compact(Heap h, HeapBlock hb, hashTable addr_table)
{
  struct cptr bottom, top;

#if 0
OzDebugf("compacting blocks with size %d\n", hb->size);
#endif
  cptr_make(&bottom, hb->b_prev, hb->b_prev->used->b_prev, PTR_USED);
  cptr_make(&top, hb, hb->used, PTR_USED);
  while (1) {
    if (cptr_advance_bottom(&bottom) == 0)
      return;
    if (cptr_advance_top(&top, &bottom) == 0)
      return;
    if (bottom.block == top.block)
      abort();
    /*
     * (1) move object (and record statistics).
     * (2) remember addresses of object to be moved.
     */
    GcCopyObject((void *)(bottom.cell + 1), (void *)(top.cell + 1),
		   hb->size);
    top.cell->flags |= GCMARK;
    if (top.status == PTR_FREE) {
      remove_cell(&(top.block->free), top.cell);
      top.cell->flags |= USED;
      append_cell(&(top.block->used), top.cell);
#ifdef ESTIMATE_OVERHEAD
      h->ncell++;
#endif ESTIMATE_OVERHEAD
      h->heap_used += hb->size;
    }
    bottom.cell->flags &= ~GCMARK;
#if 0
OzDebugf("0x%0x -> 0x%0x, diff = 0x%0x\n",
	 (unsigned int)(bottom.cell) + sizeof(CellRec),
	 (unsigned int)(top.cell) + sizeof(CellRec),
	 (int)((unsigned int)(top.cell) - (unsigned int)(bottom.cell)));
#endif
    GcRegisterPointers
      (addr_table,
       (void *)((unsigned int)(bottom.cell) + sizeof(CellRec)),
       (int)((unsigned int)(top.cell) - (unsigned int)(bottom.cell)));
#if 0
    check_blocks(top.block);
#endif
  }
}

void MmCompactHeap(Heap h, hashTable addr_table)
{
  int i;
  HeapBlock hb;

  for (i = 0; i < HB_TABLE_SIZE - 1; i++)
    if (((hb = h->blk_table[i].blk_list) != 0) && (hb != hb->b_prev))
      compact(h, hb, addr_table);
}

char *MmAlloc(Heap h, int *size)
{
  HeapBlock hb, first;
  Cell cell;
  char *result;
  int unit = (1 << SHIFT), block;

  if (*size & (unit -1))
    *size = (*size & ~(unit - 1)) + unit;	/* Round up by unit. */
  h->heap_used += *size;
  if (is_large(*size)) {
    return xmalloc_large(h, *size);
  }
  block = ThrBlockSuspend();
  OzExecEnterMonitor(&(h->lock));
  for (hb = h->blk_table[*size >> SHIFT].blk_list, first = 0;
       hb && hb != first;
       hb = hb->b_next) {
    if (! first)
      first = hb;
    if ((cell = remove_first_cell(&(hb->free))))
      goto found;
  }
  OzExecExitMonitor(&(h->lock));
  ThrUnBlockSuspend(block);
  MmCheckMemory(ThrPageSize);
  block = ThrBlockSuspend();
  OzExecEnterMonitor(&(h->lock));
  append_blk(&(h->blk_table[*size >> SHIFT].blk_list),
	     hb = get_block(h, *size));
  cell = remove_first_cell(&(hb->free));
  h->gc_ing = 0;
 found:
#ifdef ESTIMATE_OVERHEAD
  h->ncell++;
#endif ESTIMATE_OVERHEAD
  append_cell(&(hb->used), cell);
#if 0
  OzDebugf("MmAlloc: addr = 0x%08x (0x%08x), size = %d\n",
	 cell + 1, cell, *size);
#endif
  cell->flags |= USED;
  result = (char *)(cell + 1);
  bzero(result, *size);
  OzExecExitMonitor(&(h->lock));
  ThrUnBlockSuspend(block);
  return(result);
}

static void xfree_large(Heap h, HeapBlock hb)
{
  int total;

  h->heap_size -= (total = hb->size + sizeof(HeapBlockRec) + sizeof(CellRec));
  MmDecrHeap(total);
  h->heap_used -= hb->size;
#if 0
  OzDebugf("xfree_large: block (0x%08x : size = %d) was released\n",
	   hb, hb->size);
#endif
  remove_blk(&(h->blk_table[HB_TABLE_SIZE - 1].blk_list), hb);
#ifdef ESTIMATE_OVERHEAD
  h->nblk--;
  h->ncell--;
#endif ESTIMATE_OVERHEAD
  (void)munmap((caddr_t)hb, total);
}

void MmFree(Heap heap,char *ptr,unsigned int size)
{
  HeapBlock hb;
  Cell cell;
  unsigned int total;
  int block;

  block = ThrBlockSuspend();
  OzExecEnterMonitor(&(heap->lock));
  if ((hb = heap->blk_table[HB_TABLE_SIZE - 1].blk_list) != 0)
    do {
      total = hb->size + sizeof(HeapBlockRec) + sizeof(CellRec);
      if ((unsigned int)hb <= (unsigned int)ptr
	  && (unsigned int)ptr <= ((unsigned int)hb + total)) {
	xfree_large(heap, hb);
	OzExecExitMonitor(&(heap->lock));         
	ThrUnBlockSuspend( block ) ;
	return;
      }
    } while ((hb = hb->b_next) != heap->blk_table[HB_TABLE_SIZE - 1].blk_list);
  cell = (Cell)((unsigned int)ptr - sizeof(CellRec));
  hb = (HeapBlock)((unsigned int)ptr & ~(ThrPageSize - 1));
  heap->heap_used -= hb->size;
#if 0
  OzDebugf("xfree: block addr = 0x%08x, cell = 0x%08x, size = %d\n",
	   hb, cell, hb->size);
#endif
  remove_cell(&(hb->used), cell);
  cell->flags &= ~USED;
  append_cell(&(hb->free), cell);
#ifdef ESTIMATE_OVERHEAD
  heap->ncell--;
#endif ESTIMATE_OVERHEAD
  if (! hb->used) {
    remove_blk(&(heap->blk_table[hb->size >> SHIFT].blk_list), hb);
#if 0
    OzDebugf("xfree: block (0x%08x) was released\n", hb);
#endif
    (void)munmap((caddr_t)hb, ThrPageSize);
    heap->heap_size -= ThrPageSize;
    MmDecrHeap(ThrPageSize);
#ifdef ESTIMATE_OVERHEAD
    heap->nblk--;
#endif ESTIMATE_OVERHEAD
  }
  OzExecExitMonitor(&(heap->lock));
  ThrUnBlockSuspend(block);
}

void MmDestroyHeap(Heap h)
{
  HeapBlock hb, last, next;
  int i, size;

  for (i = 0; i < HB_TABLE_SIZE; i++) {
    int flg = 1;

    if ((hb = h->blk_table[i].blk_list) != 0)
      for (last = h->blk_table[i].blk_list->b_prev; flg; hb = next) {
	if (hb == last)
	  flg--;
	next = (hb->b_next && hb->b_next != hb) ? hb->b_next : 0;
	if (is_large(hb->size))
	  size = sizeof(HeapBlockRec) + sizeof(CellRec) + hb->size;
	else
	  size = ThrPageSize;
	remove_blk(&(h->blk_table[i].blk_list), hb);
	MmDecrHeap(size);
	munmap((caddr_t)hb, size);
      }
  }
  OzFree(h);
}

/***
 ***  Set Heap Size Limit (for debug only)
 ***/

static	int
mmCmdHeap( char *name, int argc, char *argv[], int sline, int eline )
{
	int	limit ;
	char	c = 0 ;

	if ( argc > 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	if ( argc == 2 ) {
		limit = OzStrtol( argv[1], NULL, 0 ) ;
		c = *(argv[1] + OzStrlen( argv[1] ) - 1) ;
		if ( c == 'k' || c == 'K' ) OzHeapSize = (1024 * limit) ;
		else {
			OzHeapSize = (1020 * 1024 * limit) ;
			c = 0 ;
		}
		mem_short = (OzHeapSize / 10) * 7;
		OzPrintf( "Set" ) ;
	} else OzPrintf( "Now" ) ;
	if ( c ) OzPrintf( " heap size %d(Kbytes)\n", OzHeapSize/1024 ) ;
	else OzPrintf( " heap size %d(Mbytes)\n", (OzHeapSize/1024)/1024 ) ;

	return( 0 ) ;
}

static	void
register_dbcmds()
{
	OzShAppend( "set", "heap", mmCmdHeap, "<size(Mbytes)[k]>",
			"set heap limit size" ) ;
	OzShAlias( "set", "heap", "set-limit" ) ;
}
