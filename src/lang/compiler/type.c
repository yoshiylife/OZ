/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef CFE
#include <stdio.h>
#include <stdlib.h>

#include "ozc.h"
#include "type.h"
#include "symbol.h"
#include "error.h"
#include "class-list.h"
#include "lang/school.h"
#include "class.h"

static 
  is_subclass (OO_ClassType super, OO_ClassType sub, int nowarn)
{
  OO_List parents = sub->class_part_list;
  int result = TYPE_NG;

  while (parents)
    {
      if (parents->car->class_type_rec.class_id_public 
	  == super->class_id_public)
	if (result > TYPE_OK && !nowarn)
	  {
	    if (super->symbol)
	      Warning ("`%s' is multiply used as super class\n", 
		       GetVID (super->symbol->string, -1));
	    else
	      Warning ("`%08x%08x' is multiply used as super class\n", 
		       (int) (super->class_id_public >> 32),
		       (int) (super->class_id_public & 0xffffffff));
	  }
	else
	  result = TYPE_SAFE;
      parents = &parents->cdr->list_rec;
    }
  return result;
}

static OO_Type *
  set_process (OO_Type *type, int process)
{
  while (process)
    {
      *type = (OO_Type) malloc (sizeof (OO_TypeProcess_Rec));
      (*type)->id = TO_TypeProcess;
      type = &(*type)->type_process_rec.type;
      process--;
    }

  return type;
}

static OO_Type *
  set_array (OO_Type *type, int array)
{
  while (array)
    {
      *type = (OO_Type) malloc (sizeof (OO_TypeArray_Rec));
      (*type)->id = TO_TypeArray;
#if 0
      (*type)->type_array_rec.length = 0;
      (*type)->type_array_rec.is_created = 0;
#endif
      type = &(*type)->type_array_rec.type;
      array--;
    }

  return type;
}

static OO_Type *
  set_type (OO_Type *type, Type ts)
{
  if (ts->next)
    {
      type = set_type (type, ts->next);
    }

  type = set_process (type, ts->process);
  type = set_array (type, ts->array);
  
  return type;
}

#if 0
static
free_type (Type ts)
{
  Type buf;

  while (ts)
    {
      buf = ts->next;
      free (ts);
      ts = buf;
    }
}
#endif

OO_Type
CreateType (int qual, char *type_str, int kind, Type ts)
{
  OO_Type *type, new_type;

  if (qual & QF_CONST)
    {
      new_type = (OO_Type) malloc (sizeof (OO_TypeSCQF_Rec));
      new_type->id = TO_TypeSCQF;
      new_type->type_scqf_rec.scqf = QF_CONST;
      type = &new_type->type_scqf_rec.type;
      qual &= ~QF_CONST;
    }
  else
    type = &new_type;

  if (ts)
    type = set_type (type, ts);
  
  if (qual)
    {
      (*type) = (OO_Type) malloc (sizeof (OO_TypeSCQF_Rec));
      (*type)->id = TO_TypeSCQF;
      (*type)->type_scqf_rec.scqf = qual;
      type = &(*type)->type_scqf_rec.type;
    }

  switch (kind)
    {
    case TC_Generic:
    case TC_Zero:
    case TC_Void:
    case TC_Char:
    case TC_Short:
    case TC_Int:
    case TC_Long:
    case TC_Float:
    case TC_Double:
    case TC_Condition:
      *type = (OO_Type) malloc(sizeof(OO_SimpleType_Rec));
      (*type)->id = TO_SimpleType;
      (*type)->simple_type_rec.symbol = CreateSymbol (type_str);
      (*type)->simple_type_rec.cl = kind;
      break;
    case TC_Object:
      if (type_str)
	{
	  if (Mode != NORMAL && Part != PRIVATE_PART)
	    {
	      *type = (OO_Type) CreateClass (NULL, 0, 0);
	      (*type)->class_type_rec.symbol = CreateSymbol (type_str);
	    }
#if 0
	  else if (!(*type = (OO_Type) SearchClass (type_str)))
	    {
	      FatalError ("`%s' not defined type\n", type_str);
	      return NULL;
	    }
#else
	  else
	    *type = (OO_Type) SearchClass (type_str);
#endif
	}
      else
	{
	  if (qual)
	    *type = (OO_Type) ThisClass;
	  else
	    *type = (OO_Type) ObjectClass;
	}
      break;
    }

#if 0
  if (ts)
    free_type (ts);
#endif

  return new_type;
}

