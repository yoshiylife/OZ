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
#include "ct.h"
#include "cl.h"
#include "executor/method-invoke.h"
#include "executor/exception.h"
#include "oz++/sysexcept.h"

void OzExecFindMethodImplementation
  (OZ_MethodImplementation imp, OZ_Object obj,
   int class_number_diff, unsigned int method_number)
/* class_number_diff == number_of_parts - n, where n means nth parts from 0. */
{
  OZ_ObjectAll all;
  OZ_Class class;
  OZ_ClassInfo class_info;
  OZ_ClassPart class_part;
  OZ_FunctionEntry func_entry;
  OZ_ClassID imp_part_id;
  int func_no;

  if ( obj == 0 ) {
    OzExecRaise( OzExceptionIllegalInvoke, 0, 0 ) ;
    /* NOT REACHED */
  }

  all = OzExecGetObjectTop(obj);
  class = CtGetClass(((OZ_Header)all)->a);
  class_info = class->class_info;
  if (class_number_diff > 0) /* method of `object' class */
    class_part = class_info->parts[0];
  else
    class_part
      = class_info->parts[((OZ_Header)obj)->e + class_number_diff];
#if 1
  if (class_part->number_of_entries < method_number + 1) {
    OzError("OzExecFindMethodImplementation: illegal method number");
    OzError("  slot1 = %d, slot2 = %d", class_number_diff, method_number);
    OzError("  impl.version id = %08x%08x",
	     (int)(class_part->cid >> 32),
	     (int)(class_part->cid & 0xffffffff));
    OzError("  number of entries       = %d",
	     class_part->number_of_entries);
    OzError("  method number requested = %d", method_number);
    /****/
    OzError("  class_info = (OZ_ClassInfo)0x%x", class_info);
    OzError("  obj = (OZ_Header)0x%x", obj);
    func_entry = &(class_part->entry[method_number]);
    imp_part_id = func_entry->class_part_id;
    func_no = func_entry->function_no;
    OzError("  func_no = %d", func_no);
    if ( obj == 0 ) {
      OzExecRaise( OzExceptionIllegalInvoke, 0, 0 ) ;
      /* NOT REACHED */
    }
    OzShutdownExecutor() ;
  }
#endif
  func_entry = &(class_part->entry[method_number]);
  imp_part_id = func_entry->class_part_id;
  func_no = func_entry->function_no;
  imp->code = (void *)ClGetCode(imp_part_id); /* incr ref_count */
  imp->function
    = (OZ_FunctionPtr)
      (((ClassCode)(imp->code))->fp_table->functions[func_no]);
  CtReleaseClass(class);
  imp->next = (OZ_MethodImplementation)ThrRunningThread->implementation_top;
  ThrRunningThread->implementation_top = (char *)imp;
#ifdef INTERSITE
  if(ThrRunningThread->foreign_flag)
    ThrRunningThread->foreign_flag += 2;
  else
    {
      if( ((OZ_Header)(all))->p )
	ThrRunningThread->foreign_flag = 2;
    }
#endif
}

void OzExecFreeMethodImplementation(OZ_MethodImplementation prev_imp)
{
  OZ_MethodImplementation imp;

  for (imp = (OZ_MethodImplementation)ThrRunningThread->implementation_top;
       imp;
       imp = imp->next) {
    if (imp == prev_imp)
      break;
    ClReleaseCode((ClassCode)(imp->code));
#ifdef INTERSITE
    if(ThrRunningThread->foreign_flag >=2)
      ThrRunningThread->foreign_flag -= 2;
#endif
  }
  ThrRunningThread->implementation_top = (char *)prev_imp;
}

void *OzExecGetMethodImplementation()
{
  return((void *)(ThrRunningThread->implementation_top));
}
