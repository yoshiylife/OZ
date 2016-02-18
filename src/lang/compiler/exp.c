/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include "ozc.h"

#include "exp.h"
#include "type.h"
#include "common.h"
#include "block.h"
#include "error.h"
#include "symbol.h"
#include "class-list.h"

static
  defined_this_block (OO_Expr exp)
{
  OO_Symbol vars;
  
  if (exp->id != TO_Symbol)
    return 1;

  vars = CurrentBlock->vars;
  while (vars)
    {
      if (!strcmp (vars->string, exp->symbol_rec.string))
	return 1;
      vars = vars->link;
    }
  return 0;
}

static int
  is_null (OO_Expr exp)
{
  if (exp == NULL) 
    return 1;
      
  if (exp->id != TO_Symbol)
    return 0;

  if (defined_this_block (exp))
    return is_null (exp->symbol_rec.value);
  else
    return 0;
}

static OO_Expr
  create_value (OO_Expr exp1, OO_Expr exp2, int op)
{
  OO_Constant val1 = NULL, val2 = NULL;
  int val, value1 = 0, value2 = 0;
  char val_str[256];

  if (exp1 && !(val1 = GetConstant (exp1)))
    return NULL;
  if (exp2 && !(val2 = GetConstant (exp2)))
    return NULL;

  if (val1)
    value1 = atoi (val1->string);
  if (val2)
    value2 = atoi (val2->string);

  switch (op)
    {
    case OP_PLUS:
      val = value1 + value2;
      break;
    case OP_MINUS:
      val = value1 - value2;
      break;
    case OP_MULT:
      val = value1 * value2;
      break;
    case OP_DIV:
      val = value1 / value2;
      break;
    case OP_MOD:
      val = value1 % value2;
      break;
    case OP_AND:
      val = value1 & value2;
      break;
    case OP_IOR:
      val = value1 | value2;
      break;
    case OP_EOR:
      val = value1 ^ value2;
      break;
    case OP_RSHIFT:
      val = value1 >> value2;
      break;
    case OP_LSHIFT:
      val = value1 << value2;
      break;
    }
  
  sprintf (val_str, "%d", val);

  return CreateExpConstant (0, "int", TC_Int, val_str);
}

OO_Expr
CreateExp0 (OO_Expr exp, int op)
{
  OO_Expr buf;

  if (Mode != NORMAL)
    return NULL;

  if (exp)
    if (CheckSimpleType (exp->expr_common_rec.type, TC_Int) < TYPE_OK)
      FatalError ("the type of this argument must be `int'\n");
  
  buf = (OO_Expr) malloc (sizeof (OO_IncDec_Rec));
  buf->inc_dec_rec.op = op;
  buf->inc_dec_rec.lvalue = exp;
  buf->id = TO_IncDec;
  if (exp)
    buf->expr_common_rec.type = exp->expr_common_rec.type;
  else
    buf->expr_common_rec.type = NULL;
  return buf;
}

OO_Expr
CreateExp1 (OO_Expr exp, int op)
{
  OO_Expr buf;
  
  if (Mode != NORMAL)
    return NULL;

  switch (op)
    {
    case OP_LENGTH:
      if (exp)
	if (CheckTypeID (exp->expr_common_rec.type, TO_TypeArray) < TYPE_OK)
	  FatalError ("the type of thie arguement must be `array'\n");
      break;
    case OP_TILDE:
    case OP_INC:
    case OP_DEC:
    case OP_PLUS:
    case OP_MINUS:
      if (exp)
	if (CheckTypeID (exp->expr_common_rec.type, TO_SimpleType) < TYPE_OK)
	  FatalError ("the type of this argument must be `simple type'\n");
      break;
    case OP_EXCLAIM:
    case OP_PARE:
      break;
    }

  buf = (OO_Expr) malloc (sizeof (OO_Unary_Rec));
  buf->unary_rec.op = op;
  buf->unary_rec.expr = exp;
  buf->id = TO_Unary;

  if (op == OP_LENGTH)
    buf->expr_common_rec.type = CreateType (0, "int", TC_Int, NULL);
  else if (exp)
    buf->expr_common_rec.type = exp->expr_common_rec.type;
  else
    buf->expr_common_rec.type = NULL;
  return buf;
}

