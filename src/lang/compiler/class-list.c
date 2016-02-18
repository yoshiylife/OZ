/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>

#include "ozc.h"
#include "lang/school.h"
#include "class-list.h"
#include "class-z.h"
#include "class.h"

#include "emit-method.h"
#include "emit-header.h"

static ClassList clist = NULL;

ClassList
AddClassList (char *name)
{
  ClassList cl, before, cl2 = clist;

  if (Mode == NORMAL)
    {
      if (ThisClass && !strcmp (ThisClass->symbol->string, name))
	return NULL;

      else if (SearchParentClass (name))
	return NULL;
    }

  while (cl2)
    {
      if (!strcmp (cl2->name, name))
	{
	  cl2->count++;
	  return NULL;
	}

      before = cl2;
      cl2 = cl2->next;
    }

  cl = (ClassList) malloc (sizeof (ClassList_Rec) + strlen (name));
  cl->count = 0;
  cl->class = 0;
  strcpy (cl->name, name);

  cl->next = NULL;

  if (clist)
    before->next = cl;
  else
    clist = cl;

  return cl;
}

void
PrintClassList ()
{
  ClassList cl = clist;

  while (cl)
    {
      printf ("%s\n", cl->name);
      cl = cl->next;
    }
}

OO_ClassType
SearchClass (char *name)
{
  ClassList cl;
  OO_ClassType class;

  if (ThisClass && ThisClass->symbol)
    {
      char *vid;

      if ((vid = GetVID (name, 0)))
	if (str2oid (vid) == ThisClass->class_id_public)
	  {
	    return ThisClass;
	  }
    }

  if (ThisClass)
    {
      OO_ParentDesc parents = ThisClass->parent_desc;
      while (parents)
	{
	  if (!strcmp (name, parents->class->symbol->string))
	    {
	      return parents->class;
	    }
	
	  parents = parents->next;
	}
    }

  cl = clist;
  while (cl)
    {
      if (!strcmp (name, cl->name))
	{
	  if (!cl->class)
#if 1
	    cl->class = CreateClass (name, GetClassSC (name) , 0);
#else
	    cl->class = CreateClass (name, 0, 0);
#endif

	  return cl->class;
	}
      cl = cl->next;
    }

  return NULL;
}

void
EmitUsedHeader (FILE *fp)
{
  ClassList list;

  Emit (fp, "#include \"%s/private.h\"\n", OBJECT_PRIVATE);

  list = clist;
  while (list)
    {
#if 0
      if (ThisClass->cl != TC_Record || 
	  !list->class || list->class->cl != TC_Record)
#else
      if (!list->class || list->class->cl != TC_Record ||
	  list->class->status != CLASS_NONE)
#endif
	{
	  char *vid = GetVID (list->name, 0);

	  if (vid)
	    Emit (fp, "#include \"%s/public.h\"\n", vid);
#if 1
	  else if (list->class && list->class->status == CLASS_RECORD_EMITED)
	    {
	      Emit (fp, "#include \"");
	      EmitVID (fp, list->class->class_id_public, 0);
	      Emit (fp, "/public.h\"\n");
	    }
#endif
	}

      else 
	{
	  Emit (fp, "\n");
	  EmitRecordMemberDefinition (list->class);
	}

      list = list->next;
    }

  Emit (fp, "\n");
}

OO_ClassType 
GetClassFromUsedList (long long vid)
{
  ClassList list = clist;
  int i;
  char class_id[19], vids[3][17];

  if (vid == ThisClass->class_id_public)
    return ThisClass;

  while (list)
    {
      if (list->class && list->class->class_id_public == vid)
	{
	  if (list->class->status == CLASS_NONE)
	    list->class = LoadClassFromZ (list->class->symbol->string, 1);
	    
	  return list->class;
	}
      list = list->next;
    }

  sprintf (class_id, "__%08x%08x", 
	   (int) (vid >> 32), (int) (vid & 0xffffffff));
  for (i = 0; i < 3; i++)
    {
      sprintf (vids[i], "%08x%08x", 
	       (int) (vid >>32), (int) ((vid + i) & 0xffffffff));
    }
  list = AddClassList (class_id); 
  list->class = LoadClassFromZ (class_id, 1);
  AddSchool (class_id, vids, list->class->qualifiers, NULL, NULL);
  return list->class;
}

void
RemoveFromClassList (char *name)
{
  ClassList list = clist, buf = NULL;

  while (list)
    {
      if (!strcmp (list->name, name))
	{
	  if (!list->count)
	    {
	      if (buf)
		buf->next = list->next;
	      else
		clist = list->next;
	      free (list);
	    }
	  else
	    list->count--;
	  return;
	}
      buf = list;
      list = list->next;
    }
}

