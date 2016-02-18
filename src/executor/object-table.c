/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <stdio.h>
/* multithread system include */
#include "thread/signal.h"
#include "thread/thread.h"
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "main.h"
#include "ot.h"
#include "queue.h"
#include "channel.h"
#include "allc.h"
#include "gc-subs.h"
#include "mem.h"
#include "proc.h"
#include "encode-subs.h"
#include "oh-impl.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"


/*
 *	External Function Signature without include file
 */
extern	OZ_Object	OzExecCifLoad( char *path, Heap heap ) ;
extern	int		OzExecCifFlush( char *path, OZ_Header entry ) ;

/***
 ***  OID Counter Management Routines.
 ***/
static	char	*oidPath = "objects/oid" ;	/* relative path from CWD */
static	int	oidCounter = 0  ;		/* last issued OID */
static	OZ_MonitorRec	oidLock ;		/* lock for oidCounter */

static	int
oidInit()
{
	int	result = -1 ;
	int	fd = -1 ;
	int	block ;
	char	buf[7] ;

	block = ThrBlockSuspend() ;
	OzInitializeMonitor( &oidLock ) ;
	OzExecEnterMonitor( &oidLock ) ;

	if ( (fd = OzOpen( oidPath, O_RDONLY )) < 0 ) {
		OzError( "Can't open OID counter '%s': %m.", oidPath ) ;
		goto error ;
	}
	if ( OzRead( fd, buf, 6 ) != 6 ) {
		OzError( "Can't read OID counter from '%s': %m.", oidPath ) ;
		goto error ;
	}
	buf[6] = 0 ;
	oidCounter = OzStrtol( buf, NULL, 16 ) ;
	if ( oidCounter < 0 || 0x0ffffff < oidCounter ) {
		OzError( "Overflow or Underflow OID counter." ) ;
		goto error ;
	}
	result = 0 ;

error:
	if ( 0 < fd ) OzClose( fd ) ;
	OzExecExitMonitor( &oidLock ) ;
	ThrUnBlockSuspend( block ) ;
	return( result ) ;
}

static	OID
oidNew()
{
	OID	result = 0LL ;
	int	fd = -1 ;
	int	block ;
	char	buf[16] ;

	block = ThrBlockSuspend() ;
	OzExecEnterMonitor( &oidLock ) ;

	if ( oidCounter == 0 ) goto error ;
	else if ( 0x0ffffff < oidCounter ) {
		OzError( "Overflow OID counter." ) ;
		goto error ;
	}

	oidCounter ++ ;

	if ( (fd=OzOpen( oidPath, O_WRONLY, 0644 )) < 0 ) {
		OzError( "Can't open OID counter '%s': %m.", oidPath ) ;
		goto error ;
	}
	OzSprintf( buf, "%06x", oidCounter ) ;
	if ( OzWrite( fd, buf, 6 ) != 6 ) {
		OzError( "Can't write OID counter to '%s': %m.", oidPath ) ;
		goto error ;
	}
	result = OzExecutorID | (OID)oidCounter ;

error:
	if ( 0 <= fd ) OzClose( fd ) ;
	OzExecExitMonitor( &oidLock ) ;
	ThrUnBlockSuspend( block ) ;
	return( result ) ;
}


/***
 ***  Object Fault Queue Management Routines.
 ***/

typedef struct ObjectRequestRec {
  FaultQueueElementRec fault_elt;
  OID oid;
} ObjectRequestRec, *ObjectRequest;

static FaultQueueRec object_fault_queue;

/* called by Object Manager. */
OID OzOmQueuedInvocation()
{
  return(((ObjectRequest)FqReceiveRequest(&object_fault_queue))->oid);
}

static void announce_message_arrival(ObjectRequest request)
{
  FqEnqueueRequest((FaultQueueElement)request, &object_fault_queue);
}

static void init_object_fault_queue()
{
  FqInitializeFaultQueue(&object_fault_queue);
}


/***
 *** Object Table Management routines.
 ***/

static ExecHashTable object_table;
static OZ_MonitorRec object_table_lock;

static void object_not_found(OID oid);

typedef enum stopflg StopFlg;
enum  stopflg {STOP_OK, STOP_NG};