OO_Expr
  CreateExpNarrow (OO_Expr type, OO_Expr exp)
{
  OO_ClassType cl;
  int qual = 0;
  OO_Expr buf;

  if (exp)
    if (CheckSimpleType (exp->expr_common_rec.type, -1) < TYPE_OK)
      {
	if (!(cl = GetClassType (exp, &qual)))
	  FatalError ("the type of argument 1 of `narrow' "
		      "must not be `class type'\n");

	if (type->symbol_rec.type->id == TO_ClassType)
	  {
	    if (CheckClassType (cl, &type->symbol_rec.type->class_type_rec, 
				-1, 1) < TYPE_OK)
	      FatalError ("argument 1 of `narrow' "
			  "must be subclass of the class of argument 2\n");
	  }
      }

  buf = (OO_Expr) malloc (sizeof (OO_Binary_Rec));
  buf->binary_rec.op = OP_NARROW;
  buf->binary_rec.expr1 = type;
  buf->binary_rec.expr2 = exp;
  buf->id = TO_Binary;

  if (type)
    {
      if (exp->expr_common_rec.type->id == TO_TypeSCQF)
	{
	  if (type->symbol_rec.type->id == TO_ClassType)
	    buf->expr_common_rec.type 
	      = CreateType (SC_GLOBAL, type->symbol_rec.string, 
			    TC_Object, NULL);
	  else
	    buf->expr_common_rec.type 
	      = CreateType (SC_GLOBAL, type->symbol_rec.string, 
			    TC_Generic, NULL);
	}
      else
	buf->expr_common_rec.type = type->symbol_rec.type;
    }
  else
    buf->expr_common_rec.type = NULL;
  return buf;
}

OO_Expr
CreateExp2 (OO_Expr exp1, OO_Expr exp2, int op)
{
  OO_Expr buf;

  if (Mode != NORMAL)
    return NULL;

  if (op != OP_COMMA && op != OP_COMMA && op != OP_NE && op != OP_EQ)
    {
      if (exp1)
	{
	  if (CheckSimpleType (exp1->expr_common_rec.type, TC_Generic) 
	      == TYPE_NG && 
	      CheckSimpleType (exp1->expr_common_rec.type, TC_Condition) 
	      == TYPE_OK)
	    FatalError ("the type of this argument must not be `condition'\n");
	}

      if (exp2)
	{
	  if (CheckSimpleType (exp1->expr_common_rec.type, TC_Generic) 
	      == TYPE_NG && 
	      CheckSimpleType (exp1->expr_common_rec.type, TC_Condition) 
	      == TYPE_OK)
	    FatalError ("the type of this argument must not be `condition'\n");
	}
    }

  switch (op)
    {
    case OP_COMMA:
    case OP_COMMA2:
      buf = (OO_Expr) malloc (sizeof (OO_Comma_Rec));
      buf->comma_rec.expr_list = (OO_List) exp1;
      if (op == OP_COMMA)
	{
	  if (exp1 && ((OO_List) exp1)->car)
	    buf->comma_rec.type 
	      = ((OO_Expr)((OO_List) exp1)->car)->expr_common_rec.type;
	  else
	    buf->expr_common_rec.type = NULL;
	  buf->id = TO_Comma;
	}
      else
	{
	  buf->expr_common_rec.type = NULL;
	  buf->id = TO_Comma2;
	}
      return buf;
    case OP_PLUS:
    case OP_MINUS:
    case OP_MULT:
    case OP_DIV:
    case OP_MOD:      
    case OP_LSHIFT:
    case OP_RSHIFT:
    case OP_AND:
    case OP_IOR:
    case OP_EOR:
    case OP_ANDAND:
    case OP_OROR:
      buf = (OO_Expr) malloc (sizeof (OO_Binary_Rec));
      buf->binary_rec.op = op;
      buf->binary_rec.expr1 = exp1;
      buf->binary_rec.expr2 = exp2;
      buf->id = TO_Binary;
      if (exp1)
	buf->expr_common_rec.type = exp1->expr_common_rec.type;
      else
	buf->expr_common_rec.type = NULL;
      return buf;
    case OP_LT:
    case OP_GT:
    case OP_LE:
    case OP_GE:
      buf = (OO_Expr) malloc (sizeof (OO_ArithCompare_Rec));
      buf->arith_compare_rec.op = op;
      buf->arith_compare_rec.expr1 = exp1;
      buf->arith_compare_rec.expr2 = exp2;
      buf->id = TO_ArithCompare;
      buf->expr_common_rec.type = CreateType (0, "int", TC_Int, NULL);
      return buf;
    case OP_EQ:
    case OP_NE:
      buf = (OO_Expr) malloc (sizeof (OO_EqCompare_Rec));
      buf->eq_compare_rec.op = op;
      buf->eq_compare_rec.expr1 = exp1;
      buf->eq_compare_rec.expr2 = exp2;
      buf->id = TO_EqCompare;
      buf->expr_common_rec.type = CreateType (0, "int", TC_Int, NULL);
      return buf;
    }

}

