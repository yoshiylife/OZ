/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "ozc.h"
#include "symbol.h"
#include "block.h"
#include "class.h"
#include "error.h"
#include "class-list.h"

OO_Block CurrentBlock = NULL;

OO_Symbol CurrentMethod;

int SlotNo = -1;

static int
  check_init_record (OO_Symbol var, OO_List exp_list)
{
  OO_List list; 
  OO_Expr exp;
  OO_Symbol sym;

  if (var->type->class_type_rec.status == CLASS_NONE)
    {
      var->type 
	= (OO_Type) GetClassFromUsedList (var->type
					  ->class_type_rec.class_id_public);
    }

  list = var->type->class_type_rec.public_list;

  while (list)
    {
      sym = &list->car->symbol_rec;

      if (!exp_list)
	return TYPE_NG;

      exp = (OO_Expr) exp_list->car;

      if (sym->type->id == TO_ClassType && 
	  sym->type->class_type_rec.cl == TC_Record)
	{
	  if (exp->id != TO_Comma2 || 
	      check_init_record (sym, exp->comma_rec.expr_list) 
	      < TYPE_OK)
	    return TYPE_NG;
	}
	
      else if (CheckType (list->car->symbol_rec.type, 
			  exp->expr_common_rec.type, 0, 0) < TYPE_OK)
	return TYPE_NG;

      do
	{
	  list = &list->cdr->list_rec;
	}
      while (list && !list->car->symbol_rec.is_variable);

      exp_list = &exp_list->cdr->list_rec;
    }

  if (exp_list)
    return TYPE_NG;

  return TYPE_OK;
}
  

static int
  check_defined_in_list (OO_Symbol sym, OO_List sym_list)
{
  OO_List list = sym_list;

  while (list)
    {
      if (!strcmp (list->car->symbol_rec.string, sym->string))
	{
	  if (!sym->is_variable)
	    if (CheckSignature (&sym->type->type_method_rec, 
				 &list->car->symbol_rec.type->type_method_rec,
				 1) == TYPE_OK)
	      {
		sym->slot_no2 = list->car->symbol_rec.slot_no2;
		return 0;
	      }
	    else
	      return -1;
	  else
	    if (CheckType (sym->type, list->car->symbol_rec.type, 1, 0) 
		== TYPE_OK)
	      return 0;
	    else
	      return -1;
	}
      list = (OO_List) list->cdr;
    }
  return -1;
}

static int 
  check_defined (OO_Symbol sym)
{
  switch (sym->access)
    {
    case PUBLIC_PART:
      return check_defined_in_list (sym, PrivClass->public_list);
    case PROTECTED_PART:
      return check_defined_in_list (sym, PrivClass->protected_list);
    case CONSTRUCTOR_PART:
      return check_defined_in_list (sym, PrivClass->constructor_list);
    }
}

static 
append_vars (OO_Symbol sym)
{
  OO_Symbol vars;

  vars = CurrentBlock->vars;

  while (vars)
    {
      if (*vars->string && !strcmp (vars->string, sym->string))
	{
	  FatalError ("symbol: `%s' is multiply defined\n", sym->string);
	  return;
	}
        
      if (!vars->link)
	{
	  vars->link = sym;
	  return;
	}
      vars = vars->link;
    }

  CurrentBlock->vars = sym;
}

static OO_Symbol 
get_symbol (char *name)
{
  OO_Symbol vars = CurrentBlock->vars;

  while (vars)
    {
      if (!strcmp (vars->string, name))
	return vars;
      vars = vars->link;
    }

  return NULL;
}

static OO_Symbol
  get_method (char *name, OO_List methods, int not_direct_call)
{
  OO_Symbol found = NULL;

  while (methods)
    {
      if ((not_direct_call || !methods->car->symbol_rec.rename) &&
	  !strcmp (methods->car->symbol_rec.string, name))
	found = &methods->car->symbol_rec;

      if (found)
	{
	  if (found->conflict > 0)
	    FatalError ("symbol: `%s' conflicts in some parents\n", name);
	  
	  if (Mode != NORMAL || found->type)
	    return found;
	  else
	    return NULL;
	}
	
      methods = &methods->cdr->list_rec;
    }

  return NULL;
}

static OO_Symbol
check_global_method (OO_Symbol sym, int qual, char *name)
{
  if (sym->type->type_method_rec.qualifier & MQ_GLOBAL)
    return sym;
  else
    {
      FatalError ("receiver is `global' but method: `%s' not so\n", name);
      return sym;
    }
}

OO_Block
CreateBlock ()
{
  OO_Block block = (OO_Block) malloc (sizeof (OO_Block_Rec));
  if (CurrentBlock)
    CurrentBlock->down = block;
  block->up = CurrentBlock;
  block->vars = NULL;
  block->down = NULL;
  CurrentBlock = block;

  return block;
}

void
DestroyBlock ()
{
  OO_Block block = CurrentBlock, bbuf;

  while (block)
    {
      OO_Symbol vars = block->vars, buf;

      while (vars)
	{
	  buf = vars->link;
	  DestroySymbol (vars);
	  vars = buf;
	}
      
      bbuf = block->down;
      free (block);
      block = bbuf;
    }

  CurrentBlock = ThisClass->block;
}

void
UpBlock () 
{
  CurrentBlock = CurrentBlock->up;
}

void
DownBlock ()
{
  if (!CurrentBlock->down)
    {
      fprintf (stderr, "cannot down block\n");
      exit (1);
    }
  CurrentBlock = CurrentBlock->down;
}