static ObjectTableEntry get_entry(OID oid, StopFlg sflg)
{
  ObjectTableEntry entry;
  int	block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&object_table_lock);
  if (!(entry = (ObjectTableEntry)OhKeySearchHashTable
	((void *)&oid, object_table))) {
    object_not_found(oid);
    OzExecExitMonitor(&object_table_lock);
    ThrUnBlockSuspend( block ) ;
    return((ObjectTableEntry)0);
  }
  if (sflg && entry->status == OT_STOP) {
    object_not_found(oid);
    OzExecExitMonitor(&object_table_lock);
    ThrUnBlockSuspend( block ) ;
    return((ObjectTableEntry)0);
  }
  entry->op_count++; /* So, call 'OtReleaseEntry' to
		      * decrement this counter. */
  OzExecExitMonitor(&object_table_lock);
  ThrUnBlockSuspend( block ) ;
  return(entry);
}

ObjectTableEntry OtGetEntry(OID oid)
{
  return(get_entry(oid, STOP_NG));
}

ObjectTableEntry OtGetEntryRaw(OID oid)
{
  return(get_entry(oid, STOP_OK));
}

void OtReleaseEntry(ObjectTableEntry entry)
{
  int	block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&object_table_lock);
  entry->op_count--;
  OzExecExitMonitor(&object_table_lock);
  ThrUnBlockSuspend( block ) ;
}

static void remove_object_entry(ObjectTableEntry entry);
int
OzOmObjectTableRemove(OID oid)
{
  ObjectTableEntry entry ;
  int	block ;
  int	ret ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&object_table_lock);
  if (!(entry = (ObjectTableEntry)OhKeySearchHashTable
	((void *)&oid, object_table))) {
    object_not_found(oid);
    ret = -1 ;
    goto finish ;
  }
  if (entry->op_count) {
    OzError("(executor)OzOmObjectTableRemove: Someone refering this entry.");
    ret = entry->op_count ;
    goto finish ;
  }
  if (entry->status != OT_STOP) {
    OzError("(executor)OzOmObjectTableRemove: ObjectNotStopped.");
    ret = -2 ;
    goto finish ;
  }
  OhRemoveFromHashTable((HashHeader)entry, object_table);
  ret = 0 ;
 finish:
  OzExecExitMonitor( &object_table_lock ) ;
  ThrUnBlockSuspend( block ) ;
  if ( ret == 0 ) {
    MmDestroyHeap( entry->heap ) ;
    remove_object_entry( entry ) ;
  }
  return( ret ) ;
}

OID OzOmAllocateCell(OZ_ClassID cid)
{
  ObjectTableEntry entry;
  int	block ;
  
#ifdef INTERSITE
  if(ThrRunningThread->foreign_flag)
    { /* Creation of global object is not premitted to foreign thread */
      OzExecRaise(OzExceptionForeignAccessViolation,0,0);
      /* NOT REACHED */
    }
#endif

  entry = (ObjectTableEntry)OzMalloc(sizeof(ObjectTableEntryRec));
  entry->status = OT_READY;
  entry->flags = OT_LOADED;
  entry->accessed = (char)0;
  entry->oid = oidNew();
  entry->heap = MmCreateHeap();
  entry->object = (OZ_Object)AllcAllocateObject(cid, entry->heap);
  entry->call_count = 0;
  entry->op_count = 0;
  OzInitializeMonitor(&entry->lock);
  OzExecInitializeCondition(&entry->object_ready, 0);
  OzExecInitializeCondition(&entry->all_messages_processed, 0);

  InitQueueBinary( entry->threads ) ;
  OzExecInitializeCondition( &entry->object_suspend, 0 ) ;
  OzInitializeMonitor( &entry->trace_lock ) ;
  entry->trace_flag = 0 ;
  entry->trace_mode = 0 ;
  entry->trace_func = 0 ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&object_table_lock);
  OhInsertIntoHashTable
    ((HashHeader)entry, (void *)(&(entry->oid)), object_table);
  OzExecExitMonitor(&object_table_lock);
  ThrUnBlockSuspend( block ) ;
  return(entry->oid);
}

