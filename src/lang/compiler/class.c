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
#endif CFE

#include "class.h"

#ifndef CFE
#include "lang/school.h"
#include "type.h"
#include "exp.h"
#include "symbol.h"
#include "block.h"
#include "common.h"
#include "emit-method.h"
#include "emit-layout.h"
#include "emit-header.h"
#include "class-z.h"

OO_ClassType ThisClass = NULL, PrivClass = NULL, ObjectClass;
OO_Symbol Self;

int Pass;

static OO_RenameAlias tail_ra;
static OO_ParentDesc tail_parents = NULL;
static OO_List tail, arg = NULL;

static char *ClassName;

static
  convert_suffix (OO_ClassType pclass)
{
  OO_List list = pclass->class_part_list;

  while (list)
    {
      OO_ParentDesc parents = ThisClass->parent_desc;
      int plus = 0;

      while (parents)
	{
	  OO_List part = parents->class->class_part_list;

	  while (part)
	    {
	      if (part->car->class_type_rec.class_id_public 
		  == list->car->class_type_rec.class_id_public)
		plus++;
	      part = &part->cdr->list_rec;
	    }

	  if (parents->class->class_id_public 
	      == list->car->class_type_rec.class_id_public)
	    plus++;

	  parents = parents->next;
	}

      list->car->class_type_rec.class_id_suffix += plus;
      list = &list->cdr->list_rec;
    }
}

static
  set_slot_no2_of_object_methods (OO_Symbol sym)
{
  int i;

  for (i = 0; i < OBJECT_METHODS; i++)
    {
      if (!strcmp (sym->string, object_methods[i].name))
	{
	  sym->slot_no2 = i;
	  return;
	}
    }

  FatalError ("symbol: `%s' not defined in `Object' class\n", sym->string);
}

static 
  check_members (OO_List list, int part)
{
  while (list)
    {
      if (!list->car->symbol_rec.type)
	FatalError ("symbol: `%s' not defined\n", 
		    list->car->symbol_rec.string);

      else if (list->car->symbol_rec.type->id == TO_TypeMethod &&
	       list->car->symbol_rec.type->type_method_rec.qualifier 
	       & MQ_ABSTRACT)
	{
	  if (Part == PRIVATE_PART)
	    {
	      if (ThisClass->qualifiers != SC_ABSTRACT)
		FatalError ("this class is not abstract, "
			    "but method: `%s' is abstract\n", 
			    list->car->symbol_rec.string);

	      else if (part == PRIVATE_PART)
		FatalError ("cannot define private abstract method:`%s'\n",
			    list->car->symbol_rec.string);
	    }
	}
      
      list = &list->cdr->list_rec;
    }
}

static 
  check_access_ctrls (OO_List this, OO_List priv)
{
  OO_List list1 = this, list2 = priv;
  int sequencial = 1;
  OO_List from;
  int list1_num = 0, list2_num = 0;

  while (list1)
    {
      if (sequencial)
	{
	  if (!list2)
	    return -1;

	  if (!strcmp (list1->car->symbol_rec.string, 
		       list2->car->symbol_rec.string))
	    {
	      list2 = &list2->cdr->list_rec;
	      list2_num++;
	    }
	  else
	    {
	      sequencial = 0;
	      from = list2;
	      list2_num = -1;
	      continue;
	    }
	}
      else
	{
	  list2 = from;
	  while (list2)
	    {
	      if (!strcmp (list1->car->symbol_rec.string, 
			   list2->car->symbol_rec.string))
		break;
	      list2 = &list2->cdr->list_rec;
	    }
	  if (!list2)
	    return -1;
	}
      list1 = &list1->cdr->list_rec;
      list1_num++;
    }

  if (sequencial)
    { 
      if (list2)
	return -1;
      else
	return 0;
    }
    
  if (list2_num < 0)
    {
      list2 = priv;
      list2_num = 0;
      while (list2)
	{
	  list2 = &list2->cdr->list_rec;
	  list2_num++;
	}
    }

  if (list1_num == list2_num)
    return 0;
  else
    return -1;
}