OO_Type
CreateProcessType (OO_Type type)
{
  OO_Type new_type;

  set_process (&new_type, 1);
  new_type->type_process_rec.type = type;

  return new_type;
}


TypedSymbol
CreateTypedSymbol (int process, int array, char *name, TypedSymbol ts)
{
  int len = name ? strlen (name) : 0;
  Type buf = (Type) malloc (sizeof (Type_Rec));

  buf->process = process;
  buf->array = array;

  if (!ts)
    {
      TypedSymbol tsym = (TypedSymbol) malloc (sizeof (TypedSymbol_Rec) 
					       + len);
      buf->next = NULL;
      tsym->type = buf;
      if (name)
	strcpy (tsym->name, name);
      else
	tsym->name[0] = '\0';
      return tsym;
    }
  else
    {
      buf->next = ts->type;
      ts->type = buf;
      return ts;
    }
}

void
DestroyTypedSymbol (TypedSymbol tsym)
{
  Type type = tsym->type, buf;

  while (type)
    {
      buf = type->next;
      free (type);
      type = buf;
    }
  free (tsym);
}

MethodSymbol
CreateMethodSymbol (TypedSymbol tsym, OO_List arg)
{
  MethodSymbol msym = (MethodSymbol) malloc (sizeof (MethodSymbol_Rec));

  msym->tsym = tsym;
  msym->arg = arg;
  return msym;
}

void
DestroyMethodSymbol (MethodSymbol msym)
{
  DestroyTypedSymbol (msym->tsym);
  free (msym);
}

OO_ClassType
  GetClassType (OO_Expr exp, int *qual)
{
  if (qual)
    *qual = 0;
  if (exp)
    {
      OO_Type type;

      if (!(type = exp->expr_common_rec.type))
	return NULL;

      if (type->id == TO_ClassType)
	return &type->class_type_rec;
      else if (type->id == TO_TypeSCQF && 
	       type->type_scqf_rec.type->id == TO_ClassType)
	{
	  if (qual)
	    *qual = type->type_scqf_rec.scqf;
	  return &type->type_scqf_rec.type->class_type_rec;
	}
      else
	if (type->id == TO_SimpleType && 
	    type->simple_type_rec.cl == TC_Generic)
	  return NULL;
	else if (type->id == TO_TypeSCQF &&
		 type->type_scqf_rec.type->id == TO_SimpleType && 
		 type->type_scqf_rec.type->simple_type_rec.cl == TC_Generic)
	  return NULL;
	else
	  {
	    FatalError ("the type of this expression is not `class type'\n");
	    return NULL;
	  }
    }
  else
    return ThisClass;
}

int 
CheckClassType (OO_ClassType c1, OO_ClassType c2, int exact, int nowarn)
{
  if (!c1 || !c2)
    return TYPE_OK;

  if (c1->class_id_public == c2->class_id_public)
    return TYPE_OK;

  if (exact > 0)
    return TYPE_NG;

  if (c2->status == CLASS_NONE)
#if 0
    if (!(c2 = GetClassFromUsedList (c2->class_id_public)))
      {
	FatalError ("used class not loaded\n");
	return TYPE_NG;
      }
#else
  c2 = GetClassFromUsedList (c2->class_id_public);
#endif

  return is_subclass (c1, c2, nowarn);
}

