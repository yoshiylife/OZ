/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "ozc.h"
#include "emit-stmt.h"
#include "emit-common.h"
#include "emit-method.h"
#include "emit-header.h"
#include "emit-layout.h"
#include "type.h"

#include "exec-function-name.h"

static int exception_depth = 0, try_part = 0;
static loop_depth = 0;

static FILE *current_file;

static void emit_statement (OO_Statement);

static int
  emit_check ()
{
  if (!current_file || Error || !Pass)
    return 1;
  else 
    return 0;
}

static char jump_command[][10] = {
  "break",
  "continue",
};

static void
emit_after_exception ()
{
  Emit (current_file, "%s ();\n", UNREGISTER_EXCEPTION_HANDLER);
  EmitIndentUp ();
  Emit (current_file, "}\n");
  EmitIndentUp ();
}

static void
emit_exit_except (int plus)
{
  int i, depth = CurrentMethod->type->type_method_rec.qualifier & MQ_LOCKED ?
    exception_depth + plus : exception_depth;

  depth -= loop_depth;

  for (i = 0; i < depth; i++)
    Emit (current_file, "%s ();\n", UNREGISTER_EXCEPTION_HANDLER);
}

static void
  emit_return (OO_Expr exp)
{
  if (!exp)
    {
      EmitIndentDown ();
      Emit (current_file, "{\n");
      EmitIndentDown ();

      EmitFreeRecordArgs (CurrentMethod->type->type_method_rec.args);

      CheckReturnType (NULL);
      if (CurrentMethod->type->type_method_rec.qualifier & MQ_LOCKED ||
	  exception_depth)
	{
	  if (CurrentMethod->type->type_method_rec.qualifier & MQ_LOCKED)
	    if (ThisClass->cl == TC_StaticObject)
	      Emit (current_file, 
		    "%s (OzLangStaticMonitor (self));\n", EXIT_MONITOR);
	    else
	      Emit (current_file, "%s (OzLangMonitor (self));\n", 
		    EXIT_MONITOR);

	  emit_exit_except (1);
	}

      Emit (current_file, "return;\n");
      Emit (current_file, "/* not reached */\n");
      
      EmitIndentUp ();
      Emit (current_file, "}\n");
      EmitIndentUp ();
    }
  else
    {
      OO_Type type = CurrentMethod->type->type_method_rec.type;
      int result = CheckReturnType (exp);

      EmitIndentDown ();
      Emit (current_file, "{\n");
      EmitIndentDown ();
      
      EmitType (current_file, type);
      
      if (CheckSimpleType (type, TC_Condition) > TYPE_NG)
	Emit (current_file, " *");

      else if (type->id == TO_ClassType && 
	       type->class_type_rec.cl == TC_Record)
	{
	  if (CurrentMethod->type->type_method_rec.qualifier & MQ_GLOBAL)
	    Emit (current_file, "_Sub *");
	  else
	    Emit (current_file, " *");
	}

      else
	Emit (current_file, " ");

      Emit (current_file, " _OZ_return = ");
      
      if (type->id == TO_ClassType && type->class_type_rec.cl == TC_Record)
	{
	  int size = GetRecordSize (&type->class_type_rec);
	  
	  size = !size ? 1 : size;

	  Emit (current_file, "(");
	  EmitType (current_file, type);
	  
	  if (CurrentMethod->type->type_method_rec.qualifier & MQ_GLOBAL)
	    {
	      size += sizeof (OZ_HeaderRec);
	      
	      Emit (current_file, "_Sub *) OzMalloc (%d);\n", size);
	      Emit (current_file, "_OZ_return->head.e = %d;\n", size);
	      Emit (current_file, "_OZ_return->head.a = ");
	      EmitVID (current_file, type->class_type_rec.class_id_public,
		       1);
	      Emit (current_file, ";\n");
#if 1
	      Emit (current_file, "_OZ_return->head.h = -3;\n");
	      Emit (current_file, "(int) _OZ_return->head.d = OZ_RECORD;\n");
#endif
	      Emit (current_file, "_OZ_return->data = ");
	    }
	  else
	    {
	      Emit (current_file, " *) OzMalloc (%d);\n", size);
	      Emit (current_file,
		    "*_OZ_return = ");
	    }
	  
	  if (exp->id == TO_Constant &&
	      !strcmp (exp->constant_rec.string, "0"))
	    {
	      Emit (current_file, "({\n");
	      EmitIndentDown ();
	      
	      Emit (current_file, "OZ");
	      EmitVID (current_file, type->class_type_rec.class_id_public, 0);
	      Emit (current_file, "Record_Rec _oz_init = ");
	      EmitRecordZeroInit (current_file, &type->class_type_rec);
	      Emit (current_file, ";\n");
	      Emit (current_file, "_oz_init;\n");
	      
	      EmitIndentUp ();
	      Emit (current_file, "})");
	    }

	  else
	    EmitExp (current_file, exp);
	}

      else if (exp->expr_common_rec.type && 
	       exp->expr_common_rec.type->id == TO_ClassType &&
	       type->id == TO_ClassType && result == TYPE_SAFE)
	{
	  EmitAsClassOf (current_file, 
			 CurrentMethod->type->type_method_rec.type
			 ->class_type_rec.class_id_public,
			 CurrentMethod->type->type_method_rec.type
			 ->class_type_rec.class_id_suffix,
			 exp->expr_common_rec.type
			 ->class_type_rec.class_id_public,
			 exp);
	}
      else
	{
	  if (CheckSimpleType (exp->expr_common_rec.type,
			       TC_Condition) > TYPE_NG &&
	      (exp->id == TO_ArrayReference ||
	       (exp->id == TO_Symbol && 
		exp->symbol_rec.class_part_defined)))
	    Emit (current_file, "&");
	  
	  EmitExp (current_file, exp);
	}

      EmitSemiColon (current_file);

      if (CurrentMethod->type->type_method_rec.qualifier & MQ_LOCKED) 
	if (ThisClass->cl == TC_StaticObject)
	  Emit (current_file, 
		"%s (OzLangStaticMonitor (self));\n", EXIT_MONITOR);
	else
	  Emit (current_file, 
		"%s (OzLangMonitor (self));\n", EXIT_MONITOR);
      
      emit_exit_except (1);
      
      EmitFreeRecordArgs (CurrentMethod->type->type_method_rec.args);
      
      Emit (current_file, "return _OZ_return;\n");
      Emit (current_file, "/* not reached */\n");
      EmitIndentUp ();
      Emit (current_file, "}\n");
      EmitIndentUp ();
    }
}

