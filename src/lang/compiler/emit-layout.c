/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <sys/file.h>

/* mine */
#include "emit-layout.h"
#include "emit-common.h"
#include "class-list.h"

#include "ozc.h"

#define LSIZE 1024
#define PAD "pad"

int DataPad[2] = {0, 0};

static OID dtype[2][LSIZE], ptype[2][LSIZE], ztype[2][LSIZE];
static unsigned int dorder[2][LSIZE], porder[2][LSIZE], zorder[2][LSIZE];
static char *dname[2][LSIZE], *pname[2][LSIZE], *zname[2][LSIZE];
static unsigned int donum[2], ponum[2], zonum[2], dnum[2], pnum[2], znum[2];
static OO_Type ptype_detail[2][LSIZE], dtype_detail[2][LSIZE];
static unsigned short data_size[2];
static unsigned short number_of_pointers[2];
static unsigned short zero[2];

/*
 * private functions
 */

static void
  emit_type_detail (OO_Type type)
{
  char kind;

  switch (type->id)
    {
    case TO_SimpleType:
      kind = format_char_of_type[type->simple_type_rec.cl];
      if (kind == 'C')
	kind = 'z';
      Emit (PrivateOutputFileD, "%c", &kind);
      return;
    case TO_ClassType:
      switch (type->class_type_rec.cl)
	{
	case TC_Record:
	  Emit (PrivateOutputFileD, "R");
	  EmitVID (PrivateOutputFileD, 
		   type->class_type_rec.class_id_public, 0);
	  break;
	case TC_StaticObject:
	  Emit (PrivateOutputFileD, "o");
	  EmitVID (PrivateOutputFileD, 
		   type->class_type_rec.class_id_public, 0);
	  break;
	case TC_Object:
	  Emit (PrivateOutputFileD, "O");
	  EmitVID (PrivateOutputFileD, 
		   type->class_type_rec.class_id_public, 0);
	  break;
	}
      return;
    case TO_TypeSCQF:
      if (type->type_scqf_rec.scqf & SC_GLOBAL)
	{
	  type = type->type_scqf_rec.type;
	  Emit (PrivateOutputFileD, "G");
	  EmitVID (PrivateOutputFileD, 
		   type->class_type_rec.class_id_public, 0);
	}
      else
	{
	  kind = format_char_of_type[type->type_scqf_rec.type
				     ->simple_type_rec.cl] - 'a' + 'A';
	  Emit (PrivateOutputFileD, "%c", &kind);
	}
      return;
    case TO_TypeArray:
      Emit (PrivateOutputFileD, "*");
      emit_type_detail (type->type_array_rec.type);
      return;
    case TO_TypeProcess:
      Emit (PrivateOutputFileD, "@");
      emit_type_detail (type->type_process_rec.type);
      return;
    }
}

static void
  emit_layout(OZ_Layout layout)
{
  int size = sizeof(OZ_LayoutRec) - sizeof(OZ_LayoutPartRec)
	+ sizeof(OZ_LayoutPartRec) * layout->number_of_common_entries
	+ sizeof(OZ_LayoutPartRec) * layout->number_of_own_entries;
  
  fwrite((char *)&size, sizeof(int), 1, PrivateOutputFileL);
  fwrite((char *)layout, size, 1, PrivateOutputFileL);
}

static void
  create_layout_info_zero (int protected, char *name)
{
  ztype[protected][znum[protected]] = OZ_CONDITION; /* type */
  zorder[protected][znum[protected]] = zonum[protected]++;
  zname[protected][znum[protected]++] = name;
  zero[protected]++;
}