OO_Expr
CreateExp3 (OO_Expr exp1, OO_Expr exp2, OO_Expr exp3)
{
  OO_Expr buf;

  if (Mode != NORMAL)
    return NULL;

  if (exp1)
    if (CheckTypeID (exp1->expr_common_rec.type, TO_SimpleType) > TYPE_OK && 
	(CheckSimpleType (exp1->expr_common_rec.type, TC_Condition) 
	 >= TYPE_OK ||
	 CheckSimpleType (exp1->expr_common_rec.type, TC_Void) >= TYPE_OK))
      FatalError ("illegal type of argument 1 in `?:' expression");

  if (exp2 && exp3)
    {
      if (CheckType (exp2->expr_common_rec.type, exp3->expr_common_rec.type, 
		     0, 0) < TYPE_OK)
	FatalError ("types of argument 2 and 3 in `?:' expression mismatch\n");
    }

  buf = (OO_Expr) malloc (sizeof (OO_Conditional_Rec));
  buf->conditional_rec.expr1 = exp1;
  buf->conditional_rec.expr2 = exp2;
  buf->conditional_rec.expr3 = exp3;
  buf->id = TO_Conditional;

  if (CheckSimpleType (exp2->expr_common_rec.type, TC_Zero) == TYPE_OK)
    buf->expr_common_rec.type = exp2->expr_common_rec.type;
  else
    buf->expr_common_rec.type = exp3->expr_common_rec.type;

  return buf;
}

OO_Expr
CreateExpAssign (OO_Expr lval, OO_Expr exp, int op)
{
  OO_Expr buf;

  if (Mode != NORMAL)
    return NULL;

  if (lval == (OO_Expr) Self)
    {
      FatalError ("cannot assign to `self'\n");
    }
  else if (exp)
    {
      if (lval && lval->id == TO_Member)
	{
	  OO_Expr member = lval->member_rec.obj;

	  while (member && member->id == TO_Member)
	    member = member->member_rec.obj;

	  if (!member || member->id != TO_Symbol)
	    FatalError ("invalid lvalue in assingment\n");
	}

      if (lval && exp)
	{
	  if (CheckType (lval->expr_common_rec.type, exp->expr_common_rec.type,
			 0, 0) < TYPE_OK)
	    FatalError ("type mismatch in `assign' expression\n");
	}
    }

  buf = (OO_Expr) malloc (sizeof (OO_Assignment_Rec));
  buf->assignment_rec.op = op;
  buf->assignment_rec.lvalue = lval;
  buf->assignment_rec.expr = exp;
  buf->id = TO_Assignment;

  if (lval)
    buf->expr_common_rec.type = lval->expr_common_rec.type;
  else
    buf->expr_common_rec.type = NULL;

  if (!lval || lval == (OO_Expr) Self)
    return buf;

  if (lval->id == TO_Symbol)
    if (op != OP_EQ)
      {
	lval->symbol_rec.value 
	  = create_value (lval->symbol_rec.value, exp, op);
	lval->symbol_rec.is_created = 1;
      }
    else
      lval->symbol_rec.value = exp;

#if 0    
  if (lval->id == TO_Unary && lval->unary_rec.op == OP_LENGTH)
    if (op != OP_EQ)
      {
	if (lval->unary_rec.expr && lval->unary_rec.expr->expr_common_rec.type)
	  {
	    lval->unary_rec.expr->expr_common_rec.type->type_array_rec.length 
	      = create_value (lval->unary_rec.expr->expr_common_rec.type
			      ->type_array_rec.length, exp, op);
	    lval->unary_rec.expr->expr_common_rec.type
	      ->type_array_rec.is_created
		= 1;
	  }
      }
    else
      if (lval->unary_rec.expr && lval->unary_rec.expr->expr_common_rec.type)
	lval->unary_rec.expr->expr_common_rec.type->type_array_rec.length 
	  = exp;
#endif

  return buf;
}

