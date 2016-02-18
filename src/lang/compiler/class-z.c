/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <unistd.h>

#include "ozc.h"
#include "type.h"
#include "symbol.h"
#include "lang/school.h"
#include "block.h"
#include "class.h"
#include "class-z.h"
#include "class-list.h"
#include "common.h"
#include "emit-layout.h"

static char filename[256];

static OO_ClassType read_class (FILE *, char *, int);

static void
  illegal_file ()
{
#ifndef CFE
  InternalError ("%s: this `.z' file incorrect\n", filename);
#else
  FatalError ("%s: this `.z' file incorrect\n", filename);
#endif
  exit (1);
}

static char 
  read_next_char (fp)
{
  char c;

  while ((c = fgetc (fp)) == ' ' || c == '\t' || c == '\n');
  if (c == ';')
    {
      while (fgetc (fp) != '\n');
      c = fgetc (fp);
    }

  return c;
}

#ifndef CFE
static OO_ClassType 
  search_class (OO_ClassType cl, long long cid, int suffix)
{
  OO_List plist = cl->class_part_list;

  if (cid == OBJECT_PUBLIC_VID || cid == OBJECT_PROTECTED_VID)

#if 1
    if (ThisClass && ThisClass->parent_desc)
      return ThisClass->parent_desc->class;
    else
      {
	OO_ClassType tmp;

	tmp = CreateClass (NULL, 0, 0);
	tmp->class_id_public = OBJECT_PUBLIC_VID;
	tmp->class_id_protected = OBJECT_PROTECTED_VID;
	tmp->class_id_suffix = 0;
	
	return tmp;
      }
#else
    return ObjectClass;
#endif

  if (!plist ||
      ((cl->class_id_public == cid || cl->class_id_protected == cid) 
       && cl->class_id_suffix == suffix))
    return cl;

  while (plist)
    {
      if ((plist->car->class_type_rec.class_id_public == cid ||
	   plist->car->class_type_rec.class_id_protected == cid) &&
	  plist->car->class_type_rec.class_id_suffix == suffix)
	return &plist->car->class_type_rec;
      plist = &plist->cdr->list_rec;
    }

  InternalError ("%08x%08x (%d), not defined class\n",
		 (int) (cid >> 32), (int) (cid & 0xffffffff), suffix);
  return NULL;
}
#endif

static
  read_parents (FILE *fp, OO_List *parent_list, int public)
{
  int l, h, num = 0;
  char buf[256], c;
  OO_List list, priv = NULL;

  while ( fgetc (fp) != '(');
  fscanf (fp, "%s", buf);
  if (strncmp (buf, LIST_START, strlen (LIST_START)))
    {
      illegal_file ();
    }

  list = (OO_List) malloc (sizeof (OO_List_Rec));
  list->cdr = NULL;
#if 1
  list->car = (OO_Object) CreateClass (NULL, 0, 0);

  sscanf (OBJECT_PUBLIC, "%08x%08x", &l, &h);
  list->car->class_type_rec.class_id_public
    = (long long)((long long)l << 32) + (h & 0xffffffff);
  sscanf (OBJECT_PROTECTED, "%08x%08x", &l, &h);
  list->car->class_type_rec.class_id_protected
    = (long long)((long long)l << 32) + (h & 0xffffffff);
#else
  list->car = (OO_Object) ObjectClass;
#endif

  *parent_list = list;

  if (strcmp (buf, LIST_START) && buf[strlen (LIST_START)] == ')')
    return NULL;

  priv = list;

  while ((c = read_next_char (fp)) != ')')
    {
      list = (OO_List) malloc (sizeof (OO_List_Rec));
      list->cdr = NULL;

      if (c != '(')
	{
	  illegal_file ();
	}
      fscanf (fp, "%s", buf);
      if (strcmp (buf, LIST_START))
	{
	  illegal_file ();
	}
      fscanf (fp, "%s", buf);
      if (*buf != '#')
	{
	  illegal_file ();
	}

      list->car = (OO_Object) CreateClass (NULL, 0, 0);

      sscanf (&buf[1], "%08x%08x", &l, &h);
      list->car->class_type_rec.class_id_public 
	= (long long)((long long)l << 32) + (h& 0xffffffff);
      fscanf (fp, "%s", buf);
      if (*buf != '#')
	{
	  illegal_file ();
	}
      sscanf (&buf[1], "%08x%08x", &l, &h);
      list->car->class_type_rec.class_id_protected
	= (long long)((long long)l << 32) + (h & 0xffffffff);
      fscanf (fp, "%s", buf);
      sscanf (buf, "%d", &list->car->class_type_rec.class_id_suffix);
      if (buf[strlen (buf) - 1] != ')')
	if (read_next_char (fp) != ')')
	  {
	    illegal_file ();
	  }
      num++;

      AppendList (&priv, list);
      priv = list;
    }

  return num;
}

