/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <string.h>
#include <varargs.h>

#include "oz++/object-type.h"
#include "lang/types.h"

#include "ozc.h"
#include "exp.h"
#include "type.h"
#include "lang/school.h"
#include "block.h"
#include "error.h"
#include "symbol.h"
#include "emit-common.h"
#include "emit-common2.h"
#include "emit-layout.h"
#include "class-list.h"
#include "common.h"

#include "exec-function-name.h"

static char buf[1024]; 

static void emit_exp (FILE *, OO_Expr);

static void
emit_scqf (char *buf, int qual)
{
  if (qual & QF_UNSIGNED)
    {
      strcat (buf, "unsigned ");
    }

  if (qual & QF_CONST)
    {
      strcat (buf, "const ");
    }
    
  if (qual & SC_GLOBAL)
    {
      strcat (buf, "global ");
    }
}

static void
emit_type (OO_Type type, int scqf, int reset)
{
  if (reset)
    buf[0] = '\0';

  if (!type)
    {
      strcat (buf, type_str[TC_Generic].str);
      return;
    }

  switch (type->id) 
    {
    case TO_SimpleType:
      strcat (buf, type_str[type->simple_type_rec.cl].str);
      break;
    case TO_ClassType:
      switch (type->class_type_rec.cl)
	{
	case TC_Record:
	  strcat (buf, "struct OZ");
	  if (type->class_type_rec.symbol)
	    strcat (buf, GetVID (type->class_type_rec.symbol->string, 0));
	  else 
	    {
	      char vid[17];

	      sprintf (vid, "%08x%08x",
		       (int) (type->class_type_rec.class_id_public >> 32),
		       (int) (type->class_type_rec.class_id_public 
			      & 0xffffffff));
	      strcat (buf, vid);
	    }
	  strcat (buf, "Record_Rec");
	  break;
	case TC_StaticObject:
	  strcat  (buf, "OZ_StaticObject");
	  break;
	case TC_Object:
	  if (scqf & SC_GLOBAL)
	    strcat (buf, "OID");
	  else
	    strcat (buf, "OZ_Object");
	  break;
	}
      break;
    case TO_TypeSCQF:
      if (type->type_scqf_rec.scqf & SC_GLOBAL)
	emit_scqf (buf, type->type_scqf_rec.scqf ^ SC_GLOBAL);
      else
	emit_scqf (buf, type->type_scqf_rec.scqf);
      emit_type (type->type_scqf_rec.type, type->type_scqf_rec.scqf, 0);
      break;
    case TO_TypeProcess:
      strcat (buf, "OZ_ProcessID");
      break;
    case TO_TypeArray:
      strcat (buf, "OZ_Array");
      break;
    }
}

#define FORMAT_MAX 256

static char
  get_type_char (OO_Type type, int qual)
{
  switch (type->id)
    {
    case TO_SimpleType:
      if (type->simple_type_rec.cl == -1)
	return 'i';
      else
	return format_char_of_type [type->simple_type_rec.cl];
    case TO_ClassType:
      if (qual & SC_GLOBAL)
	return format_char_of_type [OZ_GLOBAL_OBJECT];
      else
	return format_char_of_type [type->class_type_rec.cl];
    case TO_TypeSCQF:
      return get_type_char (type->type_scqf_rec.type, type->type_scqf_rec.scqf);
    case TO_TypeArray:
      return format_char_of_type [OZ_ARRAY];
    case TO_TypeProcess:
      return format_char_of_type [OZ_PROCESS];
    }
}

static char *
  create_args_format (OO_Type rval, OO_List args)
{
  char *form = (char *) malloc (FORMAT_MAX);
  OO_Type type;
  int len = FORMAT_MAX, i = 0;

  form[i++]  = get_type_char (rval, 0);
  
  while (args)
    {
      form[i++]  = get_type_char (((OO_Expr) args->car)
				    ->expr_common_rec.type, 
				    0);
      args = (OO_List) args->cdr;
      if (args && i == len)
	{
	  char *buf;
	  
	  len += FORMAT_MAX;
	  buf = (char *) realloc (form, len);
	  free (form);
	  form = buf;
	}
    }
  form[i] = '\0';
  return form;
}

static void
  emit_args (FILE *fp, OO_List args_list, OO_List dargs, OO_Symbol method,
	     int is_global)
{
  long long id, pid;
  OO_Expr exp, dexp = NULL;
  OO_List args;
  int number_of_record_arg = 0;

  EmitIndentDown ();
	
  args = args_list;
  while (args)
    {
      exp = (OO_Expr) args->car;
      if (dargs)
	dexp = (OO_Expr) dargs->car;
      Emit (fp, ",\n");

      if (!exp->expr_common_rec.type)
	emit_exp (fp, exp);

      else if (exp->expr_common_rec.type->id == TO_ClassType &&
	  exp->expr_common_rec.type->class_type_rec.cl == TC_Record)
	{
	  OO_ClassType cl = &exp->expr_common_rec.type->class_type_rec;
	  int size = GetRecordSize (cl);

	  size = !size ? 1 : size;
	  
	  Emit (fp, "({\n");
	  EmitIndentDown ();

	  if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
	    {
	      EmitType (fp, exp->expr_common_rec.type);
	      Emit (fp, "_Sub *_oz_arg_%d = (", number_of_record_arg);
	      EmitType (fp, exp->expr_common_rec.type);
	      Emit (fp, "_Sub *) OzMalloc (%d);\n",
		    size + sizeof (OZ_HeaderRec));

	      if (is_global)
		{
		  Emit (fp, "_oz_arg_%d->head.e = %d;\n", 
			number_of_record_arg, size + sizeof (OZ_HeaderRec));
		  Emit (fp, "_oz_arg_%d->head.a = ", number_of_record_arg);
		  EmitVID (fp, cl->class_id_public, 1);
		  Emit (fp, ";\n");
		}
#if 1
	      Emit (fp, "_oz_arg_%d->head.h = -3;\n", 
		    number_of_record_arg);
	      Emit (fp, "(int) _oz_arg_%d->head.d = OZ_RECORD;\n",
		    number_of_record_arg);
#endif
	      Emit (fp, "_oz_arg_%d->data = ", number_of_record_arg);
	    }
	  else
	    {
	      EmitType (fp, exp->expr_common_rec.type);
	      Emit (fp, " *_oz_arg_%d = (", number_of_record_arg);
	      EmitType (fp, exp->expr_common_rec.type);
	      Emit (fp, " *) OzMalloc (%d);\n", size);
	      Emit (fp, "*_oz_arg_%d = ", number_of_record_arg);
	    }
	  emit_exp (fp, exp);
	  Emit (fp, ";\n");

	  Emit (fp, "_oz_arg_%d;\n", number_of_record_arg);

	  EmitIndentUp ();
	  Emit (fp, "})\n");

	  number_of_record_arg++;
	}

      else if (dexp && dexp->expr_common_rec.type->id == TO_ClassType &&
	  exp->expr_common_rec.type->id == TO_ClassType &&
	  CheckClassType (&exp->expr_common_rec.type->class_type_rec, 
			  &dexp->expr_common_rec.type->class_type_rec, 
			  1, 0) < TYPE_OK)
	{
	  id = exp->expr_common_rec.type->class_type_rec.class_id_public;
	  pid = dexp->expr_common_rec.type->class_type_rec.class_id_public; 
	  EmitAsClassOf (fp, pid, 
			 dexp->expr_common_rec.type
			 ->class_type_rec.class_id_suffix,
			 id,
			 exp);
	}

      else if (dexp && dexp->expr_common_rec.type->id == TO_TypeSCQF &&
	       dexp->expr_common_rec.type->type_scqf_rec.scqf & SC_GLOBAL &&
	       CheckSimpleType (exp->expr_common_rec.type, TC_Zero) == TYPE_OK)
	Emit (fp, "0LL");

      else
	{
	  if (dexp && CheckSimpleType (dexp->expr_common_rec.type,
			       TC_Condition) > TYPE_NG &&
	      (exp->id == TO_ArrayReference ||
	       (exp->id == TO_Symbol && 
		exp->symbol_rec.class_part_defined)))
	    Emit (fp, "&");
	  
	  emit_exp (fp, exp);
	}

      args = (OO_List) args->cdr;
      if (dargs)
	dargs = (OO_List) dargs->cdr;
    }

  EmitIndentUp ();
}

