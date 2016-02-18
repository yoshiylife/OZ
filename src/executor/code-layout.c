/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <sys/file.h>
/* multithread system include */
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

#include "executor/exception.h"
#include "oz++/sysexcept.h"

#include "switch.h"
#include "queue.h"
#include "cl.h"
#include "oh-impl.h"
#include "dyload.h"
#include "mem.h"
#include "conf.h"
#include "ct.h"

typedef struct CodeLayoutTableEntryRec {
  HashHeaderRec hash_header;
  OZ_ClassID cid;
  ClassCodeRec code;
  ClassLayoutRec layout;
} CodeLayoutTableEntryRec, *CodeLayoutTableEntry;

#define CODE_LAYOUT_TABLE_SIZE 1024

/***
 *** Code/Layout Table Management Routines
 ***/

static ExecHashTable code_layout_table;
static OZ_MonitorRec code_layout_table_lock;

static CodeLayoutTableEntry get_code_layout_entry(OZ_ClassID cid);
static ClassCode get_code(OZ_ClassID cid)
{
  CodeLayoutTableEntry entry;
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  entry = get_code_layout_entry(cid);
  entry->code.ref_count++;
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
  return(&entry->code);
}

static ClassLayout get_layout(OZ_ClassID cid)
{
  CodeLayoutTableEntry entry;
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  entry = get_code_layout_entry(cid);
  entry->layout.ref_count++;
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
  return(&entry->layout);
}

static CodeLayoutTableEntry get_code_layout_entry(OZ_ClassID cid)
{
  CodeLayoutTableEntry entry;

  if (!(entry = (CodeLayoutTableEntry)
	          OhKeySearchHashTable((void *)(&cid), code_layout_table))) {
    MmCheckMemory(sizeof(CodeLayoutTableEntryRec));
    entry = (CodeLayoutTableEntry)OzMalloc(sizeof(CodeLayoutTableEntryRec));
    entry->cid = cid;
    entry->code.cid = cid;
    entry->code.state = CL_ABSENT;
    entry->code.is_static = 0;
    entry->code.ref_count = 0;
    entry->code.imported_codes = 0;
    entry->code.fp_table = 0 ;
    entry->code.exported_funcs = 0 ;
    entry->code.debugInfo = 0 ;
    entry->code.addr = 0;
    entry->code.size = 0;
    entry->code.sym_fname = NULL;
    entry->code.sym_nlist = NULL;
    entry->code.sym_break = NULL;
    entry->code.sym_strs = NULL;
    OzInitializeMonitor(&entry->code.lock);
    OzExecInitializeCondition(&entry->code.loaded, 0);
    entry->layout.cid = cid;
    entry->layout.state = CL_ABSENT;
    entry->layout.ref_count = 0;
    OzInitializeMonitor(&entry->layout.lock);
    OzExecInitializeCondition(&entry->layout.loaded, 0);
    OhInsertIntoHashTable
      ((HashHeader)entry, (void *)(&(entry->cid)), code_layout_table);
  }
  return(entry);
}

static void release_code_aux(ClassCode code)
{
  code->ref_count--;
}

void ClReleaseCode(ClassCode code)
{
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  release_code_aux(code);
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
}

void ClReleaseLayout(ClassLayout layout)
{
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  layout->ref_count--;
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
}

static void decr_ref_count_of_all_static_codes(ClassCode code)
{
  int i;
  ClassCode static_code;

  if (!code->imported_codes)
    return;
  for (i = 0; i < code->imported_codes->number; i++) {
    static_code = (ClassCode)code->imported_codes->entry[i].code;
    release_code_aux(static_code);
    /* decr_ref_count_of_all_static_codes(static_code); */
  }
}

/* Two functions below are called by OM */
void OzOmDisableCodeGC(OZ_ClassID cid)
{
  CodeLayoutTableEntry entry;
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  entry = get_code_layout_entry(cid);
  entry->code.ref_count++;
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
}

void OzOmEnableCodeGC(OZ_ClassID cid)  
{
  CodeLayoutTableEntry entry;
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  entry = get_code_layout_entry(cid);
  entry->code.ref_count--;
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
}

static void init_code_fault_queue();
static void init_layout_fault_queue();
static void init_relocation_wait_queue();
static void register_dbcmds();
int ClInit()
{
  OzInitializeMonitor(&code_layout_table_lock);
  code_layout_table = OhCreateHashTable(CODE_LAYOUT_TABLE_SIZE, OH_LONGLONG);
  init_code_fault_queue();
  init_layout_fault_queue();
  init_relocation_wait_queue();
  register_dbcmds();
  return( 0 ) ;
}