OID OzOmObjectTableDownLoad(OID oid, int status)
{
  ObjectTableEntry entry;
  int	block ;
  
  entry = (ObjectTableEntry)OzMalloc(sizeof(ObjectTableEntryRec));
  entry->status = status;
  entry->flags = 0;
  entry->object = (OZ_Object)0;
  entry->accessed = (char)0;
  entry->oid = oid;
  entry->heap = MmCreateHeap();
  entry->call_count = 0;
  entry->op_count = 0;
  OzInitializeMonitor(&entry->lock);
  OzExecInitializeCondition(&entry->object_ready, 0);
  OzExecInitializeCondition(&entry->all_messages_processed, 0);

  InitQueueBinary( entry->threads ) ;
  OzExecInitializeCondition( &entry->object_suspend, 0 ) ;
  OzInitializeMonitor( &entry->trace_lock ) ;
  entry->trace_flag = 0 ;
  entry->trace_mode = 0 ;
  entry->trace_func = 0 ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&object_table_lock);
  OhInsertIntoHashTable
    ((HashHeader)entry, (void *)(&(entry->oid)), object_table);
  OzExecExitMonitor(&object_table_lock);
  ThrUnBlockSuspend( block ) ;
  return(entry->oid);
}

/* Four functions below concerning the table management must be rewritten
 * later, so that table search will get faster. */

static void init_object_fault_queue();
static void register_dbcmds();
int OtInit()
{
  OzInitializeMonitor(&object_table_lock);
  object_table = OhCreateHashTable(OBJECT_TABLE_SIZE, OH_LONGLONG);
  init_object_fault_queue();
  if ( oidInit() ) return( -1 ) ;
  register_dbcmds() ;
  return( 0 ) ;
}

static void remove_object_entry(ObjectTableEntry entry)
{
  OzFree(entry);
}

int
OtMapObjectTable(int (func)(),void *args)
{
  int	ret ;
  int	block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&object_table_lock);
  ret = OhMapHashTable(object_table, func, args);
  OzExecExitMonitor(&object_table_lock);
  ThrUnBlockSuspend( block ) ;
  return( ret ) ;
}


/***
 *** Object Table Entry Management Routines.
 ***/

OID OzOmObjectTableChangeStatus(OID oid, int status)
{
  ObjectTableEntry entry;
  int	block ;
  
  if (!(entry = get_entry(oid, STOP_OK)))
    return((OID)0);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
#if 0
  if ((entry->status = status) != OT_QUEUE) {
    OzExecSignalConditionAll(&entry->object_ready);
  }
#else
  entry->status = status;
  OzExecSignalConditionAll(&entry->object_ready);
#endif
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(oid);
}

int OzOmObjectTableStatus(OID oid)
{
  ObjectTableEntry entry;
  int status;
  int	block ;
  
  if (!(entry = get_entry(oid, STOP_OK)))
    return(-1);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  status = entry->status;
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(status);
}

int OzOmSchedulerWaitThread(OID oid)
{
  ObjectTableEntry entry;
  int call_count;
  int	block ;
  
  if (!(entry = get_entry(oid, STOP_OK)))
    return(-1);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  if (entry->call_count > 0) {
    OzExecWaitCondition(&entry->lock, &entry->all_messages_processed);
  }
  call_count = entry->call_count;
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  if (call_count)
    return(TIME_OUT);
  else
    return(SUCCEEDED);
}

OID OzOmObjectTableCellIn(OID oid)
{
  ObjectTableEntry entry;
  int	block ;
  OID result = (OID)0;
  
  if (!(entry = get_entry(oid, STOP_NG)))
    return(result);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  if ((entry->object = /* OzExecCifCellIn(oid, entry->heap) */0)
      == (OZ_Object)DECODE_FAILED) {
    entry->object = (OZ_Object)0;
    OzError("(executor)OzOmObjectTableCellIn: Decoding failed.");
  } else {
    /* entry->status = OT_READY; */ /* OM does this explicitly. */
    entry->flags &= ~OT_LOADING;
    entry->flags |= OT_LOADED;
    result = oid;
  }
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(result);
}