int 
CheckType (OO_Type t1, OO_Type t2, int exact, int nowarn)
{
  if (!t1 || !t2)
    return TYPE_OK;

  if (t1->id == TO_TypeSCQF && t1->type_scqf_rec.scqf & QF_CONST)
    t1 = t1->type_scqf_rec.type;

  if (t2->id == TO_TypeSCQF && t2->type_scqf_rec.scqf & QF_CONST)
    t2 = t2->type_scqf_rec.type;

  if (t1->id == TO_SimpleType)
    {
      if (t1->simple_type_rec.cl == TC_Zero)
	return TYPE_OK;

      else if (t1->simple_type_rec.cl == TC_Generic &&
	  (t2->id == TO_SimpleType || t2->id == TO_ClassType || 
	   t2->id == TO_TypeSCQF))
	return TYPE_OK;
    }

  if (t2->id == TO_SimpleType)
    {
      if (t2->simple_type_rec.cl == TC_Zero)
	return TYPE_OK;

      else if (t2->simple_type_rec.cl == TC_Generic &&
	  (t1->id == TO_SimpleType || t1->id == TO_ClassType || 
	   t1->id == TO_TypeSCQF))
	return TYPE_OK;
    }

  if (t1->id != t2->id)
    if (exact || 
	(t1->id != TO_SimpleType && t1->id != TO_TypeSCQF) ||
	(t2->id != TO_SimpleType && t2->id != TO_TypeSCQF))
      return TYPE_NG;
  
  switch (t1->id)
    {
    case TO_SimpleType:
      if (t2->id == TO_TypeSCQF)
	return CheckType (t1, t2->type_scqf_rec.type, exact, nowarn);

      if (t1->simple_type_rec.cl == t2->simple_type_rec.cl)
	return TYPE_OK;
      else if (exact)
	return TYPE_NG;

      if (t2->simple_type_rec.cl == TC_Void)
	return TYPE_NG;

      switch (t1->simple_type_rec.cl)
	{
	case TC_Void:
	case TC_Char:
	case TC_Short:
	case TC_Int:
	case TC_Long:
	case TC_Float:
	case TC_Double:
	  if (t2->simple_type_rec.cl != TC_Condition)
	    return TYPE_OK;
	  else
	    return TYPE_NG;
	case TC_Condition:
	  return TYPE_NG;
	}
    case TO_ClassType:
      return CheckClassType (&t1->class_type_rec, &t2->class_type_rec, 
			     exact, nowarn);
    case TO_TypeSCQF:
      if (t2->id != TO_TypeSCQF)
	return CheckType (t1->type_scqf_rec.type, t2, exact, nowarn);

      if (t1->type_scqf_rec.scqf != t2->type_scqf_rec.scqf &&
	  (exact ||  t1->type_scqf_rec.scqf & SC_GLOBAL))
	return TYPE_NG;

      return CheckType (t1->type_scqf_rec.type, t2->type_scqf_rec.type,
			exact, nowarn);
    case TO_TypeProcess:
      return CheckType (t1->type_process_rec.type, t2->type_process_rec.type,
			exact, nowarn);
    case TO_TypeArray:
      return CheckType (t1->type_array_rec.type, t2->type_array_rec.type,
			exact, nowarn);
    case TO_TypeMethod:
      return CheckSignature (&t1->type_method_rec, &t2->type_method_rec,
			     exact);
    }
}

/*
 * a1 is definition of arguments
 */

int 
CheckArgs (OO_List a1, OO_List a2, int exact)
{
  OO_Type type;
  int check, result = TYPE_OK;

  while (a1)
    {
      OO_Expr exp;

      if (!a2 || !(exp = (OO_Expr) a2->car))
	return TYPE_NG;

      type = exp->expr_common_rec.type;

      check = CheckType (a1->car->symbol_rec.type, type, exact, 0);

      if (check < TYPE_OK || check == TYPE_SAFE && exact)
	return TYPE_NG;

      result = result == TYPE_OK ? check : result;

      a1 = &a1->cdr->list_rec;
      a2 = &a2->cdr->list_rec;
    }

  if (a2)
    return TYPE_NG;

  return result;
}

