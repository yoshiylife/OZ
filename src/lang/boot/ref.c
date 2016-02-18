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

static int 
  check_ref_exp(Exp exp)
{
  if (!exp)
    return;

  switch (exp->op)
    {
    case OP_VALUE:
    case OP_VAL:
      return 0;
    case OP_ARRAY_VAL:
      ((Object)exp->exp1)->ref = 1;
      return 1;
    case OP_UMINUS:
    case OP_EXP:
    case OP_BR:
      return check_ref_exp(exp->exp1);
    case OP_PLUS:
    case OP_MINUS:
    case OP_MUL:
    case OP_DIV:
    case OP_COM:
      if (check_ref_exp(exp->exp1) ||  check_ref_exp(exp->exp2))
	{
	  return 1;
	}
      else
	{
	  return 0;
	}
    default:
      return 0;
    }
}

static int 
  check_ref(Object o, Object locals, Object cell)
{
  InstanceVal inst = o->instance;
  Object l;
  int count = 0;

  while (inst)
    {
      switch (inst->type)
	{
	case T_ARRAY:
	case T_LOCAL:
	   l = locals;

	   while (l)
	     {
	       if (!l->ref && !strcmp(l->name, inst->val))
		 {
		   l->ref = 1;
		   count++;
		   break;
		 }
	       l = l->next;
	     }

	   if (!cell->ref && !strcmp (cell->name, inst->val))
	     {
	       cell->ref = 1;
	       count++;
	     }
	   break;
	 case T_EXP:
	   if (check_ref_exp((Exp)inst->val))
	     {
	       count++;
	     }
	   break;
	 default:
	   break;
	 }
      inst = inst->next;
    }
  return count;
}

/*
 * global funcitions
 */

void
  CheckRef()
{
  Object g, l;
  int count = 1, before = -1;

/*
  while (count - before) 
*/
  while (count)
    {
/*
      before = count;
*/
      count = 0;
	  
      g = g_list;
      while (g)
	{
	  count += check_ref(g, g->locals, g);
	  
	  l = g->locals;
	  while (l)
	    {
	      if (l->ref)
		{
		  count += check_ref(l, g->locals, g);
		}
	      
	      l = l->next;
	    }
	  g = g->next;
	}
    }
}
