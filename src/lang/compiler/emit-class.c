/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

/* Format of OutputFile "C" 
 * 
 * <Class ID of this> 
 * <no parts> <no parents> <no_methods> <no_redefined_methods> <no_aliased_methods>
 * <protected_data_size> <private_data_size> 
 * <no_protected_pointers> <no_private_pointers>
 * <protected_zero> <private_zero>
 * <Class ID of parents> 
 * ...
 * <slot no1> <slot no2> <Class ID of this> <func no>
 * ...
 * EOF
 */

#include <stdio.h>
#include <stdlib.h>
#include <varargs.h>

#include "emit-class.h"
#include "emit-common2.h"
#include "emit-layout.h"

#include "type.h"
#include "ozc.h"
#include "lang/school.h"
#include "class-z.h"
#include "class-list.h"

/*
 * private variables
 */

static int no_public_methods, no_methods, no_parents;
static int no_redefined_public_methods, no_redefined_methods, no_alias_methods;

static char buf[1024];

static emit_oz_method_arg (OO_TypeMethod);
static emit_oz_method_qual(int);

/*
 * private functions
 */

static void
  emit_i_header(OO_ClassType ct, int again)
{
  int no_parts = Object || ct->cl == TC_StaticObject ? 1 : ct->no_parents;
  OZ_Layout layout;
  long long id;

  if (again)
    fseek (PrivateOutputFileI, 0L, 0);

  else
    layout = EmitLayout ();

  if (ct->cl == TC_StaticObject)
    id = ct->class_id_public;
  else
    id = ct->class_id_implementation;

  fprintf(PrivateOutputFileI, "%08x%08x %08x%08x %8d %8d %8d %8d %8d\n", 
	  (int)(id >> 32), (int)(id & 0xffffffff), 
	  (int)(ct->class_id_public >> 32), 
	  (int)(ct->class_id_public & 0xffffffff), 
	  no_parts, no_parents, no_methods, no_redefined_methods,
	  no_alias_methods);

  if (!again)
    fprintf (PrivateOutputFileI, "%d %d %d %d %d %d\n",
	     layout->info.data_size_protected,
	     layout->info.data_size_private,
	     layout->info.number_of_pointer_protected,
	     layout->info.number_of_pointer_private,
	     layout->info.zero_protected,
	     layout->info.zero_private);
}


static 
  emit_i_method(OO_Symbol method_vars, OO_ClassType ct)
{
  int i = -1;
  OO_List list = ct->class_part_list;

  while (list)
    {
      if ((list->car->class_type_rec.class_id_public 
	   == method_vars->class_part_defined->class_id_public ||
	   list->car->class_type_rec.class_id_protected
	   == method_vars->class_part_defined->class_id_protected) &&
	  list->car->class_type_rec.class_id_suffix 
	  == method_vars->class_part_defined->class_id_suffix)
	break;

      i++;
      list = &list->cdr->list_rec;
    }

  fprintf(PrivateOutputFileI, "%d %d %08x%08x %d\n",
	  i,
	  method_vars->slot_no2,
	  (int)(ct->class_id_implementation >> 32), 
	  (int)(ct->class_id_implementation & 0xffffffff), 
	  method_vars->func_no);
}

static 
  emit_i_alias_method(OO_Symbol method_vars, OO_ClassType ct)
{
  int i;
  OO_List list;

  i = -1;
  list = ct->class_part_list;
  while (list)
    {
      if ((list->car->class_type_rec.class_id_public 
	   == method_vars->class_part_defined->class_id_public ||
	   list->car->class_type_rec.class_id_protected
	   == method_vars->class_part_defined->class_id_protected) &&
	  list->car->class_type_rec.class_id_suffix 
	  == method_vars->class_part_defined->class_id_suffix)
	break;

      i++;
      list = &list->cdr->list_rec;
    }

  fprintf(PrivateOutputFileI, "%d %d ", i, method_vars->slot_no2);

  i = -1;
  list = ct->class_part_list;
  while (list)
    {
      if ((list->car->class_type_rec.class_id_public 
	   == method_vars->alias->class_part_defined->class_id_public ||
	   list->car->class_type_rec.class_id_protected
	   == method_vars->alias->class_part_defined->class_id_protected) &&
	  list->car->class_type_rec.class_id_suffix 
	  == method_vars->alias->class_part_defined->class_id_suffix)
	break;

      i++;
      list = &list->cdr->list_rec;
    }

  fprintf(PrivateOutputFileI, "%d %d\n", i, method_vars->alias->slot_no2);
}

static 
  emit_i_parent(OID cid)
{
  fprintf(PrivateOutputFileI, "%08x%08x\n", 
	  (int)(cid >> 32),
	  (int)(cid & 0xffffffff));
}

