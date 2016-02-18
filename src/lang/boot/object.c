/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>

#include "object.h"

Class c_list;
Object g_list;
static Object cur_g_obj;
static Scope cur_scope = NULL;
static int count = 0;
static int oid_counter;

/*
 * private functions
 */

static char *
  create_oid()
{
  char *oid;

  oid = (char *)malloc(7);
  sprintf(oid, "%06x", oid_counter++);

  return oid;
}

static Exp
  calc_index(Exp exp)
{
  Exp e = exp;
  
  while (e->exp2)
    {
      e = e->exp2;
    }
  return e;
}

static void
  set_current_object(Object o)
{
  Scope s;

  s = (Scope)malloc(sizeof(ScopeRec));
  s->obj = o;
  s->next = NULL;

  if (cur_scope)
    {
      s->prev = cur_scope;
      cur_scope->next = s;
    }
  else
    {
      s->prev = NULL;
    }

  cur_scope = s;
}

static Object
  search_element(char *name, Exp exp, char **index)
{
  Object o = cur_g_obj->locals;
  InstanceVal inst;
  int i;

  while (o)
    {
      if (!strcmp(o->name, name))
	{
	  break;
	}
      o = o->next;
    }
  
  if (!o)
    {
      return NULL;
    }

  if (exp->exp2)
    {
      i = atoi((char *)exp->exp1);
      
      inst = o->instance;
      while (inst)
	{
	  if (i == inst->index)
	    {
	      break;
	    }
	  inst = inst->next;
	}

      if (!inst)
	{
	  return NULL;
	}

      return search_element(inst->val, exp->exp2, index);
    }
  else
    {
      *index = (char *)malloc(strlen((char *)exp->exp1) + 1);
      strcpy(*index, (char *)exp->exp1);
      if (atoi((char *)exp->exp1) < (int)o->locals)
	{
	  return o;
	}
      else
	{
	  fprintf(stderr, "%d:index too big\n", yylineno);
	  error = 1;
	  return NULL;
	}
    }
}

static InstanceVal
  search_array_instance(char *name)
{
  InstanceVal inst = cur_scope->obj->instance;
  
  while (inst)
    {
      if (!strcmp(inst->name, name))
	{
	  return inst;
	}
      inst = inst->next;
    }
  return NULL;
}

static int
check_array_exp(Exp exp, char *name)
{
  switch (exp->op)
    {
    case OP_ARRAY_VAL:
      if (atoi((char *)exp->exp2) >= (int)cur_scope->obj->locals || 
	  strcmp(name, (char *)exp->exp1)) 
	{
	  return -1;
	}
      else
	{ return 0;
	}
    case OP_VALUE:
    case OP_VAL:
      return 0;
    case OP_UMINUS:
    case OP_EXP:
      return check_array_exp(exp->exp1, name);
    case OP_PLUS:
    case OP_MINUS:
    case OP_MUL:
    case OP_DIV:
      return check_array_exp(exp->exp1, name);
      return check_array_exp(exp->exp2, name);
    }
}

static OID
calc_type(char *str, int type)
{
  int i, l, h;
  Class c = c_list;

  switch (type)
    {
    case T_GLOBAL:
      return (OID)OZ_GLOBAL_OBJECT;
    case T_ARRAY:
      return (OID)OZ_ARRAY;
    }

  for (i = 0; i < NO_TYPES; i++)
    {
      if (!strcmp(types[i].ozname, str))
	return types[i].type;
    }

  while (c)
    {
      if (!strcmp(c->name, str))
	{
	  switch (c->kind)
	    {
	    case T_STATIC:
	      return (OID)OZ_STATIC_OBJECT;
	    case T_RECORD:
	      sscanf(c->cid, "%8x%8x", &l, &h);
	      return (OID)((OID)l << 32) + (h & 0xffffffff);
	    default:
	      return (OID)OZ_LOCAL_OBJECT;
	    }
	}
      c = c->next;
    }
  fprintf (stderr, "`%s' not defined type\n", str);
}