static void
emit_function_call (FILE *fp, OO_Expr exp, OO_Symbol method, OO_List args, 
		    int exp_flag)
{
  OO_Type type = NULL;
  char type_buf[1024]; 

  if (method->type)
    type = method->type->type_method_rec.type;

  if (type && type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
    {
      Emit (fp, "({\n");
      EmitIndentDown ();

      emit_type (type,  0, 1);
	strcpy (type_buf, buf);

      if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
	{
	  Emit (fp, "%s_Sub *_OZ_result;\n", type_buf);
	  Emit (fp, "%s *_OZ_result_sub;\n", type_buf);
	}
      else
	{
	  Emit (fp, "%s *_OZ_result, *_OZ_result_sub;\n", type_buf);
	}

      Emit (fp, "_OZ_result = ");
    }

  if (method->class_part_defined->cl == TC_Object)
    Emit (fp, "%s%s ", METHOD_PREFIX, method->string);
  else
    {
      Emit (fp, "%s", METHOD_PREFIX);
      EmitVID (fp, method->class_part_defined->class_id_public, 0);
      Emit (fp, "_%s ", method->string);
    }

  Emit (fp, "(");
  if (exp_flag)
    {
      OO_ClassType cl = method->class_part_defined;

      if (cl->cl == TC_Record)
	{
	  int size = GetRecordSize (cl);
	  
	  size = !size ? 1 : size;

	  if (ThisClass->cl == TC_Record)
	    Emit (fp, "_oz_sub_self, &");
	  else
	    Emit (fp, "(OZ_Object) self, &");

#if 0	  
	  Emit (fp, "({\n");
	  EmitIndentDown ();

	  EmitType (fp, exp->expr_common_rec.type);
	  Emit (fp, " *_oz_self = (");
	  EmitType (fp, exp->expr_common_rec.type);

#if 0
	  if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
	    {
	      Emit (fp, " *) OzMalloc (%d);\n", size + sizeof (OZ_HeaderRec));
	      Emit (fp, "_oz_self->data = ");
	    }
	  else
	    {
	    }
#endif
	  Emit (fp, " *) OzMalloc (%d);\n", size);
	  Emit (fp, "*_oz_self = ");

	  EmitExp (fp, exp);
	  Emit (fp, ";\n");
	  Emit (fp, "_oz_self;\n");
	  
	  EmitIndentUp ();
	  Emit (fp, "})");
#else
	  EmitExp (fp, exp);
#endif
	}
      else
	EmitExp (fp, exp);
    }
  else
    Emit (fp, "%s", (char *)exp);

  if (method->type)
    emit_args (fp, args, method->type->type_method_rec.args, method, 0);
  else
    emit_args (fp, args, NULL, method, 0);

  Emit (fp, ")");

  if (type && type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
    {
      int size = GetRecordSize (&type->class_type_rec);

      size = !size ? 1 : size;

      Emit (fp, ";\n");

      Emit (fp, "_OZ_result_sub = (%s *) OzMalloc (%d);\n", 
	    type_buf, size);

      if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
	Emit (fp, "*_OZ_result_sub = _OZ_result->data;\n");
      else
	Emit (fp, "*_OZ_result_sub = *_OZ_result;\n");

      Emit (fp, "OzFree (_OZ_result);\n");
      Emit (fp, "*_OZ_result_sub;\n");

      EmitIndentUp ();
      Emit (fp, "})");
    }
}

static void
emit_global_method_call (FILE *fp, 
			 OO_Symbol method, OO_List args,
			 char *recv_name, OO_ClassType recv_class)
{
  char pvid[17], *format;
  int qual, is_not_void = TYPE_NG;
  OO_ClassType clp, cl;
  int pvid_suffix = 0;
  OO_Type type = NULL;
  char type_buf[1024];

  if (method->type)
    sprintf (pvid, "%08x%08x", 
	     (int) (method->class_part_defined->class_id_public >> 32),
	     (int) (method->class_part_defined->class_id_public 
		    & 0xffffffff));
  else
    strcpy (pvid, "0000000000000000");
  
  pvid_suffix = method->class_part_defined->class_id_suffix;

  if (method->type && method->class_part_defined->symbol)
    Emit (fp, "/*** global-invoke: %s in %s ***/\n",
	  method->string, method->class_part_defined->symbol->string);
  else
    Emit (fp, "/*** global-invoke: %s in %s ***/\n",
	  method->string, pvid);
    
  Emit (fp, "({\n");
  EmitIndentDown ();

  Emit (fp, "OID _OZ_oid = %s (0);\n", GET_OID);
  Emit (fp, "OID _OZ_obj = ");
  if (recv_class)
    {
      Emit (fp, "%s", recv_name);
      cl = recv_class;
    }
  else
    {
      emit_exp (fp, (OO_Expr) recv_name);
      cl = GetClassType ((OO_Expr) recv_name, &qual);
    }
  EmitSemiColon (fp);

  if (method->type)
    is_not_void = CheckSimpleType (method->type->type_method_rec.type, 
				   TC_Void);
  if (is_not_void == TYPE_NG)
    {
      type = method->type ? method->type->type_method_rec.type : NULL;
      
      if (type)
	emit_type (type, 0, 1);
      else
	strcpy (buf, "int");

      if (type && 
	  type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
	{
	  strcpy (type_buf, buf);

	  Emit (fp, "%s_Sub *_OZ_result;\n", type_buf);
	  Emit (fp, "%s *_OZ_result_sub;\n", type_buf);
	}
      else
	Emit (fp, "%s _OZ_result;\n", buf);

      Emit (fp, "_OZ_result = ");

      if (type)
	{
	  if (type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
	    Emit (fp, "(%s_Sub *) (int) ", type_buf);

	  else if (type->id == TO_ClassType || type->id == TO_TypeArray)
	    Emit (fp, "(%s) (int) ", buf);

	  else
	    Emit (fp, "(%s) ", buf);
	}
      else
	Emit (fp, "(%s) ", buf);

      Emit (fp, "%s (_OZ_oid, _OZ_obj, ", GLOBAL_INVOKE);

      if (cl)
	EmitVID (fp, cl->class_id_public, 1);
      else
	Emit (fp, "0x0LL");

      Emit (fp, ",\n");
    }
  else
    {
      Emit (fp, "%s (_OZ_oid, _OZ_obj, ", GLOBAL_INVOKE);
      if (cl)
	EmitVID (fp, cl->class_id_public, 1);
      else
	Emit (fp, "0x0LL");
      Emit (fp, ",\n");
    }

  if (!strcmp (pvid, OBJECT_PUBLIC))
    Emit (fp, "  1,\n");

  else
    {
      Emit (fp, "  OZClassPart%s_%d_in_", pvid, pvid_suffix);
      if (cl)
	EmitVID (fp, cl->class_id_public, 0);
      else
	Emit (fp, "0x0LL");
      Emit (fp, ",\n");
    }

  Emit (fp, "  %d,\n", method->slot_no2);

  if (method->type)
    {
      format = create_args_format (method->type->type_method_rec.type, args);
      Emit (fp, "  \"%s\", 0, 0", format);
      free (format);
      emit_args (fp, args, method->type->type_method_rec.args, method, 1);
    }
  else
    {
      Emit (fp, "  \"v\", 0, 0");
      emit_args (fp, args, NULL, method, 1);
    }

  Emit (fp, ");\n");

  if (type && type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
    {
      int size = GetRecordSize (&type->class_type_rec);

      size = !size ? 1 : size;

      Emit (fp, "_OZ_result_sub = (%s *) OzMalloc (%d);\n", type_buf, size);

      Emit (fp, "*_OZ_result_sub = _OZ_result->data;\n");
      Emit (fp, "OzFree (_OZ_result);\n");
      Emit (fp, "*_OZ_result_sub;\n");
    }

  else if (is_not_void == TYPE_NG)
    Emit (fp, "_OZ_result;\n");

  EmitIndentUp ();
  Emit (fp, "})");
}

static void
  emit_find_method (FILE *fp, OO_Symbol method, 
		    char *recv_name, OO_ClassType recv_class)
{
  char method_vid[17], *pvid, vid[17];
  OO_ClassType clp, cl = NULL;
  int is_not_void = TYPE_NG;
  int pvid_suffix = 0;
  OO_Type type = NULL;

  Emit (fp, "void *_OZ_Top = %s ();\n", GET_METHOD_IMPLEMENTATION);
  Emit (fp, "OZ_MethodImplementationRec _OZ_imp_rec;\n");
  Emit (fp, "OZ_Object _OZ_obj = ");
  if (recv_name)
    {
      int qual;

      if (recv_class || !strcmp (recv_name, "_oz_obj"))
	{
	  Emit (fp, "%s", recv_name);
	  cl = recv_class;
	}
      else
	{
	  emit_exp (fp, (OO_Expr) recv_name);
	  cl = GetClassType ((OO_Expr) recv_name, &qual);
	}

      if (cl)
	{
	  sprintf (vid, "%08x%08x",
		   (int) (cl->class_id_public >> 32),
		   (int) (cl->class_id_public & 0xffffffff));

	  if (method->access != PROTECTED_PART)
	    sprintf (method_vid, "%08x%08x", 
		     (int) (method->class_part_defined->class_id_public >> 32),
		     (int) (method->class_part_defined->class_id_public 
			    & 0xffffffff));
	  else
	    sprintf (method_vid, "%08x%08x", 
		     (int) (method->class_part_defined->class_id_protected 
			    >> 32),
		     (int) (method->class_part_defined->class_id_protected 
			    & 0xffffffff));
	}
      else
	{
	  strcpy (vid, "0000000000000000");
	  strcpy (method_vid, "0000000000000000");
	}
    }
  else
    {
      sprintf (vid, "%08x%08x",
	       (int) (ThisClass->class_id_public >> 32),
	       (int) (ThisClass->class_id_public & 0xffffffff));

      Emit (fp, "self");

      if (method->access != PROTECTED_PART)
	sprintf (method_vid, "%08x%08x", 
		 (int) (method->class_part_defined->class_id_public >> 32),
		 (int) (method->class_part_defined->class_id_public 
			& 0xffffffff));
      else
	sprintf (method_vid, "%08x%08x", 
		 (int) (method->class_part_defined->class_id_protected >> 32),
		 (int) (method->class_part_defined->class_id_protected 
			& 0xffffffff));
    }

  if (cl && 
      method->class_part_defined->class_id_public 
      						== cl->class_id_public)
    pvid = vid;
  else
    pvid = method_vid;


  if (method->class_part_defined)
    pvid_suffix = method->class_part_defined->class_id_suffix;

  Emit (fp, ";\n");

  if (method->type)
    {
      type = method->type->type_method_rec.type;
      is_not_void 
	= CheckSimpleType (type, TC_Void);
    }


  if (is_not_void == TYPE_NG)
    {
      if (type)
	emit_type (type, 0, 1);
      else
	strcpy (buf, "int");

      if (type)
	{
	  if (CheckSimpleType (type, TC_Condition) > TYPE_NG)
	    Emit (fp, "%s *_OZ_result;\n", buf);

	  else if (type->id == TO_ClassType && 
		   type->class_type_rec.cl == TC_Record)
	    {
	      if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
		{
		  Emit (fp, "%s_Sub *_OZ_result;\n", buf);
		  Emit (fp, "%s *_OZ_result_sub;\n", buf);
		}
	      else
		Emit (fp, "%s *_OZ_result, *_OZ_result_sub;\n", buf);
	    }

	  else 
	    Emit (fp, "%s _OZ_result;\n", buf);
	}
      else
	Emit (fp, "%s _OZ_result;\n", buf);
    }

  if (cl && method->class_part_defined->symbol)
    Emit (fp, "/*** method-invoke:  %s in %s ***/\n", 
	  method->string, method->class_part_defined->symbol->string);
  else
    Emit (fp, "/*** method-invoke: %s in %s ***/\n", 
	  method->string, pvid);

  Emit (fp, "%s (&_OZ_imp_rec, _OZ_obj,\n", FIND_METHOD_IMPLEMENTATION);

  if (!strcmp (method_vid, OBJECT_PUBLIC))
    Emit (fp, "  1,\n");
  else
    Emit (fp, "  OZClassPart%s_%d_in_%s,\n", pvid, pvid_suffix, vid);
      
  if (cl)
    Emit (fp, "  %d);\n", method->slot_no2);
  else
    Emit (fp, "  0);\n");
}

static void
emit_method_call (FILE *fp, OO_Symbol method, OO_List args,
		  char *recv_name, OO_ClassType recv_class)
{
  int is_not_void = TYPE_NG;
  OO_Type type = NULL;
  char type_buf[1024];

  Emit (fp, "({\n");
  EmitIndentDown ();
  emit_find_method (fp, method, recv_name, recv_class);
  
  if (method->type)
    is_not_void 
      = CheckSimpleType ((type = method->type->type_method_rec.type), TC_Void);

  if (is_not_void == TYPE_NG)
    {
      Emit (fp, "_OZ_result = ((");
      if (type)
	{
	  emit_type (type, 0, 1);

	  if (type->id == TO_ClassType &&
	      type->class_type_rec.cl == TC_Record)
	    strcpy (type_buf, buf);
	}
      else
	strcpy (buf, "int");

      if (type && 
	  CheckSimpleType (type, TC_Condition) > TYPE_NG)
	Emit (fp, "%s *(*)())_OZ_imp_rec.function) (_OZ_obj", buf);
      else if (type && type->id == TO_ClassType && 
	       type->class_type_rec.cl == TC_Record)
	{
	  if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
	    Emit (fp, "%s_Sub *(*)())_OZ_imp_rec.function) (_OZ_obj", 
		  type_buf);
	  else
	    Emit (fp, "%s *(*)())_OZ_imp_rec.function) (_OZ_obj", type_buf);
	}

      else
	Emit (fp, "%s (*)())_OZ_imp_rec.function) (_OZ_obj", buf);
    }
  else
    Emit (fp, "_OZ_imp_rec.function (_OZ_obj");
  
  if (method->type)
    emit_args (fp, args, method->type->type_method_rec.args, method, 0);
  else
    emit_args (fp, args, NULL, method, 0);
           
  Emit (fp, ");\n");
  Emit (fp, "%s (_OZ_Top);\n", FREE_METHOD_IMPLEMENTATION);

  if (type && type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
    {
      int size = GetRecordSize (&type->class_type_rec);
      
      size = !size ? 1 : size;

      Emit (fp, "_OZ_result_sub = (%s *) OzMalloc (%d);\n", 
	    type_buf, size);

      if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
	Emit (fp, "*_OZ_result_sub = _OZ_result->data;\n");
      else
	Emit (fp, "*_OZ_result_sub = *_OZ_result;\n");
      Emit (fp, "OzFree (_OZ_result);\n");
      Emit (fp, "*_OZ_result_sub;\n");
    }

  else if (is_not_void == TYPE_NG)
    Emit (fp, "_OZ_result;\n");

  EmitIndentUp ();
  Emit (fp, "})");
}

static void
  emit_global_instantiation (FILE *fp, OO_Expr lvalue, OO_Type type,
			     OO_Symbol method, OO_List args, OO_Expr om)
{
  char *vid, *format;
  OO_ClassType cl;
  int qual;
  ClassID public_vid = 0LL;
  OO_Symbol new_object;

  if (cl = GetClassType (lvalue, &qual))
    public_vid = cl->class_id_public;

  emit_exp (fp, lvalue);
  Emit (fp, "/*** global instantiation ***/\n");
  Emit (fp, " = ({\n");
  EmitIndentDown ();
  Emit (fp, "OID _oz_obj = ({\n");
  EmitIndentDown ();
  Emit (fp, "OID _OZ_oid = %s (0);\n", GET_OID);
  if (om)
    {
      Emit (fp, "OID _OZ_obj = ");
      emit_exp (fp, om);
      Emit (fp, ";\n");
    }
  else
    Emit (fp, "OID _OZ_obj = OzExecObjectManagerOf (OzExecGetOID (0));\n");
  Emit (fp, "OID _OZ_result;\n");

  new_object = GetMethod (NEW_OBJECT, ObjectClass, 0, PUBLIC_PART);

#ifndef OLD_OBJECT
  if (ThisClass->cl != TC_Record)
#ifdef NONISHIOKA
    Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	  "((OZ_Object) &OzExecGetObjectTop (self)->head[0])"
	  "->head.d)->oz%s;\n", 
	  OBJECT_PRIVATE, CONFIG_SET);
#else
    Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	  "((OZ_Object) &OzExecGetObjectTop (self)->head[1])"
	  "->head.d)->oz%s;\n", 
	  OBJECT_PRIVATE, CONFIG_SET);
#endif
  else
#ifdef NONISHIOKA
    Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	  "((OZ_Object) &OzExecGetObjectTop (_oz_sub_self)->head[0])"
	  "->head.d)->oz%s;\n", 
	  OBJECT_PRIVATE, CONFIG_SET);
#else
    Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	  "((OZ_Object) &OzExecGetObjectTop (_oz_sub_self)->head[1])"
	  "->head.d)->oz%s;\n", 
	  OBJECT_PRIVATE, CONFIG_SET);
#endif
  Emit (fp, "OZ_ClassID _oz_ccid =\n");
  EmitIndentDown ();
  {
    OO_List lookup_args;
    OO_Symbol lookup_method = GetMethod (LOOKUP_CONFIG, ObjectClass, 
					 0, PUBLIC_PART);
    char id[17];
    
    sprintf (id, "0x%08x%08xLL", 
	     (int) (public_vid >> 32), (int) (public_vid & 0xffffffff));
    
    lookup_args 
      = CreateList ((OO_Object) 
		    CreateExpConstant (0, "long", TC_Long, id), NULL);
    
    if (ThisClass->cl != TC_Record)
      emit_method_call (fp, lookup_method, lookup_args, "self", ObjectClass);
    else
      emit_method_call (fp, lookup_method, lookup_args, "_oz_sub_self", ObjectClass);
  }
  EmitIndentUp();
  Emit (fp, ";\n");
  Emit (fp, "if (_oz_ccid == 0);\n");
  EmitIndentDown();
  Emit (fp, "_oz_ccid = %s (", GET_DEFAULT_CONFIGURATION);
  EmitVID (fp, public_vid, 1);
  Emit (fp, ");\n");
  EmitIndentUp();
  Emit (fp, "_OZ_result = ");
  Emit (fp, "((OID (*) ()) %s) (_OZ_oid, _OZ_obj, 0x%sLL,\n", 
	GLOBAL_INVOKE,
	OBJECT_PUBLIC);
  Emit (fp, "  1,\n");
  Emit (fp, "  %d,\n", new_object->slot_no2);
#if 1
  format = create_args_format (new_object->type->type_method_rec.type, 
			       new_object->type->type_method_rec.args);
  Emit (fp, "  \"%s\", 0, 0,\n", format);
  free (format);
#else
  Emit (fp, "  \"%s\", 0, 0,\n", OM_NEW_OBJECT_FORMAT);
#endif
  if (cl)
    Emit (fp, "_oz_ccid, _oz_cset");
  else
    Emit (fp, "0x0LL");
  Emit (fp, ");\n");
#else

  Emit (fp, "_OZ_result = ");
  Emit (fp, "((OID (*) ()) %s) (_OZ_oid, _OZ_obj, 0x%sLL,\n", 
	GLOBAL_INVOKE,
	OBJECT_PUBLIC);
  Emit (fp, "  1,\n");
  Emit (fp, "  %d,\n", new_object->slot_no2);
#if 1
  format = create_args_format (new_object->type->type_method_rec.type, 
			       new_object->type->type_method_rec.args);
  Emit (fp, "  \"%s\", 0, 0,\n", format);
  free (format);
#else
  Emit (fp, "  \"%s\", 0, 0,\n", OM_NEW_OBJECT_FORMAT);
#endif
  if (cl)
    EmitVID (fp, public_vid, 1);
  else
    Emit (fp, "0x0LL");
  Emit (fp, ");\n");
#endif
  Emit (fp, "_OZ_result;\n");
  EmitIndentUp ();
  Emit (fp, "});\n");
  emit_global_method_call (fp, method, args, "_oz_obj", cl);
  Emit (fp, ";\n");
  Emit (fp, "_oz_obj;\n");
  EmitIndentUp ();
  Emit (fp, "})");
}

static void
  emit_instantiation (FILE *fp, OO_Expr lvalue,
		      OO_Symbol method, OO_List args, int is_mine)
{
  int qual;
  ClassID public_vid = 0LL;
  OO_ClassType cl = NULL;;

  if (lvalue->expr_common_rec.type)
    {
      cl = &lvalue->expr_common_rec.type->class_type_rec;
      public_vid = cl->class_id_public;
    }

  Emit (fp, "(");
  emit_exp (fp, lvalue);
  Emit (fp, " = ");
  Emit (fp, "({\n");
  EmitIndentDown ();

  if (!cl || (cl && cl->cl == TC_Object))
    {
#ifdef OLD_NEW
      Emit (fp, "OZ_Object _oz_obj = ");
      Emit (fp, "%s (", ALLOCATE_LOCAL_OBJECT);
      EmitVID (fp, public_vid, 1);
      Emit (fp, ");\n");
#else
      Emit (fp, "OZ_Object _oz_obj;\n");
#ifndef OLD_OBJECT

      if (ThisClass->cl != TC_Record)
#ifdef NONISHIOKA
	Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	      "((OZ_Object) &OzExecGetObjectTop (self)->head[0])"
	      "->head.d)->oz%s;\n", 
	      OBJECT_PRIVATE, CONFIG_SET);
#else
	Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	      "((OZ_Object) &OzExecGetObjectTop (self)->head[1])"
	      "->head.d)->oz%s;\n", 
	      OBJECT_PRIVATE, CONFIG_SET);
#endif
      else
#ifdef NONISHIOKA
	Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	      "((OZ_Object) &OzExecGetObjectTop (_oz_sub_self)->head[0])"
	      "->head.d)->oz%s;\n", 
	      OBJECT_PRIVATE, CONFIG_SET);
#else
	Emit (fp, "OZ_Object _oz_cset = ((OZ%sPart) "
	      "((OZ_Object) &OzExecGetObjectTop (_oz_sub_self)->head[1])"
	      "->head.d)->oz%s;\n", 
	      OBJECT_PRIVATE, CONFIG_SET);
#endif
      Emit (fp, "OZ_ClassID _oz_ccid =\n");
      EmitIndentDown ();
      {
	OO_List lookup_args;
	OO_Symbol lookup_method = GetMethod (LOOKUP_CONFIG, ObjectClass, 
					     0, PUBLIC_PART);
	char id[17];

	sprintf (id, "0x%08x%08xLL", 
		 (int) (public_vid >> 32), (int) (public_vid & 0xffffffff));

	lookup_args 
	  = CreateList ((OO_Object) 
			CreateExpConstant (0, "long", TC_Long, id), NULL);

	if (ThisClass->cl != TC_Record)
	  emit_method_call (fp, lookup_method, lookup_args, "self", ObjectClass);
	else
	  emit_method_call (fp, lookup_method, lookup_args, "_oz_sub_self", ObjectClass);
      }
      EmitIndentUp();
      Emit (fp, ";\n");
#else
      Emit (fp, "OZ_ClassID _oz_ccid = 0;\n");
#endif
      Emit (fp, "if (_oz_ccid == 0);\n");
      EmitIndentDown();
      Emit (fp, "_oz_ccid = %s (", GET_DEFAULT_CONFIGURATION);
      EmitVID (fp, public_vid, 1);
      Emit (fp, ");\n");
      EmitIndentUp();
      Emit (fp, "_oz_obj = %s (_oz_ccid);\n", ALLOCATE_LOCAL_OBJECT);
#ifndef OLD_OBJECT
      {
	OO_List cset_args;
	OO_Symbol sym, cset_method = GetMethod (SET_CONFIG_SET, ObjectClass, 
					   0, PUBLIC_PART);

	sym = CreateSymbol ("_oz_cset");
	sym->type 
	  = ((OO_Expr) cset_method->type->type_method_rec.args->car)
	    ->expr_common_rec.type;
	
	cset_args 
	  = CreateList ((OO_Object) sym, NULL);

	emit_method_call (fp, cset_method, cset_args, "_oz_obj", ObjectClass);

	DestroySymbol (sym);
      }
      Emit (fp, ";\n");
#endif
#endif
    }
  else 
    {
      Emit (fp, "OZ_StaticObject _oz_obj = ");
      Emit (fp, "%s (", ALLOCATE_STATIC_OBJECT);
      EmitVID (fp, public_vid, 1);
      Emit (fp, ");\n");
    }
  if (is_mine || 
      (method->class_part_defined && 
       method->class_part_defined->cl != TC_Object))
    emit_function_call (fp, (OO_Expr) "_oz_obj", method, args, 0);
  else
    emit_method_call (fp, method, args, "_oz_obj", GetClassType (lvalue, &qual));
  Emit (fp, ";\n");
  Emit (fp, "_oz_obj;\n");
  EmitIndentUp ();
  Emit (fp, "}))");
}