int
CheckSignature (OO_TypeMethod m1, OO_TypeMethod m2, int exact)
{
  int args;
  int result, check;
  int qual1, qual2;
  
  if (!m1 || !m2)
    return TYPE_OK;

  qual1 = m1->qualifier & ~(MQ_LOCKED | MQ_ABSTRACT);
  qual2 = m2->qualifier & ~(MQ_LOCKED | MQ_ABSTRACT);

  if (qual1 != qual2)
    return TYPE_NG;

  if ((result = CheckType (m1->type, m2->type, exact, 0)) < TYPE_OK ||
      result == TYPE_SAFE && exact)
    return TYPE_NG;

  if ((check = CheckArgs (m1->args, m2->args, exact)) < TYPE_OK ||
      check == TYPE_SAFE && exact)
    return TYPE_NG;

  return result | check;
}

int 
CheckSimpleType (OO_Type type, int kind)
{
  if (!type)
    return TYPE_OK;

  if (type->id == TO_SimpleType)
    {
      int cl = type->simple_type_rec.cl;

      if (cl == kind)
	return TYPE_OK;

      else if (kind != TC_Condition && kind != TC_Void)
	{
	  if (cl == TC_Generic || cl == TC_Zero)
	    return TYPE_OK;
	  else
	    return TYPE_NG;
	}

      else
	return TYPE_NG;
    }

  while (type->id == TO_TypeSCQF)
    type = type->type_scqf_rec.type;

  if (type->id != TO_SimpleType)
    return TYPE_NG;

  else 
    return CheckSimpleType (type, kind);
}

int
CheckTypeID (OO_Type type, int id)
{
  if (!type)
    return TYPE_OK;

  switch (id)
    {
    case TO_SimpleType:
      if (type->simple_type_rec.cl == TC_Generic)
	return TYPE_SAFE;

      else if (type->id == id)
	return TYPE_SAFE;

      else if (type->id == TO_TypeSCQF)
	return CheckTypeID (type->type_scqf_rec.type, id);

      return TYPE_NG;

    case TO_ClassType:
      if (type->id == id)
	return TYPE_SAFE;

      else if (type->id == TO_TypeSCQF)
	return CheckTypeID (type->type_scqf_rec.type, id);

      return TYPE_NG;

    case TO_TypeArray:
    case TO_TypeProcess:
      if (type->id != id)
	return TYPE_NG;

      else
	return TYPE_SAFE;
    }
}

int
CheckReturnType (OO_Expr exp)
{
  int result = TYPE_OK;

  if (Error)
    return TYPE_OK;

  if (exp)
    {
      if (CheckSimpleType (CurrentMethod->type->type_method_rec.type, 
			   TC_Void) == TYPE_OK)
	{
	  FatalError ("the type of this method: `%s' is `void', "
		      "so cannot return any value\n", 
		      CurrentMethod->string);
	  return TYPE_NG;
	}
      else if (!exp)
	{
	  FatalError ("the type of this method: `%s' is not `void', "
		      "so have to return some value\n", 
		      CurrentMethod->string);
	  return TYPE_NG;
	}
	

      if ((result = CheckType (CurrentMethod->type->type_method_rec.type, 
			       exp->expr_common_rec.type, 0, 0)) < TYPE_OK)
	FatalError ("illegal type of return value\n");
    }

  return result;
}
#endif CFE

void
  DestroyType (OO_Type type)
{
  if (!type)
    return;

  switch (type->id)
    {
    case TO_SimpleType:
      DestroySymbol (type->simple_type_rec.symbol);
      break;
    case TO_ClassType:
#ifndef CFE
      return;
#else
      DestroyClass (&type->class_type_rec);
      break;
#endif CFE
    case TO_TypeSCQF:
      DestroyType (type->type_scqf_rec.type);
      break;
    case TO_TypeArray:
      DestroyType (type->type_array_rec.type);
#if 0
      if (type->type_array_rec.length && type->type_array_rec.is_created)
	DestroyExp (type->type_array_rec.length);
#endif
      break;
    case TO_TypeProcess:
      DestroyType (type->type_process_rec.type);
      break;
    case TO_TypeMethod:
#ifndef CFE
      return;
#else
      DestroyType (type->type_method_rec.type);
      DestroyList (type->type_method_rec.args);
#endif CFE
    }
  free (type);
}

