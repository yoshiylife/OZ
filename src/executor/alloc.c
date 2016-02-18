/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* multithread system include */
#include "thread/thread.h"
#include "thread/monitor.h"
#include "oz++/ozlibc.h"

#include "switch.h"
#include "ot.h"
#include "ct.h"
#include "mem.h"
#include "conf.h"
#include "allc.h"
#include "channel.h"
#include "common.h"
#include "executor/alloc.h"
#include "oz++/type.h"
#include "oz++/sysexcept.h"
#include "oz++/object-type.h"

#define	CONFIGSET

#define MARK   0
#define FREE   1

/* #define ALLOC_DEBUG */

#define GET_MARK_MANUAL(header) \
  MmGetManualMark((Cell)((int)header - sizeof(CellRec)))
#define SET_MARK_MANUAL(header) \
  MmSetManualMark((Cell)((int)header - sizeof(CellRec)))

inline	static OZ_ObjectPart
header_d_to_part(void *d)
{
    return (OZ_ObjectPart)d;
}

inline	static OZ_ObjectAll
header_to_object_all(OZ_Header head)
{
    return (OZ_ObjectAll)head;
}

inline	static OZ_Object
header_to_object(OZ_Header head)
{
    return (OZ_Object)head;
}

inline	static OZ_StaticObject
header_to_static(OZ_Header head)
{
    return (OZ_StaticObject)head;
}

inline	extern OZ_Array
head_to_array(OZ_Header head)
{
    return (OZ_Array)head;
}

static int
oz_type_size (OZ_Types type) 
/* not used because compiler always emits the size */
{
     int size = 0;

     switch((int) type){
     case OZ_CHAR:
	  size = 1;
	  break;
     case OZ_SHORT:
	  size = 2;
	  break;
     case OZ_INT: case OZ_FLOAT: case OZ_ARRAY: case OZ_LOCAL_OBJECT:
     case OZ_STATIC_OBJECT: 
#if 1
     case OZ_PROCESS:
#endif
	  size = 4;
	  break;
     case OZ_DOUBLE: case OZ_LONG_LONG: case OZ_GLOBAL_OBJECT:
#if 1
     case OZ_CONDITION:
#endif
	  size = 8;
	  break;
     case OZ_RECORD:
	  /* must be implemented */
     }
     return size;
}

static void
    set_header_mem(OZ_Header head,int h,unsigned int e,long long a,void *d)
{
    head->h = h;
    head->e = e;
    head->a = a;
    head->d = d;
    head->t = 0;

    head->g = 0;
    head->p = 0;
}

static void set_allocate_info_mem(OZ_AllocateInfo info,OZ_ClassPart part)
{
  OZ_Header	*hp;
  int	i;

  info->data_size_protected         = part->info.data_size_protected;
  info->data_size_private           = part->info.data_size_private;
  info->number_of_pointer_protected = part->info.number_of_pointer_protected;
  info->number_of_pointer_private   = part->info.number_of_pointer_private;
  info->zero_protected              = part->info.zero_protected;
  info->zero_private                = part->info.zero_private;

  /* inititalize condition variables */
  hp = (OZ_Header *)(info + 1);
  hp += info->number_of_pointer_protected;
  hp += (info->number_of_pointer_protected & 1);
  hp += info->data_size_protected / sizeof(OZ_Header *);
  for (i = 0; i < info->zero_protected; i++) {
    OzExecInitializeCondition((OZ_Condition)hp, 1);
    hp += (sizeof(OZ_ConditionRec)/sizeof(OZ_Header *));
  }
  hp += info->number_of_pointer_private;
  hp += (info->number_of_pointer_private & 1);
  hp += info->data_size_private / sizeof(OZ_Header *);
  for (i = 0; i < info->zero_private; i++) {
    OzExecInitializeCondition((OZ_Condition)hp, 1);
    hp += (sizeof(OZ_ConditionRec)/sizeof(OZ_Header *));
  }
}

/* global/local object routines */