static int
  emit_array_element_type (FILE *fp, OO_Type type, int qual, int flag)
{
  switch (type->id)
    {
    case TO_SimpleType:
      if (flag)
	Emit (fp, "(long long) %d", type->simple_type_rec.cl);
      else
	Emit (fp, "%s", type_str[type->simple_type_rec.cl].str);
      return type->simple_type_rec.cl == -1 ? 
	4 : oz_size_of_type[type->simple_type_rec.cl];
    case TO_ClassType:
      if (qual & SC_GLOBAL)
	{
	  if (flag)
	    Emit (fp, "(long long) %d", OZ_GLOBAL_OBJECT);
	  else
	    Emit (fp, "OID");
	  return sizeof (OID);
	}
      else
	{
	  switch (type->class_type_rec.cl)
	    {
	    case TC_Object:
	      if (flag)
		Emit (fp, "(long long) %d", OZ_LOCAL_OBJECT);
	      else
		Emit (fp, "OZ_Object");
	      return sizeof (OZ_Object);
	    case TC_StaticObject:
	      if (flag)
		Emit (fp, "(long long) %d", OZ_STATIC_OBJECT);
	      else
		Emit (fp, "OZ_StaticObject");
	      return sizeof (OZ_StaticObject);
	    case TC_Record:
	      if (flag)
#ifdef NONISHIOKA
		Emit (fp, "(long long) %d", OZ_RECORD);
#else
	        Emit (fp, "(long long) 0x%08x%08xLL",
		      (int) (type->class_type_rec.class_id_public >> 32),
		      (int) (type->class_type_rec.class_id_public &
			     0xffffffff));
#endif
	      else
		Emit (fp, "OZ%08x%08xRecord_Rec",
		      (int) (type->class_type_rec.class_id_public >> 32),
		      (int) (type->class_type_rec.class_id_public & 
			     0xffffffff));
	      return GetRecordSize (&type->class_type_rec);
	    default:
	      InternalError ("illegal class type\n");
	      return 0;
	    }
	}
    case TO_TypeSCQF:
      return emit_array_element_type (fp, type->type_scqf_rec.type, 
				      type->type_scqf_rec.scqf, flag);
    case TO_TypeArray:
      if (flag)
	Emit (fp, "(long long) %d", OZ_ARRAY);
      else
	Emit (fp, "OZ_Array");
      return sizeof (OZ_Array);
    case TO_TypeProcess:
      if (flag)
	Emit (fp, "(long long) %d", OZ_PROCESS);
      else
	Emit (fp, "OZ_ProcessID");
      return sizeof (OZ_ProcessID);
    }
}