static void
  emit_exception_handler (OO_ExceptionHandler handler)
{
  OO_ExceptionName labels = handler->labels;

  while (labels)
    {
      OO_ClassType cl = labels->name->class_part_defined;

      Emit (current_file, 
	    "else if (!%s (eh.eid, ", EID_CMP);
  
      if (cl)
	Emit (current_file, "OZ_%08x%08x_%s)", 
	      (int) (cl->class_id_public >> 32),
	      (int) (cl->class_id_public & 0xffffffff),
	      labels->name->string);
      else
	Emit (current_file, "OzException%s)", labels->name->string);

      if (labels = &labels->next->exception_name_rec)
	Emit (current_file, 
	      " ||\n         ");
    }
      
  Emit (current_file, 
	")\n");
  EmitIndentDown ();
  Emit (current_file, "{\n");
  EmitIndentDown ();

  labels = handler->labels;
  while (labels)
    {
      OO_Symbol sym;

      if (sym = labels->arg)
	{
	  EmitType (current_file, sym->type);
	  Emit (current_file, " %s = (", sym->string);
	  EmitType (current_file, sym->type);
	  if (sym->type->id == TO_TypeArray ||
	      sym->type->id == TO_ClassType)
	    Emit (current_file, ")((int) eh.param);\n\n");
	  else
	    Emit (current_file, ") eh.param;\n\n");
	}
      labels = &labels->next->exception_name_rec;
    }
  Emit (current_file, "%s (&eh);\n", HANDLING_EXCEPTION);

  emit_statement (handler->statement);

  emit_after_exception ();

  labels = handler->labels;
  while (labels)
    {
      if (labels->arg)
	labels->arg->type = NULL;
      labels = &labels->next->exception_name_rec;
    }
}

static void
  emit_case_label (OO_CaseLabel clabel)
{
  EmitIndentUp ();

  if (clabel->expr)
    {
      Emit (current_file, "case ");
      EmitExp (current_file, clabel->expr);
      Emit (current_file, ":\n");
    }
  else
    {
      Emit (current_file, "default:\n");
    }
  EmitIndentDown ();
}