static 
set_method_in_list (OO_Symbol sym, OO_List list, int access)
{
  while (list)
    {
      if (!strcmp (sym->string, list->car->symbol_rec.string))
	{
	  if (!list->car->symbol_rec.type)
	    {
	      if (list->car->symbol_rec.conflict < 0)
		{
		  DestroySymbol (&list->car->symbol_rec);
		  if (access == CONSTRUCTOR_PART &&
		      (CheckSimpleType (sym->type->type_method_rec.type, 
					TC_Void) < TYPE_OK))
		    FatalError ("constructor: %s must be `void'\n", 
				sym->string);

		  list->car = (OO_Object) sym;
		  list->car->symbol_rec.conflict = 0;
		}
	      else
		list->car->symbol_rec.conflict = 1;
	    }
	  else
	    list->car->symbol_rec.conflict++;
	  return 1;
	}
	
      list = &list->cdr->list_rec;
    }
  return 0;
}

static 
set_method (OO_Symbol sym)
{
  if (set_method_in_list (sym, ThisClass->public_list, PUBLIC_PART))
    return 1;
  if (set_method_in_list (sym, ThisClass->constructor_list, 
			  CONSTRUCTOR_PART))
    return 1;
  if (set_method_in_list (sym, ThisClass->protected_list, 
			  PROTECTED_PART))
    return 1;

  AppendList (&ThisClass->private_list, 
	      CreateList ((OO_Object) sym, NULL));
    
  return 0;
}

static
  set_methods (OO_List list)
{
  while (list)
    {
      if (!list->car->symbol_rec.rename)
	set_method (&list->car->symbol_rec);
      list = &list->cdr->list_rec;
    }
}

static OO_Symbol
  restore_name (OO_ParentDesc parent, OO_Symbol sym)
{
  OO_RenameAlias ra = parent->rename_alias;

  while (ra)
    {
      if (ra->kind == RA_RENAME)
	{
	  if (!strcmp (sym->string, ra->to->string))
	    return ra->from;
	  
	  if (!strcmp (sym->string, ra->from->string))
	    return NULL;
	}
      else 
	{
	  if (!strcmp (sym->string, ra->to->string))
	    return NULL;
	  
	  if (!strcmp (sym->string, ra->from->string))
	    return ra->from;
	}
      ra = ra->next;
    }
  return sym;
}

static OO_Symbol
  check_redefined_in_list (OO_Symbol sym, OO_List list)
{
  while (list)
    {
      if (!strcmp (sym->string, list->car->symbol_rec.string))
	{
	  if (CheckType (list->car->symbol_rec.type, sym->type, 
			 TYPE_EXACT, TYPE_NO_WARN) < TYPE_OK)
	    FatalError ("overriding method: `%s' must be exactly same type\n",
			sym->string);
	  
	  return &list->car->symbol_rec;
	}
      list = &list->cdr->list_rec;
    }
  return NULL;
}

static 
OO_Symbol 
  redefined_object_methods (OO_ClassType cl, OO_Symbol sym)
{
  int i;

  for (i = 0; i < OBJECT_METHODS; i++)
    if (!strcmp (object_methods[i].name, sym->string))
      return check_redefined_in_list (sym, cl->public_list);

  return NULL;
}

static OO_Symbol
  is_this_redefined (OO_ParentDesc parents, OO_Symbol sym)
{
  OO_Symbol member;

  if (!parents)
      return NULL;

  if (member = redefined_object_methods (parents->class, sym))
    return member;

  parents = parents->next;
  while (parents)
    {
      if (!(sym->orig_name = restore_name (parents, sym)))
	{
	  parents = parents->next;
	  continue;
	}

      if (member = check_redefined_in_list (sym->orig_name, 
					    parents->class->public_list))
	return member;

      if (member = check_redefined_in_list (sym->orig_name, 
					    parents->class->constructor_list))
	return member;

      if (member = check_redefined_in_list (sym->orig_name, 
					    parents->class->protected_list))
	return member;

      parents = parents->next;
    }

  return NULL;
}