static void
  create_layout_info_data(int t, int protected, char *name)
{ 
  int tmp_size, size_buf;

  tmp_size = data_size[protected] + (size_buf = oz_size_of_type[t]);
  if (size_buf < 4)
    {
      if (data_size[protected] / ALINMENT_1 != (tmp_size - 1) / ALINMENT_1)
	{
	  dtype[protected][dnum[protected]] = OZ_PADDING;
	  dname[protected][dnum[protected]] = PAD;
	  data_size[protected] += (dorder[protected][dnum[protected]++] 
			 = ALINMENT_1 - (data_size[protected] % ALINMENT_1));
	}
      else if (size_buf == 2 && data_size[protected] % 2)
	{
	  dtype[protected][dnum[protected]] = OZ_PADDING;
	  dname[protected][dnum[protected]] = PAD;
	  data_size[protected] += (dorder[protected][dnum[protected]++] = 1);
	}

      dtype[protected][dnum[protected]] = oz_type[t]; /* type */
      dorder[protected][dnum[protected]] = donum[protected]++;
      data_size[protected] += size_buf;
    }
  else if (size_buf == 4) 
    {
      if (data_size[protected] % ALINMENT_1) 
	{
	  dtype[protected][dnum[protected]] = OZ_PADDING;
	  dname[protected][dnum[protected]] = PAD;
	  data_size[protected] += (dorder[protected][dnum[protected]++]
			 = ALINMENT_1 - (data_size[protected] % ALINMENT_1));
	}
      dtype[protected][dnum[protected]] = oz_type[t]; /* type */
      dorder[protected][dnum[protected]] = donum[protected]++;
      data_size[protected] += size_buf;
    }
  else 
    {
      if (data_size[protected] % ALINMENT_2)
	{
	  dtype[protected][dnum[protected]] = OZ_PADDING;
	  dname[protected][dnum[protected]] = PAD;
	  data_size[protected] += (dorder[protected][dnum[protected]++] 
			 = ALINMENT_2 - (data_size[protected] % ALINMENT_2));
	}
      dtype[protected][dnum[protected]] = oz_type[t]; /* type */
      dorder[protected][dnum[protected]] = donum[protected]++;
      data_size[protected] += size_buf;
    }

  dname[protected][dnum[protected]] = name;
}

static void
  create_layout_info_pointer(OO_Type type, int protected, char *name)
{
  int t;

  if (type->id == TO_ClassType)
    t = type->class_type_rec.cl;
  else
    t = TC_Object + 4;

  ptype_detail[protected][pnum[protected]] = type;

  ptype[protected][pnum[protected]] = oz_type[t]; /* type */
  porder[protected][pnum[protected]] = ponum[protected]++;
  pname[protected][pnum[protected]++] = name;
  number_of_pointers[protected]++;
}

static void
  create_layout_info (OO_Type type, int protected, char *name)
{
  switch (type->id)
    {
    case TO_SimpleType:
      if (type->simple_type_rec.cl == TC_Condition)
	create_layout_info_zero (protected, name);
      else
	{
	  create_layout_info_data(type->simple_type_rec.cl, protected, name);
	  dtype_detail[protected][dnum[protected]++] = type;
	}
      break;
    case TO_TypeSCQF:
      if (type->type_scqf_rec.scqf & QF_CONST)
	return;
      else if (type->type_scqf_rec.scqf & SC_GLOBAL)
	{
	  create_layout_info_data (TC_Object + 3, protected, name);
	  dtype_detail[protected][dnum[protected]++] = type;
	}
      else
	{
	  create_layout_info_data (type->type_scqf_rec.type
				   ->simple_type_rec.cl, protected, name);
	  dtype_detail[protected][dnum[protected]++] = type;
	}
      break;
    case TO_ClassType:
      switch (type->class_type_rec.cl)
	{
	case TC_Record:
	  if ((oz_size_of_type[type->class_type_rec.cl] 
	       = GetRecordSize (&type->class_type_rec)) == 1) 
	    {
	      oz_size_of_type[type->class_type_rec.cl] = 0;
	    }
	  create_layout_info_data(type->class_type_rec.cl, protected, name);
	  dtype_detail[protected][dnum[protected]++] = type;
	  break;
	case TC_StaticObject:
	  create_layout_info_pointer(type, protected, name);
	  break;
	case TC_Object:
	  create_layout_info_pointer(type, protected, name);
	  break;
	}
      break;
    case TO_TypeArray:
      create_layout_info_pointer(type, protected, name);
      break;
    case TO_TypeProcess:
      create_layout_info_data(TC_Object + 5, protected, name);
      dtype_detail[protected][dnum[protected]++] = type;
      break;
    }
}

/*
 * global functions
 */