static void
  emit_array_alloc (FILE *fp, OO_Expr exp)
{
  int size;

  Emit (fp, "OzLangArrayAlloc (&");
  emit_exp (fp, exp->assignment_rec.lvalue->unary_rec.expr);
  Emit (fp, ", ");
  size = emit_array_element_type (fp, 
				  exp->assignment_rec.lvalue
				  ->unary_rec.expr->expr_common_rec.type
				  ->type_array_rec.type,
				  0, 1);
  Emit (fp, ", %d, ", size);
  if (exp->assignment_rec.op != OP_EQ)
    {
      Emit (fp, "({\n");
      EmitIndentDown ();
      Emit (fp, "int _OZ_len;\n");
      Emit (fp, "OZ_Array _OZ_array = ");
      emit_exp (fp, exp->assignment_rec.lvalue->unary_rec.expr);
      Emit (fp, ";\n");
      Emit (fp, 
	    "_OZ_len = _OZ_array ? _OZ_array->head.h : 0;\n");
      Emit (fp, "_OZ_len %s ", op_str [exp->assignment_rec.op].str);
      emit_exp (fp, exp->assignment_rec.expr);
      Emit (fp, ";\n");
      EmitIndentUp ();
      Emit (fp, "})\n");
    }
  else
    emit_exp (fp, exp->assignment_rec.expr);
  Emit (fp, ")");
}