static 
  set_access_list (OO_Symbol sym, OO_List list, int access)
{
  while (list)
    {
      if (!strcmp (list->car->symbol_rec.string, sym->string))
	{
	  if (!list->car->symbol_rec.type)
	    DestroySymbol(&list->car->symbol_rec);
	  sym->access = access;
	  list->car = (OO_Object) sym;
	  return 1;
	}
      list = (OO_List) list->cdr;
    }

  return 0;
}

static 
  set_access (OO_Symbol sym)
{
  if (ThisClass->qualifiers == SC_SHARED || 
      ThisClass->qualifiers == SC_RECORD)
    {
      sym->access = PUBLIC_PART;
      AppendList (&ThisClass->public_list, 
		  CreateList ((OO_Object) sym, NULL));
    }
  else
    {
      if (set_access_list (sym, ThisClass->public_list, PUBLIC_PART))
	return;
     
      if (set_access_list (sym, ThisClass->constructor_list, 
			   CONSTRUCTOR_PART))
	return;
      
      if (ThisClass->qualifiers != SC_STATIC)
	if (set_access_list (sym, ThisClass->protected_list, PROTECTED_PART))
	  return;

      sym->access = PRIVATE_PART;
      AppendList (&ThisClass->private_list, 
		  CreateList ((OO_Object) sym, NULL));
    }
}
#endif

OO_ClassType 
CreateClass (char *name, int class_sc, int block)
{
  OO_ClassType cl = (OO_ClassType) malloc(sizeof(OO_ClassType_Rec));

  if (name)
    {
      cl->symbol = CreateSymbol (name);
      cl->symbol->is_class = 1;
      cl->symbol->class_part_defined = cl;
    }
  else
    cl->symbol = NULL;

  cl->public_list = NULL;
  cl->protected_list = NULL;
  cl->constructor_list = NULL;

  cl->private_list = NULL;

  cl->class_part_list = NULL;

#ifndef CFE
  if (block)
    cl->block = CreateBlock ();
  else
    cl->block = NULL;
#else
  cl->block = NULL;
#endif

  cl->parent_desc = NULL;

  cl->status = CLASS_NONE;

  if (name)
    {
      cl->class_id_public = str2oid (GetVID (name, 0));

#if 0
      if (class_sc == SC_SHARED || class_sc == SC_STATIC ||
	  class_sc == SC_RECORD)
#else
      if (class_sc == SC_SHARED)
#endif
	cl->class_id_protected = cl->class_id_public;
      else
	cl->class_id_protected = str2oid (GetVID (name, 1));

#if 0
      if (class_sc == SC_SHARED || class_sc == SC_RECORD)
#else
      if (class_sc == SC_SHARED)
#endif
	cl->class_id_implementation = cl->class_id_public;
      else
	cl->class_id_implementation = str2oid (GetVID (name, 2));
    }

  cl->qualifiers = class_sc;

  switch (class_sc)
    {
    case SC_STATIC:
      cl->cl = TC_StaticObject;
      break;
    case SC_RECORD:
      cl->cl = TC_Record;
      break;
    case SC_SHARED:
      cl->cl = TC_Shared;
      break;
    default:
      cl->cl = TC_Object;
    }

  cl->id = TO_ClassType;
 
  cl->no_parents = 0;
  cl->slot_no2 = -1;
  cl->class_id_suffix = 0;
  cl->size = -1;

  cl->used_for_instanciate = 0;
  cl->used_for_invoke = 0;

  return cl;
}