/***
 *** Class Code Record Management Routines
 ***/

static void start_code_loading(ClassCode code);
ClassCode ClGetCode(OZ_ClassID cid)
{
  ClassCode code;
  int block ;

  code = get_code(cid);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code->lock);
  if (code->state != CL_LOADED) {
    if (code->state == CL_ABSENT) {
      code->state = CL_LOADING;
      start_code_loading(code);
    }
    OzExecWaitCondition(&code->lock, &code->loaded);
    if (code->state != CL_LOADED) {
      OzExecExitMonitor(&code->lock);
      ThrUnBlockSuspend( block ) ;
      OzError("ClGetCode(%016lx): code could not be loaded.",cid);
      OzExecRaise(OzExceptionCodeNotFound, cid, 0);
      /* NOT REACHED */
    }
  }
  OzExecExitMonitor(&code->lock);
  ThrUnBlockSuspend( block ) ;
  return(code);
}

#define CL_OK 1
#define CL_NG 0
static int get_static_code(OZ_ImportedCodeEntry entry)
{
  int block ;

  entry->code = (caddr_t)get_code(entry->impl_vid);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&((ClassCode)entry->code)->lock);
  ((ClassCode)entry->code)->is_static = 1;
  if (((ClassCode)entry->code)->state != CL_LOADED) {
    if (((ClassCode)entry->code)->state == CL_ABSENT) {
      ((ClassCode)entry->code)->state = CL_LOADING;
      start_code_loading((ClassCode)entry->code);
    }
  }
  OzExecExitMonitor(&((ClassCode)entry->code)->lock);
  ThrUnBlockSuspend( block ) ;
  return(CL_OK);
}

/* Called by a daemon of OM.
 * assumed :
 * DlDynamicLoad(ClassCode code, char *file) {
 *	        :
 *	code->imported_codes = _OZ_ImportedCodesRec;
 *              :
 * }
 */

static void relocate_code(ClassCode code);
static int get_all_static_codes(ClassCode code);
static ClassCode load_code(OZ_ClassID cid, char *filename)
{
  ClassCode code ;
  int block ;

  code = get_code( cid ) ;	        /* get and inc ref count */
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code->lock);
  if (filename) {
    if ( code->state == CL_LOADED ) {
      OzError( "class %016lx code is overlapped.", cid ) ;
    } else {
      DlDynamicLoad(code, filename);	/* Load file, but not relocate */
      MmCheckMemory(code->size);
      get_all_static_codes(code);
      relocate_code(code);
    }
  } else {
    OzExecSignalConditionAll(&code->loaded);
  }
  OzExecExitMonitor(&code->lock);
  ThrUnBlockSuspend( block ) ;
  return( code ) ;
}

void OzOmLoadCode(OZ_ClassID cid, char *filename)
{
  ClassCode code = load_code(cid, filename);
  ClReleaseCode(code);	        /* dec ref count */
}

void OzOmPreloadCode(OZ_ClassID cid, char *filename)
{
  load_code(cid, filename);
}

static int get_static_code(OZ_ImportedCodeEntry entry);
static int get_all_static_codes(ClassCode code)
{
  int i;
  
  if (code->imported_codes)
    for (i = 0; i < code->imported_codes->number; i++) {
      if (get_static_code(&code->imported_codes->entry[i]) == CL_NG)
	return(CL_NG);
    }
  return(CL_OK);
}

/***
 *** Class Layout Record Management Routines
 ***/

static void start_layout_loading(ClassLayout layout);
ClassLayout ClGetLayout(OZ_ClassID cid)
{
  ClassLayout layout;
  int block ;

  layout = get_layout(cid);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&layout->lock);
  if (layout->state != CL_LOADED) {
    if (layout->state == CL_ABSENT) {
      layout->state = CL_LOADING;
      start_layout_loading(layout);
    }
    OzExecWaitCondition(&layout->lock, &layout->loaded);
    if (layout->state != CL_LOADED) {
      OzExecExitMonitor(&layout->lock);
      ThrUnBlockSuspend( block ) ;
      OzError("ClGetLayout(%016lx): layout could not be loaded.",cid);
      OzExecRaise(OzExceptionLayoutNotFound, cid, 0);
      /* NOT REACHED */
    }
  }
  OzExecExitMonitor(&layout->lock);
  ThrUnBlockSuspend( block ) ;
  return(layout);
}