OO_Expr
CreateExpArray (OO_Expr array, OO_Expr index)
{
  OO_Expr buf;
  OO_Constant val, len;
  int i, j;

  if (Mode != NORMAL)
    return NULL;

  if (array)
    {
      if (array->expr_common_rec.type->id != TO_TypeArray)
	FatalError ("the type of this exprssion is not `array'\n");
      
      if (index)
	if (CheckSimpleType (index->expr_common_rec.type, TC_Int) < TYPE_OK &&
	    CheckSimpleType (index->expr_common_rec.type, TC_Char) < TYPE_OK &&
	    CheckSimpleType (index->expr_common_rec.type, TC_Short) 
	    < TYPE_OK &&
	    CheckSimpleType (index->expr_common_rec.type, TC_Long) < TYPE_OK)
	  FatalError ("the index of array must be "
		      "`char', `short', `int' or `long'\n");
    }

  buf = (OO_Expr) malloc (sizeof (OO_ArrayReference_Rec));
  buf->array_reference_rec.array = array;
  buf->array_reference_rec.index = index;
  buf->id = TO_ArrayReference;
  if (array)
    buf->expr_common_rec.type 
      = array->expr_common_rec.type->type_array_rec.type;
  else
    buf->expr_common_rec.type = NULL;
  return buf;
}

OO_Expr
CreateExpFork (OO_Expr exp)
{
  OO_Expr buf;

  if (Mode != NORMAL)
    return NULL;

  if (exp)
    {
      if (exp->id != TO_MethodCall)
	FatalError ("the argument of this `fork' expression is not "
		    "`method call' expression\n");
      
#if 1
      else if (exp->method_call_rec.method->access == PRIVATE_PART)
	FatalError ("sorry, now cannot fork for `private' method call\n");
#endif
      
    }

  buf = (OO_Expr) malloc (sizeof (OO_Fork_Rec));
  buf->fork_rec.expr = exp;
  buf->id = TO_Fork;
  if (exp)
    buf->expr_common_rec.type = CreateProcessType (exp->expr_common_rec.type);
  else
    buf->expr_common_rec.type = NULL;
  return buf;
}

OO_Expr
CreateExpJoin (OO_Expr exp)
{
  OO_Expr buf;

  if (Mode != NORMAL)
    return NULL;

  if (exp)
    if (exp->expr_common_rec.type->id != TO_TypeProcess)
      FatalError ("the type of the argument of this `join' expression "
		  "is not `process'\n");

  buf = (OO_Expr) malloc (sizeof (OO_Join_Rec));
  buf->join_rec.expr = exp;
  buf->id = TO_Join;
  if (exp)
    buf->expr_common_rec.type 
      = exp->expr_common_rec.type->type_process_rec.type;
  else
    buf->expr_common_rec.type = NULL;
  return buf;
}

OO_Expr
CreateExpConstant (int qual, char *type_str, int kind, char *val)
{
  OO_Expr buf;

  if (Mode != NORMAL)
    return NULL;

  buf = (OO_Expr) malloc (sizeof (OO_Constant_Rec) + strlen (val));
  strcpy (buf->constant_rec.string, val);
  if (type_str)
    buf->expr_common_rec.type = CreateType (qual, type_str, kind, NULL);
  else
    if (kind == TC_Object)
      {
	if (qual)
	  buf->expr_common_rec.type = CreateType (qual, type_str, kind, NULL);
	else
	  {
	    buf->expr_common_rec.type = CreateType (SC_GLOBAL, type_str, 
						    kind, NULL);
	    buf->expr_common_rec.type->type_scqf_rec.type 
	      = (OO_Type) ObjectClass;
	  }
      }
    else
      {
	Type ts = (Type) malloc (sizeof (Type_Rec));

	ts->process = 0;
	ts->array = 1;
	ts->next = NULL;
	buf->expr_common_rec.type = CreateType (qual, "char", TC_Char, ts);
	free (ts);
      }
    
  buf->id = TO_Constant;

  return buf;
}