OZ_Layout
  EmitLayout ()
{
  int i, j, t, type_num, size, num[2];
  OZ_Layout layout;
  OO_Symbol method_vars = ThisClass->block->vars;
  
  dnum[0] = dnum[1] = pnum[0] = pnum[1] = znum[0] = znum[1] = 0;
  donum[0] = donum[1] = ponum[0] = ponum[1] = zonum[0] = zonum[1] = 0;
  data_size[0] = data_size[1] = 0;
  number_of_pointers[0] = number_of_pointers[1] = 0;
  zero[0] = zero[1] = 0;

  while (method_vars)
    {
      if (method_vars->access == PROTECTED_PART)
	{
	  if (method_vars->is_variable)
	    {
	      create_layout_info(method_vars->type, 1, 
				 method_vars->string);
	    }
	}
      else if (method_vars->access == PRIVATE_PART ||
	       (ThisClass->cl == TC_Record && 
		method_vars->access == PUBLIC_PART))
	{
	  if (method_vars->is_variable)
	    {
	      create_layout_info(method_vars->type, 0,
				 method_vars->string);
	    }
	}
      method_vars = method_vars->link;
    }

  type_num = pnum[1] + dnum[1] + znum[1] + pnum[0] + dnum[0] + znum[0];

  layout = (OZ_Layout)malloc(sizeof(OZ_LayoutRec) - sizeof(OZ_LayoutPartRec)
			     + sizeof(OZ_LayoutPartRec) * (type_num + 2));

  layout->number_of_common_entries = type_num;
  layout->number_of_own_entries = 0;

  num[0] = num[1] = 0;
  Emit (PrivateOutputFileD, "%-8d %-8d %-8d\n", 
	num[0] + num[1], num[1], num[0]);

  t = 0;
  size = 0;
  for (j = 1; j >= 0; j--)
    {
      for (i = 0; i <  pnum[j]; i++) 
	{
	  layout->own[t + layout->number_of_own_entries].order = porder[j][i];
	  layout->own[t + layout->number_of_own_entries].type = ptype[j][i];
	  t++;

	  Emit (PrivateOutputFileD, "%s %d 4 ", 
		pname[j][i], size);
	  emit_type_detail (ptype_detail[j][i]);
	  Emit (PrivateOutputFileD, "\n");
	  size += 4;
	  num[j]++;
	}
      if (pnum[j] % 2)
	size += 4;
      if (data_size[j] % ALINMENT_2)
	{
	  dtype[j][dnum[j]] = OZ_PADDING;
	  dname[j][dnum[j]] = PAD;
	  data_size[j] += (DataPad[j] = dorder[j][dnum[j]++] 
				   = ALINMENT_2 - (data_size[j] % ALINMENT_2));
	  layout->number_of_common_entries++;
	}
      for (i = 0; i <  dnum[j]; i++) 
	{
	  layout->own[t + layout->number_of_own_entries].order = dorder[j][i];
	  layout->own[t + layout->number_of_own_entries].type = dtype[j][i];
	  t++;

	  if (dtype[j][i] == OZ_PADDING)
	    size += dorder[j][i];
	  else
	    {
	      if (dtype[j][i] == OZ_RECORD) 
		{
		  OO_Type type = dtype_detail[j][i];

		  oz_size_of_type[type->class_type_rec.cl]
		    = GetRecordSize (&type->class_type_rec);
		}
	      Emit (PrivateOutputFileD, "%s %d %d ", 
		    dname[j][i], 
		    size,
		    oz_size_of_type[dtype[j][i]]);
	      emit_type_detail (dtype_detail[j][i]);
	      Emit (PrivateOutputFileD, "\n");
	      size += oz_size_of_type[dtype[j][i]];
	      num[j]++;
#ifndef NONISHIOKA
	      /*
	       * Record ID is required in layout information of a
	       * class which has a record as its instance variable for
	       * encoding/decoding between different platforms.
	       * This code segment probably should be moved to the
	       * code section where the layout information is built.
	       */
	      if (dtype[j][i] == OZ_RECORD) 
		layout->own[(t - 1) + layout->number_of_own_entries].type
		  = dtype_detail[j][i]->class_type_rec.class_id_public;
#endif
	    }
	}
      for (i = 0; i <  znum[j]; i++) 
	{
	  layout->own[t + layout->number_of_own_entries].order = zorder[j][i];
	  layout->own[t + layout->number_of_own_entries].type = ztype[j][i];
	  t++;

	  Emit (PrivateOutputFileD, "%s %d 8 z\n", zname[j][i], size);
	  size += 8;
	  num[j]++;
	}
    }

  rewind (PrivateOutputFileD);

  if (ThisClass->cl == TC_Record)
    {
      Emit (PrivateOutputFileD, "%-8d %-8d %-8d\n", 
	    num[0] + num[1], 0, 0);
    }
  else
    {
      Emit (PrivateOutputFileD, "%-8d %-8d %-8d\n", 
	    num[0] + num[1], num[1], num[0]);
    }

  layout->info.data_size_protected = data_size[1];
  ThisClass->size = layout->info.data_size_private = data_size[0];
  layout->info.number_of_pointer_protected = number_of_pointers[1];
  layout->info.number_of_pointer_private = number_of_pointers[0];
  layout->info.zero_protected = zero[1];
  layout->info.zero_private = zero[0];

  (int) layout->common 
    = (int)&layout->own[layout->number_of_own_entries] - (int) layout;

  emit_layout (layout);

  return layout;
}