OID OzOmObjectTableCellOut(OID oid)
{
  ObjectTableEntry entry;
  int	block ;
  OID result = (OID)0;
  
  if (!(entry = get_entry(oid, STOP_NG)))
    return result;
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  if (/* OzCifCellOut(entry->object) */0 == ENCODE_FAILED) {
    OzError("(executor)OzOmObjectTableCellOut: IOError.");
  } else {
    /* entry->status = OT_QUEUE; */ /* OM does this explicitly. */
    entry->flags &= ~OT_LOADED;
    MmDestroyHeap((Heap)entry->heap);
    result = oid;
  }
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(result);
}

OID OzOmObjectTableLoad(OID oid)
{
  ObjectTableEntry entry;
  int	block ;
  char	path[32] ;
  OID result = (OID)0;
  
  if (!(entry = get_entry(oid, STOP_NG)))
    return(result);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  if (entry->heap) /* in case of restoring */
    MmDestroyHeap(entry->heap);
  entry->heap = MmCreateHeap();
  OzSprintf( path, "objects/%06x", (int)(oid&0x0ffffff) ) ;
  if ((entry->object = (OZ_Object)OzExecCifLoad(path, entry->heap))
      == (OZ_Object)DECODE_FAILED) {
    entry->object = (OZ_Object)0;
    OzError("(executor)OzOmObjectTableLoad: Decoding failed.");
  } else {
    /* entry->status = OT_READY; */ /* OM does this explicitly. */
    entry->flags &= ~OT_LOADING;
    entry->flags |= OT_LOADED;
    result = oid;
  }
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(result);
}

OID OzOmObjectTableFlush(OID oid)
{
  ObjectTableEntry entry;
  int	block ;
  char	path[32] ;
  OID result = (OID)0;
  
  if (!(entry = get_entry(oid, STOP_OK)))
    return(result);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  OzSprintf( path, "objects/%06x", (int)(oid&0x0ffffff) ) ;
  if (OzExecCifFlush(path, (OZ_Header)entry->object) == ENCODE_FAILED)
    OzError("(executor)OzOmObjectTableFlush: IOError.");
  else
    result = oid;
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(result);
}

int OzOmObjectTableIsLoaded(OID oid)
{
  ObjectTableEntry entry;
  int result;
  int	block ;
  
  if (!(entry = get_entry(oid, STOP_NG)))
    return(-1);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  result = (entry->flags & OT_LOADED);
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(result);
}

static int reset_access_flag(HashHeader header);
void OzOmObjectTableResetAccessFlag(OID oid)
{
  ObjectTableEntry entry;
  int	block ;
  
  if (oid == 0) {
    block = ThrBlockSuspend() ;
    OzExecEnterMonitor(&object_table_lock);
    OhMapHashTable(object_table, reset_access_flag, 0);
    OzExecExitMonitor(&object_table_lock);
    ThrUnBlockSuspend( block ) ;
    return;
  }
  if (!(entry = get_entry(oid, STOP_NG)))
    return;
#if 0
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  entry->flags &= ~OT_ACCESSED;
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
#else
  entry->accessed = (char)0;
#endif
  OtReleaseEntry(entry);
}

static int reset_access_flag(HashHeader header)
{
  ObjectTableEntry entry = (ObjectTableEntry)header;
#if 0
  int	block ;
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  entry->flags &= ~OT_ACCESSED;
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
#else
  entry->accessed = (char)0;
#endif
  return 0;
}

int OzOmObjectTableIsAccessed(OID oid)
{
  ObjectTableEntry entry;
  int result;
  int	block ;
  
  if (!(entry = get_entry(oid, STOP_NG)))
    return(-1);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
#if 0
  if (!(result = (entry->flags & OT_ACCESSED)))
#else
  if (!(result = entry->accessed))
#endif
    entry->status = OT_QUEUE;
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return(result);
}

/* Two functions below are called by OzGlobalInvokeStub. */