void
EmitImported ()
{
  ClassList list = clist;
  int num = 0;

  if (!clist)
    return;

  while (list)
    {
#if 0
      if (list->class && list->class->cl == TC_StaticObject)
#else
      if (list->class && 
	  list->class->cl != TC_Object && list->class->cl != TC_Shared)
#endif
	num++;
      list = list->next;
    }

  Emit (PrivateOutputFileC, "\n");
  Emit (PrivateOutputFileC, "struct {\n");
  Emit (PrivateOutputFileC, "  int number;\n");
#if 0
  Emit (PrivateOutputFileC, "  OZ_ImportedCodeEntryRec entry[%d", num);

  list = clist;
  while (list)
    {
      if (list->class && list->class->cl == TC_Record)
	{
	  Emit (PrivateOutputFileC, "\n  + OzLangImportedNumber_");
	  EmitVID (PrivateOutputFileC, list->class->class_id_public, 0);
	}

      list = list->next;
    }
  
  Emit (PrivateOutputFileC, "];\n");
#else
  Emit (PrivateOutputFileC, "  OZ_ImportedCodeEntryRec entry[%d];\n", num);
#endif
  Emit (PrivateOutputFileC, "} _OZ_ImportedCodesRec = {\n");

  Emit (PrivateOutputFileC, "  %d", num);

#if 0
  list = clist;
  while (list)
    {
      if (list->class && list->class->cl == TC_Record)
	{
	  Emit (PrivateOutputFileC, "\n  + OzLangImportedNumber_");
	  EmitVID (PrivateOutputFileC, list->class->class_id_public, 0);
	}

      list = list->next;
    }
#endif
  
  Emit (PrivateOutputFileC, ",\n");
  
  list = clist;
  while (list)
    {
#if 0
      if (list->class && list->class->cl == TC_StaticObject)
#else
      if (list->class && 
	  list->class->cl != TC_Object && list->class->cl != TC_Shared)
#endif
	{
	  Emit (PrivateOutputFileC, "  ");
#if 1
	  EmitVID (PrivateOutputFileC, list->class->class_id_public, 1);
#else
	  EmitVID (PrivateOutputFileC, 
		   list->class->class_id_implementation, 1);
#endif
	  Emit (PrivateOutputFileC, ", 0,\n");
	}
#if 0
      else if (list->class && list->class->cl == TC_Record)
	{
	  Emit (PrivateOutputFileC, "  OzLangImported_");
	  EmitVID (PrivateOutputFileC, list->class->class_id_public, 0);
	  Emit (PrivateOutputFileC, ",\n");
	}
#endif
      list = list->next;
    }

  Emit (PrivateOutputFileC, "};\n");
}

#if 0
void
  EmitImportedForRecord ()
{
  ClassList list = clist;
  int num = 0;

  if (Mode != NORMAL || !Pass)
    return;

  if (!clist)
    {
      Emit (PublicOutputFileH, "#endif _OZ");
      EmitVID (PublicOutputFileH, ThisClass->class_id_public, 0);
      Emit (PublicOutputFileH, "P_H_\n");
      
      return;
    }

  while (list)
    {
      if (list->class && list->class->cl == TC_StaticObject)
	num++;
      list = list->next;
    }

  Emit (PublicOutputFileH, "\n");
  Emit (PublicOutputFileH, "#define OzLangImportedNumber_");
  EmitVID (PublicOutputFileH, ThisClass->class_id_public, 0);
  Emit (PublicOutputFileH, " %d\n\n", num);

  Emit (PublicOutputFileH, "#define OzLangImported_");
  EmitVID (PublicOutputFileH, ThisClass->class_id_public, 0);

  if (num)
    Emit (PublicOutputFileH, " \\\n");
  else
    Emit (PublicOutputFileH, " {}\n");

  list = clist;
  while (list)
    {
      if (list->class && list->class->cl == TC_StaticObject)
	{
	  Emit (PublicOutputFileH, "  ");
	  EmitVID (PublicOutputFileH, list->class->class_id_public, 1);
	  Emit (PublicOutputFileH, ", 0LL, 0");
	  num--;
	  
	  if (num)
	    Emit (PublicOutputFileH, ", \\\n");
	  else
	    Emit (PublicOutputFileH, "\n");
	}

      list = list->next;
    }

  Emit (PublicOutputFileH, "\n");

  Emit (PublicOutputFileH, "#endif _OZ");
  EmitVID (PublicOutputFileH, ThisClass->class_id_public, 0);
  Emit (PublicOutputFileH, "P_H_\n");
}
#endif

OO_ClassType 
  SetClassStatus (long long vid, int status)
{
  ClassList list = clist;

  while (list)
    {
      if (list->class->class_id_public == vid)
	{
	  if (list->class->status == CLASS_NONE ||
	      list->class->status == status)
	    return NULL;
	  else
	    {
	      list->class->status = status;
	      return list->class;
	    }
	}
      list = list->next;
    }

  return NULL;
}

void
AddClassType (OO_ClassType cl)
{
  ClassList list = clist, before, buf;

  while (list)
    {
      if (list->class && list->class->class_id_public == cl->class_id_public)
	{
	  if (list->class->status == CLASS_NONE)
	    list->class = cl;
	  
	  return;
	}

      before = list;
      list = list->next;
    }

  buf = (ClassList) malloc (sizeof (ClassList_Rec) + 18);
  buf->class = cl;
  buf->count = 0;
  sprintf (buf->name, "__%08x%08x", 
	   (int) (cl->class_id_public >> 32), 
	   (int) (cl->class_id_public & 0xffffffff));
  buf->next = NULL;

  if (clist)
    before->next = buf;
  else
    clist = buf;
}

void
EmitUsedClasses (FILE *fp)
{
  ClassList list;

  Emit (fp, "/* classes used for instanciation\n");

  for (list = clist; list; list = list->next)
    if (list->class && list->class->used_for_instanciate)
      {
	EmitVID (fp, list->class->class_id_public, 0);
	Emit (fp, "\n");
      }

  Emit (fp, "*/\n\n");

  Emit (fp, "/* classes used for invoke\n");

  for (list = clist; list; list = list->next)
    if (list->class && list->class->used_for_invoke)
      {
	EmitVID (fp, list->class->class_id_public, 0);
	Emit (fp, "\n");
      }

  Emit (fp, "*/\n\n");

  return;
}