static void
  emit_oz (char *format, ...)
{
  va_list pvar;

  va_start (pvar);
  if (Part == PUBLIC_PART)
    Emit2 (PublicOutputFileZ, format, pvar);
  else
    Emit2 (ProtectedOutputFileZ, format, pvar);
  va_end (pvar);
}

static void
  emit_oz_type (OO_Type type)
{
  OO_List args;
  OO_ClassType cl;

  switch (type->id)
    {
    case TO_SimpleType:
      emit_oz ("%s ", type_str[type->simple_type_rec.cl].str);
      break;
    case TO_ClassType:
      if (type->class_type_rec.cl != TC_Record ||
	  !(cl = SetClassStatus (type->class_type_rec.class_id_public,
				 CLASS_RECORD_EMITED)))
	{
#if 1
	  emit_oz ("#%08x%08x %d ",
		   (int) (type->class_type_rec.class_id_public >> 32),
		   (int) (type->class_type_rec.class_id_public &0xffffffff),
		   type->class_type_rec.qualifiers);
#else
	  emit_oz ("#%08x%08x ",
		   (int) (type->class_type_rec.class_id_public >> 32),
		   (int) (type->class_type_rec.class_id_public &0xffffffff));
#endif
	}
      else
	{
	  type->class_type_rec.status = CLASS_RECORD_EMITED;
	  emit_oz ("(%s\n", RECORD_START);
	  EmitClassFileZ (cl, PUBLIC_PART);
	  emit_oz (")\n", RECORD_START);
	}
      break;
    case TO_TypeSCQF:
      emit_oz ("(%s ", SCQF_START);
      emit_oz_type (type->type_scqf_rec.type);
      emit_oz ("%d) ", type->type_scqf_rec.scqf);
      break;
    case TO_TypeMethod:
      emit_oz ("(%s ", METHOD_START);
      emit_oz_type (type->type_method_rec.type);
      if (args = type->type_method_rec.args)
	emit_oz ("(%s ", LIST_START);
      else
	emit_oz ("(%s", LIST_START);
      while (args)
	{
	  emit_oz_type (args->car->symbol_rec.type);
	  args = &args->cdr->list_rec;
	}
      emit_oz (") ");
      emit_oz ("%d) ", type->type_method_rec.qualifier);
      break;
    case TO_TypeArray:
      emit_oz ("(%s ", ARRAY_START);
      emit_oz_type (type->type_array_rec.type);
      emit_oz (") ");
      break;
    case TO_TypeProcess:
      emit_oz ("(%s ", PROCESS_START);
      emit_oz_type (type->type_process_rec.type);
      emit_oz (") ");
      break;
    }
}

static void
  emit_members (OO_List list, int access)
{
  while (list)
    {
      emit_oz ("(%s %s ", DECL_START, list->car->symbol_rec.string);
      emit_oz_type (list->car->symbol_rec.type);
      switch (access)
	{
	case CONSTRUCTOR_PART:
	  emit_oz ("constructor #%08x%08x ", 
		   (int) (list->car->symbol_rec.class_part_defined
			  ->class_id_public >> 32),
		   (int) (list->car->symbol_rec.class_part_defined
			  ->class_id_public & 0xffffffff));
	  break;
	case PUBLIC_PART:
	  emit_oz ("public #%08x%08x ", 
		   (int) (list->car->symbol_rec.class_part_defined
			  ->class_id_public >> 32),
		   (int) (list->car->symbol_rec.class_part_defined
			  ->class_id_public & 0xffffffff));
	  break;
	case PROTECTED_PART:
	  emit_oz ("protected #%08x%08x ", 
		   (int) (list->car->symbol_rec.class_part_defined
			  ->class_id_protected >> 32),
		   (int) (list->car->symbol_rec.class_part_defined
			  ->class_id_protected & 0xffffffff));
	  break;
	}
      emit_oz ("%d ", 
	       list->car->symbol_rec.class_part_defined->class_id_suffix);
      if (list->car->symbol_rec.is_variable)
	{
	  if (list->car->symbol_rec.orig_name)
	    emit_oz ("%s)\n", list->car->symbol_rec.orig_name->string);
	  else
	    InternalError ("symbol: `%s' has no original name\n");
	}
      else
	{
	  emit_oz ("%d)\n", list->car->symbol_rec.slot_no2);
	}
      list = &list->cdr->list_rec;
    }
}