static 
  get_type_cl (char *str)
{
  if (!strcmp (str, "void"))
    return TC_Void;
  else if (!strcmp (str, "char"))
    return TC_Char;
  else if (!strcmp (str, "short"))
    return TC_Short;
  else if (!strcmp (str, "int"))
    return TC_Int;
  else if (!strcmp (str, "OZ_Long"))
    return TC_Long;
  else if (!strcmp (str, "float"))
    return TC_Float;
  else if (!strcmp (str, "double"))
    return TC_Double;
  else if (!strcmp (str, "OZ_ConditionRec"))
    return TC_Condition;
  else if (!strcmp (str, "OZ_Generic"))
    return TC_Generic;
}

static OO_Type
  read_type (FILE *fp)
{
  char buf[256], c;
  OO_Type type = NULL;
  int l, h, buf_num;
  OO_List priv = NULL, args;
    
  if ((c = read_next_char (fp)) != '(')
    {
      if (c == ')')
	return NULL;

      if (c == '*')
	{
	  illegal_file ();
	}

      *buf = c;
      fscanf (fp, "%s", &buf[1]);

      if (*buf != '#')
	{
	  type = (OO_Type) malloc (sizeof (OO_SimpleType_Rec));
	  type->id = TO_SimpleType;
	  type->simple_type_rec.cl = get_type_cl (buf);
	  type->simple_type_rec.symbol 
	    = CreateSymbol (oz_type_str[type->simple_type_rec.cl].str);
	  return type;
	}
      else
	{
	  int class_sc = 0;

	  sscanf (&buf[1], "%08x%08x", &l, &h);
	  fscanf (fp, "%d", &class_sc);

#ifndef CFE
	  if (class_sc == SC_RECORD)
	    {
	      char *name = GetVID (&buf[1], 0);
	      char vid_name[19];
	      
	      if (name) 
		type = (OO_Type) SearchClass (name);
	      else
		{
		  sprintf (vid_name, "__%s", &buf[1]);
		  type = (OO_Type) SearchClass (vid_name);
		}
	    }
#endif

	  if (!type)
	    {
	      type = (OO_Type) CreateClass (NULL, class_sc, 0);
	      type->class_type_rec.class_id_public 
		= (long long) ((long long) l << 32) + (h & 0xffffffff);
	    }

	  return type;
	}
    }
  else
    {
      fscanf (fp, "%s", buf);
      if (!strcmp (buf, SCQF_START))
	{
	  type = (OO_Type) malloc (sizeof (OO_TypeSCQF_Rec));
	  type->id = TO_TypeSCQF;
	  type->type_scqf_rec.type = read_type (fp);
	  fscanf (fp, "%d", &buf_num);
	  type->type_scqf_rec.scqf = buf_num;
	  if (read_next_char (fp) != ')')
	    {
	      illegal_file ();
	    }
	  return type;
	}
      else if (!strcmp (buf, METHOD_START))
	{
	  type = (OO_Type) malloc (sizeof (OO_TypeMethod_Rec));
	  type->id = TO_TypeMethod;
	  type->type_method_rec.qualifier = 0;
	  type->type_method_rec.type = read_type (fp);
	  type->type_method_rec.args = NULL;

	  if (read_next_char (fp) != '(')
	    {
	      illegal_file ();
	    }
	  fscanf (fp, "%s", buf);
	  if (strncmp (buf, LIST_START, strlen (LIST_START)))
	    {
	      illegal_file ();
	    }
	  if (!strcmp (buf, LIST_START))
	    {
	      while (1)
		{
		  OO_Type args_type;
		  
		  if (!(args_type = read_type (fp)))
		    break;
		  
		  args = CreateList ((OO_Object) CreateSymbol (NULL), NULL);
		  args->car->symbol_rec.type = args_type;
		  if (!priv)
		    type->type_method_rec.args = args;
		  else
		    AppendList (&priv, args);
		  priv = args;
		}
	    }
	  fscanf (fp, "%d", &buf_num);
	  type->type_method_rec.qualifier = buf_num;
	  if (read_next_char (fp) != ')')
	    {
	      illegal_file ();
	    }
	  return type;
	}
      else if (!strcmp (buf, ARRAY_START))
	{
	  type = (OO_Type) malloc (sizeof (OO_TypeArray_Rec));
	  type->id = TO_TypeArray;
	  type->type_array_rec.type = read_type (fp);
#if 0
	  type->type_array_rec.length = 0;
#endif
	  if (read_next_char (fp) != ')')
	    {
	      illegal_file ();
	    }
	  return type;
	}
      else if (!strcmp (buf, PROCESS_START))
	{
	  type = (OO_Type) malloc (sizeof (OO_TypeProcess_Rec));
	  type->id = TO_TypeProcess;
	  type->type_process_rec.type = read_type (fp);
	  if (read_next_char (fp) != ')')
	    {
	      illegal_file ();
	    }
	  return type;
	}

      else if (!strcmp (buf, RECORD_START))
	{
	  type = (OO_Type) read_class (fp, NULL, 1);

#ifndef CFE
	  if (Mode == NORMAL)
	    AddClassType (&type->class_type_rec);
#endif

	  if (read_next_char (fp) != ')')
	    {
	      illegal_file ();
	    }
	  return type;
	}
    }
}

