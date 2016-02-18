/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "ozc.h"
#include "type.h"
#include "stmt.h"

static OO_StatementCommon current_stmt = NULL;

static void
  debug_print_error (char c, int n)
{
  switch (c)
    {
    case 'd': case 'i': case 'o': case 'u': case 'x': 
    case 'X': 
      FatalError ("argument %d must be integer\n", n);
      break;
      
    case 'f': case 'e': 
      FatalError ("argument %d must be floating\n", n);
      break;
      
    case 'c': 
      FatalError ("argument %d must be `char'\n", n);
      break;
      
    case 'p': 
      FatalError ("argument %d must be `condition', "
		  "array or user defined type\n", n);
      break;
      
    case 'S': 
      FatalError ("argument %d must be array of `char'\n", n);
      break;
      
    case 'P': 
      FatalError ("argument %d must be process\n", n);
      break;
      
    case 'O': 
      FatalError ("argument %d must be global object\n", n);
      break;
      
    case 'H':
      FatalError ("argument %d must be local object or array\n", n);
      break;
      
    case 'V':
      FatalError ("argument %d must be local object\n", n);
      break;
      
    case 'C': 
      FatalError ("argument %d must be local object\n", n);
      break;
      
    case '*':
      FatalError ("argument %d must be `int'\n", n);
      break;

    default:
      FatalError ("need argument\n");
    }
}

static void
  check_format_and_args (char *fmt, OO_List args)
{
  char *p = fmt;
  int searching;
  OO_Type type;
  int n = 0;

  fmt[strlen (fmt)] = 0;
  p = ++fmt;

  while (*p)
    {
      if (*p == '%')
	{
	  searching = 1;

	  p++;
	  while (searching) 
	    {
	      switch (*p)
		{
		case 'd': case 'i': case 'o': case 'u': case 'x':
		case 'X': case 'f': case 'e': case 'c': case '%':
		case 'S': case 'P': case 'O': case 'V': case 'C': 
		case 'A': case 'T': case '*':
		  searching = 0;
		  break;
		default:
		  p++;
		}
	    }

	  if (*p != '%')
	    {
	      if (args && args->car)
		{
		  type = ((OO_Expr) args->car)->expr_common_rec.type;
		  args = &args->cdr->list_rec;
		}
	      else
		type = NULL;

	      n++;
	      if (!type)
		{
		  debug_print_error (0, n);
		  p++;
		  continue;
		}
	    }

	  switch (*p)
	    {
	    case 'd': case 'i': case 'o': case 'u': case 'x': 
	    case 'X': 
	      if (type->id == TO_TypeSCQF)
		type = type->type_scqf_rec.type;

	      if (type->id != TO_SimpleType ||
		  (type->simple_type_rec.cl != TC_Zero &&
		   type->simple_type_rec.cl != TC_Char &&
		   type->simple_type_rec.cl != TC_Int &&
		   type->simple_type_rec.cl != TC_Short &&
		   type->simple_type_rec.cl != TC_Long))
		debug_print_error (*p, n);
	      break;
		  
	    case 'f': case 'e': 
	      if (type->id != TO_SimpleType ||
		  (type->simple_type_rec.cl != TC_Zero &&
		   type->simple_type_rec.cl != TC_Float &&
		   type->simple_type_rec.cl != TC_Double))
		debug_print_error (*p, n);
	      break;
	      
	    case 'c': 
	      if (type->id == TO_TypeSCQF)
		type = type->type_scqf_rec.type;

	      if (type->id != TO_SimpleType)
		debug_print_error (*p, n);

	      else if (type->simple_type_rec.cl != TC_Char &&
		       (type->simple_type_rec.cl == TC_Short ||
			type->simple_type_rec.cl == TC_Int))
		Warning ("argument %d shuold be `char'\n", n);

	      break;

	    case '%':
	      break;

#if 0
	    case 'p': 
	      if (type->id != TO_ClassType &&
		  type->id != TO_TypeArray &&
		  (type->id != TO_SimpleType && 
		   type->simple_type_rec.cl != TC_Condition))
		debug_print_error (*p, n);
	      break;
#endif

	    case 'S': 
	      if (type->id != TO_TypeArray ||
		  CheckSimpleType (type->type_array_rec.type, 
				   TC_Char) == TYPE_NG)
		debug_print_error (*p, n);
	      break;

	    case 'P': 
	      if (type->id != TO_TypeProcess)
		debug_print_error (*p, n);
	      break;
	      
	    case 'O': 
	      if (type->id != TO_TypeSCQF ||
		  type->type_scqf_rec.type->id != TO_ClassType)
		debug_print_error (*p, n);
	      break;

#if 0
	    case 'H':
	      if (type->id != TO_ClassType &&
		  type->id != TO_TypeArray)
		debug_print_error (*p, n);
#endif
	      break;

	    case 'V': case 'C': case 'A': case 'T':
	      if (type->id != TO_ClassType || 
		  type->class_type_rec.cl != TC_Object)
		debug_print_error (*p, n);
	      break;

	    case '*':
	      if (CheckSimpleType (type, TC_Int) == TYPE_NG)
		debug_print_error (*p, n);
	      break;
	    }
	}

      p++;
    }
}