int
OtInvokePre(ObjectTableEntry entry, int slot1, int slot2)
{
  ObjectRequestRec request;
  int	block ;
  
#if 1
  if (slot1 > 0 && entry->status == OT_STOP 
      && slot2 != 2              /* ! Removing */
      && slot2 != 1 		 /* ! Stop */
      && slot2 != 4) {		 /* ! Flush */
    object_not_found(entry->oid);
    return(1);
  }
#endif
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
#if 0
  if (entry->status == OT_QUEUE && slot2 != 0) {
#else
  if (entry->status == OT_QUEUE && !(slot1 > 0 && slot2 == 0)) {
#endif
    if (!(entry->flags & OT_LOADING)) {
      request.oid = entry->oid;
      announce_message_arrival(&request);    /* Tell OM the object fault */
    }
    OzExecWaitCondition(&entry->lock, &entry->object_ready);
  }
  if (!(entry->object)) {
    OzExecExitMonitor(&entry->lock);
    ThrUnBlockSuspend( block ) ;
    return(-1);
  }
  entry->call_count++;
  if ( entry->flags & OT_SUSPEND )
    OzExecWaitCondition( &entry->lock, &entry->object_suspend ) ;
  InsertQueueBinary( ThrRunningThread, entry->threads ) ;
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  return(0);
}

void OtInvokePost(ObjectTableEntry entry)
{
  int	block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  RemoveQueueBinary( ThrRunningThread, entry->threads ) ;
  if (--entry->call_count == 0)
    OzExecSignalCondition(&entry->all_messages_processed);
  /* Waiting thread must be one of OM. */
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
}


/***
 ***    Suspend/Resume
 ***/

static void object_not_found(OID oid)
{
#if 0
  OzDebugf("Runtime: object-table.c: ObjectNotFound (%08x%08x).\n",
 	   (int)(oid >> 32), (int)(oid & 0xffffffff));
#endif
}

int OtGlobalObjectSuspend( ObjectTableEntry aEntry )
{
  int		ret ;
  OZ_Thread	t ;
  int		block ;
  
  block = ThrBlockSuspend() ;
  
  OzExecEnterMonitor( &aEntry->lock ) ;
  if ( ! (aEntry->flags & OT_SUSPEND) ) {
    if ( (aEntry->flags & OT_LOADED) ) {
      aEntry->flags |= OT_SUSPEND ;
      ret = 0 ;			/* Suspending normaly */
      if ( (t=aEntry->threads ) != 0 ) {
	do {
	  if ( ThrSuspend( t ) ) ret ++ ;
	} while ( (t=t->b_next) != aEntry->threads ) ;
        if ( ret ) ret = 1 ;	/* Several threads were already suspended */
      }
    } else ret = -2 ;		/* Not yet loaded */
  } else ret = -1 ;		/* Already suspended */
  OzExecExitMonitor( &aEntry->lock ) ;
  
  ThrUnBlockSuspend( block ) ;
  
  return( ret ) ;
}

int OtGlobalObjectResume( ObjectTableEntry aEntry )
{
  int		ret ;
  OZ_Thread	t ;
  int		block ;
  
  block = ThrBlockSuspend() ;
  
  OzExecEnterMonitor( &aEntry->lock ) ;
  if ( aEntry->flags & OT_SUSPEND ) {
    ret = 0 ;			/* Resumming normaly */
    if ( (t=aEntry->threads ) != 0 ) {
      do {
	if ( ThrResume( t ) ) ret ++ ;
      } while ( (t=t->b_next) != aEntry->threads ) ;
      if ( ret ) ret = 1 ;	/* Several threads were not yet resumed */
    }
    aEntry->flags &= ~OT_SUSPEND ;
    OzExecSignalConditionAll( &aEntry->object_suspend ) ;
  } else ret = -1 ;		/* Not yet suspended */
  OzExecExitMonitor( &aEntry->lock ) ;
  
  ThrUnBlockSuspend( block ) ;
  
  return( ret ) ;
}

#if	0
int OzGlobalObjectThreadKill( ObjectTableEntry aEntry, OZ_Thread aThread )
{
  int	ret = -1 ;
  OZ_Thread	t ;
  int	block ;
  
  block = ThrBlockSuspend() ;
  
  OzExecEnterMonitor( &aEntry->lock ) ;
  if ( (t=aEntry->threads ) != 0 ) {
    do {
      if ( t == aThread ) break ;
    } while ( (t=t->b_next) != aEntry->threads ) ;
    if ( t == aThread ) {
      ThrRemove( &entry->threads, aThread ) ;
      if ( --aEntry->call_count == 0 )
	OzExecSignalCondition( &aEntry->all_messages_processed ) ;
      /* Waiting thread must be one of OM. */
    } else t = 0 ;
  }
  OzExecExitMonitor( &aEntry->lock ) ;
  
  ThrUnBlockSuspend( block ) ;
  
  if ( t ) OtReleaseEntry( aEntry ) ;
  
  return( ret ) ;
}
#endif

int
OzOmObjectTableSuspend( OID aTarget )
{
	ObjectTableEntry	entry ;
		int		ret ;
  
	if ( (entry = get_entry( aTarget, STOP_OK )) != NULL ) {
		ret = OtGlobalObjectSuspend( entry ) ;
		OtReleaseEntry( entry ) ;
	} else ret = -3 ;
	return( ret ) ;
}

int
OzOmObjectTableResume( OID aTarget )
{
	ObjectTableEntry	entry ;
		int		ret ;
  
	if ( (entry = get_entry( aTarget, STOP_OK )) != NULL ) {
		ret = OtGlobalObjectResume( entry ) ;
		OtReleaseEntry( entry ) ;
	} else ret = -3 ;
	return( ret ) ;
}

/***
 ***    Garbage Collection
 ***/

#if	0	/* Not used becase to saved sp to OZ_Thread */
inline static char *find_top_from_signal_stack
  (unsigned int *fp, void *stack_top, void *stack_bottom)
{
  while (! (((unsigned int)stack_top <= (unsigned int)fp)
	     && ((unsigned int)fp <= (unsigned int)stack_bottom)))
    fp = (unsigned int *)(*(fp + 14));
  return((char *)fp);
}
#endif

struct mark_context {
  Fifo        fifo;
  Heap        heap;
  int         flag;
} ;

static int mark_proc( OzProcess proc, struct mark_context *context )
{
  if ( proc->status == PROC_EXITED ) {
    MmMarkRegion( &(proc->rval), (void*)(&(proc->rval))+sizeof(proc->rval),
                    context->fifo, context->heap, context->flag );
  } else {
    if ( proc->args ) {
      MmMarkRegion( proc->args, proc->args+proc->size,
		   context->fifo, context->heap, context->flag );
    }
  }
  return( 0 ) ;
}

void
object_gc( ObjectTableEntry entry, int compact )
{
  OZ_Thread t;
  Fifo fifo = (Fifo)OzCreateFifo();
  struct mark_context context ;
  hashTable addr_table = 0;

  if (compact)
    addr_table = (hashTable)OzCreateHash();

  while (entry->heap->decoding) {
    /* OzDebugf("\n(gc wait (0x%x) ...", RunningThread); */
    OzExecExitMonitor(&(entry->lock));
    OtGlobalObjectResume(entry);
    OzExecWaitCondition(&(entry->heap->lock), &(entry->heap->decode_end));
    OtGlobalObjectSuspend(entry);
    /* OzDebugf("gc signaled)\n"); */
    OzExecEnterMonitor(&(entry->lock));
  }

  /* Marking Phase */
  if ((t = entry->threads) != 0) {
    do {
      /* from thread stack */
      char *top;
      OzRecvChannel rchan;
#if	0	/* Not used becase to saved real sp to OZ_Thread */
      if (! (((unsigned int)(t->stack) <= (unsigned int)top)
	     && ((unsigned int)top <= (unsigned int)(t->stack_bottom)))) {
#if 1   /* conservative marking from signal stack */
	MmMarkRegion((void *)top,
		       (void *)t->signal_stack.ss_sp,
		       fifo, entry->heap,
		       1); /* 1 means 'very conservative'. */
#endif
	top = find_top_from_signal_stack
	  ((void *)top, (void *)(t->stack), (void *)(t->stack_bottom));
      }
#else
      top = (char *)t->context[2] ;
      if ( t->signal_stack.ss_onstack ) {
	frame_t	*sp ;
	GREGS	*gregs ;
	sp = (frame_t *)top ;
	sp = (frame_t *)sp->r_i6 ;
	gregs = (GREGS *)sp->r_i2 ;
	top = (char *)GREGS_SP(*gregs) ;
      }
#endif
      MmMarkRegion((void *)top, (void *)(t->stack_bottom), fifo,
		     entry->heap, 1); /* 1 means 'very conservative'. */
      /* from argument area */
      if (t->args)
	MmMarkRegion(t->args, (void *)((int)(t->args) + t->arg_size),
		       fifo, entry->heap, 1);
      /* for rval and eparam */
      rchan = (OzRecvChannel)t->channel;
      if (rchan) {
        OzExecEnterMonitor( &rchan->vars.lock );
        if (rchan->vars.next) {
          MmMarkRegion(&(rchan->vars.next->vars.rval),
                       (void *)&(rchan->vars.next->vars.rval)
                           + sizeof(rchan->vars.next->vars.rval),
		       fifo, entry->heap, 1);
          MmMarkRegion(&(rchan->vars.next->vars.eparam),
                       (void *)&(rchan->vars.next->vars.eparam)
                           + sizeof(rchan->vars.next->vars.eparam),
		       fifo, entry->heap, 1);
        }
        OzExecExitMonitor( &rchan->vars.lock );
      }
    } while ((t = t->b_next) != entry->threads) ;
    context.fifo = fifo;
    context.heap = entry->heap;
    context.flag = 1;
    PrMapProcessTable( mark_proc, &context );
  }
  GcMarkPointer((OZ_Header)(entry->object), fifo, 1);  /* and object root */
  GcTraversePointers(fifo);
  OzFreeFifo(fifo);

  if (compact)
    MmCompactHeap(entry->heap, addr_table);

  /* Sweeping Phase */
  MmSweepHeap(entry->heap, addr_table, compact);
  if (compact)
    OzFreeHash(addr_table);
}

void OzOmGCollectObject  /* assumes the object is suspended. */
  (OID oid, int compact)
{
  ObjectTableEntry entry;
  int block;
  
  if (! (entry = get_entry(oid, STOP_OK))) {
    object_not_found(oid);
    OzExecRaise(OzExceptionObjectNotFound, oid, 0);
    /* NOT REACHED */
  }
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&entry->lock);
  if (! (entry->flags & OT_LOADED)) {  /* should be devided ? */
    object_not_found(oid);
    OzExecExitMonitor(&entry->lock);
    ThrUnBlockSuspend( block ) ;
    OtReleaseEntry(entry);
    OzExecRaise(OzExceptionObjectNotFound, oid, 0);
    /* NOT REACHED */
  }
  if (! (entry->flags & OT_SUSPEND)) {
    OzError("OzGCollectObject: ObjectIsNotSuspended.");
    goto error;
  }

  OzExecEnterMonitor(&(entry->heap->lock));
  object_gc(entry, compact);
  OzExecExitMonitor(&(entry->heap->lock));

  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
  return;
 error:
  OzExecExitMonitor(&entry->lock);
  ThrUnBlockSuspend( block ) ;
  OtReleaseEntry(entry);
}