static void
  emit_compound_statement (OO_CompoundStatement stmt)
{
  EmitBlockBefore (current_file);
  EmitVars (current_file, stmt->block);
  EmitStatement (stmt->statements);
  EmitBlockAfter (current_file);
}

static void
  emit_expr_statement (OO_ExprStatement stmt)
{
  EmitExp (current_file, stmt->expr);
  EmitSemiColon (current_file);
}

static void
  emit_if_statement (OO_IfStatement stmt)
{
  Emit (current_file, "if (");
  EmitExp (current_file, stmt->expr);
  Emit (current_file, ")\n");
  EmitIndentDown ();
  emit_statement (stmt->then_part);
  EmitIndentUp ();
  if (stmt->else_part)
    {
      Emit (current_file, "else\n");
      EmitIndentDown ();
      emit_statement (stmt->else_part);
      EmitIndentUp ();
    }
}

static void
  emit_while_statement (OO_WhileStatement stmt)
{
  Emit (current_file, "while (");
  EmitExp (current_file, stmt->expr);
  Emit (current_file, ")\n");
  EmitIndentDown ();

  if (exception_depth)
    loop_depth++;

  emit_statement (stmt->statement);

  if (exception_depth)
    loop_depth--;


  EmitIndentUp ();
}

static void
 emit_do_statement (OO_DoStatement stmt)
{
  Emit (current_file, "do\n");
  EmitIndentDown ();

  if (exception_depth)
    loop_depth++;

  emit_statement (stmt->statement);
  EmitIndentUp ();
  Emit (current_file, "while (");
  EmitExp (current_file, stmt->expr);
  Emit (current_file, ");\n");

  if (exception_depth)
    loop_depth--;
}

static void
  emit_for_statement (OO_ForStatement stmt)
{
  Emit (current_file, "for (");
  EmitExp (current_file, stmt->expr1);
  Emit (current_file, "; ");
  EmitExp (current_file, stmt->expr2);
  Emit (current_file, "; ");
  EmitExp (current_file, stmt->expr3);
  Emit (current_file, ")\n");
  EmitIndentDown ();

  if (exception_depth)
    loop_depth++;

  emit_statement (stmt->statement);
  EmitIndentUp ();

  if (exception_depth)
    loop_depth--;
}

static void
  emit_switch_statement (OO_SwitchStatement stmt)
{
  Emit (current_file, "switch (");
  EmitExp (current_file, stmt->expr);
  Emit (current_file, ")\n");
  EmitIndentDown ();
  Emit (current_file, "{\n");
  EmitIndentDown ();
  
  if (exception_depth)
    loop_depth++;
  
  EmitStatement (stmt->statement);

  if (exception_depth)
    loop_depth--;

  EmitIndentUp ();
  Emit (current_file, "}\n");
  EmitIndentUp ();
}

static void
  emit_jump_statement (OO_JumpStatement stmt)
{
  char *command = jump_command[stmt->op - OP_BREAK];

  if (exception_depth - loop_depth)
    {
      EmitIndentDown ();
      Emit (current_file, "{\n");
      EmitIndentDown ();
      emit_exit_except (0);
      Emit (current_file, "%s;\n", command);
      Emit (current_file, "/* not reached */\n");
      EmitIndentUp ();
      Emit (current_file, "}\n");
      EmitIndentUp ();
    }
  else
    {
      Emit (current_file, "%s;\n", command);
      Emit (current_file, "/* not reached */\n");
    }
}

static void
  emit_inline_statement (OO_InlineStatement stmt)
{
  if (BlockDepth)
    {
      EmitIndentDown ();
      Emit (current_file, "{");
      EmitIndentDown ();
    }

  Emit (current_file, "%s", stmt->statement);
  if (stmt->statement [strlen (stmt->statement)] != '\n')
    Emit (current_file, "\n");

  if (BlockDepth)
    {
      EmitIndentUp ();
      Emit (current_file, "}\n");
      EmitIndentUp ();
    }
}