OO_Expr
CreateExpMember (OO_Expr exp, char *name)
{
  OO_Expr buf;
  OO_Type type;
  OO_List list;

#if 1
  if (Mode != NORMAL || !exp)
#else
  if (!exp)
#endif
    return NULL;

  type = exp->expr_common_rec.type;

  if (type->id != TO_ClassType || type->class_type_rec.cl != TC_Record)
    {
      FatalError ("this expression (before %s)  not recrod type\n", name);
      return NULL;
    }

  if (type->class_type_rec.status == CLASS_NONE)
    {
      type = exp->expr_common_rec.type 
	= (OO_Type) GetClassFromUsedList (type
					  ->class_type_rec.class_id_public);
    }

  list = type->class_type_rec.public_list;

  while (list)
    {
      if (!strcmp (list->car->symbol_rec.string, name))
	break;

      list = &list->cdr->list_rec;
    }

  if (!list)
    {
      FatalError ("the record of this expression "
		  "dose not contain member: %s\n", name);
      return NULL;
    }

  buf = (OO_Expr) malloc (sizeof (OO_Member_Rec));
  buf->member_rec.id = TO_Member;
  buf->member_rec.obj = exp;
  buf->member_rec.member = name;
  buf->member_rec.type = list->car->symbol_rec.type;

  return buf;
}

OO_Expr
CreateExpMethodCall (OO_Expr exp, char *name, OO_List args, int access,
		     OO_Expr om)
{
  OO_Expr buf;
  OO_ClassType cl = NULL;
  OO_Symbol method = NULL;
  int qual = 0;
  int is_global, is_constructor, is_mine;
  OO_List args_list;

  if (Mode != NORMAL)
    return NULL;

  if (exp)
    {
      if (exp == (OO_Expr) Self)
	cl = ThisClass;
      else
	{
	  cl = GetClassType (exp, &qual);

	  if (access != CONSTRUCTOR_PART && 
	      defined_this_block (exp) && 
	      cl && cl->cl != TC_Record &&
	      is_null (exp))
	    Warning ("this variable: `%s' not binded\n", 
		     exp->symbol_rec.string);
	    
	}

      if (cl && cl->status == CLASS_NONE)
	{
	  cl = GetClassFromUsedList (cl->class_id_public);

	  if (exp->expr_common_rec.type->id == TO_TypeSCQF)
	    exp->expr_common_rec.type->type_scqf_rec.type = (OO_Type) cl;
	  else
	    exp->expr_common_rec.type = (OO_Type) cl;
	}
	 
      if (cl)
	{
	  if (exp == (OO_Expr) Self)
	    {
	      if (!(method = GetMethod (name, cl, qual, PRIVATE_PART)))
		{
		  FatalError ("method: `%s' not defined\n", name);
		  cl = NULL;
		}
	    }
	  else
	    {
	      if (!(method = GetMethod (name, cl, qual, access)))
		{
		  if (access == CONSTRUCTOR_PART)
		    FatalError ("constructor: `%s' not defined\n", 
				name);
		  else
		    FatalError ("method: `%s' not defined as `public'\n", 
				name);
		  cl = NULL;
		}
	      else if (access == CONSTRUCTOR_PART && 
		       cl->qualifiers == SC_ABSTRACT)
		{
		  FatalError ("cannot create the instance of abstract class:"
			      "`%s'", cl->symbol->string);
		  cl = NULL;
		}
	    }
	}

      if (!method)
	method = CreateSymbol (name);
      
      is_global = qual & SC_GLOBAL ? 1 : 0;
      is_constructor = access == CONSTRUCTOR_PART ? 1 : 0;
      is_mine = 0;
    }
  else
    {
      if (!(method = GetMethod (name, ThisClass, 0, access)))
	FatalError ("method: `%s' not defined\n", name);

      exp = (OO_Expr) Self;
      if (method)
	{
	  cl = ThisClass;
	  is_global = 0;
	  is_constructor = 0;
	  is_mine = method->access == PRIVATE_PART;
	}
    }

  args_list = args;
  if (cl)
    if (CheckArgs (method->type->type_method_rec.args, args_list, 0) < TYPE_OK)
      FatalError ("method: `%s' arguments type mismatch\n", name);

  if (om && !is_global)
    FatalError ("method: `%s' is not global constructor, "
		"so cannot specify ObjectManager\n", name);

  buf = (OO_Expr) malloc (sizeof (OO_MethodCall_Rec));
  buf->method_call_rec.obj = exp;
  buf->method_call_rec.method = method;
  buf->method_call_rec.args = args_list;
  buf->method_call_rec.om = om;
  buf->method_call_rec.is_global = is_global;
  buf->method_call_rec.is_constructor = is_constructor;
  buf->method_call_rec.is_mine = is_mine;
  if (cl)
    {
      if (is_constructor)
	{
	  buf->expr_common_rec.type = exp->expr_common_rec.type;
	  cl->used_for_instanciate = 1;
	}
      else
	buf->expr_common_rec.type 
	  = buf->method_call_rec.method->type->type_method_rec.type;

      cl->used_for_invoke = 1;
    }
  else
#if 0
    buf->expr_common_rec.type = exp->expr_common_rec.type;
#else
    buf->expr_common_rec.type = NULL;
#endif
  buf->id = TO_MethodCall;

  if (access == CONSTRUCTOR_PART && exp->id == TO_Symbol)
    exp->symbol_rec.value = buf;

  return buf;
}

