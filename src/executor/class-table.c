/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* unix system include */
#include <sys/file.h>
/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "thread/shell.h"
#include "oz++/ozlibc.h"

#include "executor/class-table.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"

#include "switch.h"
#include "ct.h"
#include "oh-impl.h"
#include "mem.h"

typedef struct ClassEntryRec {
  HashHeaderRec hash_header;
  OZ_ClassID cid;
  OZ_ClassRec class;
} ClassEntryRec, *ClassEntry;

#define CLASS_TABLE_SIZE 1024

/***
 ***  Class Table Management Routines.
 ***/

static ExecHashTable class_table;
static OZ_MonitorRec class_table_lock;

static OZ_Class get_class(OZ_ClassID cid)
{
  ClassEntry entry;
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&class_table_lock);
  entry = (ClassEntry)OhKeySearchHashTable(&cid, class_table);
  if (!entry) {
    MmCheckMemory(sizeof(ClassEntryRec));
    entry = (ClassEntry)OzMalloc(sizeof(ClassEntryRec));
    entry->cid = cid;
    entry->class.cid = cid;
    entry->class.state = CT_ABSENT;
    entry->class.ref_count = 0;
    entry->class.size = 0;
    entry->class.class_info = 0;
    OzInitializeMonitor(&(entry->class.lock));
    OzExecInitializeCondition(&(entry->class.class_created), 0);
    OhInsertIntoHashTable
      ((HashHeader)entry, (void *)(&(entry->cid)), class_table);
  }
  entry->class.ref_count++;
  OzExecExitMonitor(&class_table_lock);
  ThrUnBlockSuspend( block ) ;
  return(&(entry->class));
}

void CtReleaseClass(OZ_Class class)
{
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&class_table_lock);
  class->ref_count--;
  OzExecExitMonitor(&class_table_lock);
  ThrUnBlockSuspend( block ) ;
}

static OZ_ClassInfo load_class_info(char *filename, OZ_Class class);
static OZ_Class load_class(OZ_ClassID cid, char *filename)
{
  OZ_Class class ;
  int block ;

  class = get_class(cid);
  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&class->lock);
  if (filename) {
    if ( class->state == CT_CREATED ) {
      OzError( "class %016lx config is overlapped.", cid ) ;
    } else {
      if ((class->class_info = load_class_info(filename, class)))
        class->state = CT_CREATED;
    }
  }
  OzExecSignalConditionAll(&class->class_created);
  OzExecExitMonitor(&class->lock);
  ThrUnBlockSuspend( block ) ;
  return( class ) ;
}

void OzOmPreloadRuntimeClassInfo(OZ_ClassID cid, char *filename)
{
  load_class(cid, filename);
}

void OzOmLoadClass(OZ_ClassID cid, char *filename)
{
  OZ_Class class = load_class(cid, filename);
  CtReleaseClass(class);
}

static void initialize_class_request_queue();
static void register_dbcmds();
int CtInit()
{
  OzInitializeMonitor(&class_table_lock);
  class_table = OhCreateHashTable(CLASS_TABLE_SIZE, OH_LONGLONG);
  initialize_class_request_queue();
  register_dbcmds();
  return( 0 ) ;
}

/***
 ***  Class (i.e. Class Table Entry) Management Routines.
 ***/

/* Called in creating objects and in method invocation.
   When you use this, do not forget calling `CtReleaseClass'. */
static FaultQueueRec class_request_queue;
static void class_creation_start(OZ_Class class);
OZ_Class CtGetClass(OZ_ClassID cid)
{
  OZ_Class class = get_class(cid);
  int block ;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&class->lock);
  if (class->state != CT_CREATED) {
    if (class->state == CT_ABSENT) {
      class->state = CT_CREATING;
      class_creation_start(class);
    }
    OzExecWaitCondition(&class->lock, &class->class_created);
    if (class->state != CT_CREATED) {
      OzExecExitMonitor(&class->lock);
      ThrUnBlockSuspend( block ) ;
      OzError("CtGetClass(%016lx): class could not be created.",cid);
      OzExecRaise(OzExceptionClassNotFound, cid, 0);
      /* NOT REACHED */
    }
  }
  OzExecExitMonitor(&class->lock);
  ThrUnBlockSuspend( block ) ;
  return(class);
}

static OZ_ClassInfo load_class_info(char *filename, OZ_Class class)
{
  int fd, i, n, offset;
  OZ_ClassInfo class_info;

  if ((fd = OzOpen(filename, O_RDONLY, 0644)) < 0) {
    OzError( "CT: cannot read-open the file[%s]" ) ;
    return((OZ_ClassInfo)0);
  }
  OzRead(fd, (char *)&n, sizeof(int));
  MmCheckMemory(n);
  class_info = (OZ_ClassInfo)OzMalloc(n);
  class->size = n;
  OzRead(fd, (char *)class_info, n);
  OzClose(fd);
  for (i = 0; i < class_info->number_of_parts; i++) {
    offset = (int)class_info->parts[i];
    offset += (int)class_info;
    class_info->parts[i] = (OZ_ClassPart)offset;
  }
  return(class_info);
}