static void
  emit_condition_ops (char op, OO_Expr expr1, OO_Expr expr2)
{
  switch (op)
    {
    case OP_WAIT:
      if (!expr2)
	if (ThisClass->cl == TC_StaticObject)
	  Emit (current_file, 
		"%s (OzLangStaticMonitor (self));\n", WAIT_CONDITION);
	else
	  Emit (current_file, "%s (OzLangMonitor (self), ", 
		WAIT_CONDITION);
      else
	if (ThisClass->cl == TC_StaticObject)
	  Emit (current_file, 
		"%s (OzLangStaticMonitor (self));\n", 
		WAIT_CONDITION_WITH_TIMEOUT);
	else
	  Emit (current_file, 
		"%s (OzLangMonitor (self), ", WAIT_CONDITION_WITH_TIMEOUT);
      break;
    case OP_SIGNAL:
      Emit (current_file, "%s (", SIGNAL_CONDITION);
      break;
    case OP_SIGNALALL:
      Emit (current_file, "%s (", SIGNAL_CONDITION_ALL);
    }
  
  if (expr1->id == TO_ArrayReference ||
      expr1->id == TO_Symbol && expr1->symbol_rec.class_part_defined)
    Emit (current_file, "&");
  EmitExp (current_file, expr1);

  if (expr2)
    {
      Emit (current_file, ", ");
      EmitExp (current_file, expr2);
    }

  Emit (current_file, ")");
  EmitSemiColon (current_file);
}

static void
  emit_with_expr_statement (OO_WithExprStatement stmt)
{
  switch (stmt->op)
    {
    case OP_RETURN:
      emit_return (stmt->expr1);
      break;
    case OP_DETACH:
      Emit (current_file, "%s (", DETACH_PROCESS);
      EmitExp (current_file, stmt->expr1);
      Emit (current_file, ")");
      EmitSemiColon (current_file);
      break;
    case OP_WAIT:
    case OP_SIGNAL:
    case OP_SIGNALALL:
      emit_condition_ops (stmt->op, stmt->expr1, stmt->expr2);
      break;
    case OP_KILL:
      Emit (current_file, 
	    "%s (", ABORT_PROCESS);
      EmitExp (current_file, stmt->expr1);
      Emit (current_file, ")");
      EmitSemiColon (current_file);
      break;
    case OP_RAISE:
      EmitIndentDown ();
      Emit (current_file, "{\n");
      EmitIndentDown ();

      if (stmt->expr1)
	{
	  OO_Symbol sym = (OO_Symbol) stmt->expr1;

	  if (!exception_depth || !try_part)
	    {
	      if (CurrentMethod->type->type_method_rec.qualifier & MQ_LOCKED)
		if (ThisClass->cl == TC_StaticObject)
		  Emit (current_file, 
			"%s (OzLangStaticMonitor (self));\n", EXIT_MONITOR);
		else
		  Emit (current_file, 
			"%s (OzLangMonitor (self));\n", EXIT_MONITOR);
	      
	      emit_exit_except (1);
	    }
      
	  Emit (current_file, "%s (", RAISE);

	  if (sym->class_part_defined)
	    {
	      Emit (current_file, "OZ_");
	      EmitVID (current_file, 
		       sym->class_part_defined->class_id_public, 0);
	      Emit (current_file, "_%s, ", sym->string);
	    }
	  else
	    {
	      Emit (current_file, "OzException%s, ", sym->string);
	    }

	  if (stmt->expr2)
	    {
	      OO_Expr exp = stmt->expr2;
	      OO_Expr dexp 
		= stmt->expr1 && 
		  stmt->expr1->expr_common_rec.type->type_method_rec.args ? 
		    (OO_Expr) stmt->expr1->expr_common_rec.type
		      ->type_method_rec.args->car 
			: NULL;
	      
	      if (dexp && dexp->expr_common_rec.type->id == TO_ClassType &&
		  exp->expr_common_rec.type->id == TO_ClassType &&
		  CheckClassType (&exp->expr_common_rec.type->class_type_rec, 
				  &dexp->expr_common_rec.type->class_type_rec, 
				  1, 0) < TYPE_OK)
		{
		  long long id 
		    = exp->expr_common_rec.type
		      ->class_type_rec.class_id_public;
		  long long 
		    pid = dexp->expr_common_rec.type
		      ->class_type_rec.class_id_public; 

		  EmitAsClassOf (current_file,
				 pid,
				 dexp->expr_common_rec.type
				 ->class_type_rec.class_id_suffix,
				 id,
				 exp);
		}
	      else if (exp->expr_common_rec.type->id == TO_TypeArray ||
		       exp->expr_common_rec.type->id == TO_ClassType)
		{
		  Emit (current_file, "((int) ");
		  EmitExp (current_file, exp);
		  Emit (current_file, ")");
		}
	      else
		{
		  EmitExp (current_file, exp);
		}

	      Emit (current_file, ", ");
	      EmitTypeFormat (current_file, exp->expr_common_rec.type);
	    }
	  else
	    Emit (current_file, "0, 0");

	  Emit (current_file, ");\n");
	}

      else
	{
	  if (!exception_depth)
	    FatalError ("`ReRaise' statement: `raise;' "
			"only use in exception statement.\n");

	  Emit (current_file, "%s ();\n", RE_RAISE);
	}
      
      Emit (current_file, "/* not reached */\n");
      EmitIndentUp ();
      Emit (current_file, "}\n"); 
      EmitIndentUp ();
      break;
    }
}