OID OzOmCallerOfThisMethod()
{
  return(((OzRecvChannel)ThrRunningThread->channel)->caller);
}

Heap OtGetHeap()
{
  return ((Heap)((OzRecvChannel)ThrRunningThread->channel)->o->heap);
}

extern int MyArchitectureType; /* in remote.c */

int OzOmMyArchitecture()
{
  return(MyArchitectureType);
}

void OzOmShutdownExecutor()
{
  OzShutdownExecutor();
}

/***
 ***  For Debug
 ***/

/*
 * add 'shell_add_command("objects", "objects", show_objects);'
 * to thread_shell in sched_shell.c.
 */

static char *state_strings[] = {"READY", "QUEUE", "STOP"};

static	int
print_object( HashHeader header, void *arg )
{
	ObjectTableEntry	entry = (ObjectTableEntry)header ;

	OzPrintf( "[0x%08x] %016lx \t%d \t%d \t%s",
		entry, entry->oid, entry->call_count, entry->op_count,
		state_strings[entry->status] ) ;
	if ( entry->flags & OT_ACCESSED ) OzPrintf( " OT_ACCESSED" ) ;
	if ( entry->flags & OT_LOADED ) OzPrintf( " OT_LOADED" ) ;
	if ( entry->flags & OT_LOADING ) OzPrintf( " OT_LOADING" ) ;
	if ( entry->flags & OT_SUSPEND ) OzPrintf( " OT_SUSPEND" ) ;
	OzPrintf( "\n" ) ;
	return( 0 ) ;
}