static Class 
search_class(char *name)
{
  Class buf = c_list;

  while (buf)
    {
      if (!strcmp(buf->name, name))
	return buf;
      buf = buf->next;
    }

  return NULL;
}

static Object
check_defined(Object list, char *name, char *class_name, char *oid, int *flag)
{
  Object o = list, before = NULL;
  Class c = c_list;

  *flag = 0;
  while (o)
    {
      if (name)
	{
	  if ((o->class && class_name && !strcmp(o->name, name)) ||
	      (!o->class && !class_name && !strcmp(o->name, name)))
	    {
	      fprintf(stderr, "%d:this label:(%s) already used\n", 
		      yylineno, name);
	      error = 1;
	      return o;
	    }
	  if (oid && !strcmp(o->oid, oid))
	    {
	      *flag = 1;
	      return NULL;
	    }
	}
      before = o;
      o = o->next;
    }

  if (!class_name)
    return before;

  while (c)
    {
      if (!strcmp(c->name, class_name))
	{
	  break;
	}
      c = c->next;
    }

  if (!c)
    {
      fprintf(stderr, "%d:this class:(%s) not defined\n", 
	      yylineno, class_name);
      error = 1;
      return NULL;
    }

  return before;
}

static Object
create_object(char *name, char *class_name, char *oid, OID type)
{
  Object buf;

  buf = (Object)malloc(sizeof(ObjectRec));

  if (name)
    {
      buf->name = (char *)malloc(strlen(name) + 1);
      strcpy(buf->name, name);
      free(name);
    }
  else
    {
      buf->name = (char *)malloc(8 + 1);
      sprintf(buf->name, "%08x", count);
    }

  if (type) /* array */
    {
      buf->class = NULL;
      if (type < (OID) 100)
	{
	  buf->oid = (char *)malloc(strlen(oid) + 1);
	  strcpy(buf->oid, oid); /* type */
	}
      else
	{
	  buf->oid = (char *)malloc(strlen(RECORD_TYPE) + 16 + 6 + 1);
	  sprintf(buf->oid, "OZ%08x%08xRecord_Rec", 
		  (int)(type >> 32), (int)(type & 0xffffffff));
	}
      (int)buf->locals = (int)class_name; /* size */
      buf->type = type;
      buf->g = cur_g_obj;
    }
  else
    {
      if (!(buf->class = search_class(class_name)))
	{
	  fprintf(stderr, "%d:class:(%s) not defined\n", yylineno, class_name);
	  error = 1;
	  return NULL;
	}
      if (oid)
	{
	  buf->oid = (char *)malloc(strlen(oid) + 1);
	  strcpy(buf->oid, oid);
	  free(oid);
	  buf->g = buf;
	}
      else
	{
	  buf->g = cur_g_obj;
	}
      free(class_name);
      buf->locals = NULL;
      buf->type = 0;
    }

  buf->ref = 0;
  buf->count = count++;
  buf->instance = NULL;
  buf->next = NULL;

  return buf;
}

/*
 * global functions
 */

void
Init()
{
  c_list = NULL;
  cur_g_obj = g_list = NULL;
  if (cur_scope)
    {
      free(cur_scope);
      cur_scope = NULL;
    }
}

void
CreateClass(char *name, char *cid, int kind)
{
  Class buf, c = c_list, before;

  while (c)
    {
      int n_dif, c_dif;
      n_dif = strcmp(c->name, name);
      c_dif = strcmp(c->cid, cid);
      
      if (!n_dif)
	{
	  if (c_dif) 
	    {
	      fprintf(stderr, "%d:this label of class:(%s) already used\n", 
		      yylineno, name);
	      error = 1;
	      return;
	    }
	  else
	    {
	      free(name);
	      free(cid);
	      return;
	    }
	}
      before = c;
      c = c->next;
    }

  buf = (Class)malloc(sizeof(ClassRec));

  buf->name = (char *)malloc(strlen(name) + 1);
  strcpy(buf->name, name);
  buf->cid = (char *)malloc(strlen(cid) + 1);
  strcpy(buf->cid, cid);
  buf->kind = kind;
  buf->next = NULL;
  buf->info = NULL;
  
  if (c_list)
    {
      before->next = buf;
    }
  else
    {
      c_list = buf;
    }

  free(name);
  free(cid);
}