static void
  emit_no_expr_statement (OO_NoExprStatement stmt)
{
  switch (stmt->op)
    {
    case OP_ABORT:
      Emit (current_file, 
	    "%s (OzExceptionAbort, 0, 0);\n", RAISE);
      Emit (current_file, "/* not reached */\n");
      break;
    case OP_ABORTABLE:
      Emit (current_file, 
	    "if (%s ())\n", THREAD_SHOULD_BE_ABORTED);
      Emit (current_file, 
	    "  %s (OzExceptionAbort, 0, 0);\n", RAISE);
      Emit (current_file, "/* not reached */\n");
      break;
    }
}

static void
  emit_exception_statement (OO_ExceptionStatement stmt)
{
  OO_ExceptionHandler handlers; 
  int i = 0;

  exception_depth++;

  EmitIndentDown ();
  Emit (current_file, "{\n");
  EmitIndentDown ();
  Emit (current_file, "OZ_ExceptionRec eh;\n");

  handlers = stmt->handler_part;
  while (handlers)
    {
      OO_ExceptionName labels = handlers->labels;
      while (labels)
	{
	  i++;
	  labels = &labels->next->exception_name_rec;
	}
      handlers = &handlers->next->exception_handler_rec;
    }
  
  Emit (current_file, 
	"%s (&eh, %d);\n", INITIALIZE_EXCEPTION_HANDLER, i);

  i = 0;
  handlers = stmt->handler_part;
  while (handlers)
    {
      OO_ExceptionName labels = handlers->labels;

      for ( ; labels ; labels = &labels->next->exception_name_rec )
	{
	  OO_Symbol name = labels->name;
	  OO_ClassType cl = name->class_part_defined;

	  Emit (current_file, "%s (&eh, ", PUT_EID_INTO_CATCH_TABLE);

	  if (cl)
	    Emit (current_file, "OZ_%08x%08x_%s);\n", 
		  (int) (cl->class_id_public >> 32),
		  (int) (cl->class_id_public & 0xffffffff),
		  name->string);
	  else
	    Emit (current_file, "OzException%s);\n", 
		  name->string);
	}

      handlers = &handlers->next->exception_handler_rec;
    }

  Emit (current_file, 
	"%s (&eh);\n", REGISTER_EXCEPTION_HANDLER_FOR);

  Emit (current_file, "if (!_setjmp (eh.jmp))\n");
  EmitIndentDown ();
  Emit (current_file, "{\n");
  EmitIndentDown ();

  try_part = 1;

  emit_statement (stmt->try_part);

  try_part = 0;

  emit_after_exception ();

  handlers = stmt->handler_part;
  while (handlers)
    {
      emit_exception_handler (handlers);
      handlers = &handlers->next->exception_handler_rec;
    }
  
  Emit (current_file, "else\n");
  EmitIndentDown ();
  Emit (current_file, "{\n");
  EmitIndentDown ();
  Emit (current_file, "%s (&eh);\n", HANDLING_EXCEPTION);

  if (exception_depth == 1 && 
      CurrentMethod->type->type_method_rec.qualifier & MQ_LOCKED)
    {
      if (ThisClass->cl == TC_StaticObject)
	Emit (current_file, 
	      "%s (OzLangStaticMonitor (self));\n", EXIT_MONITOR);
      else
	Emit (current_file, 
	      "%s (OzLangMonitor (self));\n", EXIT_MONITOR);
#if 0
      Emit (current_file, "%s ();\n", UNREGISTER_EXCEPTION_HANDLER);
#endif
    }

  Emit (current_file, "%s ();\n", RE_RAISE);
  Emit (current_file, "/* not reached */\n");
  EmitIndentUp ();
  Emit (current_file, "}\n");
  EmitIndentUp ();
  EmitIndentUp ();
  Emit (current_file, "}\n"); /* end try */
  EmitIndentUp ();

  exception_depth--;
}