static void
  emit_fork_process (FILE *fp, OO_Expr exp)
{
  OO_Expr recv;
  OO_Symbol method;
  OO_List args, list;
  OO_ClassType cl;
  int qual = 0, nargs = 1;
  char kind;

  recv = exp->method_call_rec.obj;
  method = exp->method_call_rec.method;
  list = args = exp->method_call_rec.args;

  while (list)
    {
      nargs++;
      kind = get_type_char (((OO_Expr) list->car)
			     ->expr_common_rec.type, 
			     0);
      if (kind == 'G' || kind == 'l' || kind == 'd')
	nargs++;
      list = (OO_List) list->cdr;
    }

  if (exp->method_call_rec.is_global)
    {
      char pvid[17], *vid, *format, pformat[2];
      OO_ClassType cl, clp;
      int pvid_suffix = method->class_part_defined->class_id_suffix;

      cl = GetClassType (recv, &qual);

      if (method->type)
	sprintf (pvid, "%08x%08x", 
		 (int) (method->class_part_defined->class_id_public >> 32),
		 (int) (method->class_part_defined->class_id_public 
			& 0xffffffff));
      else
	strcpy (pvid, "0000000000000000");

      nargs += 11;
      if (method->type && method->class_part_defined->symbol)
	Emit (fp, "/*** global-invoke: %s in %s ***/\n",
	      method->string, method->class_part_defined->symbol->string);
      else
	Emit (fp, "/*** global-invoke: %s in %s ***/\n",
	      method->string, pvid);

      Emit (fp, "({\n");
      EmitIndentDown ();
      Emit (fp, "OID _OZ_oid = %s (0);\n", GET_OID);
      Emit (fp, "OID _OZ_obj = ");
      emit_exp (fp, recv);
      EmitSemiColon (fp);
      Emit (fp, "OZ_ProcessID _oz_pid = ");
      if (method->type)
	pformat[0] = get_type_char (method->type->type_method_rec.type, 0);
      else
	pformat[0] = 'v';
      pformat[1] = 0;
#if 0
      Emit (fp, 
	    "%s ((void (*)())%s, '%s', %d, %d, %d,\n"
	    FORK_PROCESS,
	    GLOBAL_INVOKE,
	    pformat, THREAD_STACK, THREAD_PRIORITY, nargs);
#else
      Emit (fp, 
	    "%s ((void (*)())%s, '%s', %d, %d, OzDebugFlags, %d,\n", 
	    FORK_PROCESS,
	    GLOBAL_INVOKE,
	    pformat, THREAD_STACK, THREAD_PRIORITY, nargs);
#endif
      Emit (fp, "  _OZ_oid, _OZ_obj, 0x%sLL,\n", pvid);
      if (!strcmp (pvid, OBJECT_PUBLIC))
	Emit (fp, "  1,\n");
      else
	{
	  Emit (fp, "  OZClassPart%s_%d_in_", pvid, pvid_suffix);
	  if (cl)
	    EmitVID (fp, cl->class_id_public, 0);
	  else
	    Emit (fp, "0000000000000000");
	  Emit (fp, ",\n");
	}
      Emit (fp, "  %d,\n", method->slot_no2);
      if (method->type)
	{
	  format = create_args_format (method->type->type_method_rec.type, 
				       args);
	  Emit (fp, "  \"%s\", 0, 0", format);
	  free (format);
	}
      else
	Emit (fp, "  \"v\", 0, 0");

      if (method->type)
	emit_args (fp, args, method->type->type_method_rec.args, method, 1);
      else
	emit_args (fp, args, NULL, method, 1);
      Emit (fp, "  );\n");
      Emit (fp, "_oz_pid;\n");
      EmitIndentUp ();
      Emit (fp, "})");
      return;
    }
  else 
    {
      char format[2];

      if (method->type)
	format[0] = get_type_char (method->type->type_method_rec.type, 0);
      else
	format[0] = 'v';
      format[1] = 0;
      cl = exp->method_call_rec.method->class_part_defined;
      if (cl && cl->cl != TC_Object)
	{
	  if (cl->cl == TC_Record)
	    nargs++;

	  Emit (fp, 
		"%s ((void (*)())%s",
		FORK_PROCESS, METHOD_PREFIX);

	  EmitVID (fp, 
		   exp->method_call_rec.method->class_part_defined
		   ->class_id_public, 0);
#if 0
	  Emit (fp, 
		"_%s, '%s', %d, %d, %d,\n", 
		method->string, format,
		THREAD_STACK, THREAD_PRIORITY, nargs);
#else
	  Emit (fp, 
		"_%s, '%s', %d, %d, OzDebugFlags, %d,\n", 
		method->string, format,
		THREAD_STACK, THREAD_PRIORITY, nargs);
#endif
	  if (cl->cl == TC_Record)
	    {
	      if (ThisClass->cl == TC_Record)
		Emit (fp, "  _oz_sub_self, &");
	      else
		Emit (fp, "(OZ_Object) self, ");
	    }

	  EmitExp (fp, exp->method_call_rec.obj);

	  if (method->type)
	    emit_args (fp, args, method->type->type_method_rec.args, method, 
		       0);
	  else
	    emit_args (fp, args, NULL, method, 0);
	  Emit (fp, "  )");
	}
      else if (exp->method_call_rec.is_mine)
	{
#if 0
	  Emit (fp, 
		"%s ((void (*)())%s%s, '%s', %d, %d, %d,\n", 
		FORK_PROCESS,
		METHOD_PREFIX, method->string, format,
		THREAD_STACK, THREAD_PRIORITY, nargs);
#else
	  Emit (fp, 
		"%s ((void (*)())%s%s, '%s', %d, %d, OzDebugFlags, %d,\n", 
		FORK_PROCESS,
		METHOD_PREFIX, method->string, format,
		THREAD_STACK, THREAD_PRIORITY, nargs);
#endif
	  Emit (fp, "  self\n");
	  if (method->type)
	    emit_args (fp, args, method->type->type_method_rec.args, method,
		       0);
	  else
	    emit_args (fp, args, NULL, method, 0);
	  Emit (fp, "  )");
	}
      else
	{
	  Emit (fp, "({\n");
	  EmitIndentDown ();
	  Emit (fp, "OZ_ProcessID _oz_pid;\n\n");
	  emit_find_method (fp, method, (char *)recv, NULL);
#if 0
	  Emit (fp, "_oz_pid = %s ((void (*)())_OZ_imp_rec.function, "
		"'%s', %d, %d, %d,\n", 
		FORK_PROCESS,
		format, THREAD_STACK, THREAD_PRIORITY, nargs);
#else
	  Emit (fp, "_oz_pid = %s ((void (*)())_OZ_imp_rec.function, "
		"'%s', %d, %d, OzDebugFlags, %d,\n", 
		FORK_PROCESS,
		format, THREAD_STACK, THREAD_PRIORITY, nargs);
#endif
	  EmitExp (fp, exp->method_call_rec.obj);
	  if (method->type)
	    emit_args (fp, args, method->type->type_method_rec.args, method, 
		       0);
	  else
	    emit_args (fp, args, NULL, method, 0);
	  Emit (fp, "  );\n");
	  Emit (fp, "%s (_OZ_Top);\n", FREE_METHOD_IMPLEMENTATION);
	  Emit (fp, "_oz_pid;\n");
	  EmitIndentUp ();
	  Emit (fp, "})");
	  return;
	}
    }
}