#ifndef CFE
void 
AddParent (char *name)
{
  OO_ParentDesc parents;
  OO_ClassType cl;

  parents = (OO_ParentDesc) malloc (sizeof (OO_ParentDesc_Rec));
  parents->rename_alias = NULL;
  parents->next = NULL;

  parents->class = LoadClassFromZ (name, 0);

  convert_suffix (parents->class);

  if (ThisClass->parent_desc)
    {
      tail_parents->next = parents;
    }
  else
    {
      ThisClass->parent_desc = parents;
    }
  tail_parents = parents;

  ThisClass->no_parents += parents->class->no_parents + 1;
}

void
AddRenameAlias (char *old, char *new, int kind)
{
  OO_RenameAlias ra;
  OO_ParentDesc parents;

  ra = (OO_RenameAlias) malloc (sizeof (OO_RenameAlias_Rec));
  ra->to = CreateSymbol (new);
  ra->kind = kind;
  ra->next = NULL;
  
  if (tail_parents->rename_alias)
    tail_ra->next = ra;
  else
    tail_parents->rename_alias = ra;
  tail_ra = ra;

  if (ra->from = GetMethod (old, tail_parents->class, 0, PROTECTED_PART))
    {
      if (ra->kind == RA_ALIAS && ra->from->is_variable)
	FatalError ("instance variable: `%s' cannot be aliased\n", old);

      bcopy (ra->from, ra->to, sizeof (OO_Symbol_Rec));
      strcpy (ra->to->string, new);
      if (ra->kind == RA_ALIAS)
	{
	  ra->to->class_part_defined = tail_parents->class;
	  ra->to->slot_no2 = ++tail_parents->class->slot_no2;
	  
	  ra->to->alias = CreateSymbol (old);
	  ra->to->alias->class_part_defined = ra->from->class_part_defined;
	  ra->to->alias->slot_no2 = ra->from->slot_no2;
	}
      else
	{
	  ra->from->rename = 1;
	}
    }

  else
    {
      FatalError ("symbol: `%s' not defined in any parent classes\n", old);
      ra->from = CreateSymbol (old);
    }
}

void
LoadClass (char *filename, char *name, char *oz_root)
{
#if 0
  if (Part != PUBLIC_PART)
    PrivClass = LoadClassFromZ (name, Part == PROTECTED_PART ? 1 : 0);
#endif

  if (!(yyin = fopen(filename, "r")))
    {
      fprintf(stderr, "cannot open file: %s\n", filename);
      exit(1);
    }
  
  /* octal escaping */
  yyin = EucToOctalEscape (yyin, oz_root);

  yyparse ();

  if (ThisClass->cl == TC_Object && Part != PRIVATE_PART)
    {
      fclose (yyin);
      return;
    }

  if (!Error)
    {
      if (ThisClass->cl == TC_Record)
	EmitLayout ();
      
      else if (ThisClass->cl == TC_Shared)
	{
	  EmitExceptions ();
	  fclose (yyin);
	  return;
	}
    }

  Pass = 1;
  yylineno = 1;
  rewind (yyin);

#if 0
  if (ThisClass->cl == TC_Record)
    EmitFirst (PublicOutputFileH);
  else
#endif
    EmitFirst (PrivateOutputFileC);

  yyparse ();
  fclose (yyin);
}

void
CreateMember (OO_Symbol sym)
{
  OO_Symbol psym;

  set_access (sym);

  if ((ThisClass->cl == TC_Object && sym->access > Part) || Mode != NORMAL)
    return;

  if (ThisClass->cl == TC_Object && 
      (psym = is_this_redefined (ThisClass->parent_desc, sym)))
    {
      if (sym->is_variable)
	FatalError ("variable: `%s' defined in any parent classes\n", 
		    sym->string);

      if (psym->type->id == TO_TypeMethod && 
	  psym->type->type_method_rec.qualifier & MQ_ABSTRACT)
	psym->type->type_method_rec.qualifier ^= MQ_ABSTRACT;

      sym->class_id = psym->class_id;
      sym->class_part_defined = psym->class_part_defined;

      if (!sym->is_variable)
	sym->slot_no2 = psym->slot_no2;

      psym->class_id = ThisClass->class_id_public;
    }
  else
    {
      sym->orig_name = sym;
      sym->class_id = ThisClass->class_id_public;
      sym->class_part_defined = ThisClass;
      if (!sym->is_variable && Object)
	set_slot_no2_of_object_methods (sym);
    }
}