static int
    get_object_part_size (OZ_ClassPart part)
{
    unsigned short data_size;
    unsigned short pointer_size;
    unsigned short zero_size;
    unsigned short object_size;
    unsigned short number_of_pointer;
    
    /* size of pointers */
    number_of_pointer = part->info.number_of_pointer_protected +
	part->info.number_of_pointer_private;
    number_of_pointer += (part->info.number_of_pointer_protected & 0x00000001);
    number_of_pointer += (part->info.number_of_pointer_private & 0x00000001);
    pointer_size = sizeof(OZ_Pointer)*(number_of_pointer);

    /* size of data: 8 bytes alignment has been already considered by
       compiler */
    data_size = part->info.data_size_protected + part->info.data_size_private;

    /* size of zero (condition variables): size of Condition is 8 */
    zero_size = (part->info.zero_protected + part->info.zero_private)
      * sizeof(OZ_ConditionRec);

    /* total */
    object_size = sizeof(OZ_AllocateInfoRec) + data_size +  pointer_size
                  + zero_size;
    
    return (object_size);
}

static void *
    get_object_part_position (OZ_Object *head, OZ_ClassPart class_part)
{
    void * part;
    
    part  = (void *)(*head);
    *head = (OZ_Object)((OZ_Pointer)(* head) + get_object_part_size(class_part));
    
    return part;
}

static void 
    set_object_member
  (OZ_ObjectAll all, OZ_ClassInfo class, int size, OZ_ClassID cid)
{
    OZ_Object     obj_pos;
    OZ_ObjectPart part;
    int           count;

    set_header_mem(all->head,class->number_of_parts,size,cid,0);
    all->head->t = (int)(((char *)all) + size - sizeof(OZ_MonitorRec));
                   /* should be 'unsigned'. */
    OzInitializeMonitor((OZ_Monitor)(all->head->t));
    obj_pos = header_to_object(&(all->head[class->number_of_parts + 1]));
    
    for (count = 0; count < class->number_of_parts; count++){
	set_header_mem(&(all->head[count + 1]),LOCAL, count, 
		       class->parts[count]->compiled_vid,
		       get_object_part_position
		       (&obj_pos, class->parts[count]));
	part = header_d_to_part(all->head[count + 1].d);
	set_allocate_info_mem(&(part->info), class->parts[count]);
    }
}

OZ_Object
    AllcAllocateObject (OZ_ClassID cid, Heap heap)
{
    unsigned int size,count,number_of_parts ;
    OZ_ObjectAll object_all;
    OZ_Class     c_entry;
    int          block;
    
    c_entry = CtGetClass (cid);
    size = sizeof (OZ_HeaderRec) * (c_entry->class_info->number_of_parts + 1);
    for (count = 0; count < c_entry->class_info->number_of_parts; count++){
	size += get_object_part_size (c_entry->class_info->parts[count]);
    }
    size += sizeof(OZ_MonitorRec);
    block = ThrBlockSuspend();
    object_all = (OZ_ObjectAll) MmAlloc (heap, &size);
    set_object_member(object_all, c_entry->class_info, size, cid);
    ((OZ_Header)object_all)->d = (void *)OZ_LOCAL_OBJECT;
#ifdef INTERSITE
        ((OZ_Header)object_all)->p |= ThrRunningThread->foreign_flag & 0x01;
#endif
    ThrUnBlockSuspend(block);
    number_of_parts = c_entry->class_info->number_of_parts;
    CtReleaseClass(c_entry);

    return (header_to_object(&(object_all->head[number_of_parts])));
}

OZ_Object
    OzExecAllocateLocalObject (OZ_ClassID pvid)
{
    OZ_Object  object;
    OZ_ClassID cid;
    Heap       heap;
    
#if	defined(CONFIGSET)
    cid = pvid ;
#else
    cid = CnfGetConfigID( pvid ) ;
    if ( cid == 0LL ) OzExecRaise( OzExceptionClassNotFound, pvid, 0 ) ;
#endif
    heap = OtGetHeap() ;
    object = AllcAllocateObject( cid, heap ) ;
    return object ;
}

/* static object routines */