static void
  emit_exp (FILE *fp, OO_Expr exp)
{
  OO_List args, list;
  int qual = 0, size;
  OO_ClassType cl;

  if (!exp)
    return;

  switch (exp->id)
    {
    case TO_Symbol:
      if (exp->symbol_rec.class_part_defined)
	{
	  if (exp->symbol_rec.type->id == TO_TypeSCQF &&
	      exp->symbol_rec.type->type_scqf_rec.scqf & QF_CONST)
	    {
	      long long id 
		= exp->symbol_rec.class_part_defined->class_id_public;
	      Emit (fp, "OZ_%08x%08x_%s", 
		    (int) (id >> 32), (int) (id & 0xffffffff),
		    exp->symbol_rec.string);
	    }
	  else
	    {
	      if (CurrentMethod->type->type_method_rec.qualifier & MQ_GLOBAL &&
		  exp->symbol_rec.class_part_defined->cl == TC_Record)
		{
#if 1
		  Emit (fp, "OzLangInstanceInRecordSub(");
		  EmitVID (fp, ThisClass->class_id_public, 0);
		  Emit (fp, ", %s)", exp->symbol_rec.string);
#endif
		}
	      else
		{
		  if (exp->symbol_rec.class_part_defined->class_id_public
		      != ThisClass->class_id_public &&
		      exp->symbol_rec.type->id == TO_ClassType &&
		      exp->symbol_rec.type->class_type_rec.cl == TC_Record)
		    {
		      Emit (fp, "*(OZ");
		      EmitVID (fp, 
			       exp->symbol_rec.type
			       ->class_type_rec.class_id_public, 0);
		      Emit (fp, "Record_Rec *) ");
		    }

		  if (ThisClass->cl == TC_Object)
		    {
		      if (exp->symbol_rec.class_part_defined->class_id_public
			  == ThisClass->class_id_public)
			{
			  Emit (fp, "OZ_InstanceVariable_");
			  EmitVID (fp, ThisClass->class_id_implementation, 0);
			  Emit (fp, "(%s)", exp->symbol_rec.string);
			}
		      else if (exp->symbol_rec.class_part_defined->symbol)
			{
			  Emit (fp, "OZ_InstanceVariable_");
			  EmitClassName (fp, 
					 exp->symbol_rec.class_part_defined
					 ->symbol->string);
			  Emit (fp, "(%s)", exp->symbol_rec.string);
			}
		      else
			{
			  Emit (fp, "OzLangInstance (");
			  EmitVID (fp, ThisClass->class_id_implementation, 0);
			  Emit (fp, ", ");
			  EmitVID (fp, exp->symbol_rec.class_part_defined
				   ->class_id_protected, 0);
			  Emit (fp, ", %d, %s)",
				exp->symbol_rec.class_part_defined
				->class_id_suffix,
				exp->symbol_rec.string);
			}
		    }
		  else
		    {
		      Emit (fp, "OZ_InstanceVariable_");
		      EmitVID (fp, ThisClass->class_id_public, 0);
		      Emit (fp, "(%s)", exp->symbol_rec.string);
		    }
		}
	    }
	}

      else if (exp->symbol_rec.is_arg &&
	       exp->symbol_rec.type->id == TO_ClassType &&
	       exp->symbol_rec.type->class_type_rec.cl == TC_Record)
	{
	  if (CurrentMethod->type->type_method_rec.qualifier & MQ_GLOBAL)
	    Emit (fp, "%s->data", exp->symbol_rec.string);
	  else
	    Emit (fp, "(*%s)", exp->symbol_rec.string);
	}

      else if (!strcmp (exp->symbol_rec.string, "self") &&
	       ThisClass->cl == TC_Record)
	Emit (fp, "(*%s)", exp->symbol_rec.string);

      else
	Emit (fp, "%s", exp->symbol_rec.string);
      break;
    case TO_Constant:
      if (!strcmp (exp->constant_rec.string, "cell"))
	Emit (fp, "%s (0)", GET_OID);
      else if (!strcmp (exp->constant_rec.string, "oid"))
	Emit (fp, "%s (self)", GET_OID);
      else if (exp->constant_rec.type->id == TO_TypeArray)
	Emit (fp, "OzLangString (%s)", exp->constant_rec.string);
      else
	Emit (fp, "%s", exp->constant_rec.string);
      break;
    case TO_IncDec:
      emit_exp (fp, exp->inc_dec_rec.lvalue);
      Emit (fp, "%s", op_str [exp->inc_dec_rec.op].str);
      break;
    case TO_Unary:
      switch (exp->unary_rec.op)
	{
	case OP_PARE:
	  Emit (fp, "(");
	  emit_exp (fp, exp->unary_rec.expr);
	  Emit (fp, ")");
	  break;
	case OP_LENGTH:
	  Emit (fp, "OzLangArrayLength (");
	  emit_exp (fp, exp->unary_rec.expr);
	  Emit (fp, ")");
	  break;
	default:
	  Emit (fp, "%s", op_str [exp->unary_rec.op].str);
	  emit_exp (fp, exp->unary_rec.expr);
	  break;
	}
      break;
    case TO_Binary:
      if (exp->binary_rec.op == OP_NARROW)
	{
	  char *vid = GetVID (exp->binary_rec.expr1->symbol_rec.string, 0);
	  int qual = 0;

	  GetClassType (exp->binary_rec.expr2, &qual);
	  if (qual & SC_GLOBAL)
	    {
	      emit_exp (fp, exp->binary_rec.expr2);
	    }
	  else
	    {
	      Emit (fp, "OzLangNarrowToClass (");
	      emit_exp (fp, exp->binary_rec.expr2);
	      Emit (fp, ", 0x%sLL)", vid);
	    }
	}
      else
	{
	  emit_exp (fp, exp->binary_rec.expr1);
	  Emit (fp, " %s ", op_str[exp->binary_rec.op].str);
	  emit_exp (fp, exp->binary_rec.expr2);
	}
      break;
    case TO_Comma:
      list = exp->comma_rec.expr_list;
      Emit (fp, "( ");
      while (list)
	{
	  emit_exp (fp, (OO_Expr) list->car);
	  if ((list = &list->cdr->list_rec))
	    Emit (fp, ", ");
	}
      Emit (fp, ")");
      break;
    case TO_Comma2:
      list = exp->comma_rec.expr_list;
      Emit (fp, "{ ");
      while (list)
	{
	  emit_exp (fp, (OO_Expr) list->car);
	  if ((list = &list->cdr->list_rec))
	    Emit (fp, ", ");
	}
      Emit (fp, " }");
      break;
    case TO_ArithCompare:
      emit_exp (fp, exp->arith_compare_rec.expr1);
      Emit (fp, " %s ", op_str [exp->arith_compare_rec.op].str);
      emit_exp (fp, exp->arith_compare_rec.expr2);
      break;
    case TO_EqCompare:
      emit_exp (fp, exp->eq_compare_rec.expr1);
      Emit (fp, " %s ", op_str [exp->eq_compare_rec.op].str);
      emit_exp (fp, exp->eq_compare_rec.expr2);
      break;
    case TO_Assignment:
      if (exp->assignment_rec.lvalue->id == TO_Unary &&
	  exp->assignment_rec.lvalue->unary_rec.op == OP_LENGTH)
	{
	  emit_array_alloc (fp, exp);
	}
      else
	{
	  int check;
	  OO_Type type = exp->assignment_rec.lvalue->expr_common_rec.type;

	  emit_exp (fp, exp->assignment_rec.lvalue);
	  if (exp->assignment_rec.op != OP_EQ)
	    {
	      Emit (fp, " %s", op_str [exp->assignment_rec.op].str);
	      Emit (fp, "= ");
	    }
	  else
	      Emit (fp, " = ");

	  if (CheckSimpleType (exp->assignment_rec.expr->expr_common_rec.type,
			       TC_Zero) == TYPE_OK)
	    {
	      if (type->id == TO_TypeSCQF && 
		  type->type_scqf_rec.scqf & SC_GLOBAL)
		{
		  Emit (fp, "0LL");
		  break;
		}
	      else if (type->id == TO_ClassType &&
		       type->class_type_rec.cl == TC_Record)
		{
		  Emit (fp, "({\n");
		  EmitIndentDown ();

		  Emit (fp, "OZ");
		  EmitVID (fp, type->class_type_rec.class_id_public, 0);
#if 0
		  Emit (fp, "Record_Rec _oz_init;\n");
		  Emit (fp, "OzMemset (&_oz_init, 0, sizeof (OZ");
		  EmitVID (fp, type->class_type_rec.class_id_public, 0);
		  Emit (fp, "Record_Rec));\n");
#else
		  Emit (fp, "Record_Rec _oz_init = ");
		  EmitRecordZeroInit (fp, &type->class_type_rec);
		  Emit (fp, ";\n");
#endif
		  Emit (fp, "_oz_init;\n");

		  EmitIndentUp ();
		  Emit (fp, "})");
		  break;
		}
	    }

	  if (CheckSimpleType (type, TC_Condition) > TYPE_NG)
	      {
	      OO_Expr e = exp->assignment_rec.expr;
	      OO_Expr le = exp->assignment_rec.lvalue;
	      
	      if (le->id == TO_ArrayReference ||
		  (le->id == TO_Symbol && le->symbol_rec.class_part_defined))
		{
		  if (e->id != TO_ArrayReference &&
		      !(e->id == TO_Symbol && 
			e->symbol_rec.class_part_defined))
		    Emit (fp, "*");
		}
	      else 
		{
		  if (e->id == TO_ArrayReference ||
		      (e->id == TO_Symbol && e->symbol_rec.class_part_defined))
		    Emit (fp, "&");
		}
	      
	      emit_exp (fp, e);
	      break;
	    }

	  else if (exp->assignment_rec.expr->id == TO_Constant)
	    check = 0;

	  else
	    check = CheckType (exp->assignment_rec.lvalue
			       ->expr_common_rec.type,
			       exp->assignment_rec.expr->expr_common_rec.type,
			       0, 1);

	  if (check == TYPE_OK)
	    emit_exp (fp, exp->assignment_rec.expr);

	  else if (check > TYPE_OK)
	    {
	      OO_ClassType clp, cl;
	      int qual;

	      clp = GetClassType (exp->assignment_rec.lvalue, &qual);
	      if (qual & SC_GLOBAL)
		emit_exp (fp, exp->assignment_rec.expr);
	      else
		{
		  cl = GetClassType (exp->assignment_rec.expr, &qual);

		  if (cl && clp)
		    {
		      EmitAsClassOf (fp, clp->class_id_public,
				     clp->class_id_suffix,
				     cl->class_id_public,
				     exp->assignment_rec.expr);
		    }
		  else
		    emit_exp (fp, exp->assignment_rec.expr);
		}
	    }
	}
      break;
    case TO_Conditional:
      emit_exp (fp, exp->conditional_rec.expr1);
      Emit (fp, " ? ");
      emit_exp (fp, exp->conditional_rec.expr2);
      Emit (fp, " : ");
      emit_exp (fp, exp->conditional_rec.expr3);
      break;
    case TO_Member:
      emit_exp (fp, exp->member_rec.obj);
      Emit (fp, ".oz%s", exp->member_rec.member);
      break;
    case TO_MethodCall:
      if (exp->method_call_rec.is_constructor)
	{
	  if (exp->method_call_rec.is_global)
	    emit_global_instantiation (fp, 
				       exp->method_call_rec.obj,
				       exp->method_call_rec.obj
				       ->expr_common_rec.type
				       ->type_scqf_rec.type,
				       exp->method_call_rec.method, 
				       exp->method_call_rec.args,
				       exp->method_call_rec.om);
	  else 
	    {
	      emit_instantiation (fp, 
				  exp->method_call_rec.obj, 
				  exp->method_call_rec.method, 
				  exp->method_call_rec.args,
				  exp->method_call_rec.is_mine);
	    }
	  }
      else 
	{
	  OO_ClassType cl = exp->method_call_rec.method->class_part_defined;

	  if (exp->method_call_rec.is_global)
	    emit_global_method_call (fp,
				     exp->method_call_rec.method, 
				     exp->method_call_rec.args,
				     (char *)exp->method_call_rec.obj,
				     NULL);
	  else if ((cl && cl->cl != TC_Object) || exp->method_call_rec.is_mine)
	    emit_function_call (fp, 
				exp->method_call_rec.obj,
				exp->method_call_rec.method, 
				exp->method_call_rec.args,
				1);
	  else
	    emit_method_call (fp, 
			      exp->method_call_rec.method, 
			      exp->method_call_rec.args,
			      (char *)exp->method_call_rec.obj,
			      NULL);
	} 
	  break;
    case TO_ArrayReference:
/* for range check */
      Emit (fp, "*");
      Emit (fp, "({\n");
      EmitIndentDown ();
      Emit (fp, "OZ_Array _OZ_array = ");
      emit_exp (fp, exp->array_reference_rec.array);
      Emit (fp, ";\n");
      Emit (fp, "int _OZ_array_index = ");
      emit_exp (fp, exp->array_reference_rec.index);
      Emit (fp, ";\n");
      Emit (fp, "if (_OZ_array->head.h <= _OZ_array_index)\n");
      EmitIndentDown ();
      Emit (fp, 
	    "OzExecRaise (OzExceptionArrayRangeOverflow, 0, 0);\n");
      EmitIndentUp ();

      Emit (fp, "(");
      size = emit_array_element_type (fp, 
				      exp->array_reference_rec.array
				      ->expr_common_rec.type
				      ->type_array_rec.type,
				      0, 0);
      Emit (fp, " *) (_OZ_array->mem + _OZ_array_index * %d);\n", size);
      EmitIndentUp ();
      Emit (fp, "})\n");
/* for range check end */
      break;
    case TO_Fork:
      emit_fork_process (fp, exp->fork_rec.expr);
      break;
    case TO_Join:
      emit_type (exp->join_rec.type, 0, 1);

      if (exp->join_rec.type->id == TO_ClassType &&
	  exp->join_rec.type->class_type_rec.cl == TC_Record)
	{
	  OO_Type type = exp->join_rec.type;
	  char type_buf[256];
	  int size = GetRecordSize (&type->class_type_rec);

	  size = !size ? 1 : size;

	  strcpy (type_buf, buf);

	  Emit (fp, "({\n");
	  EmitIndentDown ();

	  Emit (fp, "%s *_OZ_result, *_OZ_result_sub;\n", type_buf);

	  Emit (fp, "_OZ_result = (%s) (int) (%s (", type_buf, JOIN_PROCESS);
	  emit_exp (fp, exp->join_rec.expr);
	  Emit (fp, ") >> 32);\n");
	  Emit (fp, ";\n");

	  Emit (fp, "_OZ_result_sub = (%s *) OzMalloc (%d);\n", type_buf, 
		size);

	  Emit (fp, "*_OZ_result_sub = *_OZ_result;\n");
	  Emit (fp, "OzFree (_OZ_result);\n");
	  Emit (fp, "*_OZ_result_sub;\n");

	  EmitIndentUp ();
	  Emit (fp, "})");
	}

      else if (exp->join_rec.type->id == TO_ClassType ||
	  exp->join_rec.type->id == TO_TypeArray)
	{
	  Emit (fp, "(%s) (int) (%s (", buf, JOIN_PROCESS);
	  emit_exp (fp, exp->join_rec.expr);
	  Emit (fp, ") >> 32)");
	}
      else 
	{
	  int cl;

	  Emit (fp, "(%s) (%s (", buf, JOIN_PROCESS);
	  emit_exp (fp, exp->join_rec.expr);

	  if (exp->join_rec.type->id == TO_TypeSCQF)
	    if (exp->join_rec.type->type_scqf_rec.type->id == TO_ClassType)
	      cl = TC_Long;
	    else
	      cl = exp->join_rec.type->type_scqf_rec.type->simple_type_rec.cl;
	  else
	    cl = exp->join_rec.type->simple_type_rec.cl;
	  switch (cl)
	    {
	    case TC_Char:
	    case TC_Short:
	    case TC_Int:
	    case TC_Float:
	      Emit (fp, ") >> 32)");
	      break;
	    case TC_Long:
	    case TC_Double:
	    case TC_Void:
	    case TC_Generic:
	      Emit (fp, "))");
	      break;
	    }
	}
      break;
    }
}