void
SetParentMethods ()
{
  OO_RenameAlias ra;
  OO_ParentDesc parents = ThisClass->parent_desc;

  if (!parents)
    return;

  while (parents)
    {
      ra = parents->rename_alias;
      while (ra)
	{
	  if (set_method (ra->to) && ra->kind == RA_ALIAS)
	    FatalError ("aliased method: `%s' should "
			"be used only as `private'\n",
			ra->to->string);

	  ra = ra->next;
	}

      set_methods (parents->class->public_list);
      set_methods (parents->class->constructor_list);
      set_methods (parents->class->protected_list);

      parents = parents->next;
    }

}

int
CheckAccessCtrls ()
{
  if (check_access_ctrls (ThisClass->public_list, PrivClass->public_list) < 0)
    return -1;

  if (check_access_ctrls (ThisClass->constructor_list, 
			  PrivClass->constructor_list) < 0)
    return -1;

  if (Part == PROTECTED_PART)
    return 0;

  if (check_access_ctrls (ThisClass->protected_list, 
			  PrivClass->protected_list) < 0)
    return -1;
  
  return 0;
}

int
CheckParents ()
{
  OO_ParentDesc p1;
  OO_List list;

  if (!ThisClass->parent_desc)
    return 0;

  /* skip `Object' class */
  p1 = ThisClass->parent_desc->next;
  while (p1)
    {
      list = PrivClass->class_part_list;
      list = &list->cdr->list_rec;
      while (list)
	{
	  if (p1->class->class_id_public 
	      == list->car->class_type_rec.class_id_public)
	    break;
	  list = &list->cdr->list_rec;
	}
      if (!list)
	return -1;
      p1 = p1->next;
    }

  return 0;
}

OO_ClassType
SearchParentClass (char *name)
{
  OO_ParentDesc parents;

  if (!ThisClass)
    return NULL;

  parents = ThisClass->parent_desc;

  while (parents)
    {
      if (parents->class && parents->class->symbol && 
	  !strcmp (name, parents->class->symbol->string))
	{
	  return parents->class;
	}

      parents = parents->next;
    }
  return NULL;
}

void
SetParents ()
{
  OO_ParentDesc parents = ThisClass->parent_desc;
  OO_List list, list2;

  if (Object)
    return;

  list = ThisClass->class_part_list 
    = (OO_List) malloc (sizeof (OO_List_Rec));
  list->cdr = NULL;

  while (parents)
    {
      list2 = parents->class->class_part_list;
      if (list2)
	list2 = &list2->cdr->list_rec;
      while (list2)
	{
	  list->car = list2->car;
	  list->car->class_type_rec.class_id_public 
	    = list->car->class_type_rec.class_id_public;
	  list->car->class_type_rec.class_id_protected
	    = list->car->class_type_rec.class_id_protected;
	  list = (OO_List) list->cdr 
	    = (OO_Object) malloc (sizeof (OO_List_Rec));
	  list->cdr = NULL;
	  list2 = &list2->cdr->list_rec;
	}
      list->car = (OO_Object) parents->class;
      if (parents = parents->next)
	{
	  list = (OO_List) list->cdr 
	    = (OO_Object) malloc (sizeof (OO_List_Rec));
	  list->cdr = NULL;
	}
    }
}

void
CheckMembers ()
{
  check_members (ThisClass->public_list, PUBLIC_PART);
  check_members (ThisClass->constructor_list, CONSTRUCTOR_PART);
  check_members (ThisClass->protected_list, PROTECTED_PART);
  check_members (ThisClass->private_list, PRIVATE_PART);
}

void 
CreateObjectClass ()
{
  ObjectClass = CreateClass (OBJECT_NAME, 0, 0);
}
#endif