static OZ_Layout load_layout_info(char *filename, ClassLayout layout);
static ClassLayout load_layout(OZ_ClassID cid, char *filename)
{
  ClassLayout layout ;
  int block ;
  
  layout = get_layout( cid ) ;
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&layout->lock);
  if (filename) {
    if ( layout->state != CL_LOADED ) {
      OzError( "class %016lx layout is overlapped.", cid ) ;
    } else {
      layout->layout_info = load_layout_info(filename, layout);
      layout->state = CL_LOADED;
    }
  }
  OzExecSignalConditionAll(&layout->loaded);
  OzExecExitMonitor(&layout->lock);
  ThrUnBlockSuspend( block ) ;
  return( layout ) ;
}

void OzOmLoadLayout(OZ_ClassID cid, char *filename)
{
  ClassLayout layout = load_layout(cid, filename);
  ClReleaseLayout(layout);
}

void OzOmPreloadLayout(OZ_ClassID cid, char *filename)
{
  load_layout(cid, filename);
}

static OZ_Layout load_layout_info(char *filename, ClassLayout lrec)
{
  int fd, n, offset;
  OZ_Layout layout;

  if ((fd = OzOpen(filename, O_RDONLY, 0644)) < 0) {
    OzError("CL: cannot read-open the file[%s]", filename);
    return((OZ_Layout)0);
  }
  OzRead(fd, (char *)&n, sizeof(int));
  MmCheckMemory(n);
  layout = (OZ_Layout)OzMalloc(n);
  lrec->size = n;
  OzRead(fd, (char *)layout, n);
  offset = (int)layout->common;
  offset += (int)layout;
  layout->common = (OZ_LayoutPart)offset;
  OzClose(fd);
  return(layout);
}

/***
 *** Code Fault Queue Management Routines
 ***/

static FaultQueueRec code_fault_queue;

/*
 * Called by Object Manager's daemon.
 */

OZ_ClassID OzOmCodeFault()
{
  return(((ClassCode)FqReceiveRequest(&code_fault_queue))->cid);
}

static void start_code_loading(ClassCode code)
{
  FqEnqueueRequest((FaultQueueElement)code, &code_fault_queue);
}

static void init_code_fault_queue()
{
  FqInitializeFaultQueue(&code_fault_queue);
}

/***
 *** Layout Fault Queue Management Routines
 ***/

static FaultQueueRec layout_fault_queue;

/*
 * Called by Object Manager's daemon.
 */

OZ_ClassID OzOmLayoutFault()
{
  return(((ClassLayout)FqReceiveRequest(&layout_fault_queue))->cid);
}

static void start_layout_loading(ClassLayout layout)
{
  FqEnqueueRequest((FaultQueueElement)layout, &layout_fault_queue);
}

static void init_layout_fault_queue()
{
  FqInitializeFaultQueue(&layout_fault_queue);
}

/***
 *** Relocation Wait Queue Management Routines
 ***/

ClassCode relocation_wait_queue;
OZ_MonitorRec relocation_wait_queue_lock;

static int are_imported_codes_loaded(ClassCode code);
static void relocate_code(ClassCode code)
{
  ClassCode queued, last, next;
  int block, flg;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&relocation_wait_queue_lock);
  if (!(are_imported_codes_loaded(code))) {
    InsertQueueBinary(code, relocation_wait_queue);
  } else {
    if ( DlRelocate(code) != 0 ) DlUnload(code);	/* relocate code */
    code->state = CL_LOADED;
    OzExecSignalConditionAll(&code->loaded);
    if (code->is_static) {

  again:

      if ((queued = relocation_wait_queue) != 0)
        for (flg = 1, last = relocation_wait_queue->b_prev; flg;
	     queued = next) {
	  if (queued == last)
	    flg--;
	  next = (queued->b_next && queued->b_next != queued)
	    ? queued->b_next : 0;
	  if (are_imported_codes_loaded(queued)) {
	    RemoveQueueBinary(queued, relocation_wait_queue);
	    if ( DlRelocate(queued) != 0 ) DlUnload(queued);
	    queued->state = CL_LOADED;
	    OzExecSignalConditionAll(&queued->loaded);
	    goto again;
	  }
	}
    }
  }
  OzExecExitMonitor(&relocation_wait_queue_lock);
  ThrUnBlockSuspend( block ) ;
}

