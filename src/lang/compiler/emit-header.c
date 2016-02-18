/*
  Copyright(c) 1994-1997 Information-technology Promotion Agency, Japan

  All rights reserved.  No guarantee.
  This technology is a result of the Open Fundamental Software Technology
  Project of Information-technology Promotion Agency, Japan (IPA).
*/

#include <stdio.h>
#include <stdlib.h>
#include <varargs.h>

#include "emit-header.h"
#include "emit-method.h"
#include "emit-common2.h"
#include "type.h"

#include "emit-layout.h"

#include "exec-function-name.h"

#include "class-list.h"
#include "ozc.h"

static char vid[17];
static FILE *current_file;
static int pointer;

static void
  emit_h (char *format, ...)
{
  va_list pvar;

  va_start (pvar);
  Emit2 (current_file, format, pvar);
  va_end (pvar);
}

#if 0
static void
  emit_h_this_type (OO_Type type, int scqf)
{
  char buf[256];
  
  switch (type->id)
    {
    case TO_SimpleType:
      emit_h ("%s ", type_str[type->simple_type_rec.cl].str);
      break;
    case TO_TypeSCQF:
      buf[0] = '\0';
      if (type->type_scqf_rec.scqf != SC_GLOBAL)
	{
	  EmitSCQF (buf, type->type_scqf_rec.scqf);
	  emit_h ("%s", buf);
	}
      emit_h_this_type (type->type_scqf_rec.type, type->type_scqf_rec.scqf);
      break;
    case TO_ClassType:
      switch (type->class_type_rec.cl)
	{
	case TC_Record:
	  emit_h ("OZ%sRecord_Rec ", 
		    &type->class_type_rec.symbol->string[2]);
	  break;
	case TC_StaticObject:
	  emit_h ("OZ_StaticObject ");
	  break;
	case TC_Object:
	  if (scqf & SC_GLOBAL)
	    emit_h ("OID ");
	  else
	    emit_h ("OZ_Object ");
	  break;
	}
      break;
    case TO_TypeArray:
      emit_h ("OZ_Array ");
      break;
    case TO_TypeProcess:
      emit_h ("OZ_ProcessID ");
      break;
    }
}
#endif

static void 
  emit_h_inherited ()
{
  OO_List part;

  emit_h ("/* inherited classes\n");
  
  if (part = ThisClass->class_part_list)
    for (part = &part->cdr->list_rec; part; part = &part->cdr->list_rec)
      {
	EmitVID (current_file, 
		 part->car->class_type_rec.class_id_protected, 0);
	emit_h ("\n");
      }

  emit_h ("*/\n\n");
}

static void
  emit_h_this (OO_Symbol member)
{
  emit_h ("  ");
#if 0
  emit_h_this_type (member->type, 0);
#endif
  if (Part == PROTECTED_PART && 
      member->type->id == TO_ClassType && 
      member->type->class_type_rec.cl == TC_Record)
    {
      emit_h ("char  oz%s[%d];\n", member->string, 
	      GetRecordSize (&member->type->class_type_rec));
    }
  else
    {
      EmitType (current_file, member->type);
      emit_h (" oz%s;\n", member->string);
    }
}

static void
  emit_h_member (OO_Symbol member, OO_Type type, int scqf, int part)
{
  switch (type->id)
    {
    case TO_SimpleType:
      if (type->simple_type_rec.cl == TC_Condition)
	{
	  if (part == 2)
	    emit_h_this (member);
	}
      else
	{
	  if (part == 1)
	    emit_h_this (member);
	}
      break;
    case TO_TypeSCQF:
      if (type->type_scqf_rec.scqf ^ QF_CONST)
	emit_h_member (member, type->type_scqf_rec.type, 
		       type->type_scqf_rec.scqf, part);
      break;
    case TO_ClassType:
      switch (type->class_type_rec.cl)
	{
	case TC_Record:
	  if (part == 1)
	    emit_h_this (member);
	  break;
	case TC_StaticObject:
	  if (part == 0)
	    {
	      pointer++;
	      emit_h_this (member);
	    }
	  break;
	case TC_Object:
	  if (scqf & SC_GLOBAL)
	    {
	      if (part == 1)
		emit_h_this (member);
	    }
	  else
	    {
	      if (part == 0)
		{
		  pointer++;
		  emit_h_this (member);
		}
	    }
	  break;
	}
      break;
    case TO_TypeArray:
      if (part == 0)
	{
	  pointer++;
	  emit_h_this (member);
	}
      break;
    case TO_TypeProcess:
      if (part == 1)
	emit_h_this (member);
      break;
    }
}

static void
emit_h_const (OO_Symbol member, OO_Type type)
{
  long long id = member->class_part_defined->class_id_protected;
      
  if (type->id == TO_TypeArray)
    {
      if (CheckSimpleType (type->type_array_rec.type, TC_Char) == TYPE_OK)
	emit_h ("#define OZ_%08x%08x_%s OzLangString(%s)\n", 
		(int) (id >> 32), (int) (id & 0xffffffff),
		member->string, member->init->constant_rec.string);
    }
  else
    {
      emit_h ("#define OZ_%08x%08x_%s ", 
	      (int) (id >> 32), (int) (id & 0xffffffff),
	      member->string);
      EmitExp (current_file, member->init);
      emit_h ("\n");
    }
    
}