static	int
otCmdList( char *name, int argc, char *argv[], int sline, int eline )
{
	OtMapObjectTable( print_object, NULL ) ;
	return( 0 ) ;
}

static	int
otCmdHeap( char *name, int argc, char *argv[], int sline, int eline )
{
	ObjectTableEntry	entry;
		OID		oid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	oid = OzStrtoull( argv[1], NULL, 16 ) ;
	oid |= OzExecutorID ;
	if (! (entry = OtGetEntryRaw(oid))) {
		OzPrintf( "%s: Object not found.\n", name ) ;
		return( -2 ) ;
	}
	OzPrintf(  "Heap of %016lx:\n", oid ) ;
	MmReportHeap( entry->heap ) ;
	MmReportHeapGlobal();
	return( 0 ) ;
}

static	int
otCmdGc( char *name, int argc, char *argv[], int sline, int eline )
{
	ObjectTableEntry	entry ;
		OID		oid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	oid = OzStrtoull( argv[1], NULL, 16 ) ;
	oid |= OzExecutorID ;
	if (! (entry = OtGetEntryRaw(oid))) {
		OzPrintf( "%s: Object not found.\n", name ) ;
		return( -2 ) ;
	}
	OzPrintf( "GC start for %016lx:\n", oid ) ;
	OtGlobalObjectSuspend( entry ) ;
	OzOmGCollectObject( oid, 1 ) ;
	OtGlobalObjectResume( entry );
	OtReleaseEntry( entry ) ;
	return( 0 ) ;
}