static void
emit_parents (OO_ParentDesc parents)
{
  OO_List list;
  long long vid;

  emit_oz ("(%s\n", LIST_START);
  while (parents)
    {
      list = parents->class->class_part_list;
      if (list)
	list = &list->cdr->list_rec;
      while (list)
	{
	  emit_oz ("(%s #%08x%08x #%08x%08x %d)\n", 
		   LIST_START,
		   (int) (list->car->class_type_rec.class_id_public 
			  >> 32),
		   (int) (list->car->class_type_rec.class_id_public 
			  & 0xffffffff),
		   (int) (list->car->class_type_rec.class_id_protected 
			  >> 32),
		   (int) (list->car->class_type_rec.class_id_protected
			  & 0xffffffff),
		   list->car->class_type_rec.class_id_suffix);
	  list = &list->cdr->list_rec;
	}

      emit_oz ("(%s #%08x%08x #%08x%08x %d)\n", 
	       LIST_START,
	       (int) (parents->class->class_id_public >> 32),
	       (int) (parents->class->class_id_public & 0xffffffff),
	       (int) (parents->class->class_id_protected >> 32),
	       (int) (parents->class->class_id_protected & 0xffffffff),
	       parents->class->class_id_suffix);
      parents = parents->next;
    }
  emit_oz (")\n");
}

/*
 * global functions
 */

void 
  EmitClassFileZ (OO_ClassType ct, int part)
{
  OO_ParentDesc parents;
  OID vid;

  if (part == PUBLIC_PART)
    vid = ct->class_id_public;
  else
    vid = ct->class_id_protected;

#if 1
  emit_oz ("(%s #%08x%08x %d\n", CLASS_START,
	   (int) (vid >> 32), (int) (vid & 0xffffffff),
	   ct->qualifiers);
#else
  emit_oz ("(%s #%08x%08x\n", CLASS_START,
	   (int) (vid >> 32), (int) (vid & 0xffffffff));
#endif
  
  /* skip `Object' class */
  if (ct->parent_desc && (parents = ct->parent_desc->next))
    emit_parents (parents);
  else
    emit_oz ("(%s)\n", LIST_START);

  emit_oz ("(%s\n", LIST_START);
  emit_members (ct->constructor_list, CONSTRUCTOR_PART);
  emit_members (ct->public_list, PUBLIC_PART);
  if (part == PROTECTED_PART)
    emit_members (ct->protected_list, PROTECTED_PART);
  emit_oz (")\n");

  emit_oz (")\n");
}

void 
  EmitClassFileI (OO_ClassType ct)
{
  OO_ParentDesc parents;
  OO_Symbol method_vars;
  OO_List list;

  no_public_methods = no_redefined_public_methods = 0;
  no_methods = no_redefined_methods = no_alias_methods = no_parents = 0;

  emit_i_header(ct, 0);

  if (ct->cl == TC_Object)
    {
      if (ct->parent_desc)
	{
	  /* skip `Object' class */
	  parents = ct->parent_desc->next;
	  while (parents)
	    {
	      emit_i_parent(parents->class->class_id_protected);
	      no_parents++;
	      parents = parents->next;
	    }
	}
      
      list = ct->private_list;
      while (list)
	{
	  if (list->car->symbol_rec.alias)
	    {
	      emit_i_alias_method(&list->car->symbol_rec, ct);
	      no_alias_methods++;
	    }
	  list = &list->cdr->list_rec;
	}
      
      method_vars = ct->block->vars;
      while (method_vars)
	{
	  if (!method_vars->alias && 
	      method_vars->class_part_defined->class_id_public 
	      != ct->class_id_public)
	    {
	      switch (method_vars->access)
		{
		case PUBLIC_PART:
		case CONSTRUCTOR_PART:
		  emit_i_method (method_vars, ct);
		  no_redefined_public_methods++;
		  no_redefined_methods++;
		  break;
		case PROTECTED_PART:
		case PRIVATE_PART:
		  if (!method_vars->is_variable)
		    {
		      emit_i_method(method_vars, ct);
		      no_redefined_methods++;
		    }
		  break;
		}
	    }
	  method_vars = method_vars->link;
	}
      
      method_vars = ct->block->vars;
      while (method_vars)
	{
	  if (method_vars->class_part_defined->class_id_public 
	      == ct->class_id_public)
	    {
	      switch (method_vars->access)
		{
		case PUBLIC_PART:
		case CONSTRUCTOR_PART:
		  emit_i_method (method_vars, ct);
		  no_public_methods++;
		  no_methods++;
		  break;
		case PROTECTED_PART:
		  if (!method_vars->is_variable)
		    {
		      emit_i_method (method_vars, ct);
		      no_methods++;
		    }
		  break;
		}
	    }
	  method_vars = method_vars->link;
	}
      emit_i_header(ct, 1);
    }
}