OO_Symbol
AddVar (int qual, char *type_str, int type_kind, TypedSymbol tsym, OO_Expr exp,
	int is_arg)
{
  OO_Symbol sym;

  if (!is_arg)
    {
      if (Pass && CurrentBlock == ThisClass->block)
	{
	  DestroyTypedSymbol (tsym);
	  return NULL;
	}
      
      else if (tsym && !*tsym->name)
	{
	  FatalError ("definition error\n");
	  return NULL;
	}

      if (ThisClass->qualifiers == SC_SHARED)
	{
	  qual |= QF_CONST;
	  if (Mode == NORMAL && !exp)
	    FatalError ("you must specify constant value\n");
	}
    }

  if (tsym)
    sym = CreateSymbol (tsym->name);

  else if (exp->id == TO_Symbol)
    sym = (OO_Symbol) exp;

  else
    sym = (OO_Symbol) exp->method_call_rec.obj;

  sym->is_variable = 1;
  sym->is_arg = is_arg;
  append_vars (sym);

  sym->type = tsym ? 
    CreateType (qual, type_str, type_kind, tsym->type) :
      exp->expr_common_rec.type;

  if (CurrentBlock == ThisClass->block)
    {
      CreateMember (sym);
      if (sym->type->id == TO_ClassType &&
	  sym->type->class_type_rec.cl == TC_Record &&
	  sym->type->class_type_rec.status == CLASS_NONE)
	sym->type 
	  = (OO_Type) GetClassFromUsedList (sym->type
					    ->class_type_rec.class_id_public);
    }

  if (tsym)
    {
      if (CurrentBlock == ThisClass->block)
	{
	  if (PrivClass && sym->access < Part && check_defined (sym) < 0)
	    FatalError ("symbol: `%s' had not defined previously, "
			"or signature changed\n", tsym->name);
	}
      DestroyTypedSymbol (tsym);
    }

  if (exp)
    {
      if ((exp->id == TO_Comma2 &&
	   check_init_record (sym, exp->comma_rec.expr_list) < TYPE_OK) ||
	  CheckType (sym->type, exp->expr_common_rec.type, 0, 0) 
	  < TYPE_OK)
	FatalError ("type mismatch about symbol: `%s'\n", sym->string);

      sym->init = (OO_Object) exp;
      sym->value = exp;
    }

  return sym;
}

OO_Symbol
AddMethod (int qual, char *type_str, int type_kind, 
	   MethodSymbol msym, int m_qual)
{
  OO_Symbol sym;
  int is_redefined;
  int proto = 0;

  if (Pass)
    return CurrentMethod = get_symbol (msym->tsym->name);

  CurrentMethod = sym = CreateSymbol (msym->tsym->name);

  append_vars (sym);

  sym->type = (OO_Type) malloc(sizeof(OO_TypeMethod_Rec));
  sym->type->id = TO_TypeMethod;
  sym->type->type_method_rec.qualifier =  m_qual;
  sym->type->type_method_rec.args = msym->arg;
  sym->type->type_method_rec.type = CreateType (qual, type_str, 
						type_kind, msym->tsym->type);
  CreateMember (sym);

  if (Mode != NORMAL)
    return sym;

  if (ThisClass->cl == TC_Record && m_qual)
    FatalError ("cannot define `global' or `locked' operator in record\n");

  if (sym->access == CONSTRUCTOR_PART && type_kind != TC_Void)
    FatalError ("the type of constructor: `%s' must be `void'\n", sym->string);

  if (PrivClass && sym->access < Part && check_defined (sym) < 0)
    FatalError ("symbol: `%s' had not defined previously, "
		"or signature changed\n", sym->string);

  if (sym->slot_no2 < 0 && sym->access <= Part)
    sym->slot_no2 = ++SlotNo;

  return sym;
}

OO_Symbol
 GetMethod (char *name, OO_ClassType cl, int qual, int access)
{
  OO_Symbol sym;
  int not_direct_call;

  if (!cl)
    return NULL;

  if (cl->status == CLASS_NONE)
    cl = GetClassFromUsedList (cl->class_id_public);
  
  not_direct_call 
    = access == CONSTRUCTOR_PART || access == PUBLIC_PART ? 1 : 0;

  if (access == CONSTRUCTOR_PART || access == PROTECTED_PART)
    {
      if (sym = get_method (name, cl->constructor_list, not_direct_call))
	return qual & SC_GLOBAL ? check_global_method (sym, qual, name) : sym;

      if (access == CONSTRUCTOR_PART)
	return NULL;
    }

  not_direct_call 
    = access != PRIVATE_PART ? 1 : 0;
      
  if (sym = get_method (name, cl->public_list, not_direct_call))
    return qual & SC_GLOBAL ? check_global_method (sym, qual, name) : sym;

  if (access == PUBLIC_PART)
    return NULL;

  if (sym = get_method (name, cl->protected_list, not_direct_call))
    return sym;

  if (access == PROTECTED_PART)
    return NULL;
  
  return get_method (name, cl->private_list, not_direct_call);
}

OO_ClassType
  GetDefinedClass (OO_Symbol sym, OO_ClassType class)
{
  OO_ClassType cl = class;
  OO_ParentDesc parents;

  if (get_method (sym->string, cl->constructor_list, 0))
    return cl;

  if (get_method (sym->string, cl->public_list, 0))
    return cl;

  if (get_method (sym->string, cl->protected_list, 0))
    return cl;

  parents = cl->parent_desc;

  while (parents)
    {
      if ((cl = GetDefinedClass(sym, parents->class)))
	return cl;

      parents = parents->next;
    }

  return NULL;
}