int
  GetRecordSize (OO_ClassType ct)
{
  int fd, n;
  OZ_Layout layout;
  char filename[256], version_id[17];
  OO_ClassType cl = ct;

  if (ct->size < 0)
    {
      if (cl->status == CLASS_NONE)
	cl = GetClassFromUsedList (cl->class_id_public);

      if (cl->size < 0)
	{
	  sprintf (version_id, "%08x%08x",
		   (int) (cl->class_id_public >> 32),
		   (int) (cl->class_id_public & 0xffffffff));
	  sprintf (filename, "%s/%s/private.l", ClassPath, version_id);
	  
	  if ((fd = open (filename, O_RDONLY, 0644)) < 0) 
	    {
	      FatalError ("cannot load layout info.: %s\n", version_id);
	      return 0;
	    }
      
	  read (fd, (char *)&n, sizeof(int));
	  layout = (OZ_Layout) malloc (n);
	  read (fd, (char *)layout, n);
	  close (fd);
	  
	  ct->size = cl->size = layout->info.data_size_private ? 
	    layout->info.data_size_private : 0;
	  
	  free (layout);
	}
      else
	ct->size = cl->size;
    }


  if (ct->size > 0)
    {
      int pad = ct->size % 8;

      return  pad ? ct->size + (8 - pad) : ct->size;
    }
  else
    return 0;
}

void
  EmitExceptions ()
{
  OO_Symbol sym;
  int line = 0;

  Emit (PrivateOutputFileD, "%-8d %-8d %-8d\n", 
	line, 0, 0);

  for (sym = ThisClass->block->vars; sym; sym = sym->link)
    {
      if (sym->is_variable)
	continue;

      Emit (PrivateOutputFileD, "%s %d ", sym->string, sym->slot_no2);
      if (sym->type->type_method_rec.args)
	{
	  int byte_size;
	  OO_Symbol arg = &sym->type->type_method_rec.args->car->symbol_rec;

	  switch (arg->type->id)
	    {
	    case TO_SimpleType:
	      byte_size = oz_size_of_type[arg->type->simple_type_rec.cl];
	      break;
	    case TO_ClassType:
	      switch (arg->type->class_type_rec.cl)
		{
		case TC_Record:
		  byte_size = GetRecordSize (&arg->type->class_type_rec);
		  break;
		case TC_StaticObject:
		case TC_Object:
		  byte_size = 4;
		  
		  break;
		}
	      break;
	    case TO_TypeSCQF:
	      if (arg->type->type_scqf_rec.scqf &  SC_GLOBAL)
		byte_size = 8;
	      else
		byte_size = oz_size_of_type[arg->type->type_scqf_rec.type
					    ->simple_type_rec.cl];
	      break;
	    case TO_TypeArray:
	    case TO_TypeProcess:
	      byte_size = 4;
	      break;
	    }
	  Emit (PrivateOutputFileD, "%d ", byte_size);
	  emit_type_detail (arg->type);
	  Emit (PrivateOutputFileD, "\n");
	}
      else
	Emit (PrivateOutputFileD, "0 v\n");

      line++;
    }

  rewind (PrivateOutputFileD);
  Emit (PrivateOutputFileD, "%-8d %-8d %-8d\n", 
	line, 0, 0);
}