void
EmitType (FILE *fp, OO_Type type)
{
  emit_type (type, 0, 1);

  Emit (fp, "%s", buf);
}

void
EmitExp (FILE *fp, OO_Expr exp)
{
  if (Error || !fp)
    return;

  emit_exp (fp, exp);
}

void
EmitSemiColon (FILE *fp)
{
  Emit (fp, ";\n");
}

void
EmitInline (FILE *fp, char *str)
{
  int len = strlen (str);
  int i = len - 1;

  while (str [i] == ' ' || str[i] == '\n')
    i--;
  str [i + 1] = '\0';
  i = 0;
  while (str [i] == ' ' || str[i] == '\n' || str[i] == '\t')
    i++;
  if (str[i]) 	
    Emit (fp, "%s\n", &str[i]);
}

void
Emit (FILE *fp, char *format, ...)
{
  va_list pvar;

  if (!fp || Error || (!Pass && Part == PRIVATE_PART))
    return;

  va_start (pvar);
  Emit2 (fp, format, pvar);
  va_end (pvar);
}

void
EmitVID (FILE *fp, long long id, int hex)
{
  if (hex)
    Emit (fp, "0x%08x%08xLL", (int) (id >> 32), (int) (id & 0xffffffff));
  else
    Emit (fp, "%08x%08x", (int) (id >> 32), (int) (id & 0xffffffff));

}