char *
CreateObject(char *name, char *class_name)
{
  Object buf, before;
  Class c = c_list;
  int flag;

  before = check_defined(cur_g_obj->locals, name, class_name, NULL, &flag);

  set_current_object(buf = create_object(name, class_name, NULL, NULL));

  if (before)
    {
      before->next = buf;
    }
  else
    {
      cur_g_obj->locals = buf;
    }

  return buf->name;
}

char *
CreateArray(char *name, char *type, int size, int kind)
{
  Object buf, before;
  OID ele_type;
  int flag;

  if (!kind && size <= 0)
    {
      fprintf(stderr, "%d:array size must be greater than 0\n", yylineno);
      error = 1;
      return;
    }

  before = check_defined(cur_g_obj->locals, name, NULL, NULL, &flag);

  ele_type = calc_type(type, kind);

  if (ele_type < (OID) 100)
    {
      buf = create_object(name, (char *)size, 
			  types[(int)ele_type].name, ele_type);
      set_current_object(buf);
    }
  else
    {
      buf = create_object(name, (char *)size, NULL, ele_type);
      set_current_object(buf);
    }

  if (before)
    {
      before->next = buf;
    }
  else
    {
      cur_g_obj->locals = buf;
    }

  return buf->name;
}

void
CreateGlobalObject(char *name, char *class_name, char *_oid)
{
  Object buf, o = g_list, before;
  Class c = c_list;
  char *oid = _oid ? _oid : create_oid ();
  int flag;

  before = check_defined(g_list, name, class_name, oid, &flag);
  while (flag)
    {
      if (_oid)
	{
	  fprintf(stderr, "%d:this oid:(%s) already used\n", 
		  yylineno, _oid);
	  error = 1;
	  return;
	}
      else
	{
	  free (oid);
	  oid = create_oid ();
	  before = check_defined(g_list, name, class_name, oid, &flag);
	}
    }

  cur_g_obj = buf = create_object(name, class_name, oid, NULL);

  set_current_object(buf);

  if (g_list) 
    {
      before->next = buf;
    }
  else
    {
      g_list = buf;
    }
}

void
CreateInstanceVal(char *name, char *val, int type, int index, char *member)
{
  InstanceVal buf;

  if (type == T_STR && strcmp(cur_scope->obj->oid, "char"))
    {
      fprintf(stderr, "%d:this array cannot has string\n", yylineno);
      error = 1;
      return;
    }

  buf = (InstanceVal)malloc(sizeof(InstanceValRec));
  buf->member = NULL;

  switch (type)
    {
    case T_EXP:
      buf->name = (char *)malloc(strlen(name) + 1);
      strcpy(buf->name, name);
      free(name);

      if (member)
	{
	  buf->member = (char *)malloc(strlen(member) + 1);
	  strcpy(buf->member, member);
	}

      buf->val = val;
      break;
    case T_STR:
      buf->name = (char *)malloc(strlen(cur_scope->obj->name) + 1);
      strcpy(buf->name, cur_scope->obj->name);

      buf->val = (char *)malloc(((int)cur_scope->obj->locals = strlen(val)) + 1);
      ((int)cur_scope->obj->locals)--;
      strcpy(buf->val, val);
      free(val);

      break;
    default:
      buf->name = (char *)malloc(strlen(name) + 1);
      strcpy(buf->name, name);
      free(name);

      buf->val = (char *)malloc(strlen(val) + 1);
      strcpy(buf->val, val);
      free(val);
      break;
    }
      
  buf->type = type;
  buf->index = index;
  buf->next = NULL;

  if (cur_scope->obj->instance)
    {
      cur_scope->obj->instance_tail->next = buf;
    }
  else
    {
      cur_scope->obj->instance = buf;
    }
  cur_scope->obj->instance_tail = buf;
}