void
DestroyExp (OO_Expr exp)
{
  if (!exp)
    return;

  switch (exp->id)
    {
    case TO_Symbol:
      return;
    case TO_Constant:
      DestroyType (exp->constant_rec.type);
      break;
    case TO_IncDec:
      DestroyExp (exp->inc_dec_rec.lvalue);
      break;
    case TO_Unary:
      DestroyExp (exp->unary_rec.expr);
      if (exp->unary_rec.op == OP_LENGTH)
	DestroyType (exp->unary_rec.type);
      break;
    case TO_Binary:
      if (exp->binary_rec.op == OP_NARROW)
	DestroySymbol (&exp->binary_rec.expr1->symbol_rec);
      else
	DestroyExp (exp->binary_rec.expr1);
      DestroyExp (exp->binary_rec.expr2);
      break;
    case TO_ArithCompare:
      DestroyExp (exp->arith_compare_rec.expr1);
      DestroyExp (exp->arith_compare_rec.expr2);
      break;
    case TO_EqCompare:
      DestroyExp (exp->eq_compare_rec.expr1);
      DestroyExp (exp->eq_compare_rec.expr2);
      break;
    case TO_Assignment:
      DestroyExp (exp->assignment_rec.lvalue);
      DestroyExp (exp->assignment_rec.expr);
      break;
    case TO_Conditional:
      DestroyExp (exp->conditional_rec.expr1);
      DestroyExp (exp->conditional_rec.expr2);
      DestroyExp (exp->conditional_rec.expr3);
      break;
    case TO_MethodCall:
      DestroyExp (exp->method_call_rec.obj);
      if (!exp->method_call_rec.method->type)
	DestroySymbol (exp->method_call_rec.method);
      DestroyList (exp->method_call_rec.args);
      break;
    case TO_ArrayReference:
      DestroyExp (exp->array_reference_rec.array);
      DestroyExp (exp->array_reference_rec.index);
      break;
    case TO_Fork:
      DestroyExp (exp->fork_rec.expr);
      free (exp->fork_rec.type);
      break;
    case TO_Join:
      DestroyExp (exp->join_rec.expr);
      break;
    }
 
  free (exp);
}

OO_Constant
GetConstant (OO_Expr exp)
{
  if (!exp)
    return NULL;

  switch (exp->id)
    {
    case TO_Constant:
      return &exp->constant_rec;
    case TO_Symbol:
      return GetConstant (exp->symbol_rec.value);
    default:
      return NULL;
    }
}

