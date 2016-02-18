/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include "object.h"

/*
 * private functions 
 */

static void
  print_exp(Exp exp, int flag)
{
  if (!exp)
    return;

  switch (exp->op)
    {
    case OP_VALUE:
    case OP_VAL:
      printf("%s", (char *)exp->exp1);
      if (exp->member)
	{
	  printf(".%s", exp->member);
	}
      break;
    case OP_ARRAY_VAL:
      printf("%s[%s]", ((Object)exp->exp1)->name, (char *)exp->exp2);
      if (exp->member)
	{
	  printf(".%s", exp->member);
	}
      break;
    case OP_UMINUS:
      printf("-");
      print_exp(exp->exp1, flag);
      break;
    case OP_NOT:
      printf("~");
      print_exp(exp->exp1, flag);
      break;
    case OP_EXP:
      printf("(");
      print_exp(exp->exp1, flag);
      printf(")");
      break;
    case OP_PLUS:
      print_exp(exp->exp1, flag);
      printf(" + ");
      print_exp(exp->exp2, flag);
      break;
    case OP_MINUS:
      print_exp(exp->exp1, flag);
      printf(" - ");
      print_exp(exp->exp2, flag);
      break;
    case OP_MUL:
      print_exp(exp->exp1, flag);
      printf(" * ");
      print_exp(exp->exp2, flag);
      break;
    case OP_DIV:
      print_exp(exp->exp1, flag);
      printf(" / ");
      print_exp(exp->exp2, flag);
      break;
    case OP_BR:
      printf("{ ");
      print_exp(exp->exp1, flag);
      printf(" }");
      break;
    case OP_COM:
      print_exp(exp->exp1, flag);
      printf(", ");
      print_exp(exp->exp2, flag);
      break;
    case OP_MOD:
      print_exp(exp->exp1, flag);
      printf(" % ");
      print_exp(exp->exp2, flag);
      break;
    case OP_OR:
      print_exp(exp->exp1, flag);
      printf(" | ");
      print_exp(exp->exp2, flag);
      break;
    case OP_EOR:
      print_exp(exp->exp1, flag);
      printf(" ^ ");
      print_exp(exp->exp2, flag);
      break;
    case OP_AND:
      print_exp(exp->exp1, flag);
      printf(" & ");
      print_exp(exp->exp2, flag);
      break;
    case OP_LSHIFT:
      print_exp(exp->exp1, flag);
      printf(" << ");
      print_exp(exp->exp2, flag);
      break;
    case OP_RSHIFT:
      print_exp(exp->exp1, flag);
      printf(" >> ");
      print_exp(exp->exp2, flag);
      break;
    }
}

static void
print_instances(Object obj, int local)
{
  InstanceVal i = obj->instance;

  while (i)
    {
      if (local)
	{
	  printf("\t");
	}

      if (i->index < 0)
	{
	  switch (i->type)
	    {
	    case T_LOCAL:
	      printf("\t%s = local(%s);\n", i->name, i->val);
	      break;
	    case T_OID:
	      printf("\t%s = oid(%s);\n", i->name, i->val);
	      break;
	    case T_GLOBAL:
	      printf("\t%s = global(%s);\n", i->name, i->val);
	      break;
	    case T_ARRAY:
	      printf("\t%s = array(%s);\n", i->name, i->val);
	      break;
	    case T_EXP:
	      if (i->member)
		{
		  printf("\t%s.%s = ", i->name, i->member);
		}
	      else
		{
		  printf("\t%s = ", i->name);
		}
	      print_exp((Exp)i->val, i->index);
	      printf(";\n");
	      break;
	    case T_STR:
	      printf("\t%s;\n", i->val);
	      break;
	    }
	  i = i->next;
	}
      else
	{
	  switch (i->type)
	    {
	    case T_LOCAL:
	      printf("\t%s[%d] = local(%s);\n", i->name, i->index, i->val);
	      break;
	    case T_OID:
	      printf("\t%s[%d] = oid(%s);\n", i->name, i->index, i->val);
	      break;
	    case T_GLOBAL:
	      printf("\t%s[%d] = global(%s);\n", i->name, i->index, i->val);
	      break;
	    case T_ARRAY:
	      printf("\t%s[%d] = array(%s);\n", i->name, i->index, i->val);
	      break;
	    case T_EXP:
	      if (i->member)
		{
		  printf("\t%s[%d].%s = ", i->name, i->index, i->member);
		}
	      else
		{
		  printf("\t%s[%d] = ", i->name, i->index);
		}
	      print_exp((Exp)i->val, i->index);
	      printf(";\n");
	      break;
	    }
	  i = i->next;
	}
    }
}

/* 
 * global functions
 */

void
  PrintObjects()
{
  Class c = c_list;
  Object o = g_list, l;

  while (c)
    {
      switch (c->kind) 
	{
	case T_STATIC:
	  printf("static class %s = %s;\n", c->name, c->cid);
	  break;
	case T_RECORD:
	  printf("record class %s = %s;\n", c->name, c->cid);
	  break;
	default:
	  printf("class %s = %s;\n", c->name, c->cid);
	  break;
	}
      c = c->next;
    }

  printf("\n");
  
  while (o)
    {
      printf("global %s %s = %s {\n", o->class->name, o->name, o->oid);

      l = o->locals;
      while (l) 
	{
	  if (l->ref)
	    {
	      if (l->class)
		{
		  printf("\n\tlocal %s %s {\n", l->class->name, l->name);
		  print_instances(l, 1);
		}
	      else
		{
		  printf("\n\tarray %s %s[%d] {\n", 
			 l->oid, l->name, (int)l->locals);
		  print_instances(l, 1);
		}
	      printf("\t}\n");
	    }
	  l = l->next;
	}

      printf("\n");

      print_instances(o, 0);

      printf("}\n\n");

      o = o->next;
    }
}