static int are_imported_codes_loaded(ClassCode code)
{
  int i, result;
  ClassCode static_code;

  if (!code->imported_codes)
    return(1);
  for (i = 0; i < code->imported_codes->number; i++) {
    static_code = (ClassCode)code->imported_codes->entry[i].code;
    result = (static_code->state == CL_LOADED);
    if (!result)
      return(0);
  }
  return(1);
}

static void init_relocation_wait_queue()
{
  relocation_wait_queue = (ClassCode)0;
  OzInitializeMonitor(&relocation_wait_queue_lock);
}

/***
 ***  GC
 ***/

static int remove_code_pre(CodeLayoutTableEntry entry)
{
  int remove_code = 0;

  if (entry->code.state != CL_ABSENT && entry->code.ref_count == 0) {
    remove_code = 1;
    entry->code.state = CL_ABSENT;
    if (entry->code.imported_codes)
      decr_ref_count_of_all_static_codes(&(entry->code));
    if (entry->layout.state == CL_ABSENT)
      OhRemoveFromHashTable((HashHeader)entry, code_layout_table);
  }
  return remove_code;
}

static int remove_code_post(CodeLayoutTableEntry entry, int remove_code)
{
  if (remove_code) {
    MmDecrHeap(entry->code.size);
    DlUnload(&(entry->code));
  }
  if (remove_code && entry->layout.state == CL_ABSENT) {
    MmDecrHeap(sizeof(CodeLayoutTableEntryRec));
    OzFree(entry);
  }
  return(remove_code);
}

static int remove_code(CodeLayoutTableEntry entry)
{
  int remove;

  remove = remove_code_pre(entry);
  return (remove_code_post(entry, remove));
}

int OzOmRemoveCode(OZ_ClassID cid)
{
  CodeLayoutTableEntry entry;
  int block, remove_code ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  entry = get_code_layout_entry(cid);
  remove_code = remove_code_pre(entry);
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
  return (remove_code_post(entry, remove_code));
}

/*
 * Called by Class Layout GC routine.
 */
static int remove_layout_pre(CodeLayoutTableEntry entry)
{
  int remove_layout = 0;

  if (entry->layout.state != CL_ABSENT && entry->layout.ref_count == 0) {
    remove_layout = 1;
    entry->layout.state = CL_ABSENT;
  }
  if (remove_layout && entry->code.state == CL_ABSENT) {
    OhRemoveFromHashTable((HashHeader)entry, code_layout_table);
  }
  return remove_layout;
}

static int remove_layout_post(CodeLayoutTableEntry entry, int remove_layout)
{
  if (remove_layout) {
    MmDecrHeap(entry->layout.size);
    OzFree(entry->layout.layout_info);
  }
  if (remove_layout && entry->code.state == CL_ABSENT) {
    MmDecrHeap(sizeof(CodeLayoutTableEntryRec));
    OzFree(entry);
  }
  return remove_layout;
}

static int remove_layout(CodeLayoutTableEntry entry)
{
  int remove;

  remove = remove_layout_pre(entry);
  return (remove_layout_post(entry, remove));
}

int OzOmRemoveLayout(OZ_ClassID cid)
{
  CodeLayoutTableEntry entry;
  int block, remove_layout ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&code_layout_table_lock);
  entry = get_code_layout_entry(cid);
  remove_layout = remove_layout_pre(entry);
  OzExecExitMonitor(&code_layout_table_lock);
  ThrUnBlockSuspend( block ) ;
  return (remove_layout_post(entry, remove_layout));
}

static int map_code_layout_table(int (func)(), void *args)
{
  int ret ;
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor( &code_layout_table_lock ) ;
  ret = OhMapHashTable(code_layout_table, func, args);
  OzExecExitMonitor( &code_layout_table_lock ) ;
  ThrUnBlockSuspend( block ) ;
  return ret ;
}

void OzOmGCollectCodes()
{
  map_code_layout_table(remove_code, 0);
}

void OzOmGCollectLayoutInfo()
{
  map_code_layout_table(remove_layout, 0);
}

/***
 ***    Misc (Not Only For Debugging Any More. Do not change)
 ***/

static int map_get_code(CodeLayoutTableEntry entry)
{
  return ((int)(&(entry->code)));
}

int ClMapCode(int (func)(), void *args)
{
  int ret ;
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor( &code_layout_table_lock ) ;
  ret = OhMapHashTable2(code_layout_table, map_get_code, func, args);
  OzExecExitMonitor( &code_layout_table_lock ) ;
  ThrUnBlockSuspend( block ) ;
  return ret ;
}

static int map_get_layout(CodeLayoutTableEntry entry)
{
  return ((int)(&(entry->layout)));
}

