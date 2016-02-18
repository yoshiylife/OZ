/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "ozc.h"

#include "block.h"

#include "lang/school.h"

#include "emit-method.h"
#include "emit-common.h"

#include "class.h"

#include "class-list.h"

#include "exec-function-name.h"

static EmitMethods emit_methods = NULL, tail = NULL;
static int emit_methods_num = 0;
static int monitor = 0;

static int enter_method = 0;

static 
add_emit_method (OO_Symbol sym)
{
  EmitMethods buf;

  buf =  (EmitMethods) malloc (sizeof (EmitMethodsRec));
  buf->sym = sym;
  buf->next = NULL;

  if (!tail)
    tail = emit_methods = buf;
  else
    tail = tail->next = buf;
  emit_methods_num++;
}

static 
emit_method_args (FILE *fp, OO_List args, OO_Symbol method, int proto)
{
  OO_List list = (OO_List) args;
  OO_Type type;

  switch (ThisClass->cl)
    {
    case TC_Object:
      Emit (fp, "(OZ_Object ");
      break;
    case TC_StaticObject:
      Emit (fp, "(OZ_StaticObject ");
      break;
    case TC_Record:
      Emit (fp, "(OZ_Object ");

      if (!proto)
	Emit (fp, "_oz_sub_self");

      Emit (fp, ", ");

      EmitType (fp, (OO_Type) ThisClass);
      
      if (method->type->type_method_rec.qualifier & MQ_GLOBAL)
	Emit (fp, "_Sub");

      Emit (fp, " *");
      break;
    }

  if (!proto)
    Emit (fp, "self");

  while (list)
    {
      type = list->car->symbol_rec.type;

      Emit (fp, ", ");
      EmitType (fp, type);

      if (method->type->type_method_rec.qualifier & MQ_GLOBAL &&
	  type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
	Emit (fp, "_Sub");

      if (CheckSimpleType (type, TC_Condition) > TYPE_NG ||
	  (type->id == TO_ClassType && type->class_type_rec.cl == TC_Record))
        Emit (fp, " *");

      else
        Emit (fp, " ");

      if (!proto)
	Emit (fp, "%s", list->car->symbol_rec.string);
      
      list = &list->cdr->list_rec;
    }

  Emit (fp, ")");
}

static int
emit_check (FILE *fp)
{
  if (!fp || Error || Pass != 1)
    return 1;
  else 
    return 0;
}

static
emit_part (FILE *fp, long long this_vid)
{
  OO_ParentDesc parents = ThisClass->parent_desc;
  int i = ThisClass->no_parents;
  long long vid;
  OO_List list;
  int object = 1;

  while (parents)
    {
      list = parents->class->class_part_list;
      if (list)
	list = &list->cdr->list_rec;
      if (object)
	object = 0;
      else
	while (list)
	  {
	    vid = list->car->class_type_rec.class_id_public;
	    Emit (fp, "#define OZClassPart%08x%08x_%d_in_%08x%08x -%d\n",
		  (int) (vid >> 32),  
		  (int) (vid & 0xffffffff),
		  list->car->class_type_rec.class_id_suffix,
		  (int) (this_vid >> 32),  
		  (int) (this_vid & 0xffffffff),
		  i);
	    
	    vid = list->car->class_type_rec.class_id_protected;
	    Emit (fp, "#define OZClassPart%08x%08x_%d_in_%08x%08x -%d\n",
		  (int) (vid >> 32),  
		  (int) (vid & 0xffffffff),
		  list->car->class_type_rec.class_id_suffix,
		  (int) (this_vid >> 32),  
		  (int) (this_vid & 0xffffffff),
		  i--);

	    list = &list->cdr->list_rec;
	  }

      vid = parents->class->class_id_public;
      if (i == ThisClass->no_parents)
	Emit (fp, "#define OZClassPart%s_0_in_%08x%08x 1\n",
	      OBJECT_PUBLIC,
	      (int) (this_vid >> 32),  
	      (int) (this_vid & 0xffffffff));
      else
	Emit (fp, "#define OZClassPart%08x%08x_%d_in_%08x%08x -%d\n",
	      (int) (vid >> 32),  
	      (int) (vid & 0xffffffff),  
	      parents->class->class_id_suffix,
	      (int) (this_vid >> 32),  
	      (int) (this_vid & 0xffffffff),  
	      i);

      vid = parents->class->class_id_protected;
      if (i == ThisClass->no_parents)
	{
	  Emit (fp, "#define OZClassPart%s_0_in_%08x%08x 1\n",
		OBJECT_PROTECTED,
		(int) (this_vid >> 32),  
		(int) (this_vid & 0xffffffff));
	  i--;
	}
      else
	Emit (fp, "#define OZClassPart%08x%08x_%d_in_%08x%08x -%d\n",
	      (int) (vid >> 32),  
	      (int) (vid & 0xffffffff),  
	      parents->class->class_id_suffix,
	      (int) (this_vid >> 32),  
	      (int) (this_vid & 0xffffffff),  
	      i--);

      parents = parents->next;
    }

  Emit (fp, "#define OZClassPart%08x%08x_%d_in_%08x%08x 0\n",
	(int) (this_vid >> 32),  
	(int) (this_vid & 0xffffffff),  
	ThisClass->class_id_suffix,
	(int) (this_vid >> 32),  
	(int) (this_vid & 0xffffffff));
  
  if (Generic)
    Emit (fp, 
	  "#define OZClassPart0000000000000000_0_in_0000000000000000 "
	  "999\n");
}

static void
  emit_method_type_and_name (FILE *fp, OO_Symbol method, int proto_def)
{
  OO_Type type = method->type->type_method_rec.type;

  EmitType (fp, type);

  if (method->type->type_method_rec.qualifier & MQ_GLOBAL &&
      type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
    Emit (fp, "_Sub");

  if (CheckSimpleType (type, TC_Condition) > TYPE_NG ||
      (type->id == TO_ClassType && type->class_type_rec.cl == TC_Record))
    Emit (fp, " *");
  else
    Emit (fp, " ");

  if (!proto_def)
    Emit (fp, "\n");
  
  if (ThisClass->cl == TC_Object)
    Emit (fp, "%s%s ", METHOD_PREFIX, method->string);
  else
    {
      Emit (fp, "%s", METHOD_PREFIX);
      EmitVID (fp, ThisClass->class_id_public, 0);
      Emit (fp, "_%s ", method->string);
    }
}


void 
EmitFirst (FILE *fp)
{
  if (emit_check (fp))
    return;

  EmitIndentReset ();

#if 0
  if (ThisClass->cl == TC_Record)
    {
      Emit (fp, "#ifndef _OZ");
      EmitVID (fp, ThisClass->class_id_public, 0);
      Emit (fp, "P_H_\n");
      Emit (fp, "#define _OZ");
      EmitVID (fp, ThisClass->class_id_public, 0);
      Emit (fp, "P_H_\n\n");
    }
  else
    {
#endif
      Emit (fp, "#include <oz++/object.h>\n\n");
      
      Emit (fp, "static unsigned int _oz_debug;\n\n");
      
      Emit (fp, "static struct {\n");
      Emit (fp, "  unsigned int size;\n");
      Emit (fp, "  unsigned int *debugFlags;\n");
      Emit (fp, "} _OZ_DebugInfoRec = {\n");
      Emit (fp, "  sizeof (_oz_debug),\n");
      Emit (fp, "  &_oz_debug,\n");
      Emit (fp, "};\n\n");
#if 0
    }
#endif
}

void 
EmitMethodsBefore (FILE *fp)
{
  OO_ParentDesc parents;
  char vid[17];
  OO_RenameAlias ra;

  if (emit_check (fp))
    return;

  parents = ThisClass->parent_desc;

  EmitIndentReset ();

  if (ThisClass->cl == TC_Object)
    {
      sprintf (vid, "%08x%08x",
	       (int) (ThisClass->class_id_implementation >> 32),
	       (int) (ThisClass->class_id_implementation & 0xffffffff));
    }
  else
    {
      sprintf (vid, "%08x%08x",
	       (int) (ThisClass->class_id_public >> 32),
	       (int) (ThisClass->class_id_public & 0xffffffff));
    }

  Emit (fp, "#include \"");
  EmitVID (fp, ThisClass->class_id_public, 0);
  Emit (fp, "/public.h\"\n");

  if (ThisClass->cl == TC_Object)
    {
      Emit (fp, "#include \"");
      EmitVID (fp, ThisClass->class_id_protected, 0);
      Emit (fp, "/protected-all.h\"\n");
      Emit (fp, "#include \"");
      EmitVID (fp, ThisClass->class_id_implementation, 0);
      Emit (fp, "/private.h\"\n");
    }

  Emit (fp, "\n");

  while (parents)
    {
      Emit (fp, "#define OZ_InstanceVariable_");
      EmitClassName (fp, parents->class->symbol->string);
      Emit (fp, "(Var) \\\n");
      Emit (fp, "\tOzLangInstance(%s, ", vid);
      EmitVID (fp, parents->class->class_id_protected, 0);
      Emit (fp, ", %d, ## Var ##)\n", 
	    parents->class->class_id_suffix);

      ra = parents->rename_alias;
      
      while (ra)
	{
	  if (ra->kind == RA_RENAME && ra->from->type->id != TO_TypeMethod)
	    Emit (fp, "#define oz%s oz%s\n",
		  ra->to->string, ra->from->string);
	  ra = ra->next;
	}

      parents = parents->next;
    }
  
  Emit (fp, "#define OZ_InstanceVariable_");
  EmitClassName (fp, ThisClass->symbol->string);
  Emit (fp, "(Var) \\\n");

  switch (ThisClass->cl)
    {
    case TC_Object:
      Emit (fp, "\tOzLangInstance(%s, %s, %d, ## Var ##)\n\n", 
	    vid, vid, ThisClass->class_id_suffix);
      break;
    case TC_StaticObject:
      Emit (fp, "\tOzLangInstanceInStatic(%s, ## Var ##)\n\n", vid);
      break;
    case TC_Record:
      Emit (fp, "\tOzLangInstanceInRecord(%s, ## Var ##)\n\n", vid);
      break;
    }

  Emit (fp, "#define OZ_InstanceVariable_");
  if (ThisClass->cl == TC_Object)
    EmitVID (fp, ThisClass->class_id_implementation, 0);
  else
    EmitVID (fp, ThisClass->class_id_public, 0);
  Emit (fp, "(Var) \\\n");

  switch (ThisClass->cl)
    {
    case TC_Object:
      Emit (fp, "\tOzLangInstance(%s, %s, %d, ## Var ##)\n", 
	    vid, vid, ThisClass->class_id_suffix);
      break;
    case TC_StaticObject:
      Emit (fp, "\tOzLangInstanceInStatic(%s, ## Var ##)\n", vid);
      break;
    case TC_Record:
      Emit (fp, "\tOzLangInstanceInRecord(%s, ## Var ##)\n\n", vid);

#if 0
      EmitMethodsHeader (fp);
#endif
      break;
    }

  Emit (fp, "\n");
}

void 
EmitMethodsAfter ()
{
  EmitMethods method = emit_methods;
  int i = 0;

  if (emit_check (PrivateOutputFileC))
    return;

  Emit (PrivateOutputFileC, "struct {\n");
  Emit (PrivateOutputFileC, "  int number_of_entry;\n");
  Emit (PrivateOutputFileC, "  char (*func[%d])();\n", emit_methods_num);
  Emit (PrivateOutputFileC, "} _OZ_FunctionPtrTableRec = {\n");
  Emit (PrivateOutputFileC, "  %d,\n", emit_methods_num);

  while (method)
    {
      Emit (PrivateOutputFileC, "  (OZ_FunctionPtr) %s%s,\n", METHOD_PREFIX,
	    method->sym->string);
      method->sym->func_no = i++;
      method = method->next;
    }

  Emit (PrivateOutputFileC, "};\n");

  EmitImported ();
}

void 
EmitMethodsAfterInStatic ()
{
  EmitMethods method = emit_methods;

  if (emit_check (PrivateOutputFileC))
    return;

  Emit (PrivateOutputFileC, "struct {\n");
  Emit (PrivateOutputFileC, "  int number;\n");
  Emit (PrivateOutputFileC, "  struct {;\n");
  Emit (PrivateOutputFileC, "    char *function_name;\n");
  Emit (PrivateOutputFileC, "    OZ_FunctionPtr function;\n");
  Emit (PrivateOutputFileC, "  } entry[%d];\n", emit_methods_num);
  Emit (PrivateOutputFileC, "} _OZ_ExportedFunctionsRec = {\n");
  Emit (PrivateOutputFileC, "  %d,\n", emit_methods_num);

  while (method)
    {
      Emit (PrivateOutputFileC, "  \"%s", METHOD_PREFIX);
      EmitVID (PrivateOutputFileC, ThisClass->class_id_public, 0);
      Emit (PrivateOutputFileC, "_%s\",\n", method->sym->string);

      Emit (PrivateOutputFileC, "  (OZ_FunctionPtr) %s", METHOD_PREFIX);
      EmitVID (PrivateOutputFileC, ThisClass->class_id_public, 0);
      Emit (PrivateOutputFileC, "_%s,\n", method->sym->string);

      method = method->next;
    }

  Emit (PrivateOutputFileC, "};\n");

  EmitImported ();
}

void
EmitMethodsHeader (FILE *fp)
{
  OO_Symbol vars;
  int i;
  EmitMethods method = emit_methods;
  OO_Type type;

  if (ThisClass->cl == TC_Object)
    {
      Emit (fp, "\n");
      
      emit_part (fp, 
		 Part == PRIVATE_PART ? ThisClass->class_id_implementation
		 : ThisClass->class_id_public);
      Emit (fp, "\n");

      if (Part != PRIVATE_PART)
	return;
    }

  Emit (fp, "\n");

  Emit (fp, "#ifndef _OBJECT_IMAGE_COMPILE_\n\n");
  while (method)
    {
      type = method->sym->type->type_method_rec.type;

      if (ThisClass->cl == TC_Object)
	Emit (fp, "static ");
      else
	Emit (fp, "extern ");

      emit_method_type_and_name (fp, method->sym, 1);
      emit_method_args (fp, method->sym->type->type_method_rec.args, 
			method->sym, 1);

      Emit (fp, ";\n\n");

      method = method->next;
    }
  Emit (fp, "#endif _OBJECT_IMAGE_COMPILE_\n\n");
}

void 
EmitMethod (FILE *fp, OO_Symbol sym)
{
  if (!Pass && sym->access <= Part)
    add_emit_method (sym);

  if (emit_check (fp))
    return;

  if (ThisClass->cl == TC_Object)
    Emit (fp, "static ");

  emit_method_type_and_name (fp, sym, 0);
  emit_method_args (fp, sym->type->type_method_rec.args, sym, 0);

  Emit (fp, "\n");

  if (sym->type->type_method_rec.qualifier & MQ_LOCKED)
    monitor = 1;
}

void
EmitMethodAfter (FILE *fp)
{
  if (emit_check (fp))
    return;

  EmitIndentUp ();

  EmitFreeRecordArgs (CurrentMethod->type->type_method_rec.args);

  Emit (fp, "}\n");
  Emit (fp, "\n");

  enter_method = 0;
}

void 
EmitVars (FILE *fp, OO_Block block)
{
  OO_Symbol vars;

  if (emit_check (fp))
    return;

  vars = block->vars;
  while (vars)
    {
      EmitType (fp, vars->type);
      Emit (fp, " ");

      if (CheckSimpleType (vars->type, TC_Generic) == TYPE_OK)
	{
	  Emit (fp, "%s", vars->string);
	  if (vars->init)
	    {
	      Emit (fp, " = ");
	      EmitExp (fp, (OO_Expr) vars->init);
	    }
	}

      else if (CheckSimpleType (vars->type, TC_Condition) < TYPE_OK)
	{
          Emit (fp, "%s", vars->string);
          if (vars->init)
	    {
	      OO_Expr exp = (OO_Expr) vars->init;

	      Emit (fp, " = ");
	      if (vars->type->id == TO_ClassType &&
		  vars->type->class_type_rec.cl == TC_Object &&
		  exp->expr_common_rec.type->id == TO_ClassType &&
		  CheckClassType (&vars->type->class_type_rec,
				  &exp->expr_common_rec.type
				  ->class_type_rec, 1, 0) < TYPE_OK)
		{
		  EmitAsClassOf (fp,
				 vars->type->class_type_rec.class_id_public,
				 vars->type->class_type_rec.class_id_suffix,
				 exp->expr_common_rec.type
				 ->class_type_rec.class_id_public,
				 (OO_Expr) vars->init);
		}
	      else if (exp->id == TO_Constant && 
		       !strcmp (exp->constant_rec.string, "0"))
		{
		  if (vars->type->id == TO_ClassType &&
		      vars->type->class_type_rec.cl == TC_Record)
		    EmitRecordZeroInit (fp, &vars->type->class_type_rec); 
		  else if (vars->type->id == TO_TypeSCQF &&
			   vars->type->type_scqf_rec.scqf & SC_GLOBAL)
		    Emit (fp, "0LL");
		  else 
		    Emit (fp, "0");
		}
	      else
		EmitExp (fp, (OO_Expr) vars->init);
	    }
	  else if (vars->type->id == TO_TypeArray || 
		   vars->type->id == TO_TypeProcess ||
		   (vars->type->id == TO_ClassType && 
		    vars->type->class_type_rec.cl != TC_Record) ||
		   (vars->type->id == TO_TypeSCQF && 
		    vars->type->type_scqf_rec.scqf & SC_GLOBAL))                     	    Emit (fp, " = 0");
        }

      else
	{
	  if (vars->init)
	    {
	      Emit (fp, "*%s = &", vars->string);
	      EmitExp (fp,  (OO_Expr) vars->init);
	    }
	  else
	    Emit (fp, 
		  "_OZ_%s, *%s = ({%s (&_OZ_%s, 1);"
		  "&_OZ_%s;})",
		  vars->string, vars->string, INITIALIZE_CONDITION,
		  vars->string, vars->string);
	}
      Emit (fp, ";\n");

      if (!(vars = vars->link))
	Emit (fp, "\n");
    }
}
  
void 
EmitBlockBefore (FILE *fp)
{
  if (emit_check (fp))
    return;

  Emit (fp, "{\n");
  EmitIndentDown ();

  if (!enter_method)
    {
      enter_method = 1;
      
      Emit (fp, "int _oz_debug_flag;\n");

      if (ThisClass->cl == TC_Object)
	{
	  Emit (fp, "OZ_Object _oz_this;\n\n");

	  Emit (fp, 
		"_oz_this = OzLangConvertToClass (self, ");
	  EmitVID (fp, ThisClass->class_id_public, 1);
	  Emit (fp, 
		");\n");
	  Emit (fp, "_oz_debug_flag = OzDebugCheck (_oz_this, ");
	  EmitVID (fp, ThisClass->class_id_public, 1);
	  Emit (fp, ",\n");
	  EmitIndentDown ();

	  switch (CurrentMethod->access)
	    {
	    case CONSTRUCTOR_PART:
	      Emit (fp, "OZ_AC_CONSTRUCTOR, ");
	      break;
	    case PUBLIC_PART:
	      Emit (fp, "OZ_AC_PUBLIC, ");
	      break;
	    case PROTECTED_PART:
	      Emit (fp, "OZ_AC_PROTECTED, ");
	      break;
	    case PRIVATE_PART:
	      Emit (fp, "OZ_AC_PRIVATE, ");
	      break;
	    }

	  Emit (fp, "self);\n");
	  
	  EmitIndentUp ();

	  Emit (fp, "if (!_oz_this)\n");
	  EmitIndentDown ();
	  Emit (fp, "%s (OzExceptionTypeCorrectionFailed, 0, 0);\n", RAISE);
	  EmitIndentUp ();

	  Emit (fp, "self = _oz_this;\n");
	}
      else 
	{
	  if (ThisClass->cl == TC_Record)
	    Emit (fp, 
		  "_oz_debug_flag = OzDebugCheck ((OZ_Object) _oz_sub_self, ");
	  else
	    Emit (fp, "\n_oz_debug_flag = OzDebugCheck ((OZ_Object) self, ");
	  EmitVID (fp, ThisClass->class_id_public, 1);
	  Emit (fp, ",\n");
	  EmitIndentDown ();

	  if (ThisClass->cl == TC_Record)
	    {
	      Emit (fp, "OZ_AC_RECORD, ");
	      Emit (fp, "self);\n");
	    }
	  else
	    {
	      switch (CurrentMethod->access)
		{
		case CONSTRUCTOR_PART:
		  Emit (fp, "OZ_AC_CONSTRUCTOR, ");
		  break;
		case PUBLIC_PART:
		  Emit (fp, "OZ_AC_PUBLIC, ");
		  break;
		case PRIVATE_PART:
		  Emit (fp, "OZ_AC_PRIVATE, ");
		  break;
		}
	      Emit (fp, "NULL);\n");
	    }
	  
	  EmitIndentUp ();
	}
      
      Emit (fp, "{\n");
      EmitIndentDown ();
    }

  if (monitor >= 1)
    {
      if (monitor == 1)
	{
	  if (ThisClass->cl == TC_StaticObject)
	    Emit (fp, 
		  "%s (OzLangStaticMonitor (self));\n", ENTER_MONITOR);
	  else
	    Emit (fp, 
		  "%s (OzLangMonitor (self));\n", ENTER_MONITOR);
	  EmitIndentDown ();
	  Emit (fp, "{\n");
	  EmitIndentDown ();

	  if (CheckSimpleType (CurrentMethod->type->type_method_rec.type,
			       TC_Void) < TYPE_OK)
	    {
	      EmitType (fp, 
			CurrentMethod->type->type_method_rec.type);
	      Emit (fp, " _OZ_return;\n");
	    }

	  Emit (fp, "OZ_ExceptionRec eh;\n\n");

	  Emit (fp, 
		"%s (&eh, 0);\n", 
		INITIALIZE_EXCEPTION_HANDLER);
	  Emit (fp, 
		"%s (&eh);\n",
		REGISTER_EXCEPTION_HANDLER_FOR);
	  Emit (fp, "if (!_setjmp (eh.jmp))\n");
	  EmitIndentDown ();
	  Emit (fp, "{\n");
	  EmitIndentDown ();
	}
      monitor++;
    }
}

void 
EmitBlockAfter (FILE *fp)
{
  if (emit_check (fp))
    return;

  if (monitor)
    {
      if (--monitor == 1)
	{
	  EmitIndentUp ();
	  Emit (fp, "}\n");
	  EmitIndentUp ();
	  Emit (fp, 
		"else\n");
	  EmitIndentDown ();
	  Emit (fp, "{\n");
	  EmitIndentDown ();
	  if (ThisClass->cl == TC_StaticObject)
	    Emit (fp, 
		  "%s (OzLangStaticMonitor (self));\n", EXIT_MONITOR);
	  else
	    Emit (fp, 
		  "%s (OzLangMonitor (self));\n", EXIT_MONITOR);
	  Emit (fp, "%s ();\n", RE_RAISE);
	  Emit (fp, "/* not reached */\n");
	  EmitIndentUp ();
	  Emit (fp, "}\n");
	  EmitIndentUp ();
	  Emit (fp, "%s ();\n", UNREGISTER_EXCEPTION_HANDLER);

	  EmitIndentUp ();
	  Emit (fp, "}\n");
	  EmitIndentUp ();
	  if (ThisClass->cl == TC_StaticObject)
	    Emit (fp, 
		  "%s (OzLangStaticMonitor (self));\n", EXIT_MONITOR);
	  else
	    Emit (fp, 
		  "%s (OzLangMonitor (self));\n", EXIT_MONITOR);
	  
	  monitor = 0;
	}
    }

  EmitIndentUp ();
  Emit (fp, "}\n");
}