/***
 ***  Class Request Queue Management Routines.
 ***/

static void class_creation_start(OZ_Class class)
{
  FqEnqueueRequest((FaultQueueElement)class, &class_request_queue);
}

OZ_ClassID OzOmClassRequest()
{
  return(((OZ_Class)FqReceiveRequest(&class_request_queue))->cid);
}

static void initialize_class_request_queue()
{
  FqInitializeFaultQueue(&class_request_queue);
}

/***
 ***  GC
 ***/

static int remove_class_pre(ClassEntry entry)
{
  int remove = 0;

  if (entry->class.ref_count == 0) {
    remove = 1;
    OhRemoveFromHashTable((HashHeader)entry, class_table);
  }
  return remove;
}

static int remove_class_post(ClassEntry entry, int remove)
{
  if (remove) {
    MmDecrHeap(sizeof(ClassEntryRec) + entry->class.size);
    OzFree(entry->class.class_info);
    OzFree(entry);
  }
  return remove;
}

static int remove_class(ClassEntry entry)
{
  int remove;

  remove = remove_class_pre(entry);
  return (remove_class_post(entry, remove));
}

int OzOmRemoveClass(OZ_ClassID cid)
{
  ClassEntry entry;
  int block, remove;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&class_table_lock);
  entry = (ClassEntry)OhKeySearchHashTable(&cid, class_table);
  remove = remove_class_pre(entry);
  OzExecExitMonitor(&class_table_lock);
  ThrUnBlockSuspend( block ) ;
  return (remove_class_post(entry, remove));
}

static int map_class_table(int (func)(), void *args)
{
  return OhMapHashTable(class_table, func, args);
}

void OzOmGCollectClassInfo()
{
  int block;

  block = ThrBlockSuspend() ;
  OzExecEnterMonitor(&class_table_lock);
  map_class_table(remove_class, 0);
  OzExecExitMonitor(&class_table_lock);
  ThrUnBlockSuspend( block ) ;
}

/***
 ***  For Debug
 ***/

static	int
print_class( HashHeader header, void *arg )
{
	ClassEntry	e = (ClassEntry)header ;
	int		*lines = arg ;

	lines[1] ++ ;
	if ( lines[0] <= lines[1] && lines[1] <= lines[2] ) {
		OzPrintf( "%3d: %016lx (%d)\n", lines[1],
			e->class.cid, e->class.ref_count ) ;
	}
	return( 0 ) ;
}

static	int
ctCmdList( char *name, int argc, char *argv[], int sline, int eline )
{
	int	lines[3] ;
	int	block ;

	lines[0] = sline ;
	lines[1] = 0 ;
	lines[2] = eline ;
	block = ThrBlockSuspend() ;
	OzExecEnterMonitor( &class_table_lock ) ;
	map_class_table( print_class, lines ) ;
	OzExecExitMonitor( &class_table_lock ) ;
	ThrUnBlockSuspend( block ) ;

	return( 0 ) ;
}

static	int
ctCmdRemove( char *name, int argc, char *argv[], int sline, int eline )
{
	OZ_ClassID	cid ;

	if ( argc < 2 ) {
		*argv = NULL ;
		return( -1 ) ;
	}
	cid = OzStrtoull( argv[1], NULL, 16 ) ; 
	if ( OzOmRemoveClass(cid) ) OzPrintf( "%16lx removed.\n", cid ) ;
	else {
		OzError( "%016lx could not be removed.", cid ) ;
		return( -2 ) ;
	}
	return( 0 ) ;
}

static	int
ctCmdGc( char *name, int argc, char *argv[], int sline, int eline )
{
	OzOmGCollectClassInfo() ;
	return( 0 ) ;
}

static	void
register_dbcmds()
{
	OzShAppend( "class", "", NULL, "", "Class information commands" ) ;
	OzShAppend( "class", "list", ctCmdList, "", "List classes" ) ;
	OzShAppend( "class", "remove", ctCmdRemove, "<version id>",
			"Remove class <version id>" ) ;
	OzShAppend( "class", "gc", ctCmdGc, "",
			"Do garbage collection for classes" ) ;
	OzShAlias( "class", "list", "classes" ) ;
	OzShAlias( "class", "remove", "rm-class" ) ;
	OzShAlias( "class", "gc", "gc-class" ) ;
}