int ClMapLayout(int (func)(), void *args)
{
  int ret ;
  int block ;
  
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor( &code_layout_table_lock ) ;
  ret = OhMapHashTable2(code_layout_table, map_get_layout, func, args);
  OzExecExitMonitor( &code_layout_table_lock ) ;
  ThrUnBlockSuspend( block ) ;
  return ret ;
}

/***
 ***  For Debug
 ***/

static	int
print_code( HashHeader header, void *arg )
{
	int		*lines = arg ;
	ClassCode	c = (ClassCode)header ;

	if ( c->state != CL_ABSENT ) {
		lines[1] ++ ;
		if ( lines[0] <= lines[1] && lines[1] <= lines[2] ) {
			OzPrintf( "%d: %016lx (%d)\n", lines[1],
				c->cid, c->ref_count ) ;
		}
	}
	return( 0 ) ;
}

static	int
clCmdCodeList( char *name, int argc, char *argv[], int sline, int eline )
{
	int	lines[3] ;

	lines[0] = sline ;
	lines[1] = 0 ;
	lines[2] = eline ;
	ClMapCode( print_code, lines ) ;
	return( 0 ) ;
}

static	int
clCmdCodeRemove( char *name, int argc, char *argv[], int sline, int eline )
{
	OZ_ClassID	cid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	cid = OzStrtoull( argv[1], NULL, 16 ) ; 
	if ( OzOmRemoveCode(cid) ) OzPrintf( "%16lx removed.\n", cid ) ;
	else {
		OzError( "%016lx could not be removed.", cid ) ;
		return( -2 ) ;
	}
	return( 0 ) ;
}

static	int
clCmdCodeGc( char *name, int argc, char *argv[], int sline, int eline )
{
	OzOmGCollectCodes() ;
	return( 0 ) ;
}

static	int
print_layout( HashHeader header, void *arg )
{
	int		*lines = arg ;
	ClassLayout	layout = (ClassLayout)header ;

	if ( layout->state != CL_ABSENT ) {
		lines[1] ++ ;
		if ( lines[0] <= lines[1] && lines[1] <= lines[2] ) {
			OzPrintf( "%3d: %016lx\n", lines[1], layout->cid ) ;
		}
	}
	return( 0 ) ;
}

static	int
clCmdLayoutList( char *name, int argc, char *argv[], int sline, int eline )
{
	int	lines[3] ;

	lines[0] = sline ;
	lines[1] = 0 ;
	lines[2] = eline ;
	ClMapLayout( print_layout, lines ) ;
	return( 0 ) ;
}

static	int
clCmdLayoutRemove( char *name, int argc, char *argv[], int sline, int eline )
{
	OZ_ClassID	cid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}

	cid = OzStrtoull( argv[1], NULL, 16 ) ; 
	if ( OzOmRemoveCode(cid) ) OzPrintf( "%16lx removed.\n", cid ) ;
	else {
		OzError( "%016lx could not be removed.", cid ) ;
		return( -2 ) ;
	}
	return( 0 ) ;
}

static	int
clCmdLayoutGc( char *name, int argc, char *argv[], int sline, int eline )
{
	OzOmGCollectLayoutInfo() ;
	return( 0 ) ;
}

static	void
register_dbcmds()
{
	OzShAppend( "code", "", NULL, "", "Class executable code commands" ) ;
	OzShAppend( "code", "list", clCmdCodeList, "",
			"List class codes" ) ;
	OzShAppend( "code", "remove", clCmdCodeRemove, "<version id>",
			"Remove code <version id>" ) ;
	OzShAppend( "code", "gc", clCmdCodeGc, "",
			"Do garbage collection for class codes" ) ;

	OzShAlias( "code", "list", "codes" ) ;
	OzShAlias( "code", "remove", "rm-code" ) ;
	OzShAlias( "code", "gc", "gc-code" ) ;
	
	OzShAppend( "layout", "", NULL, "", "Class layout commands" ) ;
	OzShAppend( "layout", "list", clCmdLayoutList, "",
			"List class layouts" ) ;
	OzShAppend( "layout", "remove", clCmdLayoutRemove, "<version id>",
			"Remove layout <version id>" ) ;
	OzShAppend( "layout", "gc", clCmdLayoutGc, "",
		"Do garbage collection for class layouts" ) ;

	OzShAlias( "layout", "list", "layouts" ) ;
	OzShAlias( "layout", "remove", "rm-layout" ) ;
	OzShAlias( "layout", "gc", "gc-layout" ) ;
}