OZ_StaticObject 
    OzExecAllocateStaticObject (OZ_ClassID comp_cid)
{
    OZ_StaticObject s_object;
    OZ_ClassPart    part;
    OZ_Class        c_entry;
    OZ_ClassID      cid;
    unsigned int    size;
    int             block;

    cid = CnfGetConfigID(comp_cid);
    if ( cid == 0LL ) OzExecRaise( OzExceptionClassNotFound, comp_cid, 0 ) ;

    c_entry = CtGetClass(cid);
    part = c_entry->class_info->parts[0];
    
    size = sizeof(OZ_HeaderRec) + sizeof(OZ_AllocateInfoRec);
    size += part->info.data_size_protected;
    size += part->info.data_size_private;
    size += sizeof(OZ_Pointer)*(part->info.number_of_pointer_protected);
    size += sizeof(OZ_Pointer)*(part->info.number_of_pointer_private);
    size += part->info.zero_protected * sizeof(OZ_ConditionRec);
    size += part->info.zero_private * sizeof(OZ_ConditionRec);
    size += sizeof(OZ_MonitorRec);

    block = ThrBlockSuspend();
    s_object = (OZ_StaticObject) MmAlloc (OtGetHeap (), &size);
    set_header_mem(&(s_object->head),STATIC,size,cid,0); 
    s_object->head.t
      = (int)(((char *)s_object) + size - sizeof(OZ_MonitorRec));
    OzInitializeMonitor((OZ_Monitor)(s_object->head.t));
    set_allocate_info_mem(&(s_object->info),part);
    s_object->head.d = (void *)OZ_STATIC_OBJECT;
    ThrUnBlockSuspend(block);
    CtReleaseClass(c_entry);
    
    return s_object;
}

/* array routines */

static void 
copy_array (OZ_Array new, OZ_Array old)
{
	int	*dst = (int *)(new->mem) ;
	int	*src = (int *)(old->mem) ;
	int	i, size, n ;
        

	if ( new->head.h < old->head.h ) n = new->head.h ;
	else n = old->head.h ;
	size = oz_type_size( new->head.a ) * n ;
	for ( i = 0 ; i < size ; i += 4 ) *(dst ++) = *(src ++ ) ;
		/* CAUTION: Assumption of least 4-bytes alignment */
}

OZ_Array
    OzExecReAllocateArray (OZ_Types type,int size,int number,OZ_Array array)
{
    OZ_Array new;
    int      array_size;
    int      block;
    
    if (number < 0) OzExecRaise( OzExceptionArrayRangeOverflow, number, 0 ) ;
    if(size == 0)
	array_size = sizeof(OZ_HeaderRec) + oz_type_size(type) * number;
    else
	array_size = sizeof(OZ_HeaderRec) + size * number;
    
    block = ThrBlockSuspend();
    new = (OZ_Array) MmAlloc (OtGetHeap (), &array_size);
    set_header_mem(&(new->head),number,array_size,type,0);
    if (type == OZ_CONDITION) {
      int i;
      OZ_Condition p = (OZ_Condition)(&(new->mem));

      for (i = 0; i < number; i++) {
	OzExecInitializeCondition((OZ_Condition)p, 1);
	p++;
      }
    }
    if(array != 0)
	copy_array(new,array);
    new->head.d = (void *)OZ_ARRAY;
    ThrUnBlockSuspend(block);
    return new;
}

static int mark_and_free(OZ_Pointer ptr,int flag);

static void 
  free_array (OZ_Array array,int flag)
{
  int count;
  int *p;
  
  SET_MARK_MANUAL(array);
  switch(array->head.a){
  case OZ_LOCAL_OBJECT:
  case OZ_STATIC_OBJECT:
  case OZ_ARRAY:
    p = (int *)(array->mem);
    for(count = 0; count < array->head.h; count++){
      if(*p != 0){
	if(mark_and_free((OZ_Pointer)*p,flag) == 1)
	  *p = 0;
	p++;
      }
    }
    break;
  default:
    break;
  }
  if(flag == FREE)
    MmFree(OtGetHeap(),(OZ_Pointer)array,array->head.e);
}