static 
  read_members (FILE *fp, OO_ClassType cl)
{
  int l, h, i;
  OO_List list;
  char buf[256], c;
  long long cid;
  int cid_suffix;

  while (fgetc (fp) != '(');
  fscanf (fp, "%s", buf);
  if (strcmp (buf, LIST_START))
    {
      illegal_file ();
    }

  while ((c = read_next_char (fp)) != ')')
    {
      if (c != '(')
	{
	  illegal_file ();
	}
      fscanf (fp, "%s", buf);
      if (strcmp (buf, DECL_START))
	{
	  illegal_file ();
	}

      fscanf (fp, "%s", buf);
      
      list = (OO_List) malloc (sizeof (OO_List_Rec));
      list->cdr = NULL;
      list->car = (OO_Object) CreateSymbol (buf);
      list->car->symbol_rec.type = read_type (fp);
      
      fscanf (fp, "%s", buf);
      
      if (!strcmp (buf, "public"))
	{
	  AppendList (&cl->public_list, list);
	  list->car->symbol_rec.access = PUBLIC_PART;
	}
      else if (!strcmp (buf, "constructor"))
	{
	  AppendList (&cl->constructor_list, list);
	  list->car->symbol_rec.access = CONSTRUCTOR_PART;
	}
      else if (!strcmp (buf, "protected"))
	{
	  AppendList (&cl->protected_list, list);
	  list->car->symbol_rec.access = PROTECTED_PART;
	}

      fscanf (fp, "%s", buf);
      if (*buf != '#')
	{
	  illegal_file ();
	}
      sscanf (&buf[1], "%08x%08x", &l, &h);
      cid = (long long) ((long long) l << 32) + (h & 0xffffffff);
      fscanf (fp, "%d", &cid_suffix);

#ifndef CFE      
      list->car->symbol_rec.class_part_defined 
	= search_class (cl, cid, cid_suffix);
#else
      list->car->symbol_rec.class_part_defined 
	= CreateClass (NULL, 0, 0);
      list->car->symbol_rec.class_part_defined->class_id_public 
	= list->car->symbol_rec.class_part_defined->class_id_protected
	  = (long long) ((long long) l << 32) + (h & 0xffffffff);
#endif

      list->car->symbol_rec.is_variable 
	= list->car->symbol_rec.type->id == TO_TypeMethod ? 0 : 1;
      list->car->symbol_rec.id = TO_Symbol;
      list->car->symbol_rec.conflict = -1;
      
      if (list->car->symbol_rec.is_variable)
	{
	  int len;

	  fscanf (fp, "%s", buf);
	  if (buf[(len = strlen (buf) - 1)] == ')')
	    buf[len] = '\0';
	  else
	    len = 0;
	  list->car->symbol_rec.orig_name = CreateSymbol (buf);
	  if (len)
	    continue;
	}
      else
	{
	  fscanf (fp, "%d", &list->car->symbol_rec.slot_no2);

#ifndef CFE
	  if (list->car->symbol_rec.class_part_defined->class_id_public 
	      == cl->class_id_public)
	    {
	      if (cl->class_id_public == ThisClass->class_id_public)
		SlotNo = SlotNo < list->car->symbol_rec.slot_no2 ?
		  list->car->symbol_rec.slot_no2 : SlotNo;
	      
	      else
		cl->slot_no2 = cl->slot_no2 < list->car->symbol_rec.slot_no2 ?
		  list->car->symbol_rec.slot_no2 : cl->slot_no2;
	    }
#endif
	}

      if (read_next_char (fp) != ')')
	{
	  illegal_file ();
	}
    }
}