static OO_Type
  is_this_const (OO_Type type)
{
  switch (type->id)
    {
    case TO_TypeSCQF:
      if (type->type_scqf_rec.scqf & QF_CONST)
	return type->type_scqf_rec.type;
    case TO_SimpleType:
    case TO_ClassType:
    case TO_TypeArray:
    case TO_TypeProcess:
      return NULL;
    }
}

static void
emit_h_class (OO_ClassType ct)
{
  OO_ParentDesc parents = ct->parent_desc;
  OO_Symbol member;
  int i;
  static char part_str[][10] = {"pointer", "data", "zero"};

  if (Part == PRIVATE_PART)
    EmitUsedHeader (PrivateOutputFileH);

  EmitMethodsHeader (current_file);

  if (Part == PUBLIC_PART)
    return;

  emit_h ("typedef struct OZ%sPart_Rec {\n", vid);
  
  emit_h ("  OZ_AllocateInfoRec alloc_info;\n");

  pointer = 0;
  for (i = 0 ; i < 3; i++)
    {
      emit_h ("\n  /* protected (%s) */\n", part_str[i]);
      member = ct->block->vars;
      while (member)
	{
	  if (member->access == PROTECTED_PART && member->is_variable)
	    {
	      emit_h_member (member, member->type, 0, i);
	    }
	  member = member->link;
	}
      if (!i && pointer % 2)
	emit_h ("  int pad0;\n");
      else if (i == 1 && DataPad[1])
	emit_h ("  char cpad0[%d];\n", DataPad[1]);
    }

  pointer = 0;
  for (i = 0 ; i < 3; i++)
    {
      if (Part == PRIVATE_PART)
	{
	  emit_h ("\n  /* private (%s) */\n", part_str[i]);
	  member = ct->block->vars;
	  while (member)
	    {
	      if (member->access == PRIVATE_PART && member->is_variable)
		{
		  emit_h_member (member, member->type, 0, i);
		}
	      member = member->link;
	    }
	}
      if (!i && pointer % 2)
	emit_h ("  int pad1;\n");
      else if (i == 1 && DataPad[0])
	emit_h ("  char cpad1[%d];\n", DataPad[0]);
    }
  
  emit_h ("} OZ%sPart_Rec, *OZ%sPart;\n\n", vid, vid);
  
  emit_h ("#ifdef OZ_ObjectPart_");
  EmitClassName (current_file, ct->symbol->string);
  emit_h ("\n");
  emit_h ("#undef OZ_ObjectPart_");
  EmitClassName (current_file, ct->symbol->string);
  emit_h ("\n");
  emit_h ("#endif\n");
  emit_h ("#define OZ_ObjectPart_");
  EmitClassName (current_file, ct->symbol->string);
  emit_h (" OZ%sPart\n\n", vid);
  
  if (Part == PRIVATE_PART)
    {
      emit_h ("typedef struct OZ%sAll_Rec {\n", vid);
      emit_h ("  OZ_HeaderRec head[%d];\n", ct->no_parents + 2);
      emit_h ("} OZ%sAll_Rec, *OZ%sAll;\n\n", vid, vid);
      
      emit_h ("#define OZ_ObjectAll_");
      EmitClassName (current_file, ct->symbol->string);
      emit_h (" OZ%sAll\n\n", vid);
    }
}

static void
emit_h_static_class (OO_ClassType ct)
{
  OO_Symbol member;
  int i;
  static char part_str[][10] = {"pointer", "data", "zero"};

  EmitUsedHeader (PublicOutputFileH);
  EmitMethodsHeader (current_file);

  emit_h ("typedef struct OZ%sStaticObject_Rec {\n", vid);
  
  emit_h ("  OZ_HeaderRec head;\n");
  emit_h ("  OZ_AllocateInfoRec alloc_info;\n");

  pointer = 0;
  for (i = 0 ; i < 3; i++)
    {
      emit_h ("\n  /* private (%s) */\n", part_str[i]);
      member = ct->block->vars;
      while (member)
	{
	  if (member->is_variable)
	    emit_h_member (member, member->type, 0, i);
	  
	  member = member->link;
	}
      if (!i && pointer % 2)
	emit_h ("  int pad1;\n");
      else if (i == 1 && DataPad[0])
	emit_h ("  char cpad1[%d];\n", DataPad[0]);
    }

  emit_h ("} OZ%sStaticObject_Rec, *OZ%sStaticObject;\n\n", vid, vid);
  
  emit_h ("#ifdef OZ_StaticObject_");
  EmitClassName (current_file, ct->symbol->string);
  emit_h ("\n");
  emit_h ("#undef OZ_StaticObject_");
  EmitClassName (current_file, ct->symbol->string);
  emit_h ("\n");
  emit_h ("#endif\n");
  emit_h ("#define OZ_StaticObject_");
  EmitClassName (current_file, ct->symbol->string);
  emit_h (" OZ%sStaticObject\n\n", vid);
}