static void
  emit_debug_print_statement (OO_DebugPrintStatement stmt)
{
  Emit (current_file, "if (_oz_debug_flag > 0)\n");
  EmitIndentDown ();

  Emit (current_file, "%s (", DEBUG_MESSAGE);
  if (stmt->exp)
    EmitExp (current_file, stmt->exp);
  else
    Emit (current_file, "OzExecGetOID (0) & 0xffffffffff000000LL");
  Emit (current_file, ",\n");
  EmitIndentDown ();
  Emit (current_file, "%s", stmt->format);

  if (stmt->args)
    {
      OO_List list = stmt->args;

      Emit (current_file, ",\n");
      while (list)
	{
	  EmitExp (current_file, (OO_Expr) list->car);
	  if ((list = &list->cdr->list_rec))
	    Emit (current_file, ",\n");
	}
    }
  
  EmitIndentUp ();
  Emit (current_file, ");\n");

  EmitIndentUp ();
}

static void
  emit_debug_block_statement (OO_DebugBlockStatement stmt)
{
  Emit (current_file, "if (_oz_debug_flag)\n");
  EmitIndentDown ();
  emit_statement (stmt->block);
  EmitIndentUp ();
}

static void
emit_statement (OO_Statement stmt)
{
  switch (stmt->id)
    {
    case TO_ExceptionHandler:
      emit_exception_handler (&stmt->exception_handler_rec);
      break;
    case TO_CaseLabel:
      emit_case_label (&stmt->case_label_rec);
      break;
    case TO_CompoundStatement:
      emit_compound_statement (&stmt->compound_statement_rec);
      break;
    case TO_ExprStatement:
      emit_expr_statement (&stmt->expr_statement_rec);
      break;
    case TO_IfStatement:
      emit_if_statement (&stmt->if_statement_rec);
      break;
    case TO_WhileStatement:
      emit_while_statement (&stmt->while_statement_rec);
      break;
    case TO_DoStatement:
      emit_do_statement (&stmt->do_statement_rec);
      break;
    case TO_ForStatement:
      emit_for_statement (&stmt->for_statement_rec);
      break;
    case TO_SwitchStatement:
      emit_switch_statement (&stmt->switch_statement_rec);
      break;
    case TO_JumpStatement:
      emit_jump_statement (&stmt->jump_statement_rec);
      break;
    case TO_InlineStatement:
      emit_inline_statement (&stmt->inline_statement_rec);
      break;
    case TO_WithExprStatement:
      emit_with_expr_statement (&stmt->with_expr_statement_rec);
      break;
    case TO_NoExprStatement:
      emit_no_expr_statement (&stmt->no_expr_statement_rec);
      break;
    case TO_ExceptionStatement:
      emit_exception_statement (&stmt->exception_statement_rec);
      break;
    case TO_DebugPrintStatement:
      emit_debug_print_statement (&stmt->debug_print_statement_rec);
      break;
    case TO_DebugBlockStatement:
      emit_debug_block_statement (&stmt->debug_block_statement_rec);
      break;
    }
}

void 
EmitStatement (OO_Statement stmt)
{
#if 0
  if (ThisClass && ThisClass->cl == TC_Record)
    current_file = PublicOutputFileH;
  else
#endif
    current_file = PrivateOutputFileC;

  if (!stmt || emit_check ())
    return;

  while (stmt)
    {
      emit_statement (stmt);
      stmt = ((OO_StatementCommon) stmt)->next;
    }
}

void
EmitFreeRecordArgs (OO_List args)
{
  EmitIndentDown ();
  Emit (current_file, "{\n");
  EmitIndentDown ();

#if 0
  if (CurrentMethod->class_part_defined->cl == TC_Record)
    Emit (current_file, "OzFree (self);\n");
#endif

  while (args)
    {
      OO_Symbol sym = &args->car->symbol_rec;

      if (sym->type->id == TO_ClassType && 
	  sym->type->class_type_rec.cl == TC_Record)
	{
	  Emit (current_file, "if (%s) ", sym->string);
	  Emit (current_file, "OzFree (%s);\n", sym->string);
	}

      args = &args->cdr->list_rec;
    }

  EmitIndentUp ();
  Emit (current_file, "}\n");
  EmitIndentUp ();
}