void
EmitClassName (FILE *fp, char *name)
{
  char *p, *newname;

  p = newname = (char *) malloc (strlen (name) + 1);

  while (*name)
    {
      switch (*name)
	{
	case '<': case '>': case ' ': case ',': case '(': case ')':
	  *p++ = '_';
	  break;
	case '*':
	  *p++ = '0';
	  break;
	case '[': 
	  *p++ = 'A';
	  break;
	case ']': 
	  break;
	case '@': 
	  *p++ = 'P';
	  break;
	default:
	  *p++ = *name;
	  break;
	}
      name++;
    }
 *p = 0;

  Emit (fp, "%s", newname);
}

void
EmitTypeFormat (FILE *fp, OO_Type type)
{
  char c = get_type_char (type, 0);

  Emit (fp, "'%c'", &c); 
}

void
EmitAsClassOf (FILE *fp, 
	       ClassID part, int part_suffix, ClassID base, OO_Expr exp)
{
  Emit (fp, "OzLangAsClassOf (");
  EmitVID (fp, part, 0);
  Emit (fp, "_%d", part_suffix);
  Emit (fp, ", ");
  EmitVID (fp, base, 0);
  Emit (fp, ", ");
  emit_exp (fp, exp);
  Emit (fp, ")");
}

void
EmitRecordZeroInit (FILE *fp, OO_ClassType cl)
{
  OO_List list; 
  OO_Symbol sym;

  Emit (fp, "{ ");

  list = GetClassFromUsedList (cl->class_id_public)->public_list;
  while (list)
    {
      sym = &list->car->symbol_rec;

      if (sym->is_variable)
	{
	  if (sym->type->id == TO_ClassType)
	    EmitRecordZeroInit (fp, &sym->type->class_type_rec);
	  else
	    Emit (fp, "0");

	  Emit (fp, ", ");
	}

      list = &list->cdr->list_rec;
    }

  Emit (fp, "}");
}

