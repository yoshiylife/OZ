/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#ifndef CFE
#include <stdio.h>
#include <stdlib.h>

#include "lang/internal.h"

#include "common.h"

#include "ozc.h"

void
DestroyObject (OO_Object obj)
{
  if (!obj)
    return;

  switch (obj->id)
    {
    case TO_Symbol:
      break;
    case TO_Constant:
    case TO_IncDec:
    case TO_Unary:
    case TO_Binary:
    case TO_ArithCompare:
    case TO_EqCompare:
    case TO_Assignment:
    case TO_Conditional:
      DestroyExp ((OO_Expr) obj);
      break;
    }
}
#endif CFE

OO_List
CreateList (OO_Object obj1, OO_Object obj2)
{
  OO_List list;

  list = (OO_List) malloc (sizeof (OO_List_Rec));
  list->car = obj1;
 
  if (obj2)
    {
      list->cdr = (OO_Object) malloc(sizeof (OO_List_Rec));
      ((OO_List) list->cdr)->car = obj2;
      ((OO_List) list->cdr)->cdr = NULL;
    }
  else
    list->cdr = NULL;

  return list;
}

void
DestroyList (OO_List list)
{
  OO_List buf;

  while (list)
    {
#ifndef CFE
      DestroyObject (list->car);
#else
      DestroyClass (list->car->symbol_rec.class_part_defined);
      DestroySymbol (&list->car->symbol_rec);
#endif CFE
      buf = (OO_List) list->cdr;
      free (list);
      list = buf;
    }
}

OO_List
AppendList (OO_List *list, OO_List list2)
{
  if (!list)
    {
      fprintf (stderr, "cannot append to `null list'\n");
      exit(1);
    }

  if (!*list)
    return *list = list2;

  if (!(*list)->cdr)
    {
      (*list)->cdr = (OO_Object) list2;
      return (*list);
    }

  AppendList ((OO_List *) &(*list)->cdr, list2);
  return *list;
}

#ifndef CFE
void
CheckList (OO_List list, OO_List list2)
{
  while (list)
    {
      CheckSymInList (list2, &list->car->symbol_rec);
      list= &list->cdr->list_rec;
    }
}

void
CheckSymInList (OO_List list, OO_Symbol sym)
{
  while (list)
    {
      if (!strcmp (list->car->symbol_rec.string, sym->string))
	{
	  FatalError ("symbol: '%s' already used\n", 
		      list->car->symbol_rec.string);
	  break;
	}
      list = &list->cdr->list_rec;
    }
}

int 
  CountList (OO_List list)
{
  int i = 0;

  while (list)
    {
      i++;
      list = &list->cdr->list_rec;
    }

  return i;
}

#if 0
OzLangPrintf (void *a)
{
  printf ("0x%x\n", a);
}
#endif
#endif CFE