static OO_ClassType
  read_class (FILE *fp, char *name, int public)
{
  char buf[256];
  OO_ClassType cl;
  int class_sc;

  while (fgetc (fp) != '(');
  fscanf (fp, "%s", buf);
  if (strcmp (buf, CLASS_START))
    illegal_file ();

#if 1
  fscanf (fp, "%s %d", buf, &class_sc);
#else
  fscanf (fp, "%s", buf);
#endif
  if (*buf != '#')
    illegal_file ();

  cl = CreateClass (name, class_sc, 0);

  if (!name)
    {
      cl->class_id_public = str2oid (&buf[1]);

#if 1
      cl->class_id_implementation = cl->class_id_public + 2LL;
#endif      
    }
    
  cl->status = public ? CLASS_PUBLIC_LOADED : CLASS_PROTECTED_LOADED;
  cl->no_parents = read_parents (fp, &cl->class_part_list, public);

  read_members (fp, cl);

  fscanf (fp, "%s", buf);

#ifndef CFE
  if (cl->cl == TC_Record)
    cl->size = GetRecordSize (cl);
#endif

  return cl;
}

OO_ClassType
LoadClassFromZ (char *name, int public)
{
  FILE *fp = NULL;
  char buf[256];
  char *vid, *name2 = name;
  OO_ClassType cl;
  int l, h;
  
  if (strlen (name) != 18 || sscanf (&name[2], "%08x%08x", &l, &h) != 2)
    vid = GetVID (name, !public);
  else
    {
      vid = &name[2];
      name = NULL;
    }

  if (!vid)
    return CreateClass (name, 0, 0);

  sprintf (filename, "%s/%s", ClassPath, vid);
  if (access (filename, F_OK))
    {
      printf ("searchclass %s", vid);
      fflush (stdout);

      gets (buf);

      if (strcmp (buf, "continue"))
	exit (1);
    }

  if (public)
    sprintf (filename, "%s/%s/public.z", ClassPath, vid);
  else
    sprintf (filename, "%s/%s/protected.z", ClassPath, vid);
  
  if (!(fp = fopen (filename, "r")))
    {
#ifndef CFE
      FatalError ("cannot load interfaces of a used class: `%s'\n", name2);
      exit (1);
#else
      return NULL;
#endif
    }

  cl = read_class (fp, name, public);

  fclose (fp);

  return cl;
}
