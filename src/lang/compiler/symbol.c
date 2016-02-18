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
#include "block.h"
#include "symbol.h"
#endif CFE

#include "type.h"

#ifndef CFE
static OO_Symbol
  get_symbol_from_parents (OO_ParentDesc parents, char *name)
{
  OO_Symbol found = NULL;
  OO_RenameAlias ra;
  OO_List list;

  while (parents)
    {
      ra = parents->rename_alias;
      
      while (ra)
	{
	  if (!strcmp (ra->to->string, name))
	    {
	      list = parents->class->protected_list;
	      while (list)
		{
		  if (!strcmp (ra->from->string, 
				   list->car->symbol_rec.string))
		    break;
		  list = &list->cdr->list_rec;		  
		}
	      if (!list)
		FatalError ("symbol: `%s' not found in any parent classes\n", 
			    ra->from->string);
	      else 
		{
		  found = CreateSymbol (name);
		  bcopy (&list->car->symbol_rec, found, 
			 sizeof (OO_Symbol_Rec));
		  strcpy (found->string, name);
		}
	      goto next;
	    }	      

	  if (!strcmp (ra->from->string, name))
	    goto next;

	  ra = ra->next;
	}

      list = parents->class->protected_list;
      while (list)
	{
	  if (!strcmp (name, list->car->symbol_rec.string))
	    if (found)
	      {
		if (!strcmp (list->car->symbol_rec.orig_name->string, name))
		  FatalError ("symbol: `%s' conflicts "
			      "in any parent classes\n", name);
		else
		  goto next;
	      }
	    else
	      {
		found = &list->car->symbol_rec;
		goto next;
	      }
	  
	  list = &list->cdr->list_rec;		  
	}
    next:
      parents = parents->next;
    }

  return found;
} 

OO_Symbol
GetSymbol (char *name)
{
  OO_Block block = CurrentBlock;
  OO_Symbol vars;

  while (block)
    {
      vars = block->vars;

      while (vars)
	{
	  if (!strcmp (vars->string, name))
	    goto found;
	  
	  vars = vars->link;
	}

      block = block->up;
    }

  if (!ThisClass)
    return NULL;

  if (vars = get_symbol_from_parents (ThisClass->parent_desc, name))
    {
    found:
      if (!vars->is_variable)
	return NULL;

#if 0
      if (Pass == 1 && vars->type && vars->type->id == TO_ClassType && 
	  !vars->type->class_type_rec.symbol)
	if (!(vars->type 
	      = (OO_Type) GetClassFromUsedList (vars->type->class_type_rec
						.class_id_public)))
	  IntrenalError ("used class not loaded\n");
#else
      if (Pass == 1 && vars->type && vars->type->id == TO_ClassType && 
	  !vars->type->class_type_rec.symbol)
	vars->type 
	  = (OO_Type) GetClassFromUsedList (vars->type->class_type_rec
					    .class_id_public);
#endif

      return vars;
    }
  else
    return NULL;
}
#endif CFE

OO_Symbol 
CreateSymbol (char *name)
{
  int len = name ? strlen (name) : 0;

  OO_Symbol sym = (OO_Symbol) malloc(sizeof(OO_Symbol_Rec) + len);
  if (len)
    strcpy(sym->string, name);
  sym->class_part_defined = NULL;
  sym->link = NULL;
  sym->id = TO_Symbol;
  sym->type = NULL;
  sym->init = NULL;
  sym->value = NULL;
  sym->is_created = 0;
  sym->conflict = -1;
  sym->is_variable = 0;
  sym->slot_no2 = -1;
  sym->func_no = -1;
  sym->access = 0;
  sym->alias = 0;
  sym->rename = 0;

  return sym;
}

void
DestroySymbol (OO_Symbol sym)
{
#ifndef CFE
  if (!sym || sym->is_arg || sym->class_part_defined)
    return;
#else
  if (!sym)
    return;
#endif

  if (sym->type)
    DestroyType (sym->type);

#ifndef CFE
  if (sym->value && sym->is_created)
    DestroyExp (sym->value);

  if (sym->init)
    {
      OO_Symbol vars = CurrentBlock->vars;

      while (vars)
	{
	  if (vars == sym)
	    break;
	  vars = vars->link;
	}
      if (!vars)
	DestroyObject (sym->init);
    }
#endif
  
  free (sym);
}