#if 1 /* For Freeing Reallocated Array Area (i.e. garbage) */
void OzFreeOldArray(OZ_Array array)
{
  MmFree(OtGetHeap(), (OZ_Pointer)array, array->head.e);
}
#endif

static void check_pointer(int *pointer,int num,int flag)
{
  int i;
  
  for(i = 0;i < num; i++,pointer++)
    if(*pointer != 0)
      if(mark_and_free((OZ_Pointer)*pointer,flag) == 1)
	*pointer = 0;
}

static void 
    free_local_object(OZ_ObjectAll all,int flag)
{
    int           i;
    int *pointer;
    OZ_ObjectPart part;
    
    SET_MARK_MANUAL(all);
    for(i = 1; i <= all->head[0].h; i++){
	part = header_d_to_part(all->head[i].d);
	pointer = (int *)(part->mem);
	check_pointer(pointer,part->info.number_of_pointer_protected,flag);
	pointer = (int *)((char *)pointer + part->info.data_size_protected
			  + (part->info.zero_protected
			     * sizeof(OZ_ConditionRec)));
	check_pointer(pointer,part->info.number_of_pointer_private,flag);
    }
    if(flag == FREE)
	MmFree(OtGetHeap(),(OZ_Pointer)all,all->head[0].e);
}

static void 
    free_static_object (OZ_StaticObject obj,int flag)
{
    int *pointer;
    
    SET_MARK_MANUAL(obj);
    pointer = (int *)(obj->mem);
    check_pointer(pointer,obj->info.number_of_pointer_protected,flag);
    pointer = (int *)((char *)pointer + obj->info.data_size_protected
		      + obj->info.zero_protected * sizeof(OZ_ConditionRec));
    check_pointer(pointer,obj->info.number_of_pointer_private,flag);
    if(flag == FREE)
	MmFree(OtGetHeap(),(OZ_Pointer)obj,obj->head.e);
}

static int 
mark_and_free(OZ_Pointer ptr,int flag)
{
    OZ_Header head;
    OZ_ObjectAll all;

    head = (OZ_Header)ptr;
    switch(head->h){
      case LOCAL:
	all = OzExecGetObjectTop((OZ_Object)ptr);
	if(flag == MARK)
	    if (GET_MARK_MANUAL(all) == 0)
		free_local_object(all,flag);
	    else
		return 1;
	else
	    free_local_object(all,flag);
	break;
      case STATIC:
	if(flag == MARK)
	    if (GET_MARK_MANUAL(head) == 0)
		free_static_object((OZ_StaticObject)ptr,flag);
	    else
		return 1;
	else
	    free_static_object((OZ_StaticObject)ptr,flag);    
	break;
      default:
	if(flag == MARK)
	    if (GET_MARK_MANUAL(head) == 0)
		free_array((OZ_Array)ptr,flag);
	    else
		return 1;
	else
	    free_array((OZ_Array)ptr,flag);
	break;
    }
    return 0;
}

void 
    OzExecFree(OZ_Pointer ptr)
{
    int block;
    block = ThrBlockSuspend();
    mark_and_free(ptr,MARK);
    mark_and_free(ptr,FREE);
   ThrUnBlockSuspend(block);
}


OID OzExecGetOID(OZ_Object obj)
{
  OZ_ObjectAll all1, all2;
  OID oid;
  ObjectTableEntry entry;

  oid = ((OzRecvChannel)ThrRunningThread->channel)->callee;
  if (!obj)
    return(oid);
  entry = OtGetEntryRaw(oid);
  all1 = OzExecGetObjectTop(entry->object);
  all2 = OzExecGetObjectTop(obj);
  OtReleaseEntry(entry);
  if (all1 != all2) {
    OzError("OzGetOID: can't do this for local object");
    OzShutdownExecutor();
    /* NOT REACHED */
  }
  return(oid);
}

#if	defined(CONFIGSET)
OZ_ClassID
OzExecGetConfigID( OZ_ClassID pvid )
{
    OZ_ClassID	cid ;

    cid = CnfGetConfigID( pvid ) ;
    if ( cid == 0LL ) OzExecRaise( OzExceptionClassNotFound, pvid, 0 ) ;
    return( cid ) ;
}
#endif