static void
  destroy_exception_names (OO_ExceptionName names)
{
  OO_ExceptionName buf;

  while (names)
    {
      buf = names;
      free (buf);
      names = &names->next->exception_name_rec;
    }
}

static void
  destroy_exception_handlers (OO_ExceptionHandler handlers)
{
  OO_ExceptionHandler buf;
  OO_Statement stmt;

  while (handlers)
    {
      destroy_exception_names (handlers->labels);

      stmt = handlers->statement;
      while (stmt)
	{
	  DestroyStatement (stmt);
	  stmt = stmt->statement_common_rec.next;
	}
      buf = handlers;
      free (buf);
      handlers = &handlers->next->exception_handler_rec;
    }
}

static void
  append_stmt (OO_Statement stmt)
{
  if (current_stmt)
    current_stmt->next = stmt;

  current_stmt = (OO_StatementCommon) stmt;
}

OO_Statement
CreateExceptionName (OO_Symbol name, OO_Symbol arg)
{
  OO_ExceptionName buf 
    = (OO_ExceptionName) malloc (sizeof (OO_ExceptionName_Rec));

  buf->id == TO_ExceptionName;
  buf->name = name;
  buf->arg = arg;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
CreateExceptionHandler ()
{
  OO_ExceptionHandler buf = (OO_ExceptionHandler)
    malloc (sizeof (OO_ExceptionHandler_Rec));

  buf->id = TO_ExceptionHandler;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
SetExceptionNames (OO_ExceptionHandler buf, OO_ExceptionName labels)
{
  buf->labels = labels;
  buf->next = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
SetExceptionHandler (OO_ExceptionHandler buf, OO_Statement stmt)
{
  OO_ExceptionName labels = buf->labels;

  buf->statement = stmt;
  buf->next = NULL;

  while (labels)
    {
      if (labels->arg)
	UpBlock ();

      labels = &labels->next->exception_name_rec;
    }

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
CreateCaseLabel (OO_Expr expr)
{
  OO_CaseLabel buf = (OO_CaseLabel)
    malloc (sizeof (OO_CaseLabel_Rec));

  buf->id = TO_CaseLabel;
  buf->expr = expr;
  buf->next = NULL;

  if (Pass && Mode == NORMAL && expr)
    if (CheckTypeID (expr->expr_common_rec.type, TO_SimpleType) 
	< TYPE_OK ||
	(CheckSimpleType (expr->expr_common_rec.type, TC_Zero) 
	 == TYPE_NG &&
	 (CheckSimpleType (expr->expr_common_rec.type, TC_Condition) 
	  >= TYPE_OK ||
	  CheckSimpleType (expr->expr_common_rec.type, TC_Float) 
	  >= TYPE_OK ||
	  CheckSimpleType (expr->expr_common_rec.type, TC_Double) 
	  >= TYPE_OK ||
	  CheckSimpleType (expr->expr_common_rec.type, TC_Void) 
	  >= TYPE_OK)))
      FatalError ("the type of this expression in `case' label is illegal\n");
  
  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
CreateCompoundStatement (OO_Block block)
{
  OO_CompoundStatement buf;

  if (!Pass || Mode != NORMAL)
    return NULL;

  buf = (OO_CompoundStatement)
    malloc (sizeof (OO_CompoundStatement_Rec));

  buf->id = TO_CompoundStatement;
  buf->block = block;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  buf->prev = (OO_Statement) current_stmt;
  current_stmt = NULL;

  return (OO_Statement) buf;
}


OO_Statement
SetCompoundStatement (OO_CompoundStatement buf, OO_Statement stmt)
{
  if (!buf)
    return NULL;

  buf->statements = stmt;

  current_stmt = (OO_StatementCommon) buf->prev;

  return (OO_Statement) buf;
}

OO_Statement
CreateExprStatement (OO_Expr expr)
{
  OO_ExprStatement buf = (OO_ExprStatement)
    malloc (sizeof (OO_ExprStatement_Rec));

  buf->id = TO_ExprStatement;
  buf->expr = expr;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
CreateIfStatement (OO_Expr expr)
{
  OO_IfStatement buf = (OO_IfStatement)
    malloc (sizeof (OO_IfStatement_Rec));

  buf->id = TO_IfStatement;
  buf->expr = expr;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
SetIfStatement (OO_IfStatement buf, 
		OO_Statement then_part, OO_Statement else_part)
{
  buf->then_part = then_part;
  buf->else_part = else_part;
  buf->next  = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
CreateWhileStatement (OO_Expr expr)
{
  OO_WhileStatement buf = (OO_WhileStatement)
    malloc (sizeof (OO_WhileStatement_Rec));

  buf->id = TO_WhileStatement;
  buf->expr = expr;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
SetWhileStatement (OO_WhileStatement buf, OO_Statement stmt)
{
  buf->statement = stmt;
  buf->next = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
CreateDoStatement ()
{
  OO_DoStatement buf = (OO_DoStatement)
    malloc (sizeof (OO_DoStatement_Rec));

  buf->id = TO_DoStatement;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
SetDoStatement (OO_DoStatement buf, OO_Statement stmt, OO_Expr expr)
{
  buf->statement = stmt;
  buf->expr = expr;
  buf->next = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
CreateForStatement (OO_Expr exp1, OO_Expr exp2, OO_Expr exp3)
{
  OO_ForStatement buf = (OO_ForStatement)
    malloc (sizeof (OO_ForStatement_Rec));

  buf->id = TO_ForStatement;
  buf->expr1 = exp1;
  buf->expr2 = exp2;
  buf->expr3 = exp3;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
SetForStatement (OO_ForStatement buf, OO_Statement stmt)
{
  buf->statement = stmt;
  buf->next = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
CreateSwitchStatement (OO_Expr expr)
{
  OO_SwitchStatement buf = (OO_SwitchStatement)
    malloc (sizeof (OO_SwitchStatement_Rec));

  buf->id = TO_SwitchStatement;
  buf->expr = expr;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
SetSwitchStatement (OO_SwitchStatement buf, OO_Statement stmt)
{
  buf->statement = stmt;
  buf->next = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
CreateJumpStatement (char op)
{
  OO_JumpStatement buf = (OO_JumpStatement)
    malloc (sizeof (OO_JumpStatement_Rec));

  buf->id = TO_JumpStatement;
  buf->op = op;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
CreateInlineStatement (char *lang_name, char *stmt)
{
  OO_InlineStatement buf = (OO_InlineStatement)
    malloc (sizeof (OO_InlineStatement_Rec));

  buf->id = TO_InlineStatement;
  buf->lang_name = lang_name;
  buf->statement = stmt;
  buf->next = NULL;
  
  if (strcmp (lang_name, "\"C\""))
    FatalError ("`inline' must be used with `\"C\"'\n");

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
CreateWithExprStatement (char op, OO_Expr expr1, OO_Expr expr2)
{
  OO_WithExprStatement buf = (OO_WithExprStatement)
    malloc (sizeof (OO_WithExprStatement_Rec));

  buf->id = TO_WithExprStatement;
  buf->expr1 = expr1;
  buf->expr2 = expr2;
  buf->op = op;
  buf->next = NULL;

  if (op == OP_WAIT || op == OP_SIGNAL || op == OP_SIGNALALL)
    {
      if (!(CurrentMethod->type->type_method_rec.qualifier & MQ_LOCKED))
	FatalError ("this method: `%s' must be `locked'\n", 
		    CurrentMethod->string);
    }

  else if (op == OP_RAISE)
    {
      if (expr1)
	{
	  if (expr2)
	    {
	      OO_Expr dexp =
		expr1->expr_common_rec.type->type_method_rec.args ? 
		(OO_Expr) expr1->expr_common_rec.type
		  ->type_method_rec.args->car : NULL;
	      
	      if (dexp)
		{
		  if (CheckType (dexp->expr_common_rec.type, 
				 expr2->expr_common_rec.type, 0, 0) < TYPE_OK)
		    FatalError ("illegal type of the argument "
				"in this exception: `%s'\n", 
				expr1->symbol_rec.string);
		}
	      else
		FatalError ("this exception: `%s' needs argument\n",
			    expr1->symbol_rec.string);
	    }

	}
    }

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
CreateNoExprStatement (char op)
{
  OO_NoExprStatement buf = (OO_NoExprStatement)
    malloc (sizeof (OO_NoExprStatement_Rec));

  buf->id = TO_NoExprStatement;
  buf->op = op;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
CreateExceptionStatement ()
{
  OO_ExceptionStatement buf = (OO_ExceptionStatement)
    malloc (sizeof (OO_ExceptionStatement_Rec));

  buf->id = TO_ExceptionStatement;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement
SetExceptionTry (OO_ExceptionStatement buf, OO_Statement try_part)
{
  buf->try_part = try_part;
  buf->next = NULL;

  return (OO_Statement) buf;
}

OO_Statement
SetExceptionHandlerList (OO_ExceptionStatement buf, 
			 OO_ExceptionHandler handlers)
{
  buf->handler_part = handlers;
  buf->next = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

OO_Statement
  CreateDebugPrintStatement (OO_Expr exp, char *format, OO_List args)
{
  OO_DebugPrintStatement buf = (OO_DebugPrintStatement)
    malloc (sizeof (OO_DebugPrintStatement_Rec));

  buf->id = TO_DebugPrintStatement;

  buf->exp = exp;
  buf->format = format;
  buf->args = args;

  if (Pass && Mode == NORMAL)
    check_format_and_args (format, args);

  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement 
  CreateDebugBlockStatement ()
{
  OO_DebugBlockStatement buf = (OO_DebugBlockStatement)
    malloc (sizeof (OO_DebugBlockStatement_Rec));

  buf->id = TO_DebugBlockStatement;
  buf->next = NULL;

  append_stmt ((OO_Statement) buf);
  return (OO_Statement) buf;
}

OO_Statement 
  SetDebugBlock (OO_DebugBlockStatement buf, OO_Statement block)
{
  buf->block = block;
  buf->next = NULL;

  current_stmt = (OO_StatementCommon) buf;
  return (OO_Statement) buf;
}

void
DestroyStatement (OO_Statement stmt)
{
  if (!stmt)
    return;

  switch (stmt->id)
    {
    case TO_CaseLabel:
      DestroyExp (stmt->case_label_rec.expr);
      free (&stmt->case_label_rec);
      break;
    case TO_CompoundStatement:
      DestroyStatements (stmt->compound_statement_rec.statements);
      free (&stmt->compound_statement_rec);
      break;
    case TO_ExprStatement:
      DestroyExp (stmt->expr_statement_rec.expr);
      free (&stmt->expr_statement_rec);
      break;
    case TO_IfStatement:
      DestroyExp (stmt->if_statement_rec.expr);
      DestroyStatement (stmt->if_statement_rec.then_part);
      DestroyStatement (stmt->if_statement_rec.else_part);
      free (&stmt->if_statement_rec);
      break;
    case TO_WhileStatement:
      DestroyExp (stmt->while_statement_rec.expr);
      DestroyStatement (stmt->while_statement_rec.statement);
      free (&stmt->while_statement_rec);
      break;
    case TO_DoStatement:
      DestroyStatement (stmt->do_statement_rec.statement);
      DestroyExp (stmt->do_statement_rec.expr);
      free (&stmt->do_statement_rec);
      break;
    case TO_ForStatement:
      DestroyExp (stmt->for_statement_rec.expr1);
      DestroyExp (stmt->for_statement_rec.expr2);
      DestroyExp (stmt->for_statement_rec.expr3);
      DestroyStatement (stmt->for_statement_rec.statement);
      free (&stmt->for_statement_rec);
      break;
    case TO_SwitchStatement:
      DestroyExp (stmt->switch_statement_rec.expr);
      DestroyStatement (stmt->switch_statement_rec.statement);
      free (&stmt->switch_statement_rec);
      break;
    case TO_JumpStatement:
      free (&stmt->jump_statement_rec);
      break;
    case TO_InlineStatement:
      free (stmt->inline_statement_rec.lang_name);
      free (stmt->inline_statement_rec.statement);
      free (&stmt->inline_statement_rec);
      break;
    case TO_WithExprStatement:
      DestroyExp (stmt->with_expr_statement_rec.expr1);
      DestroyExp (stmt->with_expr_statement_rec.expr2);
      free (&stmt->with_expr_statement_rec);
      break;
    case TO_NoExprStatement:
      free (&stmt->no_expr_statement_rec);
      break;
    case TO_ExceptionStatement:
      DestroyStatement (stmt->exception_statement_rec.try_part);
      destroy_exception_handlers (stmt->exception_statement_rec.handler_part);
      free (&stmt->exception_statement_rec);
      break;
    case TO_DebugPrintStatement:
      DestroyExp (stmt->debug_print_statement_rec.exp);
      free (stmt->debug_print_statement_rec.format);
      DestroyList (stmt->debug_print_statement_rec.args);
      free (&stmt->debug_print_statement_rec);
      break;
    case TO_DebugBlockStatement:
      DestroyStatements (stmt->debug_block_statement_rec.block);
      free (&stmt->debug_block_statement_rec);
      break;
    }

  current_stmt = NULL;
}

void 
  DestroyStatements (OO_Statement stmt)
{
  OO_Statement buf;

  while (stmt)
    {
      buf = ((OO_StatementCommon) stmt)->next;
      DestroyStatement (stmt);
      stmt = buf;
    }
}

static int
is_always_true (OO_Expr exp) {
  if (exp == NULL) return 1;

  if (exp->id != TO_Constant) return 0;

  return strcmp (exp->constant_rec.string, "0");
}

static void
check_infinite_loop_body (OO_Statement stmt) {
  if (stmt == NULL) return;

  switch (stmt->id)
    {
    case TO_JumpStatement:
      if (stmt->jump_statement_rec.op == OP_BREAK)
	FatalError ("the type of this method: `%s' is not `void', "
		    "so have to return statement\n", 
		    CurrentMethod->string);
      break;
    case TO_CompoundStatement:
      {
	OO_Statement st = stmt->compound_statement_rec.statements;
	while (st) 
	  {
	    check_infinite_loop_body (st);
	    st = ((OO_StatementCommon) st)->next;
	  }
	break;
      }
    case TO_IfStatement:
      check_infinite_loop_body (stmt->if_statement_rec.then_part);
      check_infinite_loop_body (stmt->if_statement_rec.else_part);
      break;
    case TO_ExceptionStatement:
      check_infinite_loop_body (stmt->exception_statement_rec.try_part);

      {
	OO_ExceptionHandler handlers 
	  = stmt->exception_statement_rec.handler_part;
	OO_Statement st;

	while (handlers) {
	  check_infinite_loop_body (handlers->statement);
	  handlers = &handlers->next->exception_handler_rec;
	}
      }
      
      break;
    case TO_DebugBlockStatement:
      check_infinite_loop_body (stmt->debug_block_statement_rec.block);
      break;
    case TO_WhileStatement:
    case TO_DoStatement:
    case TO_ForStatement:
    case TO_SwitchStatement:
    case TO_WithExprStatement:
    case TO_DebugPrintStatement:
    case TO_ExprStatement:
    case TO_CaseLabel:
    case TO_InlineStatement:
    case TO_NoExprStatement:
    default:
    }
}

static void
check_return_statement_of_loop (OO_Expr exp, OO_Statement st) {
  if (!is_always_true (exp))
    CheckReturnStatement (st);
  else {
    /* this loop is inifinite one, so need contains return statement.
     * if contains break, so illegal */
    check_infinite_loop_body (st);
  }
}

void 
CheckReturnStatement (OO_Statement stmt)
{
  if (!stmt ||
      CheckSimpleType (CurrentMethod->type->type_method_rec.type, 
		       TC_Void) == TYPE_OK)
    return;

  switch (stmt->id)
    {
    case TO_CompoundStatement:
      {
	OO_Statement st = stmt->compound_statement_rec.statements, tail = NULL;
	while (st) 
	  {
	    tail = st;
	    st = ((OO_StatementCommon) st)->next;
	  }
	CheckReturnStatement (tail);
	break;
      }
    case TO_IfStatement:
      CheckReturnStatement (stmt->if_statement_rec.then_part);
      CheckReturnStatement (stmt->if_statement_rec.else_part);
      break;
    case TO_WhileStatement:
      check_return_statement_of_loop (stmt->while_statement_rec.expr,
				      stmt->while_statement_rec.statement);
      break;
    case TO_DoStatement:
      check_return_statement_of_loop (stmt->do_statement_rec.expr,
				      stmt->do_statement_rec.statement);
      break;
    case TO_ForStatement:
      check_return_statement_of_loop (stmt->for_statement_rec.expr2,
				      stmt->for_statement_rec.statement);
      break;
    case TO_SwitchStatement:
      CheckReturnStatement (stmt->switch_statement_rec.statement);
      break;
    case TO_ExceptionStatement:
      CheckReturnStatement (stmt->exception_statement_rec.try_part);

      {
	OO_ExceptionHandler handlers 
	  = stmt->exception_statement_rec.handler_part;
	OO_Statement st;

	while (handlers) {
	  CheckReturnStatement (handlers->statement);
	  handlers = &handlers->next->exception_handler_rec;
	}
      }
      
      break;
    case TO_WithExprStatement:
      {
	int op = stmt->with_expr_statement_rec.op;
	if (op == OP_RETURN || op == OP_RAISE) break;
      }
    case TO_DebugPrintStatement:
    case TO_ExprStatement:
    case TO_JumpStatement:
    case TO_CaseLabel:
      FatalError ("the type of this method: `%s' is not `void', "
		  "so have to return statement\n", 
		  CurrentMethod->string);
      break;
    case TO_DebugBlockStatement:
      CheckReturnStatement (stmt->debug_block_statement_rec.block);
    case TO_InlineStatement:
      Warning ("the type of this method: `%s' is not `void', "
	       "so have to return statement\n", 
	       CurrentMethod->string);
      break;
    case TO_NoExprStatement:
    default:
    }
}

/* EOF */