char *
  UpLevel()
{
  Scope s = cur_scope;

  cur_scope = s->prev;
  free(cur_scope->next);
  cur_scope->next = NULL;

  return s->obj->name;
}

Exp
  CreateExp(Exp exp1, Exp exp2, int op, char *member, int flag)
{
  Exp buf = (Exp)malloc(sizeof(ExpRec));
  InstanceVal inst;

  switch (op)
    {
    case OP_VALUE:
    case OP_VAL:
      (char *)buf->exp1 = (char *)malloc(strlen((char *)exp1) + 1);
      strcpy((char *)buf->exp1, (char *)exp1);
      buf->exp2 = NULL;
      if (member) 
	{
	  buf->member = (char *)malloc(strlen(member) + 1);
	  strcpy(buf->member, member);
	}
      else
	{
	  buf->member = NULL;
	}
      buf->op = op;
      break;
    case OP_ARRAY_VAL:
      switch (flag)
	{
	case 2:
	  (Object)buf->exp1 = search_element((char *)exp1, exp2, 
					     (char **)&buf->exp2);
	  if (!(Object)buf->exp1)
	    {
	      fprintf(stderr, "%d:this array not defined yet\n", yylineno);
	      error = 1;
	      return NULL;
	    }

	  break;
	case 1:
	  if (!(inst = search_array_instance((char *)exp1)))
	    {
	      (Object)buf->exp1 = search_element((char *)exp1, exp2, 
						 (char **)&buf->exp2);
	      if (!(Object)buf->exp1)
		{
		  fprintf(stderr, "%d:this array not defined yet\n", yylineno);
		  error = 1;
		  return NULL;
		}
	    }
	  else
	    {
	      if (cur_scope->obj->class) /* object */
		{
		  (Object)buf->exp1 = search_element(inst->val, exp2, 
						     (char **)&buf->exp2);
		}
	      else /* array */
		{
		  (Object)buf->exp1 = search_element(cur_scope->obj->name, 
						     exp2, 
						     (char **)&buf->exp2);
		}
	      if (!(Object)buf->exp1)
		{
		  fprintf(stderr, "%d:this array not defined yet\n", yylineno);
		  error = 1;
		  return NULL;
		}
	    }
	  break;
	default:
	  (char *)buf->exp1 = (char *)malloc(strlen((char *)exp1) + 1);
	  strcpy((char *)buf->exp1, (char *)exp1);
	  break;
	}
      if (member) 
	{
	  buf->member = (char *)malloc(strlen(member) + 1);
	  strcpy(buf->member, member);
	}
      else
	{
	  buf->member = NULL;
	}
      buf->op = op;
      break;
    case OP_UMINUS:
    case OP_EXP:
    case OP_BR:
    case OP_NOT:
      buf->exp1 = exp1;
      buf->exp2 = NULL;
      buf->member = NULL;
      buf->op = op;
      break;
    case OP_PLUS:
    case OP_MINUS:
    case OP_MUL:
    case OP_DIV:
    case OP_COM:
    case OP_MOD:
    case OP_OR:
    case OP_EOR:
    case OP_AND:
    case OP_LSHIFT:
    case OP_RSHIFT:
      buf->exp1 = exp1;
      buf->exp2 = exp2;
      buf->op = op;
      buf->member = NULL;
      break;
    case OP_INDEX:
      (char *)buf->exp1 = (char *)malloc(strlen((char *)exp1) + 1);
      strcpy((char *)buf->exp1, (char *)exp1);
      buf->exp2 = exp2;
      buf->op = op;
      buf->member = NULL;
      break;
    }

  return buf;
}

void
InitCounter(char *c)
{
  if (c)
    oid_counter = atoi(c);
  else
    oid_counter = 1;
}