static	int
otCmdFlush( char *name, int argc, char *argv[], int sline, int eline )
{
	OID	oid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	oid = OzStrtoull( argv[1], NULL, 16 ) ;
	oid |= OzExecutorID ;
	OzPrintf( "Flushing %016lx:\n", oid ) ;
	OzOmObjectTableFlush( oid ) ;
	return( 0 ) ;
}

static	int
otCmdSuspend( char *name, int argc, char *argv[], int sline, int eline )
{
	ObjectTableEntry	entry ;
		OID		oid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	oid = OzStrtoull( argv[1], NULL, 16 ) ;
	oid |= OzExecutorID ;
	if (! (entry = OtGetEntryRaw(oid))) {
		OzPrintf( "%s: Object not found.\n", name ) ;
		return( -2 ) ;
	}
	OtGlobalObjectSuspend( entry ) ;
	OtReleaseEntry( entry ) ;

	return( 0 ) ;
}

static	int
otCmdResume( char *name, int argc, char *argv[], int sline, int eline )
{
	ObjectTableEntry	entry ;
		OID		oid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	oid = OzStrtoull( argv[1], NULL, 16 ) ;
	oid |= OzExecutorID ;
	if (! (entry = OtGetEntryRaw(oid))) {
		OzPrintf( "%s: Object not found.\n", name ) ;
		return( -2 ) ;
	}
	OtGlobalObjectResume( entry ) ;
	OtReleaseEntry( entry ) ;

	return( 0 ) ;
}

static	void
register_dbcmds()
{
	OzShAppend( "object", "", NULL, "", "Object commands" ) ;
	OzShAppend( "object", "list", otCmdList, "",
		"list global objects" ) ;
	OzShAppend( "object", "heap", otCmdHeap, "<object #>",
		"show global object heap information" ) ;
	OzShAppend( "object", "gc", otCmdGc, "<object #>",
		"do garbage collection" ) ;
	OzShAppend( "object", "flush", otCmdFlush, "<object #>",
		"flush global object" ) ;
	OzShAppend( "object", "suspend", otCmdSuspend, "<object #>",
		"Suspend global object" ) ;
	OzShAppend( "object", "resume", otCmdResume, "<object #>",
		"Resume global object" ) ;

	OzShAlias( "object", "list", "objects" ) ;
	OzShAlias( "object", "heap", "heap" ) ;
	OzShAlias( "object", "gc", "gc" ) ;
	OzShAlias( "object", "flush", "flush" ) ;
}