static void
emit_h_record (OO_ClassType ct)
{
#if 0
  EmitUsedHeaderInRecord (PublicOutputFileH);
  EmitUsedHeader (PublicOutputFileH);
#endif
  EmitUsedHeader (PublicOutputFileH);
  EmitRecordMemberDefinition (ct);
  EmitMethodsHeader (current_file);
}

static void
  emit_h_exception (OO_Symbol sym)
{
  Emit (current_file, "static OZ_ExceptionIDRec OZ_%s_%s = {0x%sLL, %d};\n",
	vid, sym->string, vid, sym->slot_no2);
}

static void
emit_h_shared (OO_ClassType ct)
{
  OO_Symbol member = ct->block->vars;
  int count = 0;

  while (member)
    {
      if (member->is_variable)
	emit_h_const (member, member->type->type_scqf_rec.type);
      else
	{
	  member->slot_no2 = count++;
	  emit_h_exception (member);
	}
      
      member = member->link;
    }

  Emit (current_file, "\n");
}

void
EmitHeader (OO_ClassType ct)
{
  switch (Part)
    {
    case PUBLIC_PART:
      current_file = PublicOutputFileH;
      sprintf (vid, "%08x%08x", 
	       (int)(ct->class_id_public >> 32), 
	       (int)(ct->class_id_public & 0xffffffff));

      if (ThisClass->cl != TC_Object)
	EmitUsedClasses (current_file);
      else
	emit_h_inherited ();
      break;
    case PROTECTED_PART:
      current_file = ProtectedOutputFileH;
      sprintf (vid, "%08x%08x", 
	       (int)(ct->class_id_protected >> 32), 
	       (int)(ct->class_id_protected & 0xffffffff));
      break;
    case PRIVATE_PART:
      current_file = PrivateOutputFileH;
      sprintf (vid, "%08x%08x", 
	       (int)(ct->class_id_implementation >> 32), 
	       (int)(ct->class_id_implementation & 0xffffffff));
      EmitUsedClasses (current_file);
      break;
    }

  emit_h ("#ifndef _OZ%sP_H_\n", vid);
  emit_h ("#define _OZ%sP_H_\n\n", vid);
  
  if (ThisClass->qualifiers == SC_SHARED)
    emit_h_shared (ct);
  
  else if (ThisClass->qualifiers == SC_STATIC)
    emit_h_static_class (ct);

#if 1
  else if (ThisClass->qualifiers == SC_RECORD)
    emit_h_record (ct);
#endif
  
  else
    emit_h_class (ct);
    
  emit_h ("#endif _OZ%sP_H_\n", vid);
}

#if 0
void
EmitRecordHeader (OO_ClassType ct)
{
  current_file = PublicOutputFileH;
  sprintf (vid, "%08x%08x", 
	   (int)(ct->class_id_public >> 32), 
	   (int)(ct->class_id_public & 0xffffffff));
  emit_h_record (ct);
}
#endif

void
EmitRecordMemberDefinition (OO_ClassType ct)
{
  char vid[17];

  sprintf (vid, "%08x%08x", 
	   (int)(ct->class_id_public >> 32), 
	   (int)(ct->class_id_public & 0xffffffff));

  emit_h ("#ifndef _OZ%sTYPE_\n", vid);
  emit_h ("#define _OZ%sTYPE_\n\n", vid);
  emit_h ("typedef struct OZ%sRecord_Rec {\n", vid);

  if (ct->status != CLASS_NONE)
    {
      OO_Symbol member;

      if (!ct->block)
	{
	  OO_List list = ct->public_list;
	  while (list)
	    {
	      member = (OO_Symbol) list->car;

	      if (member->is_variable)
		emit_h_member (member, member->type, 0, 1);
	      
	      list = &list->cdr->list_rec;
	    }
	}
      else
	{
	  member = ct->block->vars;
	  while (member)
	    {
	      if (member->is_variable)
		emit_h_member (member, member->type, 0, 1);
	      
	      member = member->link;
	    }
	}
    }
  
  emit_h ("} OZ%sRecord_Rec, *OZ%sRecord;\n\n", vid, vid);

  emit_h ("typedef struct OZ%sRecord_Rec_Sub {\n", vid);
  emit_h ("  struct OZ_HeaderRec head;\n");
  emit_h ("  struct OZ%sRecord_Rec data;\n", vid);
  emit_h ("} OZ%sRecord_Rec_Sub, *OZ%sRecord_Sub;\n\n", vid, vid);
  emit_h ("#endif _OZ%sTYPE_\n\n", vid);

#if 0
  emit_h ("#define OzLangRecordSize_%s %d\n\n", vid, ct->size);
#endif
}
