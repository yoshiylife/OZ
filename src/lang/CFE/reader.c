/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>

#include "lang/internal.h"

#include "cfe.h"
#include "cb.h"

#define CFE
#include "../compiler/class-z.c"

static OO_ClassType class_info = NULL;

static OO_Symbol
  search_member_in_list (OO_List list, char *name, OO_ClassType cl)
{
  int slot_no2 = -1;

  if (*name == '#')
    slot_no2 = atoi (&name[1]);

  while (list)
    {
      if (((slot_no2 >= 0 && list->car->symbol_rec.slot_no2 == slot_no2) ||
	  !strcmp (list->car->symbol_rec.string, name)) && 
	  (list->car->symbol_rec.class_part_defined->class_id_public 
	  == cl->class_id_public ||
	  list->car->symbol_rec.class_part_defined->class_id_protected
	  == cl->class_id_protected))
	return &list->car->symbol_rec;
      list = &list->cdr->list_rec;
    }
  return NULL;
}

static void
  free_class_info ()
{
  DestroyClass (class_info);
  class_info = NULL;
}

OO_ClassType
  LoadClassInfo (char *name, int public)
{
  char vid[17], *vid_buf;
  char filename[256];

  if (class_info)
    free_class_info ();

  if (!(vid_buf = GetVID (name, !public)))
    {
      fprintf (stderr, "not found `%s' in school\n", name);
      return NULL;
    }

  strcpy (vid, vid_buf);
  if (public)
    {
      sprintf (filename, "%s/%s/public.t", ClassPath, vid);
      if (LoadSubSchool (filename))
	return NULL;

      sprintf (filename, "%s/%s/public.z", ClassPath, vid);
    }
  else
    {
      sprintf (filename, "%s/%s/protected.t", ClassPath, vid);
      if (LoadSubSchool (filename))
	return NULL;

      sprintf (filename, "%s/%s/protected.z", ClassPath, vid);
    }
  
  class_info =  LoadClassFromZ (name, public);

  return class_info;
}

OO_Symbol
  SearchMember (OO_ClassType cl, char *name)
{
  OO_Symbol sym;

  if (!cl)
    return NULL;

  if (sym = search_member_in_list (cl->public_list, name, cl))
    return sym;

  if (sym = search_member_in_list (cl->constructor_list, name, cl))
    return sym;

  if (sym = search_member_in_list (cl->protected_list, name, cl))
    return sym;

  return NULL;
}
